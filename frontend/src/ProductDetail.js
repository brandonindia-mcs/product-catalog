import React, { useEffect, useState } from 'react';
import axios from 'axios';

export default function ProductDetail({ id }) {
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
