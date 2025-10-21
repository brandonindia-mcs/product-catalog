#!/bin/bash

##################  GLOBAL VARS  ##################
GLOBAL_VERSION=$(date +%Y%m%d%H%M%s)
alias stamp="echo \$(date +%Y%m%d%H%M%S)"

export BACKEND_APPNAME=product-catalog-backend
export BACKEND_DATABASE_SERVICE_NAME=pg-service
export BACKEND_SELECTOR_NAME=postgres
export BACKEND_DEPLOYMENT_NAME=postgres
export BACKEND_PODTEMPLATE_NAME=postgres
export POSTGRES_USER=catalog
export POSTGRES_DB=catalog
export POSTGRES_PASSWORD=catalog
export POSTGRE_SQL_RUNPORT=5432

export FRONTEND_APPNAME=product-catalog-frontend
export FRONTEND_WEBSERVICE_NAME=web-service
export FRONTEND_SELECTOR=web
export FRONTEND_DEPLOYMENT_NAME=web
export FRONTEND_PODTEMPLATE_NAME=web
export FRONTEND_CONTAINER=web
export WEB_HTTP_RUNPORT_PUBLIC_FRONTEND=80
export WEB_HTTPS_RUNPORT_PUBLIC_FRONTEND=443
export FRONTEND_WEBSERVICE_INGRESS_HOSTNAME=product-catalog.progress.me
export WEBSERVICE_INGRESS_PORT_K8S_FRONTEND=$WEB_HTTP_RUNPORT_PUBLIC_FRONTEND
# export VITE_API_URL=https://localhost:8443

export MIDDLEWARE_APPNAME=product-catalog-middleware
export MIDDLEWARE_API_SERVICE_NAME=api-service
export MIDDLEWARE_API_INGRESS_HOSTNAME=product-catalog.progress.me
export MIDDLEWARE_PRODUCTS_INGRESS_HOSTNAME=api-ingress.progress.me
export MIDDLEWARE_API_SERVICE_LOCALCLUSTER_NAME=https://api-service.default.svc.cluster.local
export MIDDLEWARE_SELECTOR=api
export MIDDLEWARE_DEPLOYMENT_NAME=api
export MIDDLEWARE_PODTEMPLATE_NAME=api
export MIDDLEWARE_CONTAINER=api
export MIDDLEWARE_TLS_MOUNT=certs
export MIDDLEWARE_TLS_MOUNT_PATH=/$MIDDLEWARE_TLS_MOUNT
export MIDDLEWARE_TLS_CERT_VOLUME=tls-certs
export MIDDLEWARE_LOGLEVEL=debug
export CORS_ORIGIN=https://product-catalog.progress.me
export API_HTTP_PORT_K8S_MIDDLEWARE=80
export API_HTTP_RUNPORT_K8S_MIDDLEWARE=3000
export API_HTTP_NODEPORT_K8S_MIDDLEWARE=32000
export API_HTTPS_SSLPORT_K8S_MIDDLEWARE=443
export API_HTTPS_RUNPORT_K8S_MIDDLEWARE=2443
export API_HTTPS_NODEPORT_K8S_MIDDLEWARE=32443
export API_INGRESS_PORT_K8S_MIDDLEWARE=$API_HTTPS_SSLPORT_K8S_MIDDLEWARE
export CERTIFICATE_BUILD_DIRECTORY=cert

export NODE_ENV=development
export PG_HOST=$BACKEND_DATABASE_SERVICE_NAME
export PG_DATABASE=$POSTGRES_DB
export PG_USER=$POSTGRES_USER
export PG_PASSWORD=$POSTGRES_PASSWORD
export PG_PORT=$POSTGRE_SQL_RUNPORT

STAMP=`stamp`
# export MIDDLEWARE_TLS_SECRET=middleware-tls-$STAMP
# export FRONTEND_TLS_SECRET=frontend-tls-$STAMP
export MIDDLEWARE_SECRET=middleware-secret-static
export MIDDLEWARE_TLS_SECRET=$MIDDLEWARE_SECRET-tls
export FRONTEND_TLS_SECRET=frontend-secret-static-tls

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
(namespace=${1:-default}; while true; do echo && blue $namespace $(date) && kubectl get deploy,pod,svc,ingress,rs --namespace $namespace -o wide && sleep 5;done)
}
function print_k8s_env {
for dir in frontend backend middleware;do cat $dir/k8s/$sdenv.env;done
}
function clean_productcatalog {
for dir in frontend/.nvm middleware/.nvm frontend/$FRONTEND_APPNAME middleware/$MIDDLEWARE_APPNAME;do echo cleaning $dir && rm -rf $dir;done
}

