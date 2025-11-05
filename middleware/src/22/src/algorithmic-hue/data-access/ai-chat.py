# ai-chat.py
import os
import sys
import json
from openai import AzureOpenAI

# Replace with your actual values or load from env
DEPLOYMENT=os.getenv("AI_DEPLOYMENT")
VERSION=os.getenv("AI_VERSION")
ENDPOINT=os.getenv("AI_ENDPOINT")
API_KEY=os.getenv("AI_API_KEY")
# ✅ Get the prompt from command-line arguments
if len(sys.argv) < 2:
    print(json.dumps({ "error": "No prompt provided" }))
    sys.exit(1)

system_prompt="You are a rhetorical assistant who only speaks in rhyme."
user_prompt = sys.argv[1]
try:
    client = AzureOpenAI(
        api_version=VERSION,
        azure_endpoint=ENDPOINT,
        api_key=API_KEY
)
    reply = client.chat.completions.create(
        messages=[
            { "role": "system", "content": system_prompt },
            { "role": "user",   "content": user_prompt }
        ],
        max_completion_tokens=16384,
        model=DEPLOYMENT
    ).choices[0].message.content
except Exception as e:
    reply = f"{type(e).__name__}:{e}"
finally:
    print(json.dumps({
        "reply": reply
    }))
