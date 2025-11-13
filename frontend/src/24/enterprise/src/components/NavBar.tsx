import AppBar from '@mui/material/AppBar';
import Toolbar from '@mui/material/Toolbar';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import Link from 'next/link';
import { useAppDispatch, useAppSelector } from '../store/hooks';
import { toggleDarkMode } from '../store/slices/uiSlice';

export default function NavBar() {
  const dispatch = useAppDispatch();
  const darkMode = useAppSelector((s) => s.ui.darkMode);
  return (
    <AppBar position="static">
      <Toolbar>
        <Typography variant="h6" sx={{ flexGrow: 1 }}>
          Enterprise Demo
        </Typography>
        <Link href="/" legacyBehavior passHref><Button color="inherit">Home</Button></Link>
        <Link href="/todos" legacyBehavior passHref><Button color="inherit">Todos</Button></Link>
        <Button color="inherit" onClick={() => dispatch(toggleDarkMode())}>
          {darkMode ? 'Light' : 'Dark'}
        </Button>
      </Toolbar>
    </AppBar>
  );
}
