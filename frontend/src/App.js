import { BrowserRouter, Routes, Route, Link } from 'react-router-dom';
import ProductList from './ProductList';
import ProductDetail from './ProductDetail';
import logo from './logo.svg';
import './App.css';

export default function App() {
  return (
    <BrowserRouter>
      <header>
        <Link to="/">Catalog</Link>

        <img src={logo} className="App-logo" alt="logo" />
        <p>
          Edit <code>src/App.js</code> and save to reload.
        </p>
        <a
          className="App-link"
          href="https://reactjs.org"
          target="_blank"
          rel="noopener noreferrer"
        >
          Learn React
        </a>

      </header>
      <Routes>
        <Route path="/" element={<ProductList />} />
        <Route path="/products/:id" element={<ProductDetail />} />
      </Routes>
    </BrowserRouter>
  );
}
