
uri=/debug && curl -vs http://localhost:3001/$uri

uri=/api/health && curl -vs http://localhost:3001/$uri

uri=/api/welcome && curl -vs http://localhost:3001$uri | jq\
  && read -p "Next (hit enter)" x\
  && uri=/api/health && curl -vs http://localhost:3001$uri | jq\
  && read -p "Next (hit enter)" x\
\
  && uri=/api/chat && (curl -vs -X POST http://localhost:3001$uri \
  -H "Content-Type: application/json" \
  -d '{"prompt":"You have been prompted"}' | jq)\
  && read -p "Next (hit enter)" x\
  && uri=/api/chat && (curl -vs -X POST http://localhost:3001$uri \
  -H "Content-Type: application/json" \
  -d '{"prompt": "You'\''ve been prompted"}' | jq) \
  && read -p "Next (hit enter)" x


# echo
# echo Test \#3
# curl http://localhost:3001/debug
# echo
# echo Test \#4
# curl -X POST http://localhost:3001/api/chat \
#   -H "Content-Type: application/json" \
#   -d '{"message":"Hello backend"}'
# echo