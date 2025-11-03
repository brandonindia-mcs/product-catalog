echo Test \#1
curl http://localhost:3001/api/health
echo
echo Test \#2
curl -X POST http://localhost:3001/api/chat \
     -H "Content-Type: application/json" \
     -d '{"message":"Hello backend"}'
