import React from 'react';
import { Router, Link } from '@reach/router';
import ProductList from './ProductList';
import ProductDetail from './ProductDetail';

export default function App() {
  return (
    <>
      <header><Link to="/">Catalog</Link></header>
      <Router>
        <ProductList path="/" />
        <ProductDetail path="/products/:id" />
      </Router>
    </>
  );
}
