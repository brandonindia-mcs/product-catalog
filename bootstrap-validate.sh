function validate_api {
validate_api_web_https
validate_api_k8s_https
}

function print_validate_api {
banner1 printit
echo '('
cat ./middleware/k8s/$sdenv.env || exit 1
cat ./frontend/$sdenv.env || exit 1
formatrun <<'EOF'
   banner validate_api::formatrun\
   && info curl -s http://$API_HOST:$API_HTTP_RUNPORT_K8S_MIDDLEWARE/health/db \
        && curl -s http://$API_HOST:$API_HTTP_RUNPORT_K8S_MIDDLEWARE/health/db|jq\
   && info curl -s http://$API_HOST:$API_HTTP_RUNPORT_K8S_MIDDLEWARE/products \
        && curl -s http://$API_HOST:$API_HTTP_RUNPORT_K8S_MIDDLEWARE/products|jq\
   && info curl -s http://$API_HOST:$API_HTTP_RUNPORT_K8S_MIDDLEWARE/products/1 \
        && curl -s http://$API_HOST:$API_HTTP_RUNPORT_K8S_MIDDLEWARE/products/1|jq\
        \
   && info curl -ks https://$API_HOST:$API_HTTPS_RUNPORT_K8S_MIDDLEWARE/health/db \
        && curl -ks https://$API_HOST:$API_HTTPS_RUNPORT_K8S_MIDDLEWARE/health/db|jq\
   && info curl -ks https://$API_HOST:$API_HTTPS_RUNPORT_K8S_MIDDLEWARE/products \
        && curl -ks https://$API_HOST:$API_HTTPS_RUNPORT_K8S_MIDDLEWARE/products|jq\
   && info curl -ks https://$API_HOST:$API_HTTPS_RUNPORT_K8S_MIDDLEWARE/products/1 \
        && curl -ks https://$API_HOST:$API_HTTPS_RUNPORT_K8S_MIDDLEWARE/products/1|jq\
        \
  && weblist=$(kubectl get pods --no-headers -o custom-columns=:metadata.name|/usr/bin/grep -E ^web) &&\
    for pod in ${weblist[@]};do
    \
      info kubectl exec -it $pod -- curl -s http://$SERVICE:$RUNPORT_HTTP_FRONTEND_LISTENER/health/db\
        && kubectl exec -it $pod -- curl -s http://$SERVICE:$RUNPORT_HTTP_FRONTEND_LISTENER/health/db|jq\
   && info kubectl exec -it $pod -- curl -s http://$SERVICE:$RUNPORT_HTTP_FRONTEND_LISTENER/products\
        && kubectl exec -it $pod -- curl -s http://$SERVICE:$RUNPORT_HTTP_FRONTEND_LISTENER/products|jq\
   && info kubectl exec -it $pod -- curl -s http://$SERVICE:$RUNPORT_HTTP_FRONTEND_LISTENER/products/1\
        && kubectl exec -it $pod -- curl -s http://$SERVICE:$RUNPORT_HTTP_FRONTEND_LISTENER/products/1|jq
    \
      info kubectl exec -it $pod -- curl -ks https://$SERVICE:$RUNPORT_HTTPS_FRONTEND_LISTENER/health/db\
        && kubectl exec -it $pod -- curl -ks https://$SERVICE:$RUNPORT_HTTPS_FRONTEND_LISTENER/health/db|jq\
   && info kubectl exec -it $pod -- curl -ks https://$SERVICE:$RUNPORT_HTTPS_FRONTEND_LISTENER/products\
        && kubectl exec -it $pod -- curl -ks https://$SERVICE:$RUNPORT_HTTPS_FRONTEND_LISTENER/products|jq\
   && info kubectl exec -it $pod -- curl -ks https://$SERVICE:$RUNPORT_HTTPS_FRONTEND_LISTENER/products/1\
        && kubectl exec -it $pod -- curl -ks https://$SERVICE:$RUNPORT_HTTPS_FRONTEND_LISTENER/products/1|jq
  done
EOF
echo ')'

(
set -a
source ./middleware/k8s/$sdenv.env || exit 1
source ./frontend/$sdenv.env || exit 1
set +a
logit "
   && info curl -s http://$API_HOST:$API_HTTP_RUNPORT_K8S_MIDDLEWARE/health/db \
        && curl -s http://$API_HOST:$API_HTTP_RUNPORT_K8S_MIDDLEWARE/health/db|jq\
   && info curl -s http://$API_HOST:$API_HTTP_RUNPORT_K8S_MIDDLEWARE/products \
        && curl -s http://$API_HOST:$API_HTTP_RUNPORT_K8S_MIDDLEWARE/products|jq\
   && info curl -s http://$API_HOST:$API_HTTP_RUNPORT_K8S_MIDDLEWARE/products/1 \
        && curl -s http://$API_HOST:$API_HTTP_RUNPORT_K8S_MIDDLEWARE/products/1|jq\
        \
      info curl -ks https://$API_HOST:$API_HTTPS_RUNPORT_K8S_MIDDLEWARE/health/db \
        && curl -ks https://$API_HOST:$API_HTTPS_RUNPORT_K8S_MIDDLEWARE/health/db|jq\
   && info curl -ks https://$API_HOST:$API_HTTPS_RUNPORT_K8S_MIDDLEWARE/products \
        && curl -ks https://$API_HOST:$API_HTTPS_RUNPORT_K8S_MIDDLEWARE/products|jq\
   && info curl -ks https://$API_HOST:$API_HTTPS_RUNPORT_K8S_MIDDLEWARE/products/1 \
        && curl -ks https://$API_HOST:$API_HTTPS_RUNPORT_K8S_MIDDLEWARE/products/1|jq\
        \
  && weblist=\$(kubectl get pods --no-headers -o custom-columns=:metadata.name|/usr/bin/grep -E ^web) &&\
    for pod in \${weblist[@]};do
    \
      info kubectl exec -it \$pod -- curl -s http://$SERVICE:$RUNPORT_HTTP_FRONTEND_LISTENER/health/db\
        && kubectl exec -it \$pod -- curl -s http://$SERVICE:$RUNPORT_HTTP_FRONTEND_LISTENER/health/db|jq\
   && info kubectl exec -it \$pod -- curl -s http://$SERVICE:$RUNPORT_HTTP_FRONTEND_LISTENER/products\
        && kubectl exec -it \$pod -- curl -s http://$SERVICE:$RUNPORT_HTTP_FRONTEND_LISTENER/products|jq\
   && info kubectl exec -it \$pod -- curl -s http://$SERVICE:$RUNPORT_HTTP_FRONTEND_LISTENER/products/1\
        && kubectl exec -it \$pod -- curl -s http://$SERVICE:$RUNPORT_HTTP_FRONTEND_LISTENER/products/1|jq
    \
      info kubectl exec -it \$pod -- curl -ks https://$SERVICE:$RUNPORT_HTTPS_FRONTEND_LISTENER/health/db\
        && kubectl exec -it \$pod -- curl -ks https://$SERVICE:$RUNPORT_HTTPS_FRONTEND_LISTENER/health/db|jq\
   && info kubectl exec -it \$pod -- curl -ks https://$SERVICE:$RUNPORT_HTTPS_FRONTEND_LISTENER/products\
        && kubectl exec -it \$pod -- curl -ks https://$SERVICE:$RUNPORT_HTTPS_FRONTEND_LISTENER/products|jq\
   && info kubectl exec -it \$pod -- curl -ks https://$SERVICE:$RUNPORT_HTTPS_FRONTEND_LISTENER/products/1\
        && kubectl exec -it \$pod -- curl -ks https://$SERVICE:$RUNPORT_HTTPS_FRONTEND_LISTENER/products/1|jq
  done
"
)

(
set -a
source ./middleware/k8s/$sdenv.env || exit 1
source ./frontend/$sdenv.env || exit 1
set +a
banner1 printit
logone "
curl -s http://$API_HOST:$API_HTTP_RUNPORT_K8S_MIDDLEWARE/health/db|jq
curl -ks https://$API_HOST:$API_HTTPS_RUNPORT_K8S_MIDDLEWARE/health/db|jq

curl -s http://$API_HOST:$API_HTTP_RUNPORT_K8S_MIDDLEWARE/products|jq
curl -ks https://$API_HOST:$API_HTTPS_RUNPORT_K8S_MIDDLEWARE/products|jq

curl -s http://$API_HOST:$API_HTTP_RUNPORT_K8S_MIDDLEWARE/products/1|jq
curl -ks https://$API_HOST:$API_HTTPS_RUNPORT_K8S_MIDDLEWARE/products/1|jq

weblist=\$(kubectl get pods --no-headers -o custom-columns=:metadata.name|/usr/bin/grep -E ^web)

for pod in \${weblist[@]};do
  kubectl exec -it \$pod -- curl -s http://$SERVICE:$RUNPORT_HTTP_FRONTEND_LISTENER/health/db|jq
  kubectl exec -it \$pod -- curl -ks https://$SERVICE:$RUNPORT_HTTPS_FRONTEND_LISTENER/health/db|jq
 done

for pod in \${weblist[@]};do
kubectl exec -it \$pod -- curl -s http://$SERVICE:$RUNPORT_HTTP_FRONTEND_LISTENER/products|jq
kubectl exec -it \$pod -- curl -ks https://$SERVICE:$RUNPORT_HTTPS_FRONTEND_LISTENER/products|jq
done

for pod in \${weblist[@]};do
kubectl exec -it \$pod -- curl -s http://$SERVICE:$RUNPORT_HTTP_FRONTEND_LISTENER/products/1|jq
kubectl exec -it \$pod -- curl -ks https://$SERVICE:$RUNPORT_HTTPS_FRONTEND_LISTENER/products/1|jq
done
"
)

}


