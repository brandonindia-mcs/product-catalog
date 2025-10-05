import { BrowserRouter, Routes, Route, Link } from 'react-router-dom';
import ProductList from './ProductList';
import ProductDetail from './ProductDetail';
import _debug from './_debug';
import logo from './logo.svg';
import './App.css';

export default function App() {
  return (
    <BrowserRouter>
      <header>
        <Link to="/">Catalog</Link>
        <img src={logo} className="App-logo" alt="logo" />
      </header>
      <_debug /> {/* ✅ Rendered directly, no route or link */}
      <Routes>
        <Route path="/" element={<ProductList />} />
        <Route path="/products/:id" element={<ProductDetail />} />
      </Routes>
    </BrowserRouter>
  );
}
