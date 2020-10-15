#!/bin/bash
set -o nounset
trap bucket 1 2 3 6

function fail {
  echo $1 >&2
  exit 1
}

function retry {
  local n=1
  local max=3
  local delay=5
  while true; do
    "$@" && break || {
      if [[ $n -lt $max ]]; then
        ((n++))
        echo "================================"
        echo "Command failed. Attempt $n/$max:"
        echo "================================"
        sleep $delay;
      else
        fail "The command has failed after $n attempts."
      fi
    }
  done
}

bucket()
{
    echo "${EXISTING_BUCKET_REPLICATION}" >> old.json
    retry aws s3api put-bucket-replication --bucket $FIRST_ORIGIN_NAME --replication-configuration $(cat old.json)
}

distributions=($(retry aws cloudfront list-distributions | jq -r '.DistributionList.Items[] | .Id'))
IFS=

rm -f cdn.json origins.json old.json new.json

echo "============================================================================================================="
echo "CLOUDFRONT BLUE GREEN DEPLOYMENT                                                                           "                   
echo "============================================================================================================="
for i in "${distributions[@]}"
do
  echo "==========================================================================================================="
  echo "Obtaining Cloudfront (ID: ${i}) definition file"
  retry aws cloudfront get-distribution-config --id ${i} >> cdn.json

  CDN=$(cat cdn.json | jq -r 'del(.ETag)')
  
  echo "Obtaining Cloudfront (ID: ${i}) Data from the definition file"
  echo "==========================================================================================================="
  echo $CDN | jq '.DistributionConfig.OriginGroups.Items[].Members.Items[0].OriginId' | sed 's|"||g'
  FIRST_ORIGIN=$(echo $CDN | jq '.DistributionConfig.OriginGroups.Items[].Members.Items[0].OriginId' | sed 's|"||g')
  SECOND_ORIGIN=$(echo $CDN | jq '.DistributionConfig.OriginGroups.Items[].Members.Items[1].OriginId' | sed 's|"||g')
  FIRST_ORIGIN_DOMAIN=$(echo $CDN | jq --arg a ${FIRST_ORIGIN} '.DistributionConfig.Origins.Items[] | select(.Id==$a) | .DomainName' | sed 's|"||g')
  SECOND_ORIGIN_DOMAIN=$(echo $CDN | jq --arg a ${SECOND_ORIGIN} '.DistributionConfig.Origins.Items[] | select(.Id==$a) | .DomainName' | sed 's|"||g')
  FIRST_ORIGIN_NAME=$(echo $FIRST_ORIGIN_DOMAIN | sed 's|.s3.amazonaws.com||g')
  SECOND_ORIGIN_NAME=$(echo $SECOND_ORIGIN_DOMAIN | sed 's|.s3.amazonaws.com||g')
  
  echo "==========================================================================================================="
  echo "First Origin Name: ${FIRST_ORIGIN}"
  echo "First S3 DomainName: ${FIRST_ORIGIN_DOMAIN}"
  echo "First S3 Name: ${FIRST_ORIGIN_NAME}"
  
  echo "Second Origin Name: ${SECOND_ORIGIN}"
  echo "Second S3 DomainName: ${SECOND_ORIGIN_DOMAIN}"
  echo "Second S3 Name: ${SECOND_ORIGIN_NAME}"
  echo "==========================================================================================================="
  
  echo "==========================================================================================================="
  echo "Obtaining s3 replication from the main one ${FIRST_ORIGIN_NAME}"
  echo "==========================================================================================================="

  EXISTING_BUCKET_REPLICATION=$(retry aws s3api get-bucket-replication --bucket $FIRST_ORIGIN_NAME | jq -r '.ReplicationConfiguration')
  echo "${EXISTING_BUCKET_REPLICATION}" >> old.json
  if [[ -n "$EXISTING_BUCKET_REPLICATION" ]]; then
    NEW_BUCKET_REPLICATION=$(echo $EXISTING_BUCKET_REPLICATION | sed "s|$SECOND_ORIGIN_NAME|$FIRST_ORIGIN_NAME|g")
	echo "${NEW_BUCKET_REPLICATION}" >> new.json
    echo "==========================================================================================================="
    echo "Removing s3 replication from the primary bucket ${FIRST_ORIGIN_NAME} to the failover ${SECOND_ORIGIN_NAME}"
    echo "==========================================================================================================="
	echo $EXISTING_BUCKET_REPLICATION
    retry aws s3api delete-bucket-replication --bucket $FIRST_ORIGIN_NAME
	BUCKET_DELETED="1"
  else
    echo "==========================================================================================================="
    echo "There are no replication config on the primary bucket ${FIRST_ORIGIN_NAME}"
	echo "==========================================================================================================="
    exit 1	
  fi
    
  echo "==========================================================================================================="
  echo "Deploying app on the secondary Bucket ${SECOND_ORIGIN_NAME}"
  echo "==========================================================================================================="
  
  retry aws s3 sync --sse AES256 dist/modfi-app/ s3://${SECOND_ORIGIN_NAME}/ --acl public-read
  
  echo "==========================================================================================================="
  echo "Disable Caching for the Origin Group"
  echo "==========================================================================================================="
  CDN=$(echo $CDN | jq '.DistributionConfig.CacheBehaviors.Items[0].MinTTL = 0')
  CDN=$(echo $CDN | jq '.DistributionConfig.CacheBehaviors.Items[0].MaxTTL = 0')
  CDN=$(echo $CDN | jq '.DistributionConfig.CacheBehaviors.Items[0].DefaultTTL = 0')
  previous=$(retry aws cloudfront get-distribution-config --id $i)
  result=$(retry aws cloudfront update-distribution --id $i --distribution-config $(echo $CDN |jq -r .DistributionConfig) --if-match $(echo "$previous" | jq -r '.ETag'))
  echo "$(echo $result | jq -r '.Distribution.Id + ": " + .Distribution.Status')"
  aws cloudfront wait distribution-deployed --id $i && echo "Cloudfront Modification Completed";
  
  echo "==========================================================================================================="
  echo "Invalidating the Cache"
  echo "==========================================================================================================="
  INVALIDATION=$(retry aws cloudfront create-invalidation --distribution-id ${i} --paths="/*" | jq .Invalidation.Id | sed 's|"||g') #Obtain Id
  if [[ -n "$INVALIDATION" ]]; then
	aws cloudfront wait invalidation-completed --id ${INVALIDATION} --distribution-id ${i} && echo "Cloudfront Invalidation ${INVALIDATION} Completed";
  else
    echo "==========================================================================================================="
    echo "Error the invalidation wasnt executed"
	echo "==========================================================================================================="
  fi
done
rm -f cdn.json
echo $CDN > cdn.json
echo "==========================================================================================================="
echo "Tests has to be performed"
echo "==========================================================================================================="
