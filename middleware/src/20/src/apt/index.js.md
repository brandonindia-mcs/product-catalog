You asked for the validator to focus on the API (not /chat). Your Service maps NodePort 32000 → Service port 000 → containerPort 2000. The container listens on port 2000 (TLS). The validator must therefore exercise:

External access via NodePort/Ingress: https://product-catalog.progress.me:32000/api (HTTPS)

In-cluster access (pod → service → pod): use the Service hostname and the container port (either service port 000 or container port 2000 depending on how your Service is configured and whether it terminates TLS)

Below is a single self-contained bash script (validate-api.sh) adapted to test the API surface and port topology you described. It:

Defaults to VITE_API_URL="https://product-catalog.progress.me:32000/api"

Tests GET /, GET /health, GET /api/health, GET /api, and POST /api (JSON)

Can run externally (developer laptop) or in-cluster (set IN_CLUSTER=true and use service DNS)

Handles TLS cert summary, Host header override, and prints headers + body previews

Allows explicit SERVICE_HOST and SERVICE_PORT overrides for in-cluster testing (use 2000 when you want to target the container port directly)