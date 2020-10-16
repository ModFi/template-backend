FROM node:alpine AS builder
ARG NPM_TOKEN_PARAM
ENV NPM_TOKEN=$NPM_TOKEN_PARAM
ENV NPM_URL=https://npm.pkg.github.com/ 
WORKDIR /usr/modfi/app
COPY package*.json .npmrc ./ 
RUN echo "//npm.pkg.github.com/:_authToken=$NPM_TOKEN" >> .npmrc && \
    npm install && \
    npm install -g retire && \
    retire
COPY . .
RUN ./node_modules/.bin/tsc

FROM python:3.7-alpine
WORKDIR /usr/modfi/app
RUN pip install njsscan==0.1.5 && \
    apk --no-cache add git ca-certificates gcc libc-dev
COPY .npmrc package*.json ./
COPY --chown=root:root --from=builder /usr/modfi/app/dist /usr/modfi/app
RUN njsscan /usr/modfi/app

FROM 002458576405.dkr.ecr.us-east-1.amazonaws.com/default:node
ARG NPM_TOKEN_PARAM
ENV NPM_TOKEN=$NPM_TOKEN_PARAM
ENV NPM_URL=https://npm.pkg.github.com/
WORKDIR /usr/modfi/app
COPY package*.json .npmrc ./ 
RUN echo "//npm.pkg.github.com/:_authToken=$NPM_TOKEN" >> .npmrc
COPY --from=builder /usr/modfi/app/dist dist
COPY ./docs/api/v1 ./docs/api/v1
RUN npm install --production 
EXPOSE 3000 2222
CMD ["/usr/local/bin/docker-entrypoint.sh"]
