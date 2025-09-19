const fastify = require('fastify')({ logger: true });
const cors = require('@fastify/cors');
const { Pool } = require('pg');

// Register CORS before routes
fastify.register(cors, {
  origin: '*', // In production, replace with your frontend URL(s)
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
});

const pool = new Pool({
  host: 'pg-service',
  database: 'catalog',
  user: 'catalog',
  password: 'catalog'
});

fastify.get('/products', async () => {
  const { rows } = await pool.query('SELECT * FROM products');
  return rows;
});

fastify.get('/products/:id', async (req) => {
  const { rows } = await pool.query(
    'SELECT * FROM products WHERE id=$1', [req.params.id]
  );
  return rows[0] || fastify.httpErrors.notFound();
});

fastify.get('/health/db', async (request, reply) => {
  try {
    await pool.query('SELECT 1');
    reply.send({ status: 'ok', db: true });
  } catch (err) {
    reply.code(500).send({ status: 'error', db: false, error: err.message });
  }
});

fastify.listen({ port: 3000, host: '0.0.0.0' })
  .then(() => {
    fastify.log.info('API running on port 3000');
  })
  .catch(err => {
    fastify.log.error(err);
    process.exit(1);
  });
