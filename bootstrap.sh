#!/bin/bash

##################  GLOBAL VARS  ##################
GLOBAL_VERSION=$(date +%Y%m%d%H%M%s)
alias stamp="echo \$(date +%Y%m%d%H%M%S)"
export FRONTEND_APPNAME=product-catalog-frontend
export FRONTEND_WEB_SERVICE_NAME=web-service
export FRONTEND_SELECTOR_NAME=web
export FRONTEND_DEPLOYMENT_NAME=web
export FRONTEND_PODTEMPLATE_NAME=web
export FRONTEND_CONTAINER_NAME=web
export WEB_HTTP_RUNPORT_PUBLIC_FRONTEND=80
export WEB_HTTPS_RUNPORT_PUBLIC_FRONTEND=443
# export VITE_API_URL=https://localhost:8443

export MIDDLEWARE_APPNAME=product-catalog-middleware
export MIDDLEWARE_API_SERVICE_NAME=api-service
export MIDDLEWARE_API_SERVICE_LOCALCLUSTER_NAME=https://api-service.default.svc.cluster.local
export MIDDLEWARE_SELECTOR_NAME=api
export MIDDLEWARE_DEPLOYMENT_NAME=api
export MIDDLEWARE_PODTEMPLATE_NAME=api
export MIDDLEWARE_CONTAINER_NAME=api
export MIDDLEWARE_TLS_MOUNT=certs
export MIDDLEWARE_TLS_MOUNT_PATH=/$MIDDLEWARE_TLS_MOUNT
export MIDDLEWARE_TLS_CERT_VOLUME=tls-certs
export API_HTTP_RUNPORT_K8S_MIDDLEWARE=3000
export API_HTTPS_RUNPORT_K8S_MIDDLEWARE=3443

STAMP=`stamp`
export MIDDLEWARE_TLS_SECRET=middleware-tls-$STAMP

export BACKEND_APPNAME=product-catalog-backend
export POSTGRE_SQL_RUNPORT=5432

function product_catalog {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace product_catalog $image_version
###################################
(
info ${FUNCNAME[0]}\
  && yellow ${FUNCNAME[0]}: callling install_postgres\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE install_postgres $1\
  && yellow ${FUNCNAME[0]}: callling install_api\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE install_api $1\
  && yellow ${FUNCNAME[0]}: callling update_webservice\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE update_webservice $1
)
}

function update_product_catalog {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace install_product_catalog $image_version
###################################
(
info ${FUNCNAME[0]}\
  && yellow ${FUNCNAME[0]}: callling update_webservice\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE update_webservice $1\
  && yellow ${FUNCNAME[0]}: callling install_api\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE install_api $1
)
}

function install_webservice {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace install_webservice $image_version
###################################
(
frontend_18\
  && set -u\
  && build_image_frontend $1\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE configure_webservice $1\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE k8s_webservice
)
}

function frontend_convert_18_20 {
##########  RUN COMMAND  ##########
# frontend_convert_18_20
###################################
(
frontend_upgrade_20
)
}

function update_webservice {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace update_webservice $image_version
###################################
(
frontend_update\
  && set -u\
  && build_image_frontend $1\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE configure_webservice $1\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE k8s_webservice
)
}

function install_api {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace install_api $image_version
###################################
(
middleware\
  && set -u\
  && build_image_middleware $1\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE configure_api $1\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE k8s_api

)
}

function install_postgres {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace install_postgres $image_version
###################################
(
backend\
  && set -u\
  && build_image_backend $1\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE configure_postgres $1\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE k8s_postgres
)
}

function k8s {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace k8s
###################################
(
set_registry\
  && k8s_api\
  && k8s_webservice
)
}

function k8s_update {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace k8s_update
###################################
(
set_registry\
  && k8s_api\
  && k8s_webservice_update
)
}

function set_keyvalue {
(
set -u
key=$1; value=$2; path=$3
### IF PATH DOES NOT EXIST
### THEN CREATE PATH
if [ ! -f "$path" ]; then
  touch "$path"
### ELSE IF PATH EXISTS, FILE HAS SIZE, AND DOES NOT END IN A NEW LINE
### APPEND NEWLINE
elif [[ -e "$path" && -s "$path" && "$(tail -c1 "$path" | wc -l)" -eq 0 ]]; then
  echo >>"$path"
fi
### IF PATH IS WRITABLE
### THEN IF KEY EXISTS, THEN OVERWRITE VALUE
### OTHERWISE INSERT KEY=VALUE
if [ -w "$path" ];then
  if grep -q "^$key=" "$path"; then 
    sed -i "s|^$key=.*|$key=$value|" "$path"
  else
    echo "$key=$value" >>"$path"
  fi
fi
)
}

function watch_productcatelog {
(namespace=${1:-default}; while true; do echo && blue $namespace $(date) && kubectl get all --namespace $namespace -o wide && sleep 5;done)
}
function print_k8s_env {
for dir in frontend backend middleware;do cat $dir/k8s/$sdenv.env;done
}
function clean_productcatalog {
for dir in frontend/.nvm middleware/.nvm frontend/product-catalog-frontend middleware/product-catalog-middleware;do echo cleaning $dir && rm -rf $dir;done
}

function local_registry {
# docker run -d -p 5001:5000 --name registry registry:2
echo REGISTRY START: $(docker run -d -p 5001:5000 --name registry registry:2 2>/dev/null || docker start registry >/dev/null && echo -n registry@$DOCKERHUB)
}

function set_registry {
(
set -u
set_keyvalue HUB $DOCKERHUB ./frontend/k8s/$sdenv.env
set_keyvalue HUB $DOCKERHUB ./middleware/k8s/$sdenv.env
set_keyvalue HUB $DOCKERHUB ./backend/k8s/$sdenv.env
local_registry
)
}

function default_configure {
##########  RUN COMMAND  ##########
# default_configure
###################################
(
GLOBAL_NAMESPACE=default configure $GLOBAL_VERSION
)
}

function configure {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace configure $image_version
###################################
(
set -u
image_version=$1
GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE configure_webservice $image_version
GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE configure_api $image_version
GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE configure_postgres $image_version
)
}

function configure_webservice {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace configure_webservice $image_version
###################################
(
set -u
image_version=$1
set_keyvalue REPOSITORY $FRONTEND_APPNAME ./frontend/k8s/$sdenv.env
set_keyvalue RUNPORT_HTTP $WEB_HTTP_RUNPORT_PUBLIC_FRONTEND ./frontend/k8s/$sdenv.env
set_keyvalue RUNPORT_HTTPS $WEB_HTTPS_RUNPORT_PUBLIC_FRONTEND ./frontend/k8s/$sdenv.env
set_keyvalue TAG $image_version ./frontend/k8s/$sdenv.env
set_keyvalue HUB $DOCKERHUB ./frontend/k8s/$sdenv.env
set_keyvalue NAMESPACE $GLOBAL_NAMESPACE ./frontend/k8s/$sdenv.env
set_keyvalue REPLICAS 2 ./frontend/k8s/$sdenv.env
set_keyvalue SERVICE $FRONTEND_WEB_SERVICE_NAME ./frontend/k8s/$sdenv.env
set_keyvalue SELECTOR $FRONTEND_SELECTOR_NAME ./frontend/k8s/$sdenv.env
set_keyvalue DEPLOYMENT $FRONTEND_DEPLOYMENT_NAME ./frontend/k8s/$sdenv.env
set_keyvalue PODTEMPLATE $FRONTEND_PODTEMPLATE_NAME ./frontend/k8s/$sdenv.env
set_keyvalue CONTAINER $FRONTEND_CONTAINER_NAME ./frontend/k8s/$sdenv.env
set -a
source ./frontend/k8s/$sdenv.env || exit 1
set +a
# envsubst < ./frontend/k8s/web.template.yaml | kubectl apply -f -
envsubst >./frontend/k8s/web.yaml <./frontend/k8s/web.template.yaml
)
}

