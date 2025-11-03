'use strict';

import { existsSync, readFileSync } from 'fs';
import { resolve } from 'path';
import fastifyFactory from 'fastify';
import fastifyCors from '@fastify/cors';

// Port and host configuration
const httpPort = parseInt(process.env.LISTEN_PORT_HTTP || process.argv[2] || 3001);
const httpListenHost = '0.0.0.0';
const listenPort = httpPort;
const listenHost = httpListenHost;

// Valid log levels for Pino
const validLogLevels = ['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent'];
const resolvedLogLevel = validLogLevels.includes(process.env.LOG_LEVEL)
  ? process.env.LOG_LEVEL
  : 'debug';

// Logger configuration
const loggerConfig = {
  level: resolvedLogLevel,
  transport: {
    target: 'pino-pretty',
    options: {
      translateTime: 'SYS:standard',
      ignore: 'pid,hostname'
    }
  }
};

// Create Fastify instance
const fastifyHttp = fastifyFactory({ logger: loggerConfig });

// Log startup context
fastifyHttp.log.info({
  env: process.env.NODE_ENV || 'default',
  port: listenPort,
  host: listenHost,
  logLevel: resolvedLogLevel
}, 'Fastify HTTP server starting');

// Log incoming requests
fastifyHttp.addHook('onRequest', async (req, reply) => {
  req.log.info({
    method: req.method,
    url: req.url,
    ip: req.ip
  }, 'Incoming request');
});

// Log outgoing responses
fastifyHttp.addHook('onResponse', async (req, reply) => {
  req.log.info({
    method: req.method,
    url: req.url,
    statusCode: reply.statusCode,
    responseTime: reply.getResponseTime()
  }, 'Response sent');
});

// Log uncaught errors
fastifyHttp.setErrorHandler((error, req, reply) => {
  req.log.error({ err: error }, 'Unhandled error');
  reply.code(500).send({
    status: 'error',
    error: error.message,
    timestamp: new Date().toISOString()
  });
});

// Shared route registration
const registerRoutes = (app) => {
  const resolvedCorsOrigin = process.env.CORS_ORIGIN || 'http://localhost:3001';
  app.log.info({ origin: resolvedCorsOrigin }, 'CORS origin configured');

  app.register(fastifyCors, {
    origin: resolvedCorsOrigin,
    methods: ['GET', 'POST'],
    credentials: true
  });

  app.log.info('Registering core routes: /api/welcome, /debug');

  app.get('/api/welcome', async (req, reply) => {
    try {
      req.log.info({ tlsEnabled: !!req.server?.setSecureContext }, 'TLS capability check');
      reply.send({
        status: 'ok',
        env: process.env.NODE_ENV || 'default',
        tlsEnabled: !!req.server?.setSecureContext,
        message: 'Welcome Here from server.js'
      });
    } catch (err) {
      app.log.error(err);
      reply.code(500).send({
        timestamp: new Date().toISOString(),
        status: 'error',
        error: err.message,
        message: 'Failed to welcome'
      });
    } finally {
      // Intentionally left blank for future cleanup logic
    }
  });

  app.get('/api/health', async (req, reply) => {
    try {
      req.log.info({ tlsEnabled: !!req.server?.setSecureContext }, 'TLS capability check');
      reply.send({
        status: 'ok',
        env: process.env.NODE_ENV || 'default',
        tlsEnabled: !!req.server?.setSecureContext,
        message: ''
      });
    } catch (err) {
      app.log.error(err);
      reply.code(500).send({
        timestamp: new Date().toISOString(),
        status: 'error',
        error: err.message,
        message: ''
      });
    } finally {
      // Intentionally left blank for future cleanup logic
    }
  });

  // server.post('/', async (request) => {
  //   return { reply: message ? `Echo: ${message}` : 'Please provide a message.' }
  // })
  app.post('/api/chat', async (req, reply) => {
    try {
      req.log.info({ tlsEnabled: !!req.server?.setSecureContext }, 'TLS capability check');
      const { prompt } = req.body || {};
      reply.send({
        status: 'ok',
        env: process.env.NODE_ENV || 'default',
        tlsEnabled: !!req.server?.setSecureContext,
        message: `You sent ${prompt}`
      });
    } catch (err) {
      app.log.error(err);
      reply.code(500).send({
        timestamp: new Date().toISOString(),
        status: 'error',
        error: err.message,
        message: 'Failed to generate debug info'
      });
    }
  });

  app.get('/debug', async (req, reply) => {
    try {
      reply.send({
        status: 'ok',
        env: process.env.NODE_ENV || 'default',
        tlsEnabled: !!req.server?.setSecureContext,
        message: 'Debuggery'
      });
    } catch (err) {
      app.log.error(err);
      reply.code(500).send({
        timestamp: new Date().toISOString(),
        status: 'error',
        error: err.message,
        message: 'Failed to generate debug info'
      });
    }
  });
};

registerRoutes(fastifyHttp);

// Start server
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
