# ai-chat.py
import sys
import json
from openai import AzureOpenAI

# Replace with your actual values or load from env
DEPLOYMENT=os.getenv("AI_DEPLOYMENT")
VERSION=os.getenv("AI_VERSION")
ENDPOINT=os.getenv("AI_ENDPOINT")
API_KEY=os.getenv("AI_API_KEY")


client = AzureOpenAI(
    api_version=VERSION,
    azure_endpoint=ENDPOINT,
    api_key=API_KEY
)
response = client.chat.completions.create(
    messages=[
        {
            "role": "system",
            "content": "You are a helpful assistant.",
        },
        {
            "role": "user",
            "content": "I am going to Paris, what should I see?",
        }
    ],
    max_completion_tokens=16384,
    model=DEPLOYMENT
)

print(response.choices[0].message.content)
print(json.dumps({
    "reply": response.choices[0].message.content
}))