function validate_api_k8s_http {
(
set -a
source ./middleware/k8s/$sdenv.env || exit 1
source ./frontend/$sdenv.env || exit 1
set +a

runit_nolog "weblist=\$(kubectl get pods --no-headers -o custom-columns=:metadata.name|/usr/bin/grep -E ^web)
for pod in \${weblist[@]};do
CMD=\"kubectl exec -it \$pod -- curl -s http://$SERVICE:$RUNPORT_HTTP_FRONTEND_LISTENER/health/db|jq\"
echo \$CMD && eval \$CMD
CMD=\"kubectl exec -it \$pod -- curl -s http://$SERVICE:$RUNPORT_HTTP_FRONTEND_LISTENER/products|jq\"
echo \$CMD && eval \$CMD
CMD=\"kubectl exec -it \$pod -- curl -s http://$SERVICE:$RUNPORT_HTTP_FRONTEND_LISTENER/products/1|jq\"
echo \$CMD && eval \$CMD
done"
)

}


function validate_api_web_https {
(
set -a
source ./frontend/$sdenv.env || exit 1
set +a

# runit_nolog "
# CMD=\"curl -ks https://\$API_HTTPS_FQDN_WITH_PORT/health/db|jq\"
# echo \$CMD && eval \$CMD

# CMD=\"curl -ks https://\$API_HTTPS_FQDN_WITH_PORT/products|jq\"
# echo \$CMD && eval \$CMD

# CMD=\"curl -ks https://\$API_HTTPS_FQDN_WITH_PORT/products/1|jq\"
# echo \$CMD && eval \$CMD"
# )

runit "
curl -ks https://$API_HTTPS_FQDN_WITH_PORT/health/db|jq
curl -ks https://$API_HTTPS_FQDN_WITH_PORT/products|jq
curl -ks https://$API_HTTPS_FQDN_WITH_PORT/products/1|jq
"

)

}


