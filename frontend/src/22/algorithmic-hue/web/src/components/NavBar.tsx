import { Link, useLocation } from 'react-router-dom'
import AppBar from '@mui/material/AppBar'          // MUI component
import Toolbar from '@mui/material/Toolbar'        // MUI component
import Typography from '@mui/material/Typography'  // MUI component
import Button from '@mui/material/Button'          // MUI component

export default function NavBar() {
  const { pathname } = useLocation()
  return (
    // MUI AppBar + Toolbar => structured component styling (MUI)
    <AppBar position="static" color="primary">
      <Toolbar className="justify-between"> {/* Tailwind utility class */}
        <Typography variant="h6" component="div">
          K8s React Chat
        </Typography>
        <div className="flex gap-2"> {/* Tailwind utility class */}
          <Button
            variant={pathname === '/' ? 'contained' : 'outlined'}
            color="secondary"
            component={Link}
            to="/"
          >
            Home
          </Button>
          <Button
            variant={pathname === '/chat' ? 'contained' : 'outlined'}
            color="secondary"
            component={Link}
            to="/chat"
          >
            Chat
          </Button>
        </div>
      </Toolbar>
    </AppBar>
  )
}
