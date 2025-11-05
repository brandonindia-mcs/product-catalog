// ES module React component that posts a JSON payload { message } to the middleware
// and expects a JSON response with { reply } (compatible with ai-chat-py.py).
//
// Notes on compatibility with ai-chat-py.py:
// - The middleware sends { message } in the request body to the Python script via stdin.
// - ai-chat-py.py responds with a single JSON object that includes a top-level "reply" string.
// - This component expects the middleware to return either { reply } on success or
//   a structured error object like { error, details } on failure and surfaces those to the user.
//

import React, { useState } from 'react';
import axios from 'axios';

export default function Chat() {
  // UI state
  const [input, setInput] = useState('');
  const [reply, setReply] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const API_BASE = import.meta.env.VITE_CHAT_URL || '';

  // Submit handler: POST { message } and expect { reply } in response
  const handleSubmit = async (e) => {
    e.preventDefault();
    // Reset per-request UI state
    setLoading(true);
    setError(null);
    setReply('');

    try {
      const resp = await axios.post(
        `${API_BASE}/chat`,
        { message: input },
        { timeout: 15000 } // match middleware timeout expectations
      );

      // Successful, well-formed response shape from middleware
      if (resp.data && typeof resp.data.reply === 'string') {
        setReply(resp.data.reply);
        setError(null);
      } else if (resp.data && resp.data.error) {
        // Structured error returned by middleware (surface details when present)
        const detailsText = resp.data.details ? `: ${resp.data.details}` : '';
        setError(`${resp.data.error}${detailsText}`);
      } else {
        // Unexpected but deterministic fallback
        setError('No response from model.');
      }
    } catch (err) {
      // Axios/network/timeout error handling with clear messaging for debugging
      if (err.response && err.response.data) {
        const body = err.response.data;
        if (body.error) {
          const detailsText = body.details ? `: ${body.details}` : '';
          setError(`${body.error}${detailsText}`);
        } else {
          setError('Failed to get assistant response. Try again.');
        }
      } else if (err.code === 'ECONNABORTED') {
        setError('Request timed out. Try again.');
      } else {
        // Generic, but we still log the message to console for developers
        console.error('Chat request failed:', err.message || err);
        setError('Failed to get assistant response. Try again.');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ maxWidth: 800, margin: '0 auto', padding: '1rem' }}>
      <h2>Chat with AI</h2>

      <form onSubmit={handleSubmit} style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Ask something..."
          required
          style={{ flex: 1, padding: '0.5rem', fontSize: '1rem' }}
          aria-label="Chat message"
        />
        <button type="submit" disabled={loading || !input} style={{ padding: '0.5rem 1rem' }}>
          {loading ? 'Sending…' : 'Send'}
        </button>
      </form>

      {/* Loading indicator */}
      {loading && <p style={{ marginTop: '1rem' }}>Waiting for response…</p>}

      {/* Error display: shows middleware-provided details when available */}
      {error && (
        <div
          className="error"
          role="alert"
          style={{ color: 'crimson', marginTop: '1rem', whiteSpace: 'pre-wrap' }}
        >
          <strong>Error:</strong> {error}
        </div>
      )}

      {/* Reply display */}
      {reply && (
        <div
          className="response"
          style={{
            marginTop: '1rem',
            padding: '0.75rem',
            border: '1px solid #e1e1e1',
            borderRadius: 6,
            background: '#f9f9f9',
            whiteSpace: 'pre-wrap'
          }}
        >
          <strong>AI:</strong> <div style={{ marginTop: '0.5rem' }}>{reply}</div>
        </div>
      )}
    </div>
  );
}
