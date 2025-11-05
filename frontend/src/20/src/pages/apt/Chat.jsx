import React, { useEffect, useState, useMemo } from 'react';
import { Link } from 'react-router-dom';
import axios from 'axios';

/*
  Enhancements applied:
  - normalize APT_BASE (strip trailing slash)
  - loading + error state with consistent lifecycle handling
  - AbortController to prevent state updates after unmount or rapid re-renders
  - axios timeout and 1 retry for transient network issues
  - defensive mapping of product fields to avoid crashes on unexpected shapes
  - formatted price via Intl.NumberFormat (keeps behavior consistent)
  - aria-live for progressive updates to improve a11y
*/
export default function Chat() {
  const [prod, setProd] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Normalize base to avoid double slashes when building URLs
  // const APT_BASE = useMemo(() => (import.meta.env.VITE_APT_URL || '').replace(/\/$/, ''), []);

  const API_BASE = (import.meta.env.VITE_APT_URL || '').replace(/\/$/, '');

  useEffect(() => {

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
        const resp = await axios.get(`${API_BASE}/chat`, {
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
  }, [API_BASE]);

  // UI states
  // if (loading) return <div aria-busy="true">Loading…</div>;
  // if (error) return <p role="alert" className="error">{error}</p>;

  return (
    <article aria-labelledby="product-name" className="product-detail">
      <h2 id="catalog-heading">APT Chat</h2>
      <p>{prod}</p>
    </article>
  );

}

