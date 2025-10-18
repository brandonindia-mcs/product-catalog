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
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=$component
kubectl get ingressclass
kubectl get svc -n ingress-nginx
kubectl get svc ingress-nginx-controller -n ingress-nginx -o yaml

)
}

function validate_getyaml {
(
namespace=default
kubectl get deployment web -n $namespace -o yaml
kubectl get svc web-service -n $namespace -o yaml
kubectl get deployment api -n $namespace -o yaml
kubectl get svc api-service -n $namespace -o yaml
kubectl get ingress api-service-ingress -n $namespace -o yaml
kubectl get ingress web-service-ingress -n $namespace -o yaml

)
}