function registry_local {
echo ${FUNCNAME[1]}::${FUNCNAME[0]} $(docker run -d -p $HUBPORT:5000 --name registry_local registry:2 2>/dev/null || docker start registry_local >/dev/null && echo -n registry@$DOCKERHUB:$HUBPORT)
}

function registry_cluster {
(
cluster=${1:-catalog-cluster-control-plane}
control_plane_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $cluster)
echo ${FUNCNAME[1]}::${FUNCNAME[0]} "$cluster @ control_plane_ip"
registry_node_port=30500
registry_url=registry.local
# echo 'added "insecure-registries": ["$registry_url:$registry_node_port"] to docker config on host'
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: registry
spec:
  selector:
    app: registry
  ports:
    - port: 5000
      targetPort: 5000
      nodePort: $registry_node_port
  type: NodePort
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: registry
spec:
  replicas: 1
  selector:
    matchLabels:
      app: registry
  template:
    metadata:
      labels:
        app: registry
    spec:
      containers:
        - name: registry
          image: registry:2
          ports:
            - containerPort: 5000
EOF
)
kubectl get svc registry
}

function set_registry {
(
set -u
set_keyvalue HUB $DOCKERHUB:$HUBPORT ./frontend/k8s/$sdenv.env
set_keyvalue HUB $DOCKERHUB:$HUBPORT ./middleware/k8s/$sdenv.env
set_keyvalue HUB $DOCKERHUB:$HUBPORT ./backend/k8s/$sdenv.env
registry_local
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
FRONTEND_WEBSERVICE_REPLICAS=2
>./frontend/k8s/$sdenv.env && warn ./frontend/k8s/$sdenv.env reset
set_keyvalue REPOSITORY $FRONTEND_APPNAME ./frontend/k8s/$sdenv.env
set_keyvalue RUNPORT_HTTP $WEB_HTTP_RUNPORT_PUBLIC_FRONTEND ./frontend/k8s/$sdenv.env
set_keyvalue RUNPORT_HTTPS $WEB_HTTPS_RUNPORT_PUBLIC_FRONTEND ./frontend/k8s/$sdenv.env
set_keyvalue TAG $image_version ./frontend/k8s/$sdenv.env
# set_keyvalue HUB $DOCKERHUB ./frontend/k8s/$sdenv.env
set_keyvalue HUB $DOCKERHUB:$HUBPORT ./frontend/k8s/$sdenv.env
set_keyvalue NAMESPACE $GLOBAL_NAMESPACE ./frontend/k8s/$sdenv.env
set_keyvalue REPLICAS $FRONTEND_WEBSERVICE_REPLICAS ./frontend/k8s/$sdenv.env
set_keyvalue INGRESS_PORT $WEBSERVICE_INGRESS_PORT_K8S_FRONTEND ./frontend/k8s/$sdenv.env
set_keyvalue SERVICE $FRONTEND_WEBSERVICE_NAME ./frontend/k8s/$sdenv.env
set_keyvalue INGRESS $FRONTEND_WEBSERVICE_INGRESS_HOSTNAME ./frontend/k8s/$sdenv.env
set_keyvalue SELECTOR $FRONTEND_SELECTOR ./frontend/k8s/$sdenv.env
set_keyvalue DEPLOYMENT $FRONTEND_DEPLOYMENT_NAME ./frontend/k8s/$sdenv.env
set_keyvalue PODTEMPLATE $FRONTEND_PODTEMPLATE_NAME ./frontend/k8s/$sdenv.env
set_keyvalue CONTAINER $FRONTEND_CONTAINER ./frontend/k8s/$sdenv.env
set_keyvalue TLS_SECRET $FRONTEND_TLS_SECRET ./frontend/k8s/$sdenv.env
set -a
source ./frontend/k8s/$sdenv.env || exit 1
set +a
# envsubst < ./frontend/k8s/web.template.yaml | kubectl apply -f -
envsubst >./frontend/k8s/web.yaml <./frontend/k8s/web.template.yaml
sed -i '/^[[:space:]]*#/d' ./frontend/k8s/web.yaml
)
}

