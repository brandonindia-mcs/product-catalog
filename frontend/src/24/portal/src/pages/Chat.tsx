import { useEffect, useState } from 'react'
import {
  Card,
  CardContent,
  Typography,
  TextField,
  Button,
  CircularProgress,
} from '@mui/material'
import { sendChatPrompt, getHealth, getWelcome } from '../api/chat'

type ChatEntry = {
  prompt: string
  reply: string
}

const Chat = () => {
  const [prompt, setPrompt] = useState('')
  const [history, setHistory] = useState<ChatEntry[]>([])
  const [status, setStatus] = useState('Checking backend...')
  const [welcome, setWelcome] = useState('Loading welcome message...')
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    getHealth()
      .then(() => setStatus('Backend: OK'))
      .catch(err => setStatus(`Backend error: ${err.message}`))
  }, [])

  useEffect(() => {
    getWelcome()
      .then(msg => setWelcome(msg.message))
      .catch(err => {
        console.error('Failed to fetch welcome message:', err)
        setWelcome(`Not welcome here: ${err.message}`)
      })
  }, [])

  const onSend = async () => {
    if (!prompt.trim()) return
    setLoading(true)
    try {
      const res = await sendChatPrompt(prompt)
      setHistory(prev => [...prev, { prompt, reply: res.message }])
      setPrompt('')
    } catch (err: any) {
      setHistory(prev => [...prev, { prompt, reply: `Error: ${err.message}` }])
    } finally {
      setLoading(false)
    }
  }

  return (
    <Card className="mt-6 shadow-md">
      <CardContent className="space-y-4">
        <Typography variant="h5">Chat</Typography>
        <Typography variant="body2" color="text.secondary">
          {status}
        </Typography>

        <div className="p-4">
          <Typography variant="h6">Welcome</Typography>
          <Typography variant="body1">{welcome}</Typography>
        </div>

        {loading && (
          <div className="flex items-center gap-2 text-gray-600">
            <CircularProgress size={20} />
            <Typography variant="body2">Waiting for response...</Typography>
          </div>
        )}

        <div className="space-y-2">
          {history.map((entry, index) => (
            <div key={index} className="border p-2 rounded bg-gray-50">
              <Typography variant="subtitle2" color="primary">
                Prompt:
              </Typography>
              <Typography variant="body2">{entry.prompt}</Typography>
              <Typography variant="subtitle2" color="success.main" sx={{ mt: 1 }}>
                Reply:
              </Typography>
              <Typography variant="body2">{entry.reply}</Typography>
            </div>
          ))}
        </div>

        <TextField
          label="Prompt"
          value={prompt}
          onChange={e => setPrompt(e.target.value)}
          fullWidth
        />
        <div className="flex gap-2">
          <Button variant="contained" onClick={onSend} disabled={loading}>
            Send
          </Button>
          <Button variant="outlined" onClick={() => setPrompt('')}>
            Clear
          </Button>
        </div>
      </CardContent>
    </Card>
  )
}

export default Chat
