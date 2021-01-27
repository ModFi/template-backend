FROM node:alpine AS builder
ARG NPM_TOKEN_PARAM
ENV NPM_TOKEN=$NPM_TOKEN_PARAM
ENV NPM_URL=https://npm.pkg.github.com/ 
WORKDIR /usr/modfi/app
COPY package*.json .npmrc .njsscan ./ 
RUN echo "//npm.pkg.github.com/:_authToken=$NPM_TOKEN" >> .npmrc && \
    npm install && \
    npm install -g retire && \
    retire
COPY . .
RUN ./node_modules/.bin/tsc

FROM python:3.7-alpine
WORKDIR /usr/modfi/app
RUN pip install njsscan==0.1.5 && \
    apk --no-cache add git ca-certificates gcc libc-dev npm
COPY --chown=root:root --from=builder /usr/modfi/app /usr/modfi/app
RUN njsscan --json --missing-controls /usr/modfi/app

FROM sonarsource/sonar-scanner-cli
WORKDIR /usr/src
ARG NPM_TOKEN_PARAM
ENV NPM_TOKEN=$NPM_TOKEN_PARAM
ARG ECS_SERVICE
ENV ECS_SERVICE_NAME=$ECS_SERVICE
ARG SONARQUBE_HOST
ENV SONARQUBE_HOST_URL=$SONARQUBE_HOST
ARG SONARQUBE_TOKEN
ENV SONARQUBE_TOKEN_PARAM=$SONARQUBE_TOKEN
COPY .npmrc package*.json ./
COPY --from=builder /usr/modfi/app/dist .
RUN echo "//npm.pkg.github.com/:_authToken=$NPM_TOKEN" >> .npmrc && \
    npm install --production && \
    npm install -D typescript
RUN sonar-scanner -Dsonar.projectKey=${ECS_SERVICE_NAME} -Dsonar.sources=. -Dsonar.host.url=http://${SONARQUBE_HOST_URL}:9000 -Dsonar.login=${SONARQUBE_TOKEN_PARAM}

FROM 002458576405.dkr.ecr.us-east-1.amazonaws.com/default:node
ARG NPM_TOKEN_PARAM
ENV NPM_TOKEN=$NPM_TOKEN_PARAM
ENV NPM_URL=https://npm.pkg.github.com/
WORKDIR /usr/modfi/app
COPY package*.json .npmrc ./ 
RUN echo "//npm.pkg.github.com/:_authToken=$NPM_TOKEN" >> .npmrc
COPY --from=builder /usr/modfi/app/dist dist
COPY ./docs/api/v1 ./docs/api/v1
RUN npm install --production;ls -la 
EXPOSE 3000 2222
CMD ["/usr/local/bin/docker-entrypoint.sh"]
