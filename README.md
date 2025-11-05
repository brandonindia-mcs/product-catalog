### Middleware LLM interrogtion (chat)
Demonstrates a prompt entered into a React frontend component and a middleware node.js/Fastify server calling python script.  Python constructs an AI client, uses chat completions to send a canned prompt to Azure OpenAI, then sends what it gets from the LLM back to the server.

The prompt sent to the LLM is canned.
The reply from the LLM is captured and displayed in realtime.

<img width="1874" height="1427" alt="Screenshot 2025-11-04 at 5 27 18 PM" src="https://github.com/user-attachments/assets/d2f99c4c-d0b2-4d19-a7c2-727dc02f09c8" />

## React frontend + vite
### Screenshot of Gpt Interrogation.
Demonstrates a prompt entered into a React frontend component, then a middleware node.js/Fastify server calling python script and returning with an error.  In the 12 hours post screenshot (above), my Azure credits expired so access to the LLM backend is revoked. 

<img width="1482" height="987" alt="Screenshot 2025-11-04 at 5 32 34 PM" src="https://github.com/user-attachments/assets/f3cbdd71-fc28-48ac-822a-4c0a55990f59" />
<img width="1463" height="1203" alt="Screenshot 2025-11-04 at 5 28 18 PM" src="https://github.com/user-attachments/assets/be642a1a-7b41-496d-8d2d-da12b4201aea" />

## Architecture
This is a 3-tiered web application: frontend, middleware & backend, all served under Kubernetes.  It comes with a menu driver that cleanly performs the labeled action.
1. The frontend is a React web application.
1. The middleware is a node.js layer for logic & data access.
1. The backend is a postgres database.

<img width="1091" height="335" alt="Screenshot 2025-11-04 at 7 05 26 PM" src="https://github.com/user-attachments/assets/b68dbd9f-16f2-4fbe-ba7a-5c3c22eca52e" />


## Dependencies
- kubectl
- docker
- openssl (for self-signed certs)

## Getting Started
```base
git clone git@github.com:<YOUR-SSH-USER>/product-catalog
cd ./product-catalog
. ./menu.sh <<<3
```
