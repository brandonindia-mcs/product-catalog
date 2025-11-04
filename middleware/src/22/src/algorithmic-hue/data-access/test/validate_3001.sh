function yesno { read -p "$1 yes (default) or no: " && if [[ ${REPLY} = n ]] || [[ ${REPLY} = no ]]; then return 1; fi; return 0; }

uri=/debug && curl -vs http://localhost:3001/$uri

uri=/api/health && curl -vs http://localhost:3001/$uri


echo\
  && uri=/api/welcome && yesno $uri && curl -vs http://localhost:3001$uri | jq\
  && uri=/api/health && yesno $uri && curl -vs http://localhost:3001$uri | jq\
\
  && uri=/api/chat && yesno $uri && (curl -vs -X POST http://localhost:3001$uri \
  -H "Content-Type: application/json" \
  -d '{"prompt":"You have been prompted"}' | jq)\
  && uri=/api/chat && yesno $uri && (curl -vs -X POST http://localhost:3001$uri \
  -H "Content-Type: application/json" \
  -d '{"prompt": "You'\''ve been prompted"}' | jq)

# echo
# echo Test \#3
# curl http://localhost:3001/debug
# echo
# echo Test \#4
# curl -X POST http://localhost:3001/api/chat \
#   -H "Content-Type: application/json" \
#   -d '{"message":"Hello backend"}'
# echo