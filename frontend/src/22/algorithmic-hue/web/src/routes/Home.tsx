import Card from '@mui/material/Card'              // MUI component
import CardContent from '@mui/material/CardContent'// MUI component
import Typography from '@mui/material/Typography'  // MUI component
import { Link } from 'react-router-dom'

export default function Home() {
  return (
    // MUI Card for structured layout (MUI), Tailwind for spacing/utilities
    <Card className="mt-6 shadow-md">
      <CardContent>
        <Typography variant="h5" gutterBottom>
          Welcome
        </Typography>
        <Typography variant="body1" className="text-gray-700">
          This is the Home page. Navigate to Chat to test backend connectivity and API structure.
        </Typography>
        <div className="mt-4">
          <Link to="/chat" className="text-blue-600 hover:underline">{/* Tailwind utilities */}
            Go to Chat
          </Link>
        </div>
      </CardContent>
    </Card>
  )
}
