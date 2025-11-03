import Fastify from 'fastify'
import cors from '@fastify/cors'

const PORT = process.env.PORT || 3001
const server = Fastify({ logger: true })

// Register the official CORS plugin
await server.register(cors, {
  origin: true,
  methods: ['GET', 'POST']
})

server.get('/api/welcome', async (request, reply) => {
  reply.type('text/plain')
  return 'Welcome to Algorithmic Hue — served from backend'
})

server.get('/api/health', async () => {
  return { status: 'ok' }
})

server.post('/api/chat', async (request) => {
  const { message } = request.body || {}
  return { reply: message ? `Echo: ${message}` : 'Please provide a message.' }
})

server.listen({ port: PORT, host: '0.0.0.0' })
  .then(() => console.log(`Backend listening on http://localhost:${PORT}`))
  .catch(err => {
    console.error(err)
    process.exit(1)
  })
