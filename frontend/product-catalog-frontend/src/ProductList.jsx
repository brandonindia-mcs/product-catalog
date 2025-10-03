import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import axios from 'axios';

export default function ProductList() {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const API_BASE = import.meta.env.VITE_API_URL || '';

  useEffect(() => {
    axios.get(`${API_BASE}/products`)
      .then(resp => {
        setProducts(resp.data);
        setLoading(false);
      })
      .catch(err => {
        console.error('Failed to fetch products:', err);
        setError('Unable to load products. Please try again later.');
        setLoading(false);
      });
  }, [API_BASE]);

  if (loading) return <p>Loading products…</p>;
  if (error) return <p className="error">{error}</p>;

  return (
    <section>
      <h2>Product Catalog</h2>
      <ul>
        {products.map(p => (
          <li key={p.id}>
            <Link to={`/products/${p.id}`}>
              {p.name} – {formatPrice(p.price)}
            </Link>
          </li>
        ))}
      </ul>
    </section>
  );
}

function formatPrice(price) {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD'
  }).format(price);
}