function configure_api {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace configure_api $image_version
###################################
(
set -u
image_version=$1
set_keyvalue REPOSITORY $MIDDLEWARE_APPNAME ./middleware/k8s/$sdenv.env
set_keyvalue TAG $image_version ./middleware/k8s/$sdenv.env
set_keyvalue HUB $DOCKERHUB ./middleware/k8s/$sdenv.env
set_keyvalue NAMESPACE $GLOBAL_NAMESPACE ./middleware/k8s/$sdenv.env
set_keyvalue REPLICAS 2 ./middleware/k8s/$sdenv.env
set_keyvalue RUNPORT_HTTP_FRONTEND_LISTENER $API_HTTP_RUNPORT_K8S_MIDDLEWARE ./middleware/k8s/$sdenv.env
set_keyvalue RUNPORT_HTTPS_FRONTEND_LISTENER $API_HTTPS_RUNPORT_K8S_MIDDLEWARE ./middleware/k8s/$sdenv.env
set_keyvalue SERVICE $MIDDLEWARE_API_SERVICE_NAME ./middleware/k8s/$sdenv.env
set_keyvalue SELECTOR $MIDDLEWARE_SELECTOR_NAME ./middleware/k8s/$sdenv.env
set_keyvalue DEPLOYMENT $MIDDLEWARE_DEPLOYMENT_NAME ./middleware/k8s/$sdenv.env
set_keyvalue PODTEMPLATE $MIDDLEWARE_PODTEMPLATE_NAME ./middleware/k8s/$sdenv.env
set_keyvalue CONTAINER $MIDDLEWARE_CONTAINER_NAME ./middleware/k8s/$sdenv.env
set_keyvalue TLS_MOUNT_PATH $MIDDLEWARE_TLS_MOUNT_PATH ./middleware/k8s/$sdenv.env
set_keyvalue TLS_CERT_VOLUME $MIDDLEWARE_TLS_CERT_VOLUME ./middleware/k8s/$sdenv.env
set_keyvalue TLS_SECRET $MIDDLEWARE_TLS_SECRET ./middleware/k8s/$sdenv.env

set -a
source ./middleware/k8s/$sdenv.env || exit 1
set +a
# envsubst < ./middleware/k8s/api.template.yaml | kubectl apply -f -
envsubst >./middleware/k8s/api.yaml <./middleware/k8s/api.template.yaml
)
}

function configure_postgres {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace configure_postgres $image_version
###################################
(
set -u
image_version=$1
set_keyvalue REPOSITORY $BACKEND_APPNAME ./backend/k8s/$sdenv.env
set_keyvalue TAG $image_version ./backend/k8s/$sdenv.env
set_keyvalue HUB $DOCKERHUB ./backend/k8s/$sdenv.env
set_keyvalue NAMESPACE $GLOBAL_NAMESPACE ./backend/k8s/$sdenv.env
set_keyvalue RUNPORT_POSTGRE $POSTGRE_SQL_RUNPORT ./backend/k8s/$sdenv.env
set -a
source ./backend/k8s/$sdenv.env || exit 1
set +a
# envsubst < ./backend/k8s/postgres.template.yaml | kubectl apply -f -
envsubst >./backend/k8s/postgres.yaml <./backend/k8s/postgres.template.yaml
)
}


