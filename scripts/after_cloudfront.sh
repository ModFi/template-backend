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
  if [[ -n "$CLOUDFRONT_MODS" ]]; then
    retry aws s3api put-bucket-replication --bucket $SECOND_ORIGIN_NAME --replication-configuration $(cat new.json)
  else
    retry aws s3api put-bucket-replication --bucket $FIRST_ORIGIN_NAME --replication-configuration $(cat old.json)
  fi
}

distributions=($(retry aws cloudfront list-distributions | jq -r '.DistributionList.Items[] | .Id'))
IFS=
TEST_STATUS=$1

echo "============================================================================================================="
echo "CLOUDFRONT BLUE GREEN DEPLOYMENT                                                                           "                   
echo "============================================================================================================="

for i in "${distributions[@]}"
do
echo "Obtaining Cloudfront (ID: ${i}) Data from the definition file"
echo "==========================================================================================================="
CDN=$(cat cdn.json)
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

if [[ "$TEST_STATUS" == "success" ]]; then
  echo "==========================================================================================================="
  echo "Changing Bucket order on the Origen Group, the primary its going to be ${SECOND_ORIGIN_NAME}"
  echo "==========================================================================================================="
  CDN=$(echo $CDN | jq --arg a ${SECOND_ORIGIN} '.DistributionConfig.OriginGroups.Items[].Members.Items[0].OriginId = $a')
  CDN=$(echo $CDN | jq --arg a ${FIRST_ORIGIN} '.DistributionConfig.OriginGroups.Items[].Members.Items[1].OriginId = $a')
fi

echo "==========================================================================================================="
echo "Enabling the Cache"
echo "==========================================================================================================="
CDN=$(echo $CDN | jq '.DistributionConfig.CacheBehaviors.Items[0].MinTTL = 0')
CDN=$(echo $CDN | jq '.DistributionConfig.CacheBehaviors.Items[0].MaxTTL = 31536000')
CDN=$(echo $CDN | jq '.DistributionConfig.CacheBehaviors.Items[0].DefaultTTL = 86400')
previous=$(retry aws cloudfront get-distribution-config --id $i)  
result=$(retry aws cloudfront update-distribution --id $i --distribution-config $(echo $CDN |jq -r .DistributionConfig) --if-match $(echo "$previous" | jq -r '.ETag'))
echo "$(echo $result | jq -r '.Distribution.Id + ": " + .Distribution.Status')"
aws cloudfront wait distribution-deployed --id $i && echo "Cloudfront Modification Completed";
CLOUDFRONT_MODS="1"

echo "==========================================================================================================="
echo "Adding s3 replication"
echo "==========================================================================================================="
if [[ -n "$CLOUDFRONT_MODS" ]] && [[ "$TEST_STATUS" == "success" ]]; then
  retry aws s3api put-bucket-replication --bucket $SECOND_ORIGIN_NAME --replication-configuration $(cat new.json)
else
  retry aws s3api put-bucket-replication --bucket $FIRST_ORIGIN_NAME --replication-configuration $(cat old.json)
fi
rm -f cdn.json origins.json old.json new.json
done
