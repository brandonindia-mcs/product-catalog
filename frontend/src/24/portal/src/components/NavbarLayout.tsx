// import type { ReactNode } from 'react';
import { Outlet } from 'react-router-dom';
import Navbar from './Navbar';

const Layout = () => (
  <>
    <Navbar />
    <main style={{ padding: '2rem' }}>
      <Outlet />
    </main>
  </>
);

export default Layout;
