'use strict';

import { existsSync, readFileSync } from 'fs';
import { resolve } from 'path';
import fastifyFactory from 'fastify';
import fastifyCors from '@fastify/cors';
import { Pool } from 'pg';


const httpPort = parseInt(process.env.LISTEN_PORT_HTTP || process.argv[2] || 80 || 443)
const httpListenHost = '0.0.0.0'
const listenPort = httpPort
const listenHost = httpListenHost

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
const fastify = fastifyFactory({ logger: loggerConfig });

// TLS certificate paths
// const certPath = resolve(`${process.env.CERTIFICATE_PATH}`);
// const keyPath = resolve(`${process.env.CERTIFICATE_KEY_PATH}`);
// const fastify = fastifyFactory({
//   logger: loggerConfig,
//   https: {
//     key: existsSync(keyPath) ? readFileSync(keyPath) : undefined,
//     cert: existsSync(certPath) ? readFileSync(certPath) : undefined
//   }
// });
fastify.log.trace('Sample trace message: HTTPS server initialized');
fastify.log.debug('Sample debug message: HTTPS server initialized');
fastify.log.warn('Sample warn message: HTTPS server initialized');
fastify.log.info('Sample info message: HTTPS server initialized');
fastify.log.error('Sample error message: HTTPS server initialized');
// fastify.all('*', async (req, reply) => {
//   const host = req.headers.host;
//   const url = req.raw.url;
//   fastify.log.info(`Redirecting HTTP request to https://${host}${url}`);
//   reply.redirect(`https://${host}${url}`);
// });
// fastify.addHook('onRequest', async (req, reply) => {
//   if (!req.raw.socket.encrypted) {
//     reply.code(403).send({ error: 'TLS required' });
//   }
// });

// PostgreSQL connection pool (Kubernetes service)
const pool = new Pool({
  host: process.env.PG_HOST,
  database: process.env.PG_DATABASE,
  user: process.env.PG_USER,
  password: process.env.PG_PASSWORD,
  port: process.env.PG_PORT,
  // ,max: 10,
  // idleTimeoutMillis: 30000,
  // ssl: process.env.DB_SSL === 'true'
});

// Shared route registration function
const registerRoutes = (app) => {
  app.register(fastifyCors, {
    origin: process.env.CORS_ORIGIN,
    methods: ['GET', 'POST'],
    credentials: true
  });

  app.get('/products', async (req, reply) => {
    let client;
    try {
      client = await pool.connect();
      const { rows } = await client.query('SELECT * FROM products');
      reply.send(rows);
    } catch (err) {
      app.log.error(err);
      reply.code(500).send({
        timestamp: new Date().toISOString(), // Adds ISO 8601 formatted timestamp
        status: 'error',
        error: err.message,
        message: 'Failed to fetch products'
      });
    } finally {
      if (client) client.release();
    }
  });

  app.get('/products/:id', async (req, reply) => {
    let client;
    try {
      client = await pool.connect();
      const { rows } = await client.query(
        'SELECT * FROM products WHERE id=$1',
        [req.params.id]
      );
      if (rows.length === 0) {
        reply.code(404).send({
          status: 'not_found',
          id: req.params.id,
          message: 'Product not found'
        });
      } else {
        reply.send(rows[0]);
      }
    } catch (err) {
      app.log.error(err);
      reply.code(500).send({
        timestamp: new Date().toISOString(), // Adds ISO 8601 formatted timestamp
        status: 'error',
        error: err.message,
        id: req.params.id,
        message: 'Failed to fetch product'
      });
    } finally {
      if (client) client.release();
    }
  });

  app.get('/health/db', async (req, reply) => {
    let client;
    try {
      client = await pool.connect();
      await client.query('SELECT 1');
      reply.send({ status: 'ok', message: 'Database connection success' });
    } catch (err) {
      app.log.error(err);
      reply.code(500).send({
        timestamp: new Date().toISOString(), // Adds ISO 8601 formatted timestamp
        status: 'error',
        error: err.message,
        message: 'Database unreachable'
      });
    } finally {
      if (client) client.release();
    }
  });

  app.get('/debug', async (req, reply) => {
    try {
      reply.send({
        status: 'ok',
        env: process.env.NODE_ENV || 'dev',
        dbPool: {
          total: pool.totalCount,
          idle: pool.idleCount,
          waiting: pool.waitingCount
        },
        tlsEnabled: !!req.server?.setSecureContext
      });
    } catch (err) {
      app.log.error(err);
      reply.code(500).send({
        timestamp: new Date().toISOString(), // Adds ISO 8601 formatted timestamp
        status: 'error',
        error: err.message,
        message: 'Failed to generate debug info'
      });
    }
  });


  app.addHook('onClose', async () => {
    await pool.end();
    app.log.info('PostgreSQL pool closed');
  });
};

registerRoutes(fastify);

// Start both servers
const start = async () => {
  try {
    await fastify.listen({ port: listenPort, host: listenHost });
    fastify.log.info(`HTTP middleware listening on port ${listenPort}`);
  } catch (err) {
    console.error('Startup error:', err);
    process.exit(1);
  }
};

start();
