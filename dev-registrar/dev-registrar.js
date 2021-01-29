const portastic = require('portastic');
const axios = require('axios');
const winston = require('winston');
const format = winston.format;
const transports = winston.transports;

const logger = winston.createLogger({
  level: 'info',
  transports: [
    new transports.Console({
      format: format.combine(
        format.colorize(),
        format.timestamp({
          format: 'YYYY-MM-DD HH:mm:ss'
        }),
        format.printf(info => {
          return `${info.timestamp} ${info.level}: ${info.message}`;
        })
      )
    })
  ]
});

const KONG_URL = 'http://localhost:8001/upstreams';
const HOST_FROM_DOCKER = 'host.docker.internal';

// List of all services and default local ports
const servicesInfo = require('./services-info');

// Create axios http client
const httpClient = axios.create({ baseURL: KONG_URL });

// Map ports to services
const portsToServices = servicesInfo.reduce((agg, serviceInfo) => {
  agg[serviceInfo.port] = serviceInfo.service
  return agg;
}, {});

// Monitor all ports
const portsToMonitor = servicesInfo.map(serviceInfo => serviceInfo.port);
const monitor = new portastic.Monitor(portsToMonitor, {
  interval: 500
});
monitor.on('open', port => onServiceStopped(port));
monitor.on('close', port => onServiceStarted(port));

// Called when a service starts
const onServiceStarted = function (port) {
  const service = portsToServices[port];
  console.log(`${service} running locally`);

  const localServiceAddress = `${HOST_FROM_DOCKER}:${port}`;

  // Get all upstream targets for the service
  httpClient.get(`${service}/targets`)
    .then(response => {
      const targets = response.data.data;
      const devTargetExists = targets.find(target => target.target === localServiceAddress);

      // Add target if it doesn't already exist
      if (!devTargetExists) {
        console.log(`adding ${service} dev target to kong and deactivating the others`);
        httpClient.post(`${service}/targets`, {target: localServiceAddress})
          .then(() => {
            // Mark all other targets as unhealthy
            targets.forEach(target => {
              httpClient.post(`${service}/targets/${target.target}/unhealthy`);
            });
          });
      }
  });
}

// Called when a service stops
const onServiceStopped = function (port) {
  const service = portsToServices[port];
  logger.info(`${service} not running locally`);

  const localServiceAddress = `${HOST_FROM_DOCKER}:${port}`;

  httpClient.get(`${service}/targets`)
    .then(response => {
      const targets = response.data.data;
      const devTargetExists = targets.find(target => target.target === localServiceAddress);

      if (devTargetExists) {
        console.log(`removing ${service} dev target from kong and reactivating the others`);
        httpClient.delete(`${service}/targets/${localServiceAddress}`)
          .then(() => {
            const remainingTargets = targets.filter(target => target.target !== localServiceAddress)
            // Mark all other targets as healthy
            remainingTargets.forEach(target => {
              httpClient.post(`${service}/targets/${target.target}/healthy`);
            });
          });
      }
    });
}