function frontend_18 {
##########  RUN COMMAND  ##########
# frontend_18
###################################
(
node_version=18
working_directory=frontend
dependency_list=(
  ./$working_directory/src/$node_version/etc\
  ./$working_directory/src/$node_version/src\
  ./$working_directory/src/$node_version/Dockerfile\
  ./$working_directory/src/$node_version/$sdenv.env\
)
for dep in ${dependency_list[@]}; do
  expanded_path=$(eval echo "$dep")
  if [ -e "$expanded_path" ]; then
    echo "[✔] Found: $expanded_path"
  else
    echo "[✘] Missing: $expanded_path"
    exit 1
  fi
done

pushd ./$working_directory
node_refresh $node_version

(
if [ -d $FRONTEND_APPNAME ];then
warn $(yellow ${FUNCNAME[0]}: $FRONTEND_APPNAME found, not craeting a new react app)
return 1
fi
echo && blue "------------------ NEW REACT APP ------------------"
npx -y create-react-app $FRONTEND_APPNAME
)
cp ./src/$node_version/Dockerfile .
cd $FRONTEND_APPNAME
cp ../src/$node_version/etc/* .
cp -r ../src/$node_version/src/* ./src
cp ../src/$node_version/$sdenv.env ./.env || exit 1
npm install react@18.2.0 react-dom@18.2.0 react-router-dom@6 axios --legacy-peer-deps
npm install
popd
)
}

function frontend_upgrade_20 {
##########  RUN COMMAND  ##########
# frontend_upgrade_20
###################################
(
node_version=20
old_version=18
working_directory=frontend
dependency_list=(
  ./$working_directory/src/$node_version/etc\
  ./$working_directory/src/$node_version/src\
  ./$working_directory/src/$node_version/Dockerfile\
  ./$working_directory/src/$node_version/$sdenv.env\
)
for dep in ${dependency_list[@]}; do
  expanded_path=$(eval echo "$dep")
  if [ -e "$expanded_path" ]; then
    echo "[✔] Found: $expanded_path"
  else
    echo "[✘] Missing: $expanded_path"
    exit 1
  fi
done

pushd ./$working_directory
node_refresh $node_version

### RENAME AND PRESERVE LEGACY
for f in $(/bin/ls ./src/$old_version/src); do echo cp "./src/$old_version/src/$f" "./src/$node_version/legacy/$old_version/${f%.js}.jsx";done
for f in $(/bin/ls ./src/$old_version/src); do cp "./src/$old_version/src/$f" "./src/$node_version/legacy/$old_version/${f%.js}.jsx";done

(
if [ -d $FRONTEND_APPNAME ];then
rm -rf $FRONTEND_APPNAME/node_modules
rm $FRONTEND_APPNAME/package-lock.json
npm uninstall react-scripts
npm install

find ./$FRONTEND_APPNAME/src -type f -name "*.js" -exec bash -c 'for f; do echo mv "$f" "${f%.js}.jsx"; done' _ {} +
find ./$FRONTEND_APPNAME/src -type f -name "*.js" -exec bash -c 'for f; do mv "$f" "${f%.js}.jsx"; done' _ {} +

SEARCH='process.env.REACT_APP_API_URL'
REPLACE='import.meta.env.VITE_API_URL'
find ./$FRONTEND_APPNAME/src -type f \( -name "*.jsx" \) -exec sed -i "s|$SEARCH|$REPLACE|g" {} +

frontend_update

fi
)
)
}

function node_refresh {
# (
node_version=${1:-20}
banner3 refreshing node, node_version $node_version
export NVM_HOME=$(pwd)/.nvm
export NVM_DIR=$(pwd)/.nvm
echo NVM_HOME is $NVM_HOME

if [ ! -d $NVM_DIR ];then
    install_nvm;
fi
if [ -d $NVM_DIR ];then
    installnode;
    nodever $node_version;
fi
# )
}

function frontend_update {
##########  RUN COMMAND  ##########
# frontend_update
###################################
(
node_version=${1:-20}
working_directory=frontend
banner2 working_directory $working_directory, node_version $node_version
dependency_list=(
  ./$working_directory/src/$node_version/etc\
  ./$working_directory/src/$node_version/src\
  ./$working_directory/src/$node_version/Dockerfile\
  ./$working_directory/src/$node_version/$sdenv.env\
)
for dep in ${dependency_list[@]}; do
  expanded_path=$(eval echo "$dep")
  if [ -e "$expanded_path" ]; then
    echo "[✔] Found: $expanded_path"
  else
    echo "[✘] Missing: $expanded_path"
    exit 1
  fi
done

pushd ./$working_directory
node_refresh $node_version

cp ./src/$node_version/* .
cd $FRONTEND_APPNAME
rm -rf ./node_modules ./package-lock.json
cp ../src/$node_version/etc/* .
cp -r ../src/$node_version/src/* ./src
cp ../src/$node_version/$sdenv.env ./.env || exit 1
npm install
npm run build

)
}

function default_build_image_frontend {
##########  RUN COMMAND  ##########
# build_build_image_frontend
###################################
build_image_frontend
}
function build_image_frontend {
##########  RUN COMMAND  ##########
# build_image_frontend $image_version
###################################
(
image_version=$1
set -u
if [ -z "$image_version" ];then image_version=latest;fi
if [ ! -d ./frontend ];then echo must be at project root: $(pwd) && return 1;fi
NOCACHE=
if [[ $sdenv = 'prod' ]];then NOCACHE=--no-cache;fi
appname=$FRONTEND_APPNAME
echo -e \\nBuilding $appname:$image_version

set_registry
# formatrun <<'EOF'
docker build $NOCACHE\
  -t $appname:$image_version\
  frontend\
  || return 1
# EOF

# formatrun <<'EOF'
docker tag $appname:$image_version $DOCKERHUB/$appname:$image_version
docker push $DOCKERHUB/$appname:$image_version

# docker tag $appname $DOCKERHUB/$appname
# docker push $DOCKERHUB/$appname
# EOF

echo Pushed $DOCKERHUB/$appname:$image_version
)
}


function default_k8s_webservice {
##########  RUN COMMAND  ##########
# default_k8s_webservice
###################################
GLOBAL_NAMESPACE=default k8s_webservice
}
function k8s_webservice {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace k8s_webservice
###################################
(
set -u
# formatrun <<'EOF'
# kubectl apply -f ./frontend/k8s/web.yaml\
#   && kubectl wait --namespace $GLOBAL_NAMESPACE --for=condition=Ready pod -l app=web --timeout=60s\
#   && kubectl port-forward --namespace $GLOBAL_NAMESPACE svc/web-service 8081:80

# EOF
logit "kubectl apply -f ./frontend/k8s/web.yaml\
  && kubectl wait --namespace $GLOBAL_NAMESPACE --for=condition=Ready pod -l app=web --timeout=60s\
  && kubectl port-forward --namespace $GLOBAL_NAMESPACE svc/web-service 8081:80
"

runit "kubectl apply -f ./frontend/k8s/web.yaml\
  && kubectl wait --namespace $GLOBAL_NAMESPACE --for=condition=Ready pod -l app=web --timeout=60s
"

)
}


function k8s_webservice_update {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace k8s_webservice_update
###################################
(
export $(grep -v '^#' ./frontend/k8s/$sdenv.env | xargs)
set -u
configure_webservice $TAG
# formatrun <<'EOF'
# kubectl set image deployment/web web=$HUB/$REPOSITORY:$TAG\
#   && kubectl rollout status deployment/web

# EOF
banner1 logit
logit "kubectl set image deployment/web web=$HUB/$REPOSITORY:$TAG\
  && kubectl rollout status deployment/web
"

)
}


function middleware {
##########  RUN COMMAND  ##########
# middleware
###################################
(
node_version=20
working_directory=middleware
banner2 working_directory $working_directory, node_version $node_version
cert_directory=certs && mkdir -p ./$cert_directory
(
  shopt -s nullglob dotglob
  files=($cert_directory/*.pem)
  [ ${#files[@]} -eq 0 ]\
    && generate_selfsignedcert $cert_directory\
    || warn $cert_directory not generating certs
)

mkdir -p ./$working_directory/src/$node_version/etc/certs
cp ./certs/*.pem ./$working_directory/src/$node_version/etc/certs/

set_keyvalue KEY_NAME certs/key.pem ./middleware/k8s/$sdenv.env
set_keyvalue CERT_NAME certs/cert.pem ./middleware/k8s/$sdenv.env
dependency_list=(
  ./$working_directory/src/$node_version/etc\
  ./$working_directory/src/$node_version/src\
  ./$working_directory/src/$node_version/etc/certs/cert.pem\
  ./$working_directory/src/$node_version/etc/certs/key.pem\
)
for dep in ${dependency_list[@]}; do
  expanded_path=$(eval echo "$dep")
  if [ -e "$expanded_path" ]; then
    echo "[✔] Found: $expanded_path"
  else
    echo "[✘] Missing: $expanded_path"
    exit 1
  fi
done

pushd ./$working_directory
node_refresh $node_version
mkdir -p $MIDDLEWARE_APPNAME
cp ./src/$node_version/* .
cd $MIDDLEWARE_APPNAME
cp -r ../src/$node_version/etc/* .
cp -r ../src/$node_version/src/* .
npm install
popd
)
}

function default_build_image_middleware {
##########  RUN COMMAND  ##########
# build_image_middleware
###################################
build_image_middleware
}
function build_image_middleware {
##########  RUN COMMAND  ##########
# build_image_middleware $image_version
###################################
(
image_version=$1
set -u
if [ -z "$image_version" ];then image_version=latest;fi
if [ ! -d ./middleware ];then echo must be at project root && return 1;fi
NOCACHE=
if [[ $sdenv = 'prod' ]];then NOCACHE=--no-cache;fi
appname=$MIDDLEWARE_APPNAME
echo -e \\nBuilding $appname:$image_version

set_registry
# formatrun <<'EOF'
docker build $NOCACHE\
  -t $appname:$image_version\
  --build-arg EXPOSE_PORT_HTTP=$API_HTTP_RUNPORT_K8S_MIDDLEWARE\
  --build-arg EXPOSE_PORT_HTTPS=$API_HTTPS_RUNPORT_K8S_MIDDLEWARE\
  middleware\
  || return 1
# EOF

# formatrun <<'EOF'
docker tag $appname:$image_version $DOCKERHUB/$appname:$image_version
docker push $DOCKERHUB/$appname:$image_version

# docker tag $appname $DOCKERHUB/$appname
# docker push $DOCKERHUB/$appname
# EOF

echo Pushed $DOCKERHUB/$appname:$image_version
)
}

function default_k8s_api {
##########  RUN COMMAND  ##########
# default_k8s_api
###################################
GLOBAL_NAMESPACE=default k8s_api
}
function k8s_api {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace k8s_api
###################################
(
# set -u
# formatrun <<'EOF'
# kubectl apply -f ./middleware/k8s/api.yaml\
#   && kubectl wait --namespace $GLOBAL_NAMESPACE --for=condition=Ready pod -l app=api --timeout=60s\
#   && kubectl port-forward --namespace $GLOBAL_NAMESPACE svc/$MIDDLEWARE_API_SERVICE_NAME $API_HTTP_RUNPORT_K8S_MIDDLEWARE:$API_HTTP_RUNPORT_K8S_MIDDLEWARE

# EOF
set -a
source ./middleware/k8s/$sdenv.env || exit 1
set +a
runit "kubectl create secret generic $MIDDLEWARE_TLS_SECRET\
    --from-file=cert.pem=certs/cert.pem\
    --from-file=key.pem=certs/key.pem
"
runit "kubectl apply -f ./middleware/k8s/api.yaml\
  && kubectl wait --namespace $GLOBAL_NAMESPACE\
    --for=condition=Ready pod -l app=api --timeout=60s
"

logit "kubectl port-forward --namespace $GLOBAL_NAMESPACE\
    svc/$MIDDLEWARE_API_SERVICE_NAME $API_HTTP_RUNPORT_K8S_MIDDLEWARE:$API_HTTP_RUNPORT_K8S_MIDDLEWARE
"

# kubectl rollout restart deployment api
)
}


function validate_api {
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
curl -s https://$API_HOST:$API_HTTPS_RUNPORT_K8S_MIDDLEWARE/products/1|jq

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


function validate_api_k8s_https {
(
set -a
source ./middleware/k8s/$sdenv.env || exit 1
source ./frontend/$sdenv.env || exit 1
set +a

runit_nolog "weblist=\$(kubectl get pods --no-headers -o custom-columns=:metadata.name|/usr/bin/grep -E ^web)
for pod in \${weblist[@]};do
echo \$CMD && eval \$CMD
CMD=\"kubectl exec -it \$pod -- curl -ks https://$SERVICE:$RUNPORT_HTTPS_FRONTEND_LISTENER/health/db|jq\"
echo \$CMD && eval \$CMD
CMD=\"kubectl exec -it \$pod -- curl -ks https://$SERVICE:$RUNPORT_HTTPS_FRONTEND_LISTENER/products|jq\"
echo \$CMD && eval \$CMD
CMD=\"kubectl exec -it \$pod -- curl -ks https://$SERVICE:$RUNPORT_HTTPS_FRONTEND_LISTENER/products/1|jq\"
echo \$CMD && eval \$CMD
done"
)

}


function backend {
(
set -u
)
}

function build_image_backend {
(
image_version=$1
set -u
if [ -z "$image_version" ];then image_version=latest;fi
if [ ! -d ./backend ];then echo must be at project root && return 1;fi
NOCACHE=
if [[ $sdenv = 'prod' ]];then NOCACHE=--no-cache;fi
appname=$BACKEND_APPNAME
echo -e \\nBuilding $appname:$image_version

set_registry
# formatrun <<'EOF'
docker build $NOCACHE\
  -t $appname:$image_version\
  backend\
  || return 1
# EOF

# formatrun <<'EOF'
docker tag $appname:$image_version $DOCKERHUB/$appname:$image_version
docker push $DOCKERHUB/$appname:$image_version

# docker tag $appname $DOCKERHUB/$appname
# docker push $DOCKERHUB/$appname
# EOF

echo Pushed $DOCKERHUB/$appname:$image_version
)
}

function default_k8s_postgres {
##########  RUN COMMAND  ##########
# default_k8s_postgres
###################################
GLOBAL_NAMESPACE=default k8s_postgres
}
function k8s_postgres {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace k8s_postgres
###################################
(
set -u

# formatrun <<'EOF'
# kubectl apply -f ./backend/k8s/postgres.yaml\
#   && kubectl wait --namespace $GLOBAL_NAMESPACE --for=condition=Ready pod -l app=postgres --timeout=60s

# EOF
logit "kubectl apply -f ./backend/k8s/postgres.yaml\
  && kubectl wait --namespace $GLOBAL_NAMESPACE --for=condition=Ready pod -l app=postgres --timeout=60s
"

runit "kubectl apply -f ./backend/k8s/postgres.yaml\
  && kubectl wait --namespace $GLOBAL_NAMESPACE --for=condition=Ready pod -l app=postgres --timeout=60s
"

# kubectl rollout restart deployment postgres
)
}


function pgadmin() {
(
set -u
image_version=$1
set_keyvalue NAMESPACE $GLOBAL_NAMESPACE ./opt/pgadmin/k8s/$sdenv.env
set_keyvalue TAG $image_version ./opt/pgadmin/k8s/$sdenv.env
set -a
source ./opt/pgadmin/k8s/$sdenv.env || exit 1
set +a
# envsubst < ./backend/k8s/postgres.template.yaml | kubectl apply -f -
envsubst >./opt/pgadmin/k8s/pgadmin.yaml <./opt/pgadmin/k8s/pgadmin.template.yaml
# kubectl rollout restart deployment api

# kubectl apply -f ./opt/pgadmin/k8s/pgamin.yaml -n $GLOBAL_NAMESPACE\
#   && kubectl port-forward svc/pgadmin 5050:80 -n $GLOBAL_NAMESPACE

echo -e "
kubectl apply -f ./opt/pgadmin/k8s/pgamin.yaml -n $GLOBAL_NAMESPACE\\\\\n\
  && kubectl wait --namespace $GLOBAL_NAMESPACE --for=condition=Ready pod -l app=pgadmin --timeout=30s\\\\\n\
  && kubectl port-forward svc/pgadmin 8080:80 -n $GLOBAL_NAMESPACE"
)
}

function install_nvm() {
  NVM_DIR="${NVM_DIR:-$(pwd)/.nvm}"
  echo && blue "------------------ INSTALL NVM ------------------" && echo
  git clone https://github.com/nvm-sh/nvm.git $NVM_DIR
  echo installing nvm @ $NVM_DIR
  # echo $([ -s $NVM_DIR/nvm.sh ] && . $NVM_DIR/nvm.sh && [ -s $NVM_DIR/bash_completion ] && . $NVM_DIR/bash_completion && nvm install --lts)
  echo $([ -s $NVM_DIR/nvm.sh ] && . $NVM_DIR/nvm.sh && [ -s $NVM_DIR/bash_completion ] && . $NVM_DIR/bash_completion && nvm install-latest-npm)
}

function installnode() {
  if [ ! -d $NVM_DIR ];then echo no NVM_DIR: $NVM_DIR && return 1;fi
  echo && blue "------------------ NODE VIA NVM ------------------" && echo
  cyan "Updating nvm:" && echo $(pushd $NVM_DIR && git pull && popd || popd)
  if  ! command -v nvm >/dev/null; then
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
  fi
  nodever
}

function nodever() {
  if [ ! -z "$1" ]; then
    nvm install ${1} >/dev/null 2>&1 && nvm use ${_} > /dev/null 2>&1\
      && nvm alias default ${_} > /dev/null 2>&1; nodever; else
    yellow "INFORMATIONAL: Use nodever to install or switch node versions:" && echo -e "\tusage: nodever [ver]"
    blue "node: $(node -v)"
    blue "npm: $(npm -v)"
    blue "nvm: $(nvm -v)"
  fi
}

function getyarn() {
  echo && blue "------------------ YARN - NEEDS NVM ------------------" && echo
  if ! command -v yarn >/dev/null 2>&1; then grey "Getting yarn: " && npm install --global yarn >/dev/null; fi
}

function green { println '\e[32m%s\e[0m' "$*"; }
function yellow { println '\e[33m%s\e[0m' "$*"; }
function blue { println '\e[34m%s\e[0m' "$*"; }                                                                                    
function red { println '\e[31m%s\e[0m' "$*"; }
function banner1 { echo; echo "$(tput setaf 0;tput setab 6)$(date "+%Y-%m-%d %H:%M:%S") BANNER ${FUNCNAME[1]}::${*}$(tput sgr 0)"; }
function banner2 { echo; echo "$(tput setaf 0;tput setab 6)$(date "+%Y-%m-%d %H:%M:%S") BANNER ${FUNCNAME[2]}::${FUNCNAME[1]} ${*}$(tput sgr 0)"; }
function banner3 { echo; echo "$(tput setaf 0;tput setab 6)$(date "+%Y-%m-%d %H:%M:%S") BANNER ${FUNCNAME[3]}::${FUNCNAME[2]}::${FUNCNAME[1]} ${*}$(tput sgr 0)"; }
function info { echo; echo "$(tput setaf 0;tput setab 7)$(date "+%Y-%m-%d %H:%M:%S") INFO:$(tput sgr 0) ${*}"; }
function warn { echo; echo "$(tput setaf 1;tput setab 3)$(date "+%Y-%m-%d %H:%M:%S") WARN:$(tput sgr 0) ${*}"; }
function pass { echo; echo "$(tput setaf 0;tput setab 2)$(date "+%Y-%m-%d %H:%M:%S") PASS:$(tput sgr 0) ${*}"; }
function fail { echo; echo "$(tput setaf 8;tput setab 1)$(date "+%Y-%m-%d %H:%M:%S") FAIL:$(tput sgr 0) ${*}"; }
function abort_hard  { echo; red "**** ABORT($1): $(date "+%Y-%m-%d %H:%M:%S") **** " && echo -e "\t${@:2}\n" && read -p "press CTRL+C or die!" ; exit 1; }
function abort       { echo; red "**** ABORT($1): $(date "+%Y-%m-%d %H:%M:%S") ****" && echo -e "\t${@:2}\n"; }
function yesno { read -p "$1 yes (default) or no: " && if [[ ${REPLY} = n ]] || [[ ${REPLY} = no ]]; then return 1; fi; return 0; }

__BOOTSTRAP_DEBUG__() {
  [ "$1" = "on" ] || [ "$1" = "true" ] && echo "DEBUGGING ON ${FUNCNAME[1]}"
  if is_set_u_enabled; then
    echo "set -u is ON"
  else
    echo "set -u is OFF"
  fi
}

is_set_u_enabled() {
  ( unset __test__; : "$__test__" ) 2>/dev/null
  [ $? -ne 0 ]
}

function formatrun {
(
raw_cmd=$(cat)
# CMD=$(echo "$raw_cmd" | sed -E ':a;N;$!ba;s/\\\s*\n/ /g')
# eval "$CMD"

### UNCOMMENT WHEN READY
# runit "$(echo "$raw_cmd" | sed -E ':a;N;$!ba;s/\\\s*\n/ /g')"
echo -e "$raw_cmd"
)
}

function runit_nolog {
banner2
eval "$*"
}

function runit {
banner2
echo -e "$*"
eval "$*"
}

function logit {
banner3
echo -e "$*"
}

function logone {
echo -e "$*"
}

function generate_selfsignedcert {
(
set -u
blue "------------------ GENERATING SELF-SIGNED CERTIFICATE ------------------"
dir=$1
canonical_name=localhost
CMD="openssl req -x509 -newkey rsa:4096 -nodes -keyout ./$dir/key.pem \
    -out ./$dir/cert.pem -days 365 \
    -subj \"/CN=$canonical_name\""
echo $CMD
mkdir -p ./$dir\
  && eval $CMD
ls $dir
)
}
