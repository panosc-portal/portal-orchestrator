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

- If you launched quickstart with `-k`, a Kong admin interface is also launched. It is available at `http://localhost:1337/`. You need to create an account the first time it is accessed. This account is local (nothing is sent on the internet) and does not send emails.
- After that, you need to configure the connexion to the Kong admin API. Use `http://kong:8001/` as the address.
From there you can see and change every Kong objects (services, routes, targets ...) You can also explore and configure plugins.

### Import kong configuration
__First method:__

When running quickstart.sh up, add `-i`.

Once it has been done once, it is not necessary to keep it, as it will slow down the startup of services, and show errors in the logs.

__Second method (you need [HTTPie](https://httpie.io/) installed):__

Run `bash routes.sh`. (__warning:__ there's a sleep at the beginning, it take a while to start)

### Exposed ports
Each microservice is exposed via the Kong API gateway at `http://localhost:8000/<service>/`.
For example, to access api-service you can use `http://localhost:8000/api-service/api/v1/`.

It is also available directly. To see on which port each service is available, please use: 
```
./quickstart.sh ps
```

By default the following ports are open for the microservices:
| service | Exposed ports |
|---------|---------------|
| account-service | 4011 |
| desktop-service | 4021 (api) & 4022 (ws) |
| api-service | 4020 |
| cloud-service | 4010 |
| cloud-provider-kubernetes | 4000 |

For example, to access api-service you can use `http://localhost:4011/api/v1/`.

### How to stop the server
To stop a running environnment, simply hit `Ctrl-C`.
Alternatively, you can launch everything detached by adding -d to the command, and stop everything by replacing `up` with `down` in the command.
The `./quickstart.sh down` command is also useful to clean most objects (containers, networks ...) previously created. 

## Steps to launch a development environment

### Prerequisites
Each microservice code is cloned in a directory. It must keep the repo name and be located one directory level above the docker compose files.
```bash
git clone https://github.com/panosc-portal/api-service
git clone https://github.com/panosc-portal/desktop-service
git clone https://github.com/panosc-portal/account-service
git clone https://github.com/panosc-portal/cloud-service
git clone https://github.com/panosc-portal/cloud-provider-kubernetes
```

Depending on the microservice language (see below), run the following commands to build them:
 * Node.js: `npm install` and `npm run build`
 * Java: `mvn package` (with `-DskipTests=true` if you don't want to run the unit tests)

The following table shows the language of each microservice:

| Service | Language |
|---------|----------|
| account-service | Javascript |
| api-service | Javascript |
| cloud-service | Javascript |
| cloud-provider-kubernetes | Javascript |
| desktop-service | Java |

### Launch command
Launch process and configuration is the same except that you add another argument to `quickstart.sh`:

```
./quickstart.sh -d
```
> WARNING : sometime the command hang during the `npm install` part of an image creation. If this is the case, relaunch the command and it should be fine.

### Development and debugging
For each microservice an additional port (starting at 9229) is exposed for the Javascript (or Java) debugger. Type
```
./quickstart.sh -d ps
```
to see the exposed ports of the different services.

By default the `develop.override.yml` file specifies the following debug ports:

| Service | Debug port |
|---------|------------|
| account-service | 9229 |
| api-service | 9230 |
| cloud-service | 9231 |
| cloud-provider-kubernetes | 9232 |
| desktop-service |9233 |

The following is an example VS Code launch config to connect to a Javascript debugger (you may need to change the `localRoot` accordingly depending on where you launch the debugging task):
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

### Live reload (applies to Javascript microservices)
In debug mode, the local source code is mounted as a volume on `/home/node/app/` for each container. JS files are watched for modifications (TypeScript files are not watched yet). If you make local modifications and run `npm run build`, the microservice will be reloaded.

Live reload is not available for Java-based microservices but the method described below provides a way of developing and debugging all microservices locally.

### Running and developing a microservice locally (without docker)
In certain cases when developing a microservice it is useful to run it locally rather than in a container. This is true especially for Java microservices (for which live reload is not available) or for Node.js microservices where `node_modules` contains symbolic links which are not propagated into the container.

Running the portal as shown above (with or without `-d`) you need to then run a small *service registrar* application. The registrar will listen for different microservices running locally and automatically insert them into the Kong API gateway. All API requests for that microservice will the be redirected to your locally running one.

To run the *service registrar* type the following command:
```
./run-dev-registrar.sh
```
This starts up the registrar application and listens to specific ports for active local microservices. 

The following table shows the ports on which the local microservices should run (this can be modified by editing `dev-registrar/services-info.json`):

|Service | Local port|
|--------|-----------|
| account-service | 5011 |
| desktop-service | 5021 (api) & 5022 (ws) |
| api-service | 5020 |
| cloud-service | 5010 |
| cloud-provider-kubernetes | 5000 |

Running a microservice locally means that you can develop and debug directly using an IDE rather than using the remote debugging outlined above. You will also obviously need to provide a `.env` file specific to the local microservice (you can extract the relevant section from the `template.env` provided here) or explicitly set the environment variables.

