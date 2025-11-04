## React 18 frontend (node 22) + vite
<img width="860" height="953" alt="Screenshot 2025-11-04 at 5 24 58 PM" src="https://github.com/user-attachments/assets/4892f082-a259-4ec3-b117-992b48942dd8" />

<img width="860" height="953" alt="Screenshot 2025-11-04 at 5 25 18 PM" src="https://github.com/user-attachments/assets/ba014ce3-6cd1-45e4-9985-56a4040f2b5f" />

### Backend LLM interrogtion (chat)
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
