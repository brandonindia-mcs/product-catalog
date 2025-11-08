#!/usr/bin/env bash
# simple API validator — tests external NodePort and optional in-cluster Service
# Usage examples:
#   # External NodePort (default)
#   VITE_API_URL="https://product-catalog.progress.me:32443/api" ./validate-api.sh
#
#   # External with explicit Host header (when using node-ip + nodePort)
#   HOST_HEADER="product-catalog.progress.me" VITE_API_URL="https://<node-ip>:32443/api" ./validate-api.sh
#
#   # In-cluster test (run inside a pod)
#   IN_CLUSTER=true VITE_API_URL="https://product-catalog:2443/api" ./validate-api.sh
set -euo pipefail

: "${VITE_API_URL:=https://product-catalog.progress.me:32443/api}"
: "${TIMEOUT:=8}"
: "${HOST_HEADER:=}"
: "${IN_CLUSTER:=false}"

CURL=${CURL:-curl}

echo
echo "Validating API: ${VITE_API_URL}"
[ -n "$HOST_HEADER" ] && echo "Using Host header: ${HOST_HEADER}"
echo

# helper: simple GET that prints status and first 1k of body
simple_get() {
  url="$1"
  hdrs=()
  [ -n "$HOST_HEADER" ] && hdrs+=(-H "Host: ${HOST_HEADER}")
  echo "GET ${url}"
  $CURL -sS -m $TIMEOUT -D - "${hdrs[@]}" "$url" -o /tmp/validate_api_body || true
  status=$(awk 'NR==1{print $2}' /tmp/validate_api_body || true)
  # if curl wrote headers to stdout, fallback to parse http status from output:
  if [ -z "$status" ]; then
    status=$($CURL -sS -m $TIMEOUT -o /tmp/validate_api_body -w "%{http_code}" "${hdrs[@]}" "$url" 2>/dev/null || true)
  fi
  echo "  HTTP status: $status"
  if [ -s /tmp/validate_api_body ]; then
    echo "  Body (first 1k):"
    head -c 1024 /tmp/validate_api_body | sed 's/^/    /'
  else
    echo "  Body: <empty>"
  fi
  echo
  rm -f /tmp/validate_api_body
}

# helper: simple POST JSON
simple_post() {
  url="$1"
  data='{"message":"validation-ping"}'
  hdrs=(-H "Content-Type: application/json")
  [ -n "$HOST_HEADER" ] && hdrs+=(-H "Host: ${HOST_HEADER}")
  echo "POST ${url}  (payload: ${data})"
  $CURL -sS -m $TIMEOUT -D - "${hdrs[@]}" -d "$data" -X POST "$url" -o /tmp/validate_api_body || true
  status=$($CURL -sS -m $TIMEOUT -o /dev/null -w "%{http_code}" "${hdrs[@]}" -d "$data" -X POST "$url" 2>/dev/null || true)
  echo "  HTTP status: $status"
  if [ -s /tmp/validate_api_body ]; then
    echo "  Body (first 1k):"
    head -c 1024 /tmp/validate_api_body | sed 's/^/    /'
  else
    echo "  Body: <empty>"
  fi
  echo
  rm -f /tmp/validate_api_body
}

# Primary checks
simple_get "${VITE_API_URL%/}/"         # root
simple_get "${VITE_API_URL%/}/health"   # common health
simple_get "${VITE_API_URL%/}/api"      # api root
simple_get "${VITE_API_URL%/}/api/health"

# POST to /api
simple_post "${VITE_API_URL%/}/api"

# Optional in-cluster direct check hint
if [ "${IN_CLUSTER}" = "true" ]; then
  echo "Note: running in-cluster check. If the service uses containerPort 2443 you may need to target that port directly."
  echo
fi

echo "Validation script finished."
