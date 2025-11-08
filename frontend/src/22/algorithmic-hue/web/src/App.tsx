import { Routes, Route } from 'react-router-dom'
import Home from './routes/Home'
import Chat from './routes/Chat'
import NavBar from './components/NavBar'

export default function App() {
  return (
    <div className="min-h-screen bg-gray-50">
      <NavBar />
      <main className="max-w-4xl mx-auto p-4">
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/chat" element={<Chat />} />
        </Routes>
      </main>
    </div>
  )
}
