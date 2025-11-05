// src/pages/ChatWithGPT.jsx
import React, { useState } from "react";

export default function ChatWithGPT() {
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [messages, setMessages] = useState([]); // {role:'user'|'assistant', text}

  const send = async (e) => {
    e?.preventDefault();
    if (!input.trim()) return;

    const userMsg = { role: "user", text: input.trim() };
    setMessages((m) => [...m, userMsg]);
    setInput("");
    setLoading(true);

    try {
      const resp = await fetch("/api/chat", {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        credentials: "include",
        body: JSON.stringify({
          messages: [
            { role: "system", content: "You are a helpful assistant." },
            { role: "user", content: userMsg.text }
          ]
        })
      });

      if (!resp.ok) {
        const txt = await resp.text();
        throw new Error(`API ${resp.status}: ${txt}`);
      }

      const data = await resp.json();
      const assistantText = data?.choices?.[0]?.message?.content || data?.content || "No response";
      setMessages((m) => [...m, { role: "assistant", text: assistantText }]);
    } catch (err) {
      setMessages((m) => [...m, { role: "assistant", text: `Error: ${err.message}` }]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ padding: 24, maxWidth: 800, margin: "0 auto" }}>
      <h2>Ask GPT-5 Mini</h2>

      <div style={{
        border: "1px solid #ddd",
        borderRadius: 8,
        padding: 12,
        minHeight: 240,
        marginBottom: 12,
        background: "#fafafa"
      }}>
        {messages.length === 0 && <div style={{ color: "#666" }}>No messages yet. Ask something.</div>}
        {messages.map((m, i) => (
          <div key={i} style={{ marginBottom: 8 }}>
            <div style={{ fontSize: 12, color: "#888" }}>{m.role}</div>
            <div style={{
              background: m.role === "user" ? "#e6f7ff" : "#fff",
              padding: 8,
              borderRadius: 6,
              border: "1px solid #eee",
              whiteSpace: "pre-wrap"
            }}>{m.text}</div>
          </div>
        ))}
      </div>

      <form onSubmit={send} style={{ display: "flex", gap: 8 }}>
        <input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Type a question (e.g., Where should I go in Paris?)"
          style={{ flex: 1, padding: 8, borderRadius: 6, border: "1px solid #ccc" }}
          disabled={loading}
        />
        <button type="submit" disabled={loading} style={{ padding: "8px 12px", borderRadius: 6 }}>
          {loading ? "Thinking..." : "Send"}
        </button>
      </form>
    </div>
  );
}
