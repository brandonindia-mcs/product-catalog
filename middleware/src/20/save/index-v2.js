'use strict';

const fs = require('fs');
const path = require('path');
const fastifyFactory = require('fastify');
const fastifyCors = require('@fastify/cors');
const { Pool } = require('pg');
require('dotenv').config();

// TLS certificate paths
const certPath = path.resolve('/certs/cert.pem');
const keyPath = path.resolve('/certs/key.pem');

// Shared logger config
const loggerConfig = {
  level: 'info',
  transport: {
    target: 'pino-pretty',
    options: { translateTime: 'SYS:standard' }
  }
};

// Create HTTP and HTTPS Fastify instances
const fastifyHttp = fastifyFactory({ logger: loggerConfig });
const fastifyHttps = fastifyFactory({
  logger: loggerConfig,
  https: {
    key: fs.existsSync(keyPath) ? fs.readFileSync(keyPath) : undefined,
    cert: fs.existsSync(certPath) ? fs.readFileSync(certPath) : undefined
  }
});

// PostgreSQL connection pool (Kubernetes service)
const pool = new Pool({
  host: process.env.PG_HOST || 'postgresX',
  database: process.env.PG_DATABASE || 'product_catalogX',
  user: process.env.PG_USER || 'postgresX',
  password: process.env.PG_PASSWORD || 'postgresX',
  port: process.env.PG_PORT || 54320,
  max: 10,
  idleTimeoutMillis: 30000,
  ssl: process.env.DB_SSL === 'true'
});

// Shared route registration function
const registerRoutes = (app) => {
  app.register(fastifyCors, {
    origin: process.env.CORS_ORIGIN || 'http://localhost:8081',
    methods: ['GET', 'POST'],
    credentials: true
  });

  app.get('/health', async (req, reply) => {
    try {
      const client = await pool.connect();
      await client.query('SELECT 1');
      client.release();
      reply.send({ status: 'ok' });
    } catch (err) {
      app.log.error(err);
      reply.code(500).send({ status: 'error', message: 'Database unreachable' });
    }
  });

  app.get('/products', async (req, reply) => {
    try {
      const client = await pool.connect();
      const result = await client.query('SELECT * FROM products');
      client.release();
      reply.send(result.rows);
    } catch (err) {
      app.log.error(err);
      reply.code(500).send({ error: 'Failed to fetch products' });
    }
  });

  app.addHook('onClose', async () => {
    await pool.end();
    app.log.info('PostgreSQL pool closed');
  });
};

// Register routes on both servers
registerRoutes(fastifyHttp);
registerRoutes(fastifyHttps);

// Start both servers
const start = async () => {
  try {
    await fastifyHttp.listen({ port: 3000, host: '0.0.0.0' });
    fastifyHttp.log.info('HTTP middleware listening on port 3000');

    await fastifyHttps.listen({ port: 3443, host: '0.0.0.0' });
    fastifyHttps.log.info('HTTPS middleware listening on port 3443');
  } catch (err) {
    console.error('Startup error:', err);
    process.exit(1);
  }
};

start();
