End-to-end local test (curl → server.js → ai-chat-py.py)
Below are the exact steps, commands, and expected results to run an end-to-end local test on your workstation (no Kubernetes required). This uses the stdin-based JSON payload approach from the regenerated server.js and the ai-chat-py.py you validated.

Prerequisites

Node.js (v18+ recommended) and npm available locally

Python 3 (python3) and pip available locally

msgspec installed in the Python environment: pip install msgspec

Your working directory contains: server.js (the commented, stdin-based version), ai-chat-py.py (the msgspec-based script), and package.json (with express, cors installed).

``` bash
. test/node_refresh.sh
node_refresh 20
python3 -m pip install --user msgspec
chmod +x ./ai-chat-py.py
npm install --include=dev
npm start
### alternates
PY_SCRIPT=ai-chat-py.py node server.js
PYTHON_CMD=python node server.js
###
npm test
npm run curl
curl -s -X POST http://localhost:3001/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello from curl test"}' | jq

```

### Deploy Troubleshooting
Summary of likely causes
Liveness/readiness probes are hitting a path that returns 404 (probe misconfigured) causing restarts/unready state and preventing requests from reaching the middleware.

Middleware may not be listening where the Deployment expects (port mismatch, wrong PORT env).

Python script or Node startup errors can cause the app to crash or return non-JSON, which the frontend then surfaces as "no response".

Frontend issues: wrong API base (VITE_API_URL), CORS, or axios/network errors preventing Chat.jsx from reaching the middleware.

1. Confirm pod status, events, and exact probe config
```bash
# get the pod name
POD=$(getpod chat)
kubectl describe pod $POD

kubectl logs "$POD"
kubectl logs "$POD" --previous

# exec into the pod
kubectl exec -it "$POD" -- /bin/sh
# inside the shell run:
node --version
python3 --version
ls -l
cat package.json
# verify server file exists and package.json contains "type":"module" for ES import
cat server.js | sed -n '1,200p'

# check python script behavior
echo '{"message":"hello"}' | python3 ai-chat-py.py

# check server probe and chat endpoints locally
curl -v http://127.0.0.1:3001/health || true
curl -v http://127.0.0.1:3001/ || true
curl -v http://127.0.0.1:3001/chat -H "Content-Type: application/json" -d '{"message":"hello"}' || true

```