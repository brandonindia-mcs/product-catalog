import { useEffect, useState } from 'react'
import Card from '@mui/material/Card'
import CardContent from '@mui/material/CardContent'
import Typography from '@mui/material/Typography'
import TextField from '@mui/material/TextField'
import Button from '@mui/material/Button'
import CircularProgress from '@mui/material/CircularProgress'
import { sendChatPrompt, getHealth, getWelcome } from '../api/chat'

type ChatEntry = {
  prompt: string
  reply: string
}

export default function Chat() {
  const [prompt, setPrompt] = useState('')
  const [history, setHistory] = useState<ChatEntry[]>([])
  const [status, setStatus] = useState<string>('Checking backend...')
  const [welcome, setWelcome] = useState<string>('Getting Welcoming...')
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    getHealth()
      .then(() => setStatus('Backend: OK'))
      .catch(err => setStatus(`Backend error: ${err.message}`))
  }, [])

  useEffect(() => {
    getWelcome()
      .then(msg => setWelcome(msg))
      .catch(err => setWelcome(`not welcome here: ${err.message}`))
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
        <Typography variant="body2" color="text.secondary">{status}</Typography>
        <div className="p-4">
          <h1 className="text-xl font-bold">Welcome</h1>
          <p>{welcome}</p>
        </div>

        {loading && (
          <div className="flex items-center gap-2 text-gray-600">
            <CircularProgress size={20} />
            <Typography variant="body2">Waiting for response...</Typography>
          </div>
        )}
        {/* Display Area */}
        <div className="space-y-2">
          {history.map((entry, index) => (
            <div key={index} className="border p-2 rounded bg-gray-50">
              <Typography variant="subtitle2" className="text-blue-700">Prompt:</Typography>
              <Typography variant="body2">{entry.prompt}</Typography>
              <Typography variant="subtitle2" className="text-green-700 mt-2">Reply:</Typography>
              <Typography variant="body2">{entry.reply}</Typography>
            </div>
          ))}
        </div>

        {/* Input Area */}
        <TextField
          label="Prompt"
          value={prompt}
          onChange={e => setPrompt(e.target.value)}
          fullWidth
        />
        <div className="flex gap-2">
          <Button variant="contained" onClick={onSend} disabled={loading}>Send</Button>
          <Button variant="outlined" onClick={() => setPrompt('')}>Clear</Button>
        </div>
      </CardContent>
    </Card>
  )
}