function configure_api {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace configure_api $image_version
###################################
(
set -u
image_version=$1
MIDDLEWARE_API_REPLICAS=2
>./middleware/k8s/$sdenv.env && warn ./middleware/k8s/$sdenv.env reset
set_keyvalue REPOSITORY $MIDDLEWARE_APPNAME ./middleware/k8s/$sdenv.env
set_keyvalue TAG $image_version ./middleware/k8s/$sdenv.env
# set_keyvalue HUB $DOCKERHUB ./middleware/k8s/$sdenv.env
set_keyvalue HUB $DOCKERHUB:$HUBPORT ./middleware/k8s/$sdenv.env
set_keyvalue NAMESPACE $GLOBAL_NAMESPACE ./middleware/k8s/$sdenv.env
set_keyvalue REPLICAS $MIDDLEWARE_API_REPLICAS ./middleware/k8s/$sdenv.env
set_keyvalue HTTP_PORT $API_HTTP_PORT_K8S_MIDDLEWARE ./middleware/k8s/$sdenv.env
set_keyvalue HTTP_TARGET_PORT $API_HTTP_RUNPORT_K8S_MIDDLEWARE ./middleware/k8s/$sdenv.env
set_keyvalue HTTP_NODE_PORT $API_HTTP_NODEPORT_K8S_MIDDLEWARE ./middleware/k8s/$sdenv.env
set_keyvalue SSL_PORT $API_HTTPS_SSLPORT_K8S_MIDDLEWARE ./middleware/k8s/$sdenv.env
set_keyvalue SSL_TARGET_PORT $API_HTTPS_RUNPORT_K8S_MIDDLEWARE ./middleware/k8s/$sdenv.env
set_keyvalue SSL_NODE_PORT $API_HTTPS_NODEPORT_K8S_MIDDLEWARE ./middleware/k8s/$sdenv.env
set_keyvalue INGRESS_PORT $API_INGRESS_PORT_K8S_MIDDLEWARE ./middleware/k8s/$sdenv.env
set_keyvalue API_LISTEN_PORT_HTTP $API_HTTP_RUNPORT_K8S_MIDDLEWARE ./middleware/k8s/$sdenv.env
set_keyvalue API_LISTEN_PORT_HTTPS $API_HTTPS_RUNPORT_K8S_MIDDLEWARE ./middleware/k8s/$sdenv.env
set_keyvalue SERVICE $MIDDLEWARE_API_SERVICE_NAME ./middleware/k8s/$sdenv.env
set_keyvalue INGRESS_API $MIDDLEWARE_API_INGRESS_HOSTNAME ./middleware/k8s/$sdenv.env
set_keyvalue INGRESS_PRODUCTS $MIDDLEWARE_PRODUCTS_INGRESS_HOSTNAME ./middleware/k8s/$sdenv.env
set_keyvalue SELECTOR $MIDDLEWARE_SELECTOR ./middleware/k8s/$sdenv.env
set_keyvalue DEPLOYMENT $MIDDLEWARE_DEPLOYMENT_NAME ./middleware/k8s/$sdenv.env
set_keyvalue PODTEMPLATE $MIDDLEWARE_PODTEMPLATE_NAME ./middleware/k8s/$sdenv.env
set_keyvalue CONTAINER $MIDDLEWARE_CONTAINER ./middleware/k8s/$sdenv.env
set_keyvalue LOGLEVEL $MIDDLEWARE_LOGLEVEL ./middleware/k8s/$sdenv.env

set_keyvalue CORS_ORIGIN $CORS_ORIGIN ./middleware/k8s/$sdenv.env
set_keyvalue TLS_MOUNT_PATH $MIDDLEWARE_TLS_MOUNT_PATH ./middleware/k8s/$sdenv.env
set_keyvalue TLS_CERT_VOLUME $MIDDLEWARE_TLS_CERT_VOLUME ./middleware/k8s/$sdenv.env
set_keyvalue SECRET $MIDDLEWARE_SECRET ./middleware/k8s/$sdenv.env
set_keyvalue TLS_SECRET $MIDDLEWARE_TLS_SECRET ./middleware/k8s/$sdenv.env
set_keyvalue CERTIFICATE cert.pem ./middleware/k8s/$sdenv.env
set_keyvalue CERTIFICATE_KEY key.pem ./middleware/k8s/$sdenv.env

set_keyvalue NODE_ENV development ./middleware/k8s/$sdenv.env
set_keyvalue PG_HOST $PG_HOST ./middleware/k8s/$sdenv.env
set_keyvalue PG_DATABASE $PG_DATABASE ./middleware/k8s/$sdenv.env
set_keyvalue PG_USER $PG_USER ./middleware/k8s/$sdenv.env
set_keyvalue PG_PASSWORD $PG_PASSWORD ./middleware/k8s/$sdenv.env
set_keyvalue PG_PORT $PG_PORT ./middleware/k8s/$sdenv.env

set -a
source ./middleware/k8s/$sdenv.env || exit 1
set +a
# envsubst < ./middleware/k8s/api.template.yaml | kubectl apply -f -
envsubst >./middleware/k8s/api.yaml <./middleware/k8s/api.template.yaml
sed -i '/^[[:space:]]*#/d' ./middleware/k8s/api.yaml
)
}

