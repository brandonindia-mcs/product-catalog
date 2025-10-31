'use strict';

import React, { useState, useRef, useEffect } from 'react';

/*
  ChatWithGPTadv.jsx

  - Security-first: no secrets hard-coded, uses credentials: 'include' and optional build-time header only if provided.
  - Input validation and size limits before sending to backend.
  - Streaming via SSE for incremental updates with robust cleanup.
  - Non-streaming POST fallback with AbortController and error handling.
  - Performance: minimal re-renders, incremental UI updates, debounce on repeated sends prevented.
*/

const MAX_MESSAGE_LENGTH = 2000;
const MAX_MESSAGES = 12;
const STREAM_PING_INTERVAL_MS = 15000;

export default function ChatWithGPTadv() {
  'use strict';

  const [input, setInput] = useState('');
  const [messages, setMessages] = useState([]); // { role: 'user'|'assistant', text: string }
  const [loading, setLoading] = useState(false);
  const [streaming, setStreaming] = useState(false);
  const evtRef = useRef(null);
  const abortCtrlRef = useRef(null);
  const lastSentAtRef = useRef(0);

  useEffect(() => {
    return () => {
      // cleanup on unmount
      if (evtRef.current) {
        try { evtRef.current.close(); } catch (_) {}
        evtRef.current = null;
      }
      if (abortCtrlRef.current) {
        try { abortCtrlRef.current.abort(); } catch (_) {}
        abortCtrlRef.current = null;
      }
    };
  }, []);

  function safeAppendMessage(msg) {
    setMessages((prev) => {
      const next = [...prev, msg];
      if (next.length > 100) next.splice(0, next.length - 100);
      return next;
    });
  }

  function validateUserText(text) {
    if (!text || typeof text !== 'string') return { ok: false, error: 'empty' };
    const trimmed = text.trim();
    if (trimmed.length === 0) return { ok: false, error: 'empty' };
    if (trimmed.length > MAX_MESSAGE_LENGTH) return { ok: false, error: 'too_long' };
    if (messages.filter((m) => m.role === 'user').length >= MAX_MESSAGES) {
      return { ok: false, error: 'too_many_user_messages' };
    }
    return { ok: true, text: trimmed };
  }

  async function sendNonStream(userText) {
    'use strict';
    if (loading) return;
    const v = validateUserText(userText);
    if (!v.ok) {
      safeAppendMessage({ role: 'assistant', text: `Validation error: ${v.error}` });
      return;
    }

    // simple debounce to avoid accidental double submits
    const now = Date.now();
    if (now - lastSentAtRef.current < 800) return;
    lastSentAtRef.current = now;

    safeAppendMessage({ role: 'user', text: v.text });
    setLoading(true);
    abortCtrlRef.current = new AbortController();

    try {
      const headers = {
        'Content-Type': 'application/json'
      };
      const buildKey = process.env.REACT_APP_INTERNAL_API_KEY || '';
      if (buildKey) headers['X-Internal-API-Key'] = buildKey;

      const resp = await fetch('/api/chat', {
        method: 'POST',
        credentials: 'include',
        headers,
        body: JSON.stringify({
          messages: [
            { role: 'system', content: 'You are a helpful assistant.' },
            { role: 'user', content: v.text }
          ],
          max_completion_tokens: 1024
        }),
        signal: abortCtrlRef.current.signal
      });

      if (!resp.ok) {
        const txt = await resp.text();
        safeAppendMessage({ role: 'assistant', text: `Error ${resp.status}: ${txt}` });
        return;
      }

      const data = await resp.json();
      const assistantText =
        data?.choices?.[0]?.message?.content ??
        data?.choices?.[0]?.text ??
        JSON.stringify(data);
      safeAppendMessage({ role: 'assistant', text: assistantText });
    } catch (err) {
      if (err.name === 'AbortError') {
        safeAppendMessage({ role: 'assistant', text: 'Request aborted' });
      } else {
        safeAppendMessage({ role: 'assistant', text: `Request failed: ${String(err)}` });
      }
    } finally {
      setLoading(false);
      abortCtrlRef.current = null;
    }
  }

  function startStreaming(userText) {
    'use strict';
    if (streaming) return;
    const v = validateUserText(userText);
    if (!v.ok) {
      safeAppendMessage({ role: 'assistant', text: `Validation error: ${v.error}` });
      return;
    }

    // debounce
    const now = Date.now();
    if (now - lastSentAtRef.current < 800) return;
    lastSentAtRef.current = now;

    // prepare payload for GET-safe transport
    const payload = {
      messages: [
        { role: 'system', content: 'You are a helpful assistant.' },
        { role: 'user', content: v.text }
      ],
      max_completion_tokens: 1024
    };

    let encoded;
    try {
      // browser-safe base64
      encoded = btoa(unescape(encodeURIComponent(JSON.stringify(payload))));
    } catch (err) {
      safeAppendMessage({ role: 'assistant', text: 'Failed to encode payload' });
      return;
    }

    const url = `/api/chat/stream?payload=${encodeURIComponent(encoded)}`;

    // close previous stream if any
    if (evtRef.current) {
      try { evtRef.current.close(); } catch (_) {}
      evtRef.current = null;
    }

    // add user message and assistant placeholder
    safeAppendMessage({ role: 'user', text: v.text });
    safeAppendMessage({ role: 'assistant', text: '' });

    setStreaming(true);

    // use credentials to rely on cookie-based auth and avoid exposing keys
    const evt = new EventSource(url, { withCredentials: true });
    evtRef.current = evt;

    let partial = '';
    let lastUpdateAt = Date.now();

    const localPing = setInterval(() => {
      try { evtRef.current && evtRef.current.dispatchEvent(new MessageEvent('ping')); } catch (_) {}
    }, STREAM_PING_INTERVAL_MS);

    evt.onmessage = (e) => {
      try {
        const obj = JSON.parse(e.data);
        if (obj.type === 'delta' || obj.type === 'chunk') {
          partial += obj.text ?? obj.chunk ?? '';
          // update the last assistant message only to avoid re-rendering entire list
          setMessages((prev) => {
            if (prev.length === 0) return [{ role: 'assistant', text: partial }];
            const last = prev[prev.length - 1];
            if (last.role !== 'assistant') {
              return [...prev, { role: 'assistant', text: partial }];
            }
            const copy = prev.slice();
            copy[copy.length - 1] = { ...last, text: partial };
            return copy;
          });
          lastUpdateAt = Date.now();
        } else if (obj.type === 'done') {
          cleanupStream();
        } else if (obj.type === 'error') {
          cleanupStream();
          safeAppendMessage({ role: 'assistant', text: `Stream error: ${obj.error}` });
        }
      } catch (err) {
        // ignore parse errors
      }
    };

    evt.onerror = () => {
      cleanupStream();
      safeAppendMessage({ role: 'assistant', text: 'Stream connection error' });
    };

    function cleanupStream() {
      if (evtRef.current) {
        try { evtRef.current.close(); } catch (_) {}
        evtRef.current = null;
      }
      clearInterval(localPing);
      setStreaming(false);
    }
  }

  // UI handlers
  const handleSendClick = (e) => {
    e?.preventDefault();
    sendNonStream(input);
    setInput('');
  };

  const handleStreamClick = (e) => {
    e?.preventDefault();
    startStreaming(input);
    setInput('');
  };

  const handleCancel = () => {
    if (abortCtrlRef.current) {
      try { abortCtrlRef.current.abort(); } catch (_) {}
    }
    if (evtRef.current) {
      try { evtRef.current.close(); } catch (_) {}
      evtRef.current = null;
    }
    setLoading(false);
    setStreaming(false);
  };

  return (
    <div style={{ padding: 20, maxWidth: 900, margin: '0 auto' }}>
      <h2>Chat with GPT-5 Mini</h2>

      <div
        aria-live="polite"
        style={{
          border: '1px solid #e6e6e6',
          borderRadius: 8,
          padding: 12,
          minHeight: 260,
          marginBottom: 12,
          background: '#fff'
        }}
      >
        {messages.length === 0 && <div style={{ color: '#666' }}>No messages yet. Ask something.</div>}
        {messages.map((m, i) => (
          <div key={i} style={{ marginBottom: 10 }}>
            <div style={{ fontSize: 12, color: '#888', marginBottom: 4 }}>{m.role}</div>
            <div
              style={{
                background: m.role === 'user' ? '#f0f8ff' : '#f8f8f8',
                padding: 10,
                borderRadius: 6,
                border: '1px solid #eee',
                whiteSpace: 'pre-wrap'
              }}
            >
              {m.text}
            </div>
          </div>
        ))}
      </div>

      <form
        onSubmit={(e) => {
          e.preventDefault();
          startStreaming(input);
          setInput('');
        }}
        style={{ display: 'flex', gap: 8, alignItems: 'center' }}
      >
        <input
          aria-label="message"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Type your question, e.g. Where should I go in Paris?"
          style={{ flex: 1, padding: 10, borderRadius: 6, border: '1px solid #ccc' }}
          maxLength={MAX_MESSAGE_LENGTH}
          disabled={loading || streaming}
        />

        <div style={{ display: 'flex', gap: 8 }}>
          <button
            type="button"
            onClick={handleSendClick}
            disabled={loading || streaming}
            style={{ padding: '8px 12px', borderRadius: 6 }}
          >
            Send
          </button>

          <button
            type="button"
            onClick={handleStreamClick}
            disabled={loading || streaming}
            style={{ padding: '8px 12px', borderRadius: 6 }}
          >
            Stream
          </button>

          <button
            type="button"
            onClick={handleCancel}
            style={{ padding: '8px 12px', borderRadius: 6 }}
          >
            Cancel
          </button>
        </div>
      </form>
    </div>
  );
}
