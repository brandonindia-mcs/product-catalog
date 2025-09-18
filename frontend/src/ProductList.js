import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import axios from 'axios';

export default function ProductList() {
  const [products, set] = useState([]);
  useEffect(() => {
    axios.get('/api/products').then(resp => set(resp.data));
  }, []);
  return (
    <ul>
      {products.map(p => (
        <li key={p.id}>
          <Link to={`/products/${p.id}`}>{p.name} – ${p.price}</Link>
        </li>
      ))}
    </ul>
  );
}
