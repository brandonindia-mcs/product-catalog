## React 18 frontend (node 22) + vite
<img width="1482" height="987" alt="Screenshot 2025-11-04 at 5 32 34 PM" src="https://github.com/user-attachments/assets/f3cbdd71-fc28-48ac-822a-4c0a55990f59" />
<img width="1463" height="1203" alt="Screenshot 2025-11-04 at 5 28 18 PM" src="https://github.com/user-attachments/assets/be642a1a-7b41-496d-8d2d-da12b4201aea" />

### Backend LLM interrogtion (chat)
This requires an explanation.  The prompt sent to Azure OpenAI was canned, the reply from the LLM was captured and displayed in realtime.
In the 12 hours post this screenshot, my Azure credits expired so access to the LLM backend is revoked.

<img width="1874" height="1427" alt="Screenshot 2025-11-04 at 5 27 18 PM" src="https://github.com/user-attachments/assets/d2f99c4c-d0b2-4d19-a7c2-727dc02f09c8" />

## Architecture
This is a 3-tiered web application: frontend, middleware, & backend, all served under Kubernetes.  It comes with a menu driver that cleanly performs the labeled action.
1. The frontend is a React web application.
1. The middleware is a node.js layer for logic & data access.
1. The backend is a postgres database.

<img width="2380" height="498" alt="Screenshot 2025-10-21 at 1 19 25 PM" src="https://github.com/user-attachments/assets/29e7cdd4-5033-4a6f-832f-85964cc8b62b" />


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
