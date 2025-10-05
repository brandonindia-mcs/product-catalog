'use strict';

const fs = require('fs');
const path = require('path');
const fastifyFactory = require('fastify');
const fastifyCors = require('@fastify/cors');
const { Pool } = require('pg');

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
  host: process.env.PG_HOST || 'pg-service',
  database: process.env.PG_DATABASE || 'catalog',
  user: process.env.PG_USER || 'catalog',
  password: process.env.PG_PASSWORD || 'catalog',
  port: process.env.PG_PORT || 5432
  // ,max: 10,
  // idleTimeoutMillis: 30000,
  // ssl: process.env.DB_SSL === 'true'
});

// Shared route registration function
const registerRoutes = (app) => {
  app.register(fastifyCors, {
    origin: process.env.CORS_ORIGIN || '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    credentials: true
  });

  app.get('/products', async () => {
    const { rows } = await pool.query('SELECT * FROM products');
    return rows;
  });

  app.get('/products/:id', async (req) => {
    const { rows } = await pool.query(
      'SELECT * FROM products WHERE id=$1', [req.params.id]
    );
    return rows[0] || app.httpErrors.notFound();
  });

  app.get('/health/db', async (request, reply) => {
    try {
      await pool.query('SELECT 1');
      reply.send({ status: 'ok', db: true });
    } catch (err) {
      reply.code(500).send({ status: 'error', db: false, error: err.message });
    }
  });

  app.get('/debug', async (req, reply) => {
    reply.send({
      env: process.env.NODE_ENV || 'development',
      dbPool: {
        total: pool.totalCount,
        idle: pool.idleCount,
        waiting: pool.waitingCount
      },
      tlsEnabled: !!app.server?.setSecureContext
    });
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
