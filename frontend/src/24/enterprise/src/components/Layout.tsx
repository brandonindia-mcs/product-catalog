import { ReactNode } from 'react';
import Container from '@mui/material/Container';
import NavBar from './NavBar';

export default function Layout({ children }: { children: ReactNode }) {
  return (
    <>
      <NavBar />
      <Container maxWidth="lg" sx={{ mt: 4 }}>
        {children}
      </Container>
    </>
  );
}