function configure_postgres {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace configure_postgres $image_version
###################################
(
set -u
image_version=$1
>./backend/k8s/$sdenv.env && warn ./backend/k8s/$sdenv.env reset
set_keyvalue REPOSITORY $BACKEND_APPNAME ./backend/k8s/$sdenv.env
set_keyvalue TAG $image_version ./backend/k8s/$sdenv.env
# set_keyvalue HUB $DOCKERHUB ./backend/k8s/$sdenv.env
set_keyvalue HUB $DOCKERHUB:$HUBPORT ./backend/k8s/$sdenv.env
set_keyvalue NAMESPACE $GLOBAL_NAMESPACE ./backend/k8s/$sdenv.env
set_keyvalue RUNPORT_POSTGRE $POSTGRE_SQL_RUNPORT ./backend/k8s/$sdenv.env

set_keyvalue SERVICE $BACKEND_DATABASE_SERVICE_NAME ./backend/k8s/$sdenv.env
set_keyvalue POSTGRES_DB $POSTGRES_DB ./backend/k8s/$sdenv.env
set_keyvalue POSTGRES_USER $POSTGRES_USER ./backend/k8s/$sdenv.env
set_keyvalue POSTGRES_PASSWORD $POSTGRES_PASSWORD ./backend/k8s/$sdenv.env
set -a
source ./backend/k8s/$sdenv.env || exit 1
set +a
# envsubst < ./backend/k8s/postgres.template.yaml | kubectl apply -f -
envsubst >./backend/k8s/postgres.yaml <./backend/k8s/postgres.template.yaml
sed -i '/^[[:space:]]*#/d' ./backend/k8s/postgres.yaml
)
}