function validate_api_k8s_https {
(
set -a
source ./middleware/k8s/$sdenv.env || exit 1
set +a

# runit_nolog "
# weblist=\$(kubectl get pods --no-headers -o custom-columns=:metadata.name|/usr/bin/grep -E ^web)
# for pod in \${weblist[@]};do

# CMD=\"kubectl exec -it \$pod -- curl -ks https://$SERVICE:$SSL_PORT/health/db|jq\"
# echo \$CMD && eval \$CMD

# CMD=\"kubectl exec -it \$pod -- curl -ks https://$SERVICE:$SSL_PORT/products|jq\"
# echo \$CMD && eval \$CMD

# CMD=\"kubectl exec -it \$pod -- curl -ks https://$SERVICE:$SSL_PORT/products/1|jq\"
# echo \$CMD && eval \$CMD
# done"


runit "
weblist=\$(kubectl get pods --no-headers -o custom-columns=:metadata.name|/usr/bin/grep -E ^web)
for pod in \${weblist[@]};do
kubectl exec -it \$pod -- curl -ks https://$SERVICE:$SSL_PORT/health/db|jq
kubectl exec -it \$pod -- curl -ks https://$SERVICE:$SSL_PORT/products|jq
kubectl exec -it \$pod -- curl -ks https://$SERVICE:$SSL_PORT/products/1|jq
done
"
)

}


