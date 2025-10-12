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
      </header>
      <Routes>
        <Route path="/" element={<ProductList />} />
        <Route path="/products/:id" element={<ProductDetail />} />
      </Routes>
    </BrowserRouter>
  );
}
