import { Link } from 'react-router-dom';
import reactLogo from '/react.svg'
import viteLogo from '/vite.svg'

const Navbar = () => {
  return (
    <>
    <nav style={{ padding: '1rem', background: '#f0f0f0' }}>
      <Link to="/" style={{ marginRight: '1rem' }}>Home</Link>
      <Link to="/about" style={{ marginRight: '1rem' }}>About</Link>
      <Link to="/catalog" style={{ marginRight: '1rem' }}>Catalog</Link>
    </nav>
      <div>
        <a href="https://vite.dev" target="_blank">
          <img src={viteLogo} className="logo" alt="Vite logo" />
        </a>
        <a href="https://react.dev" target="_blank">
          <img src={reactLogo} className="logo react" alt="React logo" />
        </a>
      </div>
    </>
  );
};

export default Navbar;
