FROM node:alpine AS builder
ARG NPM_TOKEN_PARAM
ENV NPM_TOKEN=$NPM_TOKEN_PARAM
ENV NPM_URL=https://npm.pkg.github.com/ 
WORKDIR /usr/modfi/app
COPY package*.json .npmrc ./ 
RUN echo "//npm.pkg.github.com/:_authToken=$NPM_TOKEN" >> .npmrc && \
    npm install
COPY . .
RUN ./node_modules/.bin/tsc

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