function validate_web {
(
component=${1:-controller}
date
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=$component
kubectl get ingressclass
kubectl get svc -n ingress-nginx
kubectl get svc ingress-nginx-controller -n ingress-nginx -o yaml

kubectl logs -n ingress-nginx -l app.kubernetes.io/component=$component
curl -v http://product-catalog.progress.me/
curl -vk https://product-catalog.progress.me/
kubectl describe ingress web-ingress
kubectl get svc web-service
kubectl get pods -l app=web

)
}


function validate_ingress {
(
component=${1:-controller}
date
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=$component
kubectl get ingressclass
kubectl get svc -n ingress-nginx
kubectl get svc ingress-nginx-controller -n ingress-nginx -o yaml

)
}

function validate_getyaml {
(
namespace=default
date
kubectl get deployment web -n $namespace -o yaml
kubectl get svc web-service -n $namespace -o yaml
kubectl get deployment api -n $namespace -o yaml
kubectl get svc api-service -n $namespace -o yaml
kubectl get ingress api-service-ingress -n $namespace -o yaml
kubectl get ingress web-service-ingress -n $namespace -o yaml

)
}


function validate_service_endpoints {
>./build/validate_service_endpoints.out
(
date
echo \*\*\*\*\* Describing $MIDDLEWARE_API_SERVICE_NAME
kubectl describe svc $MIDDLEWARE_API_SERVICE_NAME
echo \*\*\*\*\* Netstat $MIDDLEWARE_DEPLOYMENT_NAME
kubectl exec -it deploy/$MIDDLEWARE_DEPLOYMENT_NAME -- netstat -tlnp

echo \*\*\*\*\* Describing $FRONTEND_WEBSERVICE_NAME
kubectl describe svc $FRONTEND_WEBSERVICE_NAME
echo \*\*\*\*\* Netstat $FRONTEND_DEPLOYMENT_NAME
kubectl exec -it deploy/$FRONTEND_DEPLOYMENT_NAME -- netstat -tlnp

echo \*\*\*\*\* Describing $BACKEND_DATABASE_SERVICE_NAME
kubectl describe svc $BACKEND_DATABASE_SERVICE_NAME
echo \*\*\*\*\* Netstat $BACKEND_DEPLOYMENT_NAME
kubectl exec -it deploy/$BACKEND_DEPLOYMENT_NAME -- netstat -tlnp
) 2>&1 | tee ./build/validate_service_endpoints.out
}

function get_yaml_out {
(
get_web_out
get_api_out
get_postgres_out
) 2>&1 | tee ./build/yaml.out
}

function get_web_out {
(
date
kubectl get deployment web -o yaml
kubectl get svc web-service -o yaml
kubectl get ingress web-service-ingress -o yaml
) 2>&1 | tee ./build/web.out
}

function get_api_out {
(
date
kubectl get deployment api -o yaml
kubectl get svc api-service -o yaml
kubectl get ingress api-service-ingress -o yaml
) 2>&1 | tee ./build/api.out
}

function get_postgres_out {
(
date
kubectl get deployment postgre -o yaml
kubectl get svc pg-service -o yaml
) 2>&1 | tee ./build/postgres.out
}