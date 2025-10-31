'use strict';

import fastifyFactory from 'fastify';
import fastifyCors from '@fastify/cors';

const httpPort = parseInt(process.env.LISTEN_PORT_HTTP || process.argv[2] || 80)
const httpListenHost = '0.0.0.0'
const httpsPort = parseInt(process.env.LISTEN_PORT_HTTPS || process.argv[2] || 443)
const httpsListenHost = '0.0.0.0'
const listenPort = httpPort
const listenHost = httpListenHost

// Configurable runtime parameters
const PYTHON_CMD = process.env.PYTHON_CMD || 'python3'; // command used to run python
const PY_SCRIPT = process.env.PY_SCRIPT || 'ai-chat-py.py'; // python script filename
const PY_TIMEOUT_MS = parseInt(process.env.PY_TIMEOUT_MS, 10) || 10000; // 10s per-request timeout

/**
 * callPython(payloadObject)
 * - Spawns the python process and writes JSON to its stdin.
 * - Collects stdout/stderr, enforces a timeout, and parses stdout as JSON.
 * - Resolves with the 'reply' string or rejects with an Error containing details.
 */
function callPython(payloadObject) {
  return new Promise((resolve, reject) => {
    // Serialize payload to JSON bytes
    let inputJson;
    try {
      inputJson = JSON.stringify(payloadObject);
    } catch (err) {
      return reject(new Error(`failed to stringify payload: ${err.message}`));
    }

    // Spawn python with stdin/stdout/stderr pipes
    const py = spawn(PYTHON_CMD, [PY_SCRIPT], { stdio: ['pipe', 'pipe', 'pipe'] });

    let stdout = '';
    let stderr = '';
    let timedOut = false;

    // Kill process if it exceeds timeout
    const timeout = setTimeout(() => {
      timedOut = true;
      // Using SIGKILL for deterministic termination; on some platforms SIGTERM is preferred.
      try {
        py.kill('SIGKILL');
      } catch (e) {
        // ignore
      }
    }, PY_TIMEOUT_MS);

    // Collect stdout and stderr
    py.stdout.on('data', (chunk) => {
      stdout += chunk.toString();
    });

    py.stderr.on('data', (chunk) => {
      stderr += chunk.toString();
    });

    // Handle spawn-level errors
    py.on('error', (err) => {
      clearTimeout(timeout);
      return reject(new Error(`failed to spawn python process: ${err.message}`));
    });

    // When the python process exits, inspect results
    py.on('close', (code) => {
      clearTimeout(timeout);

      if (timedOut) {
        return reject(new Error('python process timed out'));
      }

      if (code !== 0) {
        // Provide stderr to help debugging; middleware will return it in 'details'
        return reject(new Error(`python exited with code ${code}. stderr: ${stderr.trim()}`));
      }

      const outTrim = stdout.trim();
      if (!outTrim) {
        return reject(new Error(`no output from python. stderr: ${stderr.trim()}`));
      }

      // Parse python JSON output
      try {
        const parsed = JSON.parse(outTrim);
        // Expect the script to return a top-level { reply: string } on success
        if (parsed && typeof parsed.reply === 'string') {
          return resolve(parsed.reply);
        } else if (parsed && parsed.error) {
          // The python script signalled a structured error; bubble it up
          return reject(new Error(`python error object: ${JSON.stringify(parsed)}`));
        } else {
          return reject(new Error(`unexpected python output shape: ${outTrim}`));
        }
      } catch (err) {
        return reject(new Error(`invalid json from python: ${err.message}; raw: ${outTrim}`));
      }
    });

    // Write the JSON payload to python stdin, then close stdin to let the script run
    try {
      py.stdin.write(inputJson);
      py.stdin.end();
    } catch (err) {
      // If writing to stdin fails, kill process and reject
      try {
        py.kill('SIGKILL');
      } catch (e) {
        // ignore
      }
      clearTimeout(timeout);
      return reject(new Error(`failed to write to python stdin: ${err.message}`));
    }
  });
}


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
fastifyHttp.log.trace('Sample trace message: HTTPS server initialized');
fastifyHttp.log.debug('Sample debug message: HTTPS server initialized');
fastifyHttp.log.warn('Sample warn message: HTTPS server initialized');
fastifyHttp.log.info('Sample info message: HTTPS server initialized');
fastifyHttp.log.error('Sample error message: HTTPS server initialized');

// Shared route registration function
const registerRoutes = (app) => {
  app.register(fastifyCors, {
    origin: process.env.CORS_ORIGIN,
    methods: ['GET', 'POST'],
    credentials: true
  });

  app.get('/health/chat', async (req, reply) => {
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

};

// Register routes on both servers
registerRoutes(fastifyHttp);

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
