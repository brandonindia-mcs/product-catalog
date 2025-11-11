import { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import axios from 'axios';
import type { Product } from '../types/Product';

export default function ProductDetail() {
  const { id } = useParams();
  const [prod, setProd] = useState<Product | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

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
        const resp = await axios.get(`${API_BASE}/catalog/${encodeURIComponent(id)}`, {
          timeout: timeoutMs,
          signal // axios supports AbortController signal in modern versions; fallback handled below
        });
        if (!signal.aborted) {
          setProd(resp.data ?? null);
          setError(null);
          setLoading(false);
        }
      } catch (err: unknown) {
        if (signal.aborted) return;

        let status: number | undefined;
        let message: string | undefined;
        let code: string | undefined;

        if (axios.isAxiosError(err)) {
          status = err.response?.status;
          message = err.message;
          code = err.code;
        } else {
          console.error('Non-Axios error:', err);
          setError('Unexpected error occurred.');
          setLoading(false);
          return;
        }

        console.error('Failed to fetch product:', err);

        if (status === 404) {
          setError('Product not found.');
        } else if (status && status >= 400 && status < 500) {
          setError('Unable to load product details. Please check the request.');
        } else if (code === 'ECONNABORTED' || message?.includes('timeout')) {
          if (attempts <= maxRetries + 1) {
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
