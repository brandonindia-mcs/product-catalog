#!/usr/bin/env python3
# ai-chat-py.py
#
# Minimal, test-friendly mock LLM endpoint that:
# - accepts a JSON payload (from stdin or as a single JSON string arg)
# - parses it using msgspec for schema validation
# - returns a single top-level JSON object on stdout containing "reply"
#
# Notes:
# - Install msgspec in your container image: pip install msgspec
# - This script intentionally prints ONLY JSON to stdout (no extra logs).
# - On parse/validation error it returns a JSON object without "reply" so
#   middleware can surface a deterministic error message and debugging details.

import sys
import time
import msgspec
from typing import Optional

# ---- Schema definitions ----
class InPayload(msgspec.Struct):
    message: str

class OutPayload(msgspec.Struct):
    reply: str
    # Optional debug field (kept for development; middleware can ignore it)
    debug: Optional[str] = None

# ---- Helpers ----
def read_stdin() -> str:
    """
    Read all data from stdin. If no data is present and a single argv is provided,
    treat argv[1] as the JSON payload.
    """
    if not sys.stdin.isatty():
        data = sys.stdin.read()
        if data and data.strip():
            return data
    # Fallback: if caller passed a single argument, use it
    if len(sys.argv) >= 2:
        return sys.argv[1]
    return ""

def output_json(obj: msgspec.Struct) -> None:
    """
    Encode the msgspec Struct to JSON bytes and write to stdout. Flush and exit.
    """
    try:
        b = msgspec.json.encode(obj)
        # Write bytes directly so we guarantee no extra encoding or newline noise
        sys.stdout.buffer.write(b)
        sys.stdout.buffer.write(b"\n")
        sys.stdout.flush()
    except Exception:
        # If encoding fails, write minimal JSON error to stdout to keep middleware deterministic.
        sys.stdout.buffer.write(b'{"error":"failed_to_encode_response"}\n')
        sys.stdout.flush()

# ---- Main logic ----
def main() -> None:
    raw = read_stdin()
    if not raw:
        # No input provided — return a helpful reply for manual tests
        out = OutPayload(reply="Mock response: no input received. Send a JSON object like {\"message\":\"...\"}.",
                         debug="no_input")
        output_json(out)
        return

    # Parse input using msgspec to enforce schema
    try:
        # msgspec.json.decode returns native Python types unless given a type
        payload: InPayload = msgspec.json.decode(raw, type=InPayload)
    except Exception as e:
        # Invalid JSON or schema mismatch — return structured error object (no reply key)
        # Middleware will treat missing reply as failure and surface details.
        err_obj = {"error": "invalid_input", "details": str(e)}
        sys.stdout.buffer.write(msgspec.json.encode(err_obj) + b"\n")
        sys.stdout.flush()
        return

    # Simulate processing latency (small) to emulate real model interaction
    time.sleep(0.15)

    # Build the mock reply. Structure this to be easily swapped with AzureOpenAI output.
    user_msg = payload.message.strip()
    if not user_msg:
        reply_text = "Mock response: I didn't catch that. Please send a non-empty message."
    else:
        # Example deterministic mock reply that echoes and adds a suggestion
        reply_text = f"Mock response: You said '{user_msg}'. Suggested highlight: Eiffel Tower, Le Marais, and Musée d'Orsay."

    out = OutPayload(reply=reply_text, debug="mock_with_msgspec")
    output_json(out)

if __name__ == "__main__":
    main()
