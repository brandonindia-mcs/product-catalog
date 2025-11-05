# (
# function blue { println '\e[34m%s\e[m' "$*"; }

if [ -r ./watch ];then . ./watch.sh;else . ./menu/watch.sh;fi

function print_validate_api {
banner1 printit
echo '('
cat ./middleware/k8s/$sdenv.env || fail no ./middleware/k8s/$sdenv.env:$LINENO
# cat ./frontend/$sdenv.env || fail no ./frontend/$sdenv.env:$LINENO
cat ./frontend/.env.$sdenv || fail no ./frontend/.env.$sdenv:$LINENO
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

# (
set -a
source ./middleware/k8s/$sdenv.env || fail no ./middleware/k8s/$sdenv.env:$LINENO
# source ./frontend/$sdenv.env || fail no ./frontend/$sdenv.env:$LINENO
source ./frontend/.env.$sdenv || fail no ./frontend/.env.$sdenv:$LINENO
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
# )

# (
set -a
source ./middleware/k8s/$sdenv.env || fail no ./middleware/k8s/$sdenv.env:$LINENO
# source ./frontend/$sdenv.env || fail no ./frontend/$sdenv.env:$LINENO
source ./frontend/.env.$sdenv || fail no ./frontend/.env.$sdenv:$LINENO
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
# )

}


function validate_api_k8s_http {
# (
set -a
source ./middleware/k8s/$sdenv.env || fail no ./middleware/k8s/$sdenv.env:$LINENO
# source ./frontend/$sdenv.env || fail no ./frontend/$sdenv.env:$LINENO
source ./frontend/.env.$sdenv || fail no ./frontend/.env.$sdenv:$LINENO
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
# )

}


function validate_api_web_https {
# (
set -a
# source ./frontend/$sdenv.env || fail no ./frontend/$sdenv.env:$LINENO
source ./frontend/.env.$sdenv || fail no ./frontend/.env.$sdenv:$LINENO
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

# )

}


function validate_middleware_k8s_https {
(
set -a
component=api
source ./middleware/k8s/$sdenv.env || fail no ./middleware/k8s/$sdenv.env:$LINENO
source ./middleware/k8s/$sdenv$component.env || fail no ./middleware/k8s/$sdenv$component.env:$LINENO
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

(
set -a
component=chat
source ./middleware/k8s/$sdenv.env || fail no ./middleware/k8s/$sdenv.env:$LINENO
source ./middleware/k8s/$sdenv$component.env || fail no ./middleware/k8s/$sdenv$component.env:$LINENO
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
NS=default
PRODUCT_CATALOG_SECURE_API_FQDN=https://product-catalog.progress.me:32443
PRODUCT_CATALOG_CHAT_FQDN=https://product-catalog.progress.me:3001
function validate_insecure_api {
curl -vk -X POST $PRODUCT_CATALOG_SECURE_API_FQDN/api \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"system","content":"You are a helpful assistant."},{"role":"user","content":"Hello"}]}'

}
function validate_insecure_chat {
url=http://$(NS=default get_last_pod_ip chat):3001/chat
curl -v -X POST $url \
  -H "Content-Type: application/json" \
  -d '{"messages":"hello"}'
echo
echo curl -vk -X POST $url

}

function escape {
  local input="$1"
  # Escape double quotes and single quotes
  local escaped="${input//\"/\\\"}"
  escaped="${escaped//\'/\\\'}"
  echo "$escaped"
}

  function get_pod { kubectl get pod -n $NS -l app=$1 -o jsonpath='{.items[0].metadata.name}' ; }
  function getpod { NS=$NS get_pod $1 ; }
  function getlabels { kubectl get deployment -n $NS $1 -o jsonpath="{.spec.selector.matchLabels}" ; }
  function get_last_pod { kubectl get pods -n $NS -l app=$1 --sort-by=.metadata.creationTimestamp -o jsonpath="{.items[-1].metadata.name}" ; }
  function get_last_pod_ip { kubectl get pod -n $NS $(get_last_pod $1) -o jsonpath='{.status.podIP}' ; }
  # function get_last_nginx_ip { $(NS=ingress-nginx get_last_pod ingress-nginx-controller)   --sort-by=.metadata.creationTimestamp   -o jsonpath='{.items[-1].status.podIP}' ; }
  function get_last_running_pod_ip {  kubectl get pod -n $NS --field-selector=status.phase=Running -o jsonpath='{.items[0].status.podIP}' ; }


function validate_web {
# (
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

# )
}


function validate_ingress {
# (
component=${1:-controller}
date
kubectl logs -n $ns -l app.kubernetes.io/component=$component
kubectl get ingressclass
kubectl get svc -n $ns
kubectl get svc ingress-nginx-controller -n $ns -o yaml

# )
}

function validate_getyaml {
# (
namespace=default
date
kubectl get deployment web -n $namespace -o yaml
kubectl get svc web-service -n $namespace -o yaml
kubectl get deployment api -n $namespace -o yaml
kubectl get svc api-service -n $namespace -o yaml
kubectl get ingress api-service-ingress -n $namespace -o yaml
kubectl get ingress web-service-ingress -n $namespace -o yaml

# )
}


function validate_service_endpoints {
>./build/validate_service_endpoints.out
# (
echo \*\*\*\*\* kubectl exec -it deploy/$FRONTEND__WEB_DEPLOYMENT -- netstat -tulnp
kubectl exec -it deploy/$FRONTEND__WEB_DEPLOYMENT -- netstat -tulnp

echo \*\*\*\*\* kubectl exec -it deploy/$MIDDLEWARE_API_DEPLOYMENT -- netstat -tulnp
kubectl exec -it deploy/$MIDDLEWARE_API_DEPLOYMENT -- netstat -tulnp

echo \*\*\*\*\* kubectl exec -it deploy/$MIDDLEWARE_APT_DEPLOYMENT -- netstat -tulnp
kubectl exec -it deploy/$MIDDLEWARE_APT_DEPLOYMENT -- netstat -tulnp

echo \*\*\*\*\* kubectl exec -it deploy/$BACKEND_DB_DEPLOYMENT -- netstat -tulnp
kubectl exec -it deploy/$BACKEND_DB_DEPLOYMENT -- netstat -tulnp
# )
}



function describe_service_endpoints {
>./build/describe_service_endpoints.out
(
date
echo \*\*\*\*\* Describing $FRONTEND_WEBSERVICE
kubectl describe svc $FRONTEND_WEBSERVICE
echo \*\*\*\*\* $FRONTEND_DEPLOYMENT netstat -tulnp
kubectl exec -it deploy/$FRONTEND_DEPLOYMENT -- netstat -tulnp

echo \*\*\*\*\* Describing $MIDDLEWARE_API_SERVICE
kubectl describe svc $MIDDLEWARE_API_SERVICE
echo \*\*\*\*\* $MIDDLEWARE_DEPLOYMENT netstat -tulnp
kubectl exec -it deploy/$MIDDLEWARE_DEPLOYMENT -- netstat -tulnp

echo \*\*\*\*\* Describing $BACKEND_DATABASE_SERVICE
kubectl describe svc $BACKEND_DATABASE_SERVICE
echo \*\*\*\*\* $BACKEND_DEPLOYMENT netstat -tulnp
kubectl exec -it deploy/$BACKEND_DEPLOYMENT -- netstat -tulnp
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
  echo get deployment web:
  kubectl get deployment web -o yaml
  echo get svc web-service:
  kubectl get svc web-service -o yaml
  echo get ingress web-service-ingress:
  kubectl get ingress web-service-ingress -o yaml
) 2>&1 | tee ./build/web.out
}

function get_api_out {
(
date
  echo get deployment api:
  kubectl get deployment api -o yaml
  echo get svc api-service:
  kubectl get svc api-service -o yaml
  echo get ingress api-service-ingress:
  kubectl get ingress api-service-ingress -o yaml
) 2>&1 | tee ./build/api.out
}

function get_postgres_out {
(
date
  echo get deployment postgre:
  kubectl get deployment postgre -o yaml
  echo  get svc db-service:
  kubectl get svc db-service -o yaml
) 2>&1 | tee ./build/postgres.out
}


# )