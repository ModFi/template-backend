![Create Tag & Release After Dev Deploy](https://github.com/ModFi/##REPO##/workflows/Create%20Tag%20&%20Release%20After%20Dev%20Deploy/badge.svg)
![Update Service From Release](https://github.com/ModFi/##REPO##/workflows/Update%20Service%20From%20Release/badge.svg)

# Base Readme

Created automatically using as base the template repository

# Things to do

Replace on the readme file the string `##REPO##` to the repository name.
Also, either at `src/Application.ts` or at the swagger config `docs/api/v1/assets/openapi.yaml` you must replace the strings `##SERVICE##` and `##PORT` with the service name and the port (for local development) respectively.  

Also, add to the env variable `API_DOCS_ENABLED` in order to enable swagger docs.  


Corresponding to the `NODE_ENV` value in the npm script you're running, differents `.env` files will load. Please refer to `src/Environment.ts` to see how that works.

Run `npm install` and then `npm run ts` and test your health endpoint. If your server port locally is other than `3000` please add it to the corresponding `.env` file. 

#### IMPORTANT !!!
Do not delete the branchs until you know that it's not going to be deployed on Qa/Prod environments because it deletes the Release Tag too.

### Shared Modfi Library

https://github.com/ModFi/backend-utils

## Github & Jira integration
When a developer makes a commit, they should add a Jira Software issue key to the commit message,  
For example:  
`git commit -m "PROJ-123 add a README file to the project."`
`git push origin <branchname>`
  
Also, it works for the Pull request if you put the issue /story key on the Pull request title .

## Sonarqube url [Site](http://54.158.192.246:9000)
Where the analyzed code status is

## See [Github Actions & Environment Status](https://github.com/ModFi/action-dashboard)
Where you find out all the status of the services and their version

## Useful Links to read

[How to start working on a new service](https://modfi.atlassian.net/wiki/spaces/AR/pages/235470855/How+start+working+on+a+new+Service+Api)

[Docker Compose Local Environment](https://modfi.atlassian.net/wiki/spaces/AR/pages/259293213/Local+Docker+compose+environment)

[Application Ci/Cd](https://modfi.atlassian.net/wiki/spaces/AR/pages/141459459/Application+CI+CD)

[Dev Aws Account Details](https://modfi.atlassian.net/wiki/spaces/AR/pages/198279169/Dev+Aws+Account+Details)

[Aws User Account Setup](https://modfi.atlassian.net/wiki/spaces/AR/pages/226918421/User+Account+Setup)

[How services connect](https://modfi.atlassian.net/wiki/spaces/AR/pages/230129665/How+the+services+connect+.)

[Accessing inside the containers](https://modfi.atlassian.net/wiki/spaces/AR/pages/260112385/Accesing+inside+the+containers+from+the+Jump+Box)

See all the another confluence pages to have more details .






