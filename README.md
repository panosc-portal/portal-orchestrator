# PaNOSC Portal orchestrator

## How does it work?

To implement a microservice architecture, we use an API Gateway. We chose [Kong](https://konghq.com/) for this. It manages load balancing and no-configuration communication between services. In our case, the "no-configuration" works by passing a HTTP header in each request with the "gateway address".
To simplify testing and development, a set of docker-compose configuration files is provided. It allows to launch a complete PaNOSC Portal Server in a few simple steps.
To further simplify a quickstart script is provided. Just run it to launch PaNOSC Portal!
Data inside the database are persistent until you remove the Docker volumes.

## Quick Start
```bash
./quickstart.sh
```
It copies `template.env` to `.env` (please review and adapt the configuration values to your local environment, notably for k8s configuration).

It then launch the PaNOSC Portal Server in standalone mode. It comes with a local database, with the schemas/tables/ created, but no data inside. In this mode, the Node JS debuggers are not accessible, please see further in this documentation how to do it.

## Steps to launch a standalone PaNOSC Portal Server

### Prerequisites
- docker engine is installed and working
- docker-compose is installed
### Commands
- Copy `template.env` to `.env` (If you used `quickstart.sh` without arguments, it has already been done)
- Fill in `.env` and/or comment unused configuration.
- `./quickstart up`

### Kong admin interface

- If you launched docker-compose with `-f konga.override.yml`, a Kong admin interface is also launched. This is the case with the `quickstart` script. It is available at http://localhost:1337/. You need to create an account the first time it is accessed. This account is local (nothing is sent on the internet) and does not send emails.
- After that, you need to configure the connexion to the Kong admin API. Use http://kong:8001/ as the address.
From there you can see and change every Kong objects (services, routes, targets ...) You can also explore and configure plugins.

### Import kong configuration
__First method:__

When running docker-compose up, add `-f init-routes.override.yml`.

If you used quickstart.sh without arguments, it has already been done.

Once it has been done once, it is not necessary to keep it, as it will slow down the startup of services, and show errors in the logs.

__Second method :__
- Go to http://localhost:1337/
- Create an account and a connexion if not already done
- Go to Snapshots
- Import from File `snapshot_1.json`
- Open snapshot details > restore > select all checkboxes (services, routes ...)
- If there is some errors about foreign keys, restore again (see step above)

__Third method (you need [HTTPie](https://httpie.io/) installed):__
```bash
http POST localhost:8001/services/ name=api-service url=http://api-service/
http POST localhost:8001/services/ name=account-service url=http://account-service/
http POST localhost:8001/services/ name=cloud-service url=http://cloud-service/
http POST localhost:8001/services/ name=cloud-provider-kubernetes url=http://cloud-provider-kubernetes/

http POST localhost:8001/routes/ name=api-service-route service:='{"name":"api-service"}' paths:='["/api-service/"]'
http POST localhost:8001/routes/ name=account-service-route service:='{"name":"account-service"}' paths:='["/account-service/"]'
http POST localhost:8001/routes/ name=cloud-service-route service:='{"name":"cloud-service"}' paths:='["/cloud-service/"]'
http POST localhost:8001/routes/ name=cloud-provider-kubernetes-route service:='{"name":"cloud-provider-kubernetes"}' paths:='["/cloud-provider-kubernetes/"]'

http POST localhost:8001/upstreams/ name=api-service
http POST localhost:8001/upstreams/ name=account-service
http POST localhost:8001/upstreams/ name=cloud-service
http POST localhost:8001/upstreams/ name=cloud-provider-kubernetes

http POST localhost:8001/upstreams/api-service/targets/ target=api-service:4020
http POST localhost:8001/upstreams/account-service/targets/ target=account-service:4011
http POST localhost:8001/upstreams/cloud-service/targets/ target=cloud-service:4010
http POST localhost:8001/upstreams/cloud-provider-kubernetes/targets/ target=cloud-provider-kubernetes:4000

http POST localhost:8001/plugins/ name=request-transformer config.add.headers=Gateway-host:kong:8000 -f
```

### Exposed ports
Each microservice is exposed via the Kong API gateway at `http://localhost:8000/<service>/`.
For example, to access api-service you can use `http://localhost:8000/api-service/api/v1/`.

It is also available directly. To see on which port each service is available, please use: 
```
docker-compose -f docker-compose.yml -f konga.override.yml ps
```
For example, to access api-service you can use `http://localhost:4011/api/v1/`.

### How to stop the server
To stop a running environnment, simply hit `Ctrl-C`.
Alternatively, you can launch everything detached by adding -d to the command, and stop everything by replacing `up` with `down` in the command.
The `docker-compose down` command is also useful to clean most objects (containers, networks ...) previously created. 

## Steps to launch a development environment

### Prerequisites
Each microservice code is cloned in a directory. It must keep the repo name and be located one directory level above the docker compose files.
```bash
git clone https://github.com/panosc-portal/api-service
git clone https://github.com/panosc-portal/account-service
git clone https://github.com/panosc-portal/cloud-service
git clone https://github.com/panosc-portal/cloud-provider-kubernetes
```
Run `npm install` and `npm run build` for each microservice.

### Launch command
Launch process and configuration is the same except that you add another docker-compose file:

```
docker-compose -f docker-compose.yml -f develop.override.yml -f konga.override.yml up
```
> WARNING : sometime the command hang during the `npm install` part of an image creation. If this is the case, relaunch the command and it should be fine.

### Development and debugging
For each microservice an additional port (starting at 9229) is exposed for the Javascript debugger. Type
```
docker-compose -f docker-compose.yml -f konga.override.yml-f develop.override.yml ps
```
to see the exposed ports of the different services.

By default the `develop.override.yml` file specifies the following debug ports:

| service| debug port |
|--------|------------|
| account-service | 9229 |
| api-service | 9230 |
| cloud-service | 9231 |
| cloud-provider-kubernetes | 9232 |

Example VS Code launch config to connect to the debugger (you may need tp change the `localRoot` accordingly depending on where you launch the debugging task):
```json
{
    "address": "localhost",
    "localRoot": "${workspaceFolder}/account-service/",
    "name": "Debug Account service",
    "port": 9229,
    "remoteRoot": "/home/node/app/",
    "request": "attach",
    "skipFiles": [
        "<node_internals>/**"
    ],
    "type": "pwa-node"
}
```

### Live reload
In debug mode, the local source code is mounted as a volume on `/home/node/app/` for each container. JS files are watched for modifications (TypeScript files are not watched yet). If you make local modifications and run `npm run build`, the microservice will be reloaded.

### Running and developing a microservice locally (without docker)
In certain cases when developing a microservice it is useful to run it locally rather than in a container. This is true especially for Java microservices (for which live reload is not available) or for Node.js microservices where `node_modules` contains symbolic links which are not propagated into the container.

Running the portal as shown above (with or without `develop.override.yml`) you need to then run a small *service registrar* application. The registrar will listen for different microservices running locally and automatically insert them into the Kong API gateway. All API requests for that microservice will the be redirected to your locally running one.

To run the *service registrar* type the following command:
```
./run-dev-registrar.sh
```
This starts up the registrar application and listens to specific ports for active local microservices. 

The following table shows the ports on which the local microservices should run (this can be modified by editing `dev-registrar/services-info.json`):

|service| local port|
|-------|-----------|
| account-service | 5011 |
| api-service | 5020 |
| cloud-service | 5010 |
| cloud-provider-kubernetes | 5000 |

Running a microservice locally means that you can develop and debug directly using an IDE rather than using the remote debugging outlined above. You will also obviously need to provide a `.env` file specific to the local microservice (you can extract the relevant section from the `template.env` provided here).

