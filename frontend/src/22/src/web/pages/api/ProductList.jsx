import React, { useEffect, useState, useMemo } from 'react';
import { Link } from 'react-router-dom';
import axios from 'axios';

/*
  Enhancements applied:
  - normalize API_BASE (strip trailing slash)
  - loading + error state with consistent lifecycle handling
  - AbortController to prevent state updates after unmount or rapid re-renders
  - axios timeout and 1 retry for transient network issues
  - defensive mapping of product fields to avoid crashes on unexpected shapes
  - formatted price via Intl.NumberFormat (keeps behavior consistent)
  - aria-live for progressive updates to improve a11y
*/
export default function ProductList() {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Normalize base to avoid double slashes when building URLs
  const API_BASE = useMemo(() => (import.meta.env.VITE_API_URL || '').replace(/\/$/, ''), []);

  useEffect(() => {
    const controller = new AbortController();
    const signal = controller.signal;

    let attempts = 0;
    const maxRetries = 1; // total attempts = maxRetries + 1
    const timeoutMs = 10_000;

    setLoading(true);
    setError(null);

    const fetchProducts = async () => {
      attempts += 1;
      try {
        const resp = await axios.get(`${API_BASE}/products`, { timeout: timeoutMs, signal });
        if (!signal.aborted) {
          // Defensive: ensure we always store an array
          setProducts(Array.isArray(resp.data) ? resp.data : []);
          setLoading(false);
        }
      } catch (err) {
        if (signal.aborted) return;

        console.error('Failed to fetch products:', err);

        // Retry once for timeouts or transient network errors
        const isTimeout = err.code === 'ECONNABORTED' || (err?.message || '').toLowerCase().includes('timeout');
        const status = err?.response?.status;

        if (isTimeout && attempts <= maxRetries + 1) {
          console.warn(`Products request timed out, retrying (${attempts}/${maxRetries + 1})`);
          return fetchProducts();
        }

        if (status === 404) setError('No products found.');
        else setError('Unable to load products. Please try again later.');

        setLoading(false);
      }
    };

    // If API_BASE is empty, surface a clear error instead of making a bad request
    if (!API_BASE) {
      setError('API base is not configured.');
      setLoading(false);
    } else {
      fetchProducts();
    }

    return () => controller.abort();
  }, [API_BASE]);

  // UI states
  if (loading) return <p aria-busy="true">Loading products…</p>;
  if (error) return <p role="alert" className="error">{error}</p>;

  // Defensive rendering: ensure products is an array
  if (!Array.isArray(products) || products.length === 0) {
    return <p>No products available.</p>;
  }

  return (
    <section aria-labelledby="catalog-heading">
      <h2 id="catalog-heading">Product Catalog</h2>

      {/* aria-live helps screen readers pick up list updates */}
      <ul aria-live="polite">
        {products.map((p) => {
          // Defensive extraction and formatting for each product
          const id = p?.id ?? '';
          const name = p?.name ?? 'Unnamed product';
          const priceVal = typeof p?.price === 'number' ? p.price : parseFloat(p?.price) || 0;

          return (
            <li key={id || name} style={{ marginBottom: 8 }}>
              <Link to={`/products/${encodeURIComponent(id)}`}>
                {name} – {formatPrice(priceVal)}
              </Link>
            </li>
          );
        })}
      </ul>
    </section>
  );
}

function formatPrice(price) {
  return new Intl.NumberFormat(undefined, { style: 'currency', currency: 'USD' }).format(price);
}