function frontend_18 {
##########  RUN COMMAND  ##########
# frontend_18
###################################
# fail ${FUNCNAME[0]} disabled; return 1
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
# warn node refresh disabled; return 1
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

node_version=${1:-20}
cp ./src/$node_version/* .
mkdir -p $FRONTEND_APPNAME && cd $_
rm -rf ./node_modules ./package-lock.json
cp ../src/$node_version/etc/* ../src/$node_version/etc/.* .
cp -r ../src/$node_version/src/. ./src/
cp -r ../src/$node_version/public/. ./public/
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
runit "docker build $NOCACHE\
  -t $appname:$image_version\
  frontend"\
  || return 1
# runit "docker image ls $appname"
runit "docker tag $appname:$image_version $DOCKERHUB:$HUBPORT/$appname:$image_version" || return 1
runit "docker push $DOCKERHUB:$HUBPORT/$appname:$image_version" || return 1

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
set -e
set -a
source ./frontend/k8s/$sdenv.env || exit 1
set +a
runit "kubectl apply -f ./frontend/k8s/web.yaml\
  && kubectl wait --namespace $GLOBAL_NAMESPACE --for=condition=Ready pod -l app=$FRONTEND_SELECTOR --timeout=60s
"

)
}


function k8s_webservice_update {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace k8s_webservice_update
###################################
(
export $(grep -v '^#' ./frontend/k8s/$sdenv.env | xargs)
set -ue
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
middleware_certificates

set_keyvalue KEY_NAME certs/key.pem ./middleware/k8s/$sdenv.env
set_keyvalue CERT_NAME certs/cert.pem ./middleware/k8s/$sdenv.env
set_keyvalue CERTIFICATE_KEY key.pem ./middleware/k8s/$sdenv.env
set_keyvalue CERTIFICATE cert.pem ./middleware/k8s/$sdenv.env
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
cp ./src/$node_version/* .
mkdir -p $MIDDLEWARE_APPNAME && cd $_
cp -r ../src/$node_version/etc/* .
cp -r ../src/$node_version/src/* .
npm install
popd
)
}


function middleware_certificates {
##########  RUN COMMAND  ##########
# middleware_certificates
###################################
(
  set -u
  echo looking for certificates: ./$CERTIFICATE_BUILD_DIRECTORY
  shopt -s nullglob dotglob
  files=(./$CERTIFICATE_BUILD_DIRECTORY/*.pem)
  [ ${#files[@]} -eq 0 ]\
    && generate_selfsignedcert_cnf .\
    && middleware_src_certificates\
    || warn middleware not generating certs

)
}


function middleware_src_certificates {
##########  RUN COMMAND  ##########
# middleware_src_certificates
###################################
(
  set -u
  DESTINATION=$working_directory/src/$node_version/etc/certs
  ls -l $DESTINATION
  if yesno "Replace certs @ ./$DESTINATION, then replace k8s secrets?";then
  mkdir -p ./$working_directory/src/$node_version/etc/certs\
    && cp -p ./$CERTIFICATE_BUILD_DIRECTORY/*.pem ./$working_directory/src/$node_version/etc/certs/\
    && ls -l $DESTINATION\
    && middleware_secrets
  fi
)
}

function middleware_secrets {
##########  RUN COMMAND  ##########
# middleware_secrets
###################################
(
set -u
GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE k8s_secrets_delete
GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE k8s_secrets
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
runit "docker build $NOCACHE\
  -t $appname:$image_version\
  --build-arg EXPOSE_PORT_HTTPS=$API_HTTPS_NODEPORT_K8S_MIDDLEWARE\
  middleware"\
  || return 1
###  --build-arg EXPOSE_PORT_HTTP=$API_HTTP_RUNPORT_K8S_MIDDLEWARE\
# runit "docker image ls $appname"
runit "docker tag $appname:$image_version $DOCKERHUB:$HUBPORT/$appname:$image_version" || return 1
runit "docker push $DOCKERHUB:$HUBPORT/$appname:$image_version" || return 1

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
set -e
set -a
source ./middleware/k8s/$sdenv.env || exit 1
set +a
runit "kubectl apply -f ./middleware/k8s/api.yaml\
  && kubectl wait --namespace $GLOBAL_NAMESPACE\
    --for=condition=Ready pod -l app=$MIDDLEWARE_SELECTOR --timeout=60s
"

# kubectl rollout restart deployment api
)
}

function k8s_secrets_delete {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace k8s_secrets_delete
###################################
(
kubectl delete secret $MIDDLEWARE_SECRET
kubectl delete secret $MIDDLEWARE_TLS_SECRET
kubectl delete secret $FRONTEND_TLS_SECRET

)
}

function k8s_secrets {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace k8s_secrets
###################################
(
set -ue
### REUSE THE SAME CERT FOR DEVELOPMENT
# GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE k8s_secret_api
# GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE k8s_secret_web

CERTIFICATE_FILE_NAME=cert.pem
CERTIFICATE_KEY_FILE_NAME=key.pem
runit "kubectl create secret generic $MIDDLEWARE_SECRET\
    --from-file=$CERTIFICATE_FILE_NAME=./$CERTIFICATE_BUILD_DIRECTORY/$CERTIFICATE_FILE_NAME\
    --from-file=$CERTIFICATE_KEY_FILE_NAME=./$CERTIFICATE_BUILD_DIRECTORY/$CERTIFICATE_KEY_FILE_NAME
"
runit "kubectl create secret tls $MIDDLEWARE_TLS_SECRET\
    --cert=./$CERTIFICATE_BUILD_DIRECTORY/$CERTIFICATE_FILE_NAME\
    --key=./$CERTIFICATE_BUILD_DIRECTORY/$CERTIFICATE_KEY_FILE_NAME
"
runit "kubectl create secret tls $FRONTEND_TLS_SECRET\
    --cert=./$CERTIFICATE_BUILD_DIRECTORY/$CERTIFICATE_FILE_NAME\
    --key=./$CERTIFICATE_BUILD_DIRECTORY/$CERTIFICATE_KEY_FILE_NAME
"
)
}

function k8s_secret_api {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace k8s_secret_api
###################################
(
set -e
MIDDLEWARE_CERTIFICATE_FILE_NAME=cert.pem
MIDDLEWARE_CERTIFICATE_KEY_FILE_NAME=key.pem
runit "kubectl create secret generic $MIDDLEWARE_SECRET\
    --from-file=$MIDDLEWARE_CERTIFICATE_FILE_NAME=./$CERTIFICATE_BUILD_DIRECTORY/$MIDDLEWARE_SELECTOR/$MIDDLEWARE_CERTIFICATE_FILE_NAME\
    --from-file=$MIDDLEWARE_CERTIFICATE_KEY_FILE_NAME=./$CERTIFICATE_BUILD_DIRECTORY/$MIDDLEWARE_SELECTOR/$MIDDLEWARE_CERTIFICATE_KEY_FILE_NAME
"
runit "kubectl create secret tls $MIDDLEWARE_TLS_SECRET\
    --cert=./$CERTIFICATE_BUILD_DIRECTORY/$MIDDLEWARE_SELECTOR/$MIDDLEWARE_CERTIFICATE_FILE_NAME\
    --key=./$CERTIFICATE_BUILD_DIRECTORY/$MIDDLEWARE_SELECTOR/$MIDDLEWARE_CERTIFICATE_KEY_FILE_NAME
"
)
}


function k8s_secret_web {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace k8s_secret_web
###################################
(
set -e
FRONTEND_CERTIFICATE_FILE_NAME=cert.pem
FRONTEND_CERTIFICATE_KEY_FILE_NAME=key.pem
runit "kubectl create secret tls $FRONTEND_TLS_SECRET\
    --cert=./$CERTIFICATE_BUILD_DIRECTORY/$FRONTEND_SELECTOR/$FRONTEND_CERTIFICATE_FILE_NAME\
    --key=./$CERTIFICATE_BUILD_DIRECTORY/$FRONTEND_SELECTOR/$FRONTEND_CERTIFICATE_KEY_FILE_NAME
"
)
}


. ./bootstrap-validate.sh 2>/dev/null || echo ./bootstrap-validate.sh not found... continuing


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
runit "docker build $NOCACHE\
  -t $appname:$image_version\
  backend"\
  || return 1
# runit "docker image ls $appname"
runit "docker tag $appname:$image_version $DOCKERHUB:$HUBPORT/$appname:$image_version" || return 1
runit "docker push $DOCKERHUB:$HUBPORT/$appname:$image_version" || return 1

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
set -ue

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

function k8s_nginx {
##########  RUN COMMAND  ##########
# k8s_nginx
###################################
kubectl apply\
  -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml
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
sed -i '/^[[:space:]]*#/d' ./opt/pgadmin/k8s/pgadmin.yaml
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

function generate_selfsignedcert_cnf_new {
(
set -u
blue "------------------ GENERATING SELF-SIGNED CERTIFICATE ------------------"
dir=$1
CMD="openssl req -x509 -newkey rsa:4096 -nodes -keyout ./$dir/product-catalog-selfsigned-key-$STAMP.pem \
    -out ./$dir/product-catalog-selfsigned-cert-$STAMP.pem -days 365\
    -config ./$CERTIFICATE_BUILD_DIRECTORY/openssl.cnf"
echo $CMD
mkdir -p ./$dir\
  && eval $CMD
ls $dir
)
}

function generate_selfsignedcert_cnf {
(
set -ue
dir=$1
blue "------------------ GENERATING SELF-SIGNED CERTIFICATE $dir ------------------"
CMD="openssl req -x509 -newkey rsa:4096 -nodes -keyout ./$CERTIFICATE_BUILD_DIRECTORY/$dir/key.pem \
    -out ./$CERTIFICATE_BUILD_DIRECTORY/$dir/cert.pem -days 365\
    -config ./$CERTIFICATE_BUILD_DIRECTORY/$dir/openssl.cnf"
mkdir -p ./$CERTIFICATE_BUILD_DIRECTORY/$dir\
  && echo $CMD\
  && eval $CMD
# working_directory=middleware
# node_version=20
# DESTINATION=$working_directory/src/$node_version/etc/certs
# ls -l $DESTINATION
# if yesno "Replace certs @ ./$DESTINATION, then replace k8s secrets?";then
# cp -p ./$CERTIFICATE_BUILD_DIRECTORY/$dir/*.pem ./$working_directory/src/$node_version/etc/certs/
# GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE k8s_secrets_delete
# ls -l $DESTINATION
# GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE k8s_secrets
# fi
)
}

function generate_selfsignedcert {
(
set -u
blue "------------------ GENERATING SELF-SIGNED CERTIFICATE ------------------"
canonical_name=localhost
CMD="openssl req -x509 -newkey rsa:4096 -nodes -keyout ./key.pem \
    -out ./cert.pem -days 365 \
    -subj \"/CN=$canonical_name\""
echo $CMD
eval $CMD
ls *.pem
)
}
