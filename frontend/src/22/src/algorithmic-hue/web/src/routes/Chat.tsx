import { useEffect, useState } from 'react'
import Card from '@mui/material/Card'                // MUI component
import CardContent from '@mui/material/CardContent'  // MUI component
import Typography from '@mui/material/Typography'    // MUI component
import TextField from '@mui/material/TextField'      // MUI component
import Button from '@mui/material/Button'            // MUI component
import { sendChatMessage, getHealth, getWelcome } from '../api/chat'

export default function Chat() {
  const [message, setMessage] = useState('')
  const [reply, setReply] = useState<string | null>(null)
  const [status, setStatus] = useState<string>('Checking backend...')
  const [welcome, setWelcome] = useState<string>('Getting Welcoming...')

  useEffect(() => {
    // Health check: should return HTTP 200 from backend (no TLS required in dev)
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
    setReply(null)
    try {
      const res = await sendChatMessage(message)
      setReply(res.reply)
    } catch (err: any) {
      setReply(`Error: ${err.message}`)
    }
  }

  return (
    // MUI Card + Tailwind utilities for spacing and layout
    <Card className="mt-6 shadow-md">
      <CardContent className="space-y-4">{/* Tailwind spacing */}
        <Typography variant="h5">Chat</Typography>
        <Typography variant="body2" color="text.secondary">{status}</Typography>
        <div className="p-4">
        <h1 className="text-xl font-bold">Welcome</h1>
        <p>{welcome}</p>
        </div>
        <TextField
          label="Message"
          value={message}
          onChange={e => setMessage(e.target.value)}
          fullWidth
        />
        <div className="flex gap-2"> {/* Tailwind utilities */}
          <Button variant="contained" onClick={onSend}>Send</Button>
          <Button variant="outlined" onClick={() => setMessage('')}>Clear</Button>
        </div>
        {reply && (
          <Typography variant="body1" className="text-gray-800">
            {reply}
          </Typography>
        )}
      </CardContent>
    </Card>
  )
}
