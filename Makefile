start: 
	npm run dev
test: 
	npm run test
vm:
	docker-compose --env-file .env.development up --build	
vm_stop:
	docker-compose down	
vm_clean:
	docker system prune -a

stores:
	curl http://localhost:3000/offers/v1/stores
categories:
	curl http://localhost:3000/offers/v1/categories
offers:
	curl http://localhost:3000/offers/v1
health:
	curl http://localhost:3000/offers/v1/health

project: step1 step2


step2:
	npm install --save axios compression dotenv helmet jsonwebtoken jwk-to-pem morgan uuid winston
	npm install --save express-openapi-validator swagger-ui-express yamljs @types/yamljs @types/swagger-ui-express
	npm install --save-dev @types/yamljs @types/swagger-ui-express
	npm install --save-dev eslint eslint-config-airbnb-typescript eslint-plugin-import 
	npm install --save-dev @typescript-eslint/eslint-plugin @typescript-eslint/parser
	npm install --save-dev @types/compression @types/express @types/helmet
	npm install --save-dev @types/jsonwebtoken @types/jwk-to-pem
	npm install --save-dev mocha @types/mocha @types/morgan @types/node @types/uuid
	npm i --save chai-http chai 
	npm i --save-dev @types/chai @types/chai-http

step1:
	npm init -y
	npm install typescript ts-node
	npm install --save express body-parser nodemon
	mkdir lib
	mkdir lib/config
	touch lib/config/app.ts
	touch lib/server.ts
	mkdir lib/routes
	mkdir lib/model
	mkdir lib/utils
	touch lib/environment.ts
	mkdir -p docs/api/v1/assets
	
