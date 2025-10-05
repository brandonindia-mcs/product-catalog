import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import axios from 'axios';

export default function ProductDetail() {
  const { id } = useParams();
  const [prod, setProd] = useState(null);
  const [error, setError] = useState(null);
  const API_BASE = import.meta.env.VITE_API_URL || '';

  useEffect(() => {
    axios.get(`${API_BASE}/products/${id}`)
      .then(resp => setProd(resp.data))
      .catch(err => {
        console.error('Failed to fetch product:', err);
        setError('Unable to load product details.');
      });
  }, [id, API_BASE]);

  if (error) return <p className="error">{error}</p>;
  if (!prod) return <div>Loading…</div>;

  return (
    <div>
      <h1>{prod.name}</h1>
      <p>{prod.description}</p>
      <p>Price: ${prod.price}</p>
    </div>
  );
  
}
