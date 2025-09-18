import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { useParams } from 'react-router-dom';

export default function ProductDetail() {
  const { id } = useParams(); // 👈 this replaces the prop
  const [prod, set] = useState(null);

  useEffect(() => {
    axios.get(`/api/products/${id}`).then(resp => set(resp.data));
  }, [id]);

  if (!prod) return <div>Loading…</div>;
  return (
    <div>
      <h1>{prod.name}</h1>
      <p>{prod.description}</p>
      <p>Price: ${prod.price}</p>
    </div>
  );
}
