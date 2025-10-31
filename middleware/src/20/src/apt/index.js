'use strict';

import { existsSync, readFileSync } from 'fs';
import { resolve } from 'path';
import fastifyFactory from 'fastify';
import fastifyCors from '@fastify/cors';


const httpPort = parseInt(process.env.LISTEN_PORT_HTTP || process.argv[2] || 443)
const httpListenHost = '0.0.0.0'
const listenPort = httpPort
const listenHost = httpListenHost

// TLS certificate paths
const certPath = resolve(`${process.env.CERTIFICATE_PATH}`);
const keyPath = resolve(`${process.env.CERTIFICATE_KEY_PATH}`);

// THIS FIXES PINO'S UNDEFINED LOG LEVEL ERROR
const validLogLevels = ['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent'];
const resolvedLogLevel = validLogLevels.includes(process.env.LOG_LEVEL)
  ? process.env.LOG_LEVEL
  : 'debug';

// // Shared logger config
const loggerConfig = {
level: resolvedLogLevel,
  transport: {
    target: 'pino-pretty',
    options: { 
      translateTime: 'SYS:standard',
      ignore: 'pid,hostname' // optional: cleaner output
    }
  }
};

// Create HTTP and HTTPS Fastify instances
const fastifyHttp = fastifyFactory({ logger: loggerConfig });
const fastifyHttps = fastifyFactory({
  logger: loggerConfig,
  https: {
    key: existsSync(keyPath) ? readFileSync(keyPath) : undefined,
    cert: existsSync(certPath) ? readFileSync(certPath) : undefined
  }
});
fastifyHttps.log.trace('Sample trace message: HTTPS server initialized');
fastifyHttps.log.debug('Sample debug message: HTTPS server initialized');
fastifyHttps.log.warn('Sample warn message: HTTPS server initialized');
fastifyHttps.log.info('Sample info message: HTTPS server initialized');
fastifyHttps.log.error('Sample error message: HTTPS server initialized');
fastifyHttp.all('*', async (req, reply) => {
  const host = req.headers.host;
  const url = req.raw.url;
  fastifyHttp.log.info(`Redirecting HTTP request to https://${host}${url}`);
  reply.redirect(`https://${host}${url}`);
});
fastifyHttp.addHook('onRequest', async (req, reply) => {
  if (!req.raw.socket.encrypted) {
    reply.code(403).send({ error: 'TLS required' });
  }
});

// Shared route registration function
const registerRoutes = (app) => {
  app.register(fastifyCors, {
    origin: process.env.CORS_ORIGIN,
    methods: ['GET', 'POST'],
    credentials: true
  });

  app.get('/chat', async (req, reply) => {
    try {
      reply.send("this is it works as written");
    } catch (err) {
      app.log.error(err);
      reply.code(500).send({
        timestamp: new Date().toISOString(),
        status: 'error',
        error: err.message,
        message: 'Unexpected error occurred'
      });
    }
  });

};

registerRoutes(fastifyHttps);

// Start both servers
const start = async () => {
  try {
    await fastifyHttp.listen({ port: listenPort, host: listenHost });
    fastifyHttp.log.info(`HTTP middleware listening on port ${listenPort}`);

  } catch (err) {
    console.error('Startup error:', err);
    process.exit(1);
  }
};

start();
