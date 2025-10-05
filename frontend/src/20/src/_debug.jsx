import React, { useEffect, useState } from 'react';
import axios from 'axios';

export default function _debug() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [apiUrl, setApiUrl] = useState('');

  useEffect(() => {
    const url = import.meta.env.VITE_API_URL || '';
    if (!url) {
      setError('VITE_API_URL is not defined');
    } else {
      setApiUrl(url);
    }
    setLoading(false);
  }, []);

  if (loading) return <p>Loading stuff here...</p>;
  if (error) return <p className="error">{error}</p>;

  return (
    <section>
      <h2>Debugging Information</h2>
      <div>
        <p className="_debug-green">import.meta.env.VITE_API_URL: {apiUrl}</p>
      </div>
    </section>
  );
}
