import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import axios, { AxiosError } from 'axios';
import type { Product } from '../types/Product';

export default function ProductList() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const API_BASE = (import.meta.env.VITE_API_URL || '').replace(/\/$/, '');

  useEffect(() => {
    const controller = new AbortController();
    const signal = controller.signal;

    let attempts = 0;
    const maxRetries = 1;
    const timeoutMs = 10_000;

    setLoading(true);
    setError(null);

    const fetchProducts = async () => {
      attempts += 1;
      try {
        const resp = await axios.get<Product[]>(`${API_BASE}/products`, {
          timeout: timeoutMs,
          signal,
        });

        if (!signal.aborted) {
          setProducts(Array.isArray(resp.data) ? resp.data : []);
          setLoading(false);
        }
      } catch (err) {
        if (signal.aborted) return;

        const axiosErr = err as AxiosError;
        console.error('Failed to fetch products:', axiosErr);

        const isTimeout =
          axiosErr.code === 'ECONNABORTED' ||
          (axiosErr.message || '').toLowerCase().includes('timeout');
        const status = axiosErr.response?.status;

        if (isTimeout && attempts <= maxRetries + 1) {
          console.warn(`Products request timed out, retrying (${attempts}/${maxRetries + 1})`);
          return fetchProducts();
        }

        setError(
          status === 404
            ? 'No products found.'
            : `Unable to load products from: ${API_BASE}/products`
        );
        setLoading(false);
      }
    };

    if (!API_BASE) {
      setError('API base is not configured.');
      setLoading(false);
    } else {
      fetchProducts();
    }

    return () => controller.abort();
  }, [API_BASE]);

  if (loading) return <p aria-busy="true">Loading products…</p>;
  if (error) return <p role="alert" className="error">{error}</p>;
  if (!Array.isArray(products) || products.length === 0) {
    return <p>No products available.</p>;
  }

  return (
    <section aria-labelledby="catalog-heading">
      <h2 id="catalog-heading">Product Catalog</h2>
      <ul aria-live="polite">
        {products.map((p) => {
          const id = p?.id ?? '';
          const name = p?.name ?? 'Unnamed product';
          const priceVal =
            typeof p?.price === 'number' ? p.price : parseFloat(p?.price as string) || 0;

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

function formatPrice(price: number): string {
  return new Intl.NumberFormat(undefined, {
    style: 'currency',
    currency: 'USD',
  }).format(price);
}
