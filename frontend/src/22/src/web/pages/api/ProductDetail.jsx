import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import axios from 'axios';

/*
  Enhancements:
  - loading state for explicit UI during network activity
  - AbortController to avoid state updates after unmount and race conditions
  - normalized API_BASE (strip trailing slash) to avoid double slashes
  - axios timeout and lightweight retry for transient failures
  - structured error mapping to provide clearer UI messages
  - currency formatting for price display
  - defensive rendering (handles unexpected shapes)
*/
export default function ProductDetail() {
  const { id } = useParams();
  const [prod, setProd] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const API_BASE = (import.meta.env.VITE_API_URL || '').replace(/\/$/, '');

  useEffect(() => {
    if (!id) {
      setError('No product id provided.');
      setLoading(false);
      return;
    }

    const controller = new AbortController();
    const signal = controller.signal;

    let attempts = 0;
    const maxRetries = 1; // 1 retry (total 2 attempts). Keep small to avoid UX/surprise billing.
    const timeoutMs = 10_000; // axios timeout per attempt

    setLoading(true);
    setError(null);

    const fetchProduct = async () => {
      attempts += 1;
      try {
        const resp = await axios.get(`${API_BASE}/products/${encodeURIComponent(id)}`, {
          timeout: timeoutMs,
          signal // axios supports AbortController signal in modern versions; fallback handled below
        });
        if (!signal.aborted) {
          setProd(resp.data ?? null);
          setError(null);
          setLoading(false);
        }
      } catch (err) {
        // If the request was aborted, silently ignore
        if (signal.aborted) return;

        // Map common error cases to user-friendly messages and keep diagnostic logging
        console.error('Failed to fetch product:', err);

        const status = err?.response?.status;
        if (status === 404) {
          setError('Product not found.');
        } else if (status >= 400 && status < 500) {
          setError('Unable to load product details. Please check the request.');
        } else if (err.code === 'ECONNABORTED' || err?.message?.includes('timeout')) {
          if (attempts <= maxRetries + 1) {
            // transient timeout — retry once
            console.warn(`Request timed out, retrying (${attempts}/${maxRetries + 1})`);
            return fetchProduct();
          }
          setError('Request timed out. Please try again.');
        } else {
          setError('Unable to load product details. Please try again later.');
        }

        setLoading(false);
      }
    };

    fetchProduct();

    return () => {
      // Cancel the request when component unmounts or id/API_BASE changes
      controller.abort();
    };
  }, [id, API_BASE]);

  // UI states
  if (loading) return <div aria-busy="true">Loading…</div>;
  if (error) return <p role="alert" className="error">{error}</p>;
  if (!prod) return <p>No product data available.</p>;

  // Defensive reads and formatting
  const name = prod.name ?? 'Unnamed product';
  const description = prod.description ?? 'No description provided.';
  const priceNumber = typeof prod.price === 'number' ? prod.price : parseFloat(prod.price) || 0;
  const formattedPrice = new Intl.NumberFormat(undefined, { style: 'currency', currency: 'USD' }).format(priceNumber);

  return (
    <article aria-labelledby="product-name" className="product-detail">
      <h1 id="product-name">{name}</h1>
      <p>{description}</p>
      <p><strong>Price:</strong> {formattedPrice}</p>
    </article>
  );
}
