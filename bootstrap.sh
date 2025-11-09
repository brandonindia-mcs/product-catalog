#!/bin/bash

##################  GLOBAL VARS  ##################
GLOBAL_VERSION=$(date +%Y%m%d%H%M%s)
KUBECTL_TIMEOUT=15s
alias stamp="echo \$(date +%Y%m%d%H%M%S)"

export APPNAME=product-catalog
export DOMAIN_HOSTNAME=${APPNAME}.progress.notls

export BACKEND_APPNAME=${APPNAME}-backend
export BACKEND_DATABASE_SERVICE=db-service
export BACKEND_SELECTOR=postgres
export BACKEND_DEPLOYMENT=postgres
export BACKEND_DB_DEPLOYMENT=postgres
export BACKEND_POD_TEMPLATE=postgres
export POSTGRES_USER=catalog
export POSTGRES_DB=catalog
export POSTGRES_PASSWORD=catalog
export POSTGRE_SQL_RUNPORT=5432

export FRONTEND_APPNAME=${APPNAME}-frontend
export FRONTEND_WEBSERVICE=web-service
export FRONTEND_WEBSERVICE_INGRESS=$FRONTEND_WEBSERVICE-ingress
export FRONTEND_SELECTOR=web
export FRONTEND_DEPLOYMENT=web
export FRONTEND__WEB_DEPLOYMENT=web
export FRONTEND_POD_TEMPLATE=web
export WEB_HTTP_RUNPORT_PUBLIC_FRONTEND=80
export FRONTEND_WEBSERVICE_INGRESS_HOSTNAME=$DOMAIN_HOSTNAME

export MIDDLEWARE_APPNAME=${APPNAME}-middleware
export MIDDLEWARE_DATA_SERVICE=data-service
export MIDDLEWARE_DATA_INGRESS_HOSTNAME=$DOMAIN_HOSTNAME
export MIDDLEWARE_PRODUCTS_INGRESS_HOSTNAME=data-ingress.progress.notls
export MIDDLEWARE_DATA_SERVICE_INGRESS=data-ingress-ingress
export MIDDLEWARE_DATA_SELECTOR=data
export MIDDLEWARE_data_SELECTOR=data
export MIDDLEWARE_DATA_DEPLOYMENT=data
export MIDDLEWARE_DATA_POD_TEMPLATE=data
export DATA_HTTP_PORTNAME_K8S_MIDDLEWARE=http
export DATA_HTTP_PORT_K8S_MIDDLEWARE=80
export DATA_HTTP_RUNPORT_K8S_MIDDLEWARE=2080
export DATA_HTTP_NODEPORT_K8S_MIDDLEWARE=32080
export PRODUCTS_HTTP_PORT_K8S_MIDDLEWARE=80
# export DATA_INGRESS_PORT_K8S_MIDDLEWARE=$DATA_HTTPS_PORT_K8S_MIDDLEWARE

export MIDDLEWARE_LOGLEVEL=debug
export CORS_ORIGIN_HTTP=http://$DOMAIN_HOSTNAME
export NODE_TESTING_PORT=3333

export NODE_ENV=development
export PG_HOST=$BACKEND_DATABASE_SERVICE
export PG_DATABASE=$POSTGRES_DB
export PG_USER=$POSTGRES_USER
export PG_PASSWORD=$POSTGRES_PASSWORD
export PG_PORT=$POSTGRE_SQL_RUNPORT

STAMP=`stamp`
export MIDDLEWARE_TLS_MOUNT=certs
export MIDDLEWARE_TLS_MOUNT_PATH=/$MIDDLEWARE_TLS_MOUNT
export MIDDLEWARE_TLS_CERT_VOLUME=tls-certs
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
  # "# NOT CALLING # && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE $function $1"\
  # && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE $function $1\
cleanup_yaml frontend/k8s/$GLOBAL_NAMESPACE
cleanup_yaml middleware/k8s/$GLOBAL_NAMESPACE
info ${FUNCNAME[0]}\
  && function=install_postgres && yellow ${FUNCNAME[0]}: callling $function\
  "# NOT CALLING # && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE $function $1"\
  && function=install_middleware && yellow ${FUNCNAME[0]}: callling $function\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE $function $1\
  && function=update_webservice && yellow ${FUNCNAME[0]}: callling $function\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE $function $1
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
  && yellow ${FUNCNAME[0]}: callling install_middleware\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE install_middleware $1
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

function install_ingress {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace install_ingress $image_version
###################################
(
set -u\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE configure_ingress $1\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE k8s_ingress

)
}

function update_webservice {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace update_webservice $image_version
###################################
(
cleanup_yaml frontend/k8s/$GLOBAL_NAMESPACE
frontend_update\
  && set -u\
  && build_image_frontend $1\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE configure_ingress_frontend $1\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE configure_webservice $1\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE k8s_webservice
)
}

function install_middleware {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace install_middleware $image_version
###################################
(
cleanup_yaml middleware/k8s/$GLOBAL_NAMESPACE
middleware\
  && set -ue\
  && build_image_middleware $1\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE configure_ingress_middleware $1\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE configure_middleware $1\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE k8s_data\

)
}

function install_postgres {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace install_postgres $image_version
###################################
(
# >./backend/k8s/$sdenv.env && warn ./backend/k8s/$sdenv.env reset
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
  && k8s_data\
  && k8s_webservice
)
}

function k8s_update {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace k8s_update
###################################
(
set_registry\
  && k8s_data\
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
set_keyvalue HUB $DOCKERHUB:$HUBPORT ./frontend/k8s/$GLOBAL_NAMESPACE/$sdenv.env
set_keyvalue HUB $DOCKERHUB:$HUBPORT ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv.env
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
# GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE configure_ingress $image_version
GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE configure_webservice $image_version
GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE configure_middleware $image_version
GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE configure_postgres $image_version
)
}

function configure_webservice {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace configure_webservice $image_version
###################################
(
set -u
component=web
image_version=$1
FRONTEND_WEBSERVICE_REPLICAS=1
set_keyvalue REPOSITORY $FRONTEND_APPNAME ./frontend/k8s/$GLOBAL_NAMESPACE/$sdenv.env
set_keyvalue RUNPORT_HTTP $WEB_HTTP_RUNPORT_PUBLIC_FRONTEND ./frontend/k8s/$GLOBAL_NAMESPACE/$sdenv.env
set_keyvalue TAG $image_version ./frontend/k8s/$GLOBAL_NAMESPACE/$sdenv.env
set_keyvalue HUB $DOCKERHUB:$HUBPORT ./frontend/k8s/$GLOBAL_NAMESPACE/$sdenv.env
set_keyvalue NAMESPACE $GLOBAL_NAMESPACE ./frontend/k8s/$GLOBAL_NAMESPACE/$sdenv.env
set_keyvalue REPLICAS $FRONTEND_WEBSERVICE_REPLICAS ./frontend/k8s/$GLOBAL_NAMESPACE/$sdenv.env
set_keyvalue SERVICE $FRONTEND_WEBSERVICE ./frontend/k8s/$GLOBAL_NAMESPACE/$sdenv.env
set_keyvalue SELECTOR $FRONTEND_SELECTOR ./frontend/k8s/$GLOBAL_NAMESPACE/$sdenv.env
set_keyvalue DEPLOYMENT $FRONTEND_DEPLOYMENT ./frontend/k8s/$GLOBAL_NAMESPACE/$sdenv.env
set_keyvalue POD_TEMPLATE $FRONTEND_POD_TEMPLATE ./frontend/k8s/$GLOBAL_NAMESPACE/$sdenv.env
set_keyvalue CONTAINER $FRONTEND_DEPLOYMENT ./frontend/k8s/$GLOBAL_NAMESPACE/$sdenv.env
set_keyvalue TLS_SECRET $FRONTEND_TLS_SECRET ./frontend/k8s/$GLOBAL_NAMESPACE/$sdenv.env

set -ae
source ./frontend/k8s/$GLOBAL_NAMESPACE/$sdenv.env || exit 1
set +a
# envsubst < ./frontend/k8s/$GLOBAL_NAMESPACE/web.template.yaml | kubectl apply -f -
envsubst >./frontend/k8s/$GLOBAL_NAMESPACE/web.yaml <./frontend/k8s/$GLOBAL_NAMESPACE/web.template.yaml
sed -i '/^[[:space:]]*#/d' ./frontend/k8s/$GLOBAL_NAMESPACE/web.yaml
info ${FUNCNAME[0]}: new ./frontend/k8s/$GLOBAL_NAMESPACE/web.yaml, ./frontend/k8s/$GLOBAL_NAMESPACE/$sdenv.env properties: 
cat ./frontend/k8s/$GLOBAL_NAMESPACE/$sdenv.env

)
}

function configure_middleware {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace configure_middleware $image_version
###################################
(
cleanup_yaml middleware/k8s/$GLOBAL_NAMESPACE
GLOBAL_NAMESPACE=$namespace configure_middleware_data $image_version
GLOBAL_NAMESPACE=$namespace configure_middleware_chat $image_version
GLOBAL_NAMESPACE=$namespace configure_ingress_middleware $image_version
)
}


function configure_middleware_data {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace configure_middleware_data $image_version
###################################
(
set -u
component=data
image_version=$1
MIDDLEWARE_DATA_REPLICAS=1
set_keyvalue REPOSITORY $MIDDLEWARE_APPNAME-$component ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue TAG $image_version ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue HUB $DOCKERHUB:$HUBPORT ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue NAMESPACE $GLOBAL_NAMESPACE ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue REPLICAS $MIDDLEWARE_DATA_REPLICAS ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env

set_keyvalue HTTP_PORT $DATA_HTTP_PORT_K8S_MIDDLEWARE ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue HTTP_PORT_NAME $DATA_HTTP_PORTNAME_K8S_MIDDLEWARE ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue HTTP_TARGET_PORT $DATA_HTTP_RUNPORT_K8S_MIDDLEWARE ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue CONTAINER_PORT $DATA_HTTP_RUNPORT_K8S_MIDDLEWARE ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue HTTP_NODE_PORT $DATA_HTTP_NODEPORT_K8S_MIDDLEWARE ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue LISTEN_PORT_HTTP $DATA_HTTP_RUNPORT_K8S_MIDDLEWARE ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env

set_keyvalue SERVICE $MIDDLEWARE_DATA_SERVICE ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue SELECTOR $MIDDLEWARE_DATA_SELECTOR ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue DEPLOYMENT $MIDDLEWARE_DATA_DEPLOYMENT ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue POD_TEMPLATE $MIDDLEWARE_DATA_POD_TEMPLATE ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue CONTAINER $MIDDLEWARE_DATA_DEPLOYMENT ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env

set_keyvalue CORS_ORIGIN $CORS_ORIGIN_HTTP ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue TLS_MOUNT_PATH $MIDDLEWARE_TLS_MOUNT_PATH ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue TLS_CERT_VOLUME $MIDDLEWARE_TLS_CERT_VOLUME ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue SECRET $MIDDLEWARE_SECRET ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue TLS_SECRET $MIDDLEWARE_TLS_SECRET ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue CERTIFICATE cert.pem ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue CERTIFICATE_KEY key.pem ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env

set_keyvalue LOG_LEVEL $MIDDLEWARE_LOGLEVEL ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue PG_HOST $PG_HOST ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue PG_DATABASE $PG_DATABASE ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue PG_USER $PG_USER ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue PG_PASSWORD $PG_PASSWORD ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue PG_PORT $PG_PORT ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env

set -ae
source ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env || exit 1
set +a
# envsubst < ./middleware/k8s/$GLOBAL_NAMESPACE/template/$component.template.yaml | kubectl apply -f -
envsubst >./middleware/k8s/$GLOBAL_NAMESPACE/$component.yaml <./middleware/k8s/$GLOBAL_NAMESPACE/template/$component.template.yaml
sed -i '/^[[:space:]]*#/d' ./middleware/k8s/$GLOBAL_NAMESPACE/$component.yaml
info ${FUNCNAME[0]}: new ./middleware/k8s/$GLOBAL_NAMESPACE/$component.yaml, ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env properties: 
cat ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env

)
}


function configure_postgres {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace configure_postgres $image_version
###################################
(
set -u
component=postgres
image_version=$1
set_keyvalue REPOSITORY $BACKEND_APPNAME ./backend/k8s/$sdenv.env
set_keyvalue TAG $image_version ./backend/k8s/$sdenv.env
set_keyvalue HUB $DOCKERHUB:$HUBPORT ./backend/k8s/$sdenv.env
set_keyvalue NAMESPACE $GLOBAL_NAMESPACE ./backend/k8s/$sdenv.env
set_keyvalue RUNPORT_POSTGRE $POSTGRE_SQL_RUNPORT ./backend/k8s/$sdenv.env
set_keyvalue SELECTOR $BACKEND_SELECTOR ./backend/k8s/$sdenv.env
set_keyvalue DEPLOYMENT $BACKEND_DEPLOYMENT ./backend/k8s/$sdenv.env
set_keyvalue POD_TEMPLATE $BACKEND_POD_TEMPLATE ./backend/k8s/$sdenv.env
set_keyvalue CONTAINER $BACKEND_DEPLOYMENT ./backend/k8s/$sdenv.env

set_keyvalue SERVICE $BACKEND_DATABASE_SERVICE ./backend/k8s/$sdenv.env
set_keyvalue POSTGRES_DB $POSTGRES_DB ./backend/k8s/$sdenv.env
set_keyvalue POSTGRES_USER $POSTGRES_USER ./backend/k8s/$sdenv.env
set_keyvalue POSTGRES_PASSWORD $POSTGRES_PASSWORD ./backend/k8s/$sdenv.env
set -ae
source ./backend/k8s/$sdenv.env || exit 1
set +a
# envsubst < ./backend/k8s/postgres.template.yaml | kubectl apply -f -
envsubst >./backend/k8s/postgres.yaml <./backend/k8s/postgres.template.yaml
sed -i '/^[[:space:]]*#/d' ./backend/k8s/postgres.yaml
info ${FUNCNAME[0]}: new ./backend/k8s/postgres.yaml, ./backend/k8s/$sdenv.env properties: 
cat ./backend/k8s/$sdenv.env

)
}

function configure_ingress {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace configure_ingress $image_version
###################################
(
set -u
GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE configure_ingress_frontend
GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE configure_ingress_middleware
)
}

function configure_ingress_frontend {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace configure_ingress_frontend $image_version
###################################
(
set -u
component=web
# image_version=$1
#web
set_keyvalue NAMESPACE $GLOBAL_NAMESPACE ./frontend/k8s/$GLOBAL_NAMESPACE/$sdenv-ingress.env
set_keyvalue SERVICE $FRONTEND_WEBSERVICE ./frontend/k8s/$GLOBAL_NAMESPACE/$sdenv-ingress.env
set_keyvalue INGRESS $FRONTEND_WEBSERVICE_INGRESS ./frontend/k8s/$GLOBAL_NAMESPACE/$sdenv-ingress.env
set_keyvalue INGRESS_HOST $FRONTEND_WEBSERVICE_INGRESS_HOSTNAME ./frontend/k8s/$GLOBAL_NAMESPACE/$sdenv-ingress.env
set_keyvalue INGRESS_PORT $WEB_HTTP_RUNPORT_PUBLIC_FRONTEND ./frontend/k8s/$GLOBAL_NAMESPACE/$sdenv-ingress.env
set_keyvalue TLS_SECRET $FRONTEND_TLS_SECRET ./frontend/k8s/$GLOBAL_NAMESPACE/$sdenv-ingress.env

set -ae
source ./frontend/k8s/$GLOBAL_NAMESPACE/$sdenv-ingress.env || exit 1
set +a
# envsubst < ./frontend/k8s/$GLOBAL_NAMESPACE/web.template.yaml | kubectl apply -f -
envsubst >./frontend/k8s/$GLOBAL_NAMESPACE/web-ingress.yaml <./frontend/k8s/$GLOBAL_NAMESPACE/web-ingress.template.yaml
sed -i '/^[[:space:]]*#/d' ./frontend/k8s/$GLOBAL_NAMESPACE/web-ingress.yaml
info ${FUNCNAME[0]}: new ./frontend/k8s/$GLOBAL_NAMESPACE/web-ingress.yaml, ./frontend/k8s/$GLOBAL_NAMESPACE/$sdenv-ingress.env properties: 
cat ./frontend/k8s/$GLOBAL_NAMESPACE/$sdenv-ingress.env

)
}
function configure_ingress_middleware {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace configure_ingress_middleware $image_version
###################################
# read -p "at ${FUNCNAME[0]}"
(
set -u
GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE configure_ingress_middleware_data $image_version
)
}


function configure_ingress_middleware_data {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace configure_ingress_middleware_data $image_version
###################################
# read -p "at ${FUNCNAME[0]}"
(
set -u
component=data
set_keyvalue SERVICE $MIDDLEWARE_DATA_SERVICE ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component-ingress.env
set_keyvalue INGRESS $MIDDLEWARE_DATA_SERVICE_INGRESS ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component-ingress.env

set_keyvalue DATA_HOSTNAME $MIDDLEWARE_DATA_INGRESS_HOSTNAME ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component-ingress.env
set_keyvalue DATA_PORT $DATA_HTTP_PORT_K8S_MIDDLEWARE ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component-ingress.env
set_keyvalue DATA_URI /data ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component-ingress.env

set_keyvalue PRODUCTS_HOSTNAME $MIDDLEWARE_PRODUCTS_INGRESS_HOSTNAME ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component-ingress.env
set_keyvalue PRODUCTS_PORT $PRODUCTS_HTTP_PORT_K8S_MIDDLEWARE ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component-ingress.env
set_keyvalue PRODUCTS_URI /products ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component-ingress.env

set_keyvalue TLS_SECRET $MIDDLEWARE_TLS_SECRET ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component-ingress.env
set_keyvalue SSL_TRUEFALSE true ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component-ingress.env

set -ae
source ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component-ingress.env || exit 1
set +a
# envsubst < ./middleware/k8s/$GLOBAL_NAMESPACE/template/$component.template.yaml | kubectl apply -f -
envsubst >./middleware/k8s/$GLOBAL_NAMESPACE/$component-ingress.yaml <./middleware/k8s/$GLOBAL_NAMESPACE/template/$component-ingress.template.yaml
sed -i '/^[[:space:]]*#/d' ./middleware/k8s/$GLOBAL_NAMESPACE/$component-ingress.yaml
info ${FUNCNAME[0]}: new ./middleware/k8s/$GLOBAL_NAMESPACE/$component-ingress.yaml, ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component-ingress.env properties: 
cat ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component-ingress.env

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
    fail "[✘] Missing: $expanded_path"
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
    fail "[✘] Missing: $expanded_path"
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

SEARCH='process.env.REACT_APP_DATA_URL'
REPLACE='import.meta.env.VITE_DATA_URL'
find ./$FRONTEND_APPNAME/src -type f \( -name "*.jsx" \) -exec sed -i "s|$SEARCH|$REPLACE|g" {} +

frontend_update

fi
)
)
}

function frontend_update_20 {
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
  ./$working_directory/src/$node_version/.env.$sdenv\
)
for dep in ${dependency_list[@]}; do
  expanded_path=$(eval echo "$dep")
  if [ -e "$expanded_path" ]; then
    echo "[✔] Found: $expanded_path"
  else
    fail "[✘] Missing: $expanded_path"
    exit 1
  fi
done

# pushd ./$working_directory
project_build=./$working_directory/build
mkdir -p ./$working_directory/build && pushd ./$project_build
node_refresh $node_version

cp ../src/$node_version/* ../src/$node_version/.* .
mkdir -p $FRONTEND_APPNAME && cd $_
rm -rf ./node_modules ./package-lock.json
cp ../../src/$node_version/etc/* ../../src/$node_version/etc/.* .
cp -r ../../src/$node_version/src/. ./src/
cp -r ../../src/$node_version/public/. ./public/
cp ../../src/$node_version/.env.$sdenv ./.env || exit 1
npm install
npm run build

)
}

function frontend_update {
##########  RUN COMMAND  ##########
# frontend_update
###################################
(
node_version=${1:-22}
working_directory=frontend
banner2 working_directory $working_directory, node_version $node_version
dependency_list=(
  ./$working_directory/src/$node_version/etc\
  ./$working_directory/src/$node_version/src\
  ./$working_directory/src/$node_version/Dockerfile\
  ./$working_directory/src/$node_version/.env.$sdenv\
)
for dep in ${dependency_list[@]}; do
  expanded_path=$(eval echo "$dep")
  if [ -e "$expanded_path" ]; then
    echo "[✔] Found: $expanded_path"
  else
    fail "[✘] Missing: $expanded_path"
    exit 1
  fi
done

# pushd ./$working_directory
project_build=./$working_directory/build && rm -rf $project_build/*
mkdir -p ./$working_directory/build && pushd ./$project_build
node_refresh $node_version

cp ../src/$node_version/* ../src/$node_version/.* .
mkdir -p $FRONTEND_APPNAME && cd $_
rm -rf ./node_modules ./package-lock.json
cp ../../src/$node_version/etc/* ../../src/$node_version/etc/.* .
cp -r ../../src/$node_version/public/. ./public/
cp ../../src/$node_version/.env.$sdenv ./.env || exit 1
cp -r ../../src/$node_version/src/web/. ./src/
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
build_directory=frontend/build
NOCACHE=
if [[ $sdenv = 'prod' ]];then NOCACHE=--no-cache;fi
appname=$FRONTEND_APPNAME
echo -e \\nBuilding $appname:$image_version

set_registry
runit "docker build $NOCACHE\
  -t $appname:$image_version\
  $build_directory"\
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
source ./frontend/k8s/$GLOBAL_NAMESPACE/$sdenv*.env || exit 1
set +a
runit "kubectl apply -f ./frontend/k8s/$GLOBAL_NAMESPACE/web.yaml -f ./frontend/k8s/$GLOBAL_NAMESPACE/web-ingress.yaml\
  && kubectl wait --namespace $GLOBAL_NAMESPACE --for=condition=Ready pod -l app=$FRONTEND_SELECTOR --timeout=$KUBECTL_TIMEOUT
"

)
}


function k8s_webservice_update {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace k8s_webservice_update
###################################
(
export $(grep -v '^#' ./frontend/k8s/$GLOBAL_NAMESPACE/$sdenv.env | xargs)
set -ue
configure_webservice $TAG
banner1 logit
logit "kubectl set image deployment/web web=$HUB/$REPOSITORY:$TAG\
  && kubectl rollout status deployment/web
"

)
}


GLOBAL_MIDDLEWARE_COMPONENT_LIST=( data )
function middleware {
##########  RUN COMMAND  ##########
# middleware
###################################
(
node_version=${1:-22}
working_directory=middleware
banner2 working_directory $working_directory, node_version $node_version
# middleware_certificate

dependency_list+=(
  ./$working_directory/src/$node_version/etc\
  ./$working_directory/src/$node_version/src\
)
for dep in ${dependency_list[@]}; do
  expanded_path=$(eval echo "$dep")
  if [ -e "$expanded_path" ]; then
    echo "[✔] Found: $expanded_path"
  else
    fail "[✘] Missing: $expanded_path"
    exit 1
  fi
done


project_build=./$working_directory/build
mkdir -p ./$working_directory/build && pushd ./$project_build
node_refresh $node_version

mkdir -p $MIDDLEWARE_APPNAME && cd $_
cp ../../src/$node_version/* ../../src/$node_version/.* .
cp -r ../../src/$node_version/etc/* .
cp -r ../../src/$node_version/src/* .

is_array GLOBAL_MIDDLEWARE_COMPONENT_LIST && echo GLOBAL_MIDDLEWARE_COMPONENT_LIST is an array
is_array GLOBAL_MIDDLEWARE_COMPONENT_LIST || echo GLOBAL_MIDDLEWARE_COMPONENT_LIST IS NOT an array
if is_array GLOBAL_MIDDLEWARE_COMPONENT_LIST;then
echo "Components ${#GLOBAL_MIDDLEWARE_COMPONENT_LIST[@]}"
for component in ${GLOBAL_MIDDLEWARE_COMPONENT_LIST[@]};do
  banner1 building from GLOBAL_MIDDLEWARE_COMPONENT_LIST: $component
  pushd $component || continue
    # node_refresh $node_version
    # cp ../.npmrc .
    npm install
    npm ci
  popd
done
elif [ -z "$GLOBAL_MIDDLEWARE_COMPONENT_LIST" ];then warn no component, did you meain menu \"middleware data\"? && return 1
else
while IFS= read -r component; do
  banner3 building from argument: $component
  pushd $component || continue
    # node_refresh $node_version
    # cp ../.npmrc .
    npm install
    npm ci
    # npm start $NODE_TESTING_PORT
    # npm start $NODE_TESTING_PORT & pid=$!; echo "started pid=$pid"
    # ( sleep 10; kill -TERM "$pid" 2>/dev/null || true; sleep 5; kill -KILL "$pid" 2>/dev/null || true ) &
  popd
done <<< "$GLOBAL_MIDDLEWARE_COMPONENT_LIST"
fi
popd
)
}

is_array() {
  declare -p "$1" 2>/dev/null | grep -q 'declare \-a'
}


function middleware_component_certificates {
##########  RUN COMMAND  ##########
# middleware_component_certificates
###################################
  generate_selfsignedcert_cnf $MIDDLEWARE_APPNAME/api
}
function middleware_certificate {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace middleware_certificate
###################################
(
  set -u
  echo -n looking for certificates: ./$CERTIFICATE_BUILD_DIRECTORY/
  shopt -s nullglob dotglob
  files=(./$CERTIFICATE_BUILD_DIRECTORY/*.pem)
  [ ${#files[@]} -eq 0 ]\
    && echo "  no certs found, generating..."\
    && generate_selfsignedcert_cnf $MIDDLEWARE_APPNAME\
    && cp -p ./$CERTIFICATE_BUILD_DIRECTORY/*.pem ./$CERTIFICATE_BUILD_DIRECTORY/$MIDDLEWARE_APPNAME\
    && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE middleware_src_certificates\
    || warn found certificates in ./$CERTIFICATE_BUILD_DIRECTORY/ - not generating for $MIDDLEWARE_APPNAME

  set_keyvalue KEY_NAME certs/key.pem ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv.env
  set_keyvalue CERT_NAME certs/cert.pem ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv.env
  set_keyvalue CERTIFICATE_KEY key.pem ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv.env
  set_keyvalue CERTIFICATE cert.pem ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv.env
  dependency_list=(
    ./$working_directory/src/$node_version/etc/certs/cert.pem\
    ./$working_directory/src/$node_version/etc/certs/key.pem\
  )
)
}


function middleware_src_certificates {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace middleware_src_certificates
###################################
(
  set -u
  DESTINATION=$working_directory/src/$node_version/etc/certs
  echo $DESTINATION: && /bin/ls -l $DESTINATION
  if yesno "Replace certs @ ./$DESTINATION, then replace k8s secrets?";then
  mkdir -p ./$DESTINATION\
    && cp -p ./$CERTIFICATE_BUILD_DIRECTORY/*.pem ./$DESTINATION/\
    && echo $DESTINATION: && /bin/ls -l $DESTINATION\
    && cp -p ./$CERTIFICATE_BUILD_DIRECTORY/*.pem ./$DESTINATION/\
    && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE middleware_secrets
  fi
)
}

function middleware_secrets {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace middleware_secrets
###################################
(
set -u
GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE k8s_secrets_delete
GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE k8s_secrets # TLS
)
}

function middle_secrets {
##########  RUN COMMAND  ##########
# middle_secrets
###################################
(
component=middle_secrets
key=
base=
model=
internal=
set_keyvalue AZURE_DATA_KEY $(echo -n $key|base64|tr -d '\n') ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue AZURE_DATA_BASE $(echo -n $base|base64) ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue AZURE_DEPLOYMENT $(echo -n $model|base64) ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue INTERNAL_DATA_KEY $(echo -n $internal|base64) ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set -ae
source ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env || exit 1
set +a
envsubst < ./middleware/k8s/$GLOBAL_NAMESPACE/template/azure-secrets.template.yaml | kubectl apply -f -
# envsubst >./middleware/k8s/$GLOBAL_NAMESPACE/azure-secrets.yaml <./middleware/k8s/$GLOBAL_NAMESPACE/template/azure-secrets.template.yaml
sed -i '/^[[:space:]]*#/d' ./middleware/k8s/$GLOBAL_NAMESPACE/template/azure-secrets.template.yaml
info ${FUNCNAME[0]}: ./middleware/k8s/$GLOBAL_NAMESPACE/azure-secrets.yaml, ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env properties: 
 
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
build_image_middleware_data $image_version
)
}


function build_image_middleware_data {
##########  RUN COMMAND  ##########
# build_image_middleware_data $image_version
###################################
(
image_version=$1
component=data
banner2 building image_version: $image_version image: $component
set -u
if [ -z "$image_version" ];then image_version=latest;fi
if [ ! -d ./middleware ];then echo must be at project root && return 1;fi
build_directory=middleware/build
NOCACHE=
if [[ $sdenv = 'prod' ]];then NOCACHE=--no-cache;fi
appname=$MIDDLEWARE_APPNAME
cp ./middleware/src/etc/Dockerfile.$component ./$build_directory/Dockerfile
image=$appname-$component
echo -e \\nBuilding $image:$image_version

# DOCKER_ARGUMENT=EXPOSE_PORT_HTTPS
# DOCKER_ARGUMENT_VALUE=$DATA_HTTPS_NODEPORT_K8S_MIDDLEWARE
set_registry
runit "docker build $NOCACHE\
  -t $image:$image_version\
  --build-arg EXPOSE_PORT_HTTP=$DATA_HTTP_NODEPORT_K8S_MIDDLEWARE\
  $build_directory"\
  || return 1
runit "docker tag $image:$image_version $DOCKERHUB:$HUBPORT/$image:$image_version" || return 1
runit "docker push $DOCKERHUB:$HUBPORT/$image:$image_version" || return 1
set_keyvalue REPOSITORY $image ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue TAG $image_version ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env

echo Pushed $DOCKERHUB/$image:$image_version
kubectl set image deployment/$component $component=$DOCKERHUB:$HUBPORT/$image:$image_version -n $GLOBAL_NAMESPACE\
    && kubectl wait --for=condition=available deployment/$component --timeout=60s\
    || echo -e "\tmust be a new deployment, let's apply YAML"\
    && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE k8s_${component}\
    || echo something bad happened

)
}


function default_k8s_data {
##########  RUN COMMAND  ##########
# default_k8s_data
###################################
GLOBAL_NAMESPACE=default k8s_data
}

function k8s_middleware {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace k8s_middleware
###################################
(
set -ue
is_array GLOBAL_MIDDLEWARE_COMPONENT_LIST && echo GLOBAL_MIDDLEWARE_COMPONENT_LIST is an array
is_array GLOBAL_MIDDLEWARE_COMPONENT_LIST || echo GLOBAL_MIDDLEWARE_COMPONENT_LIST IS NOT an array
if is_array GLOBAL_MIDDLEWARE_COMPONENT_LIST;then
echo "Components ${#GLOBAL_MIDDLEWARE_COMPONENT_LIST[@]}"
for component in ${GLOBAL_MIDDLEWARE_COMPONENT_LIST[@]};do
banner1 kubectl apply from GLOBAL_MIDDLEWARE_COMPONENT_LIST: $component
SELECTOR_VARIABLE=MIDDLEWARE_$(echo $component)_SELECTOR
set -a
source ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv*$component*.env || exit 1
set +a
runit "kubectl apply -f ./middleware/k8s/$GLOBAL_NAMESPACE/$component.yaml -f ./middleware/k8s/$GLOBAL_NAMESPACE/$component-ingress.yaml\
  && kubectl wait --namespace $GLOBAL_NAMESPACE\
    --for=condition=Ready pod -l app=${!SELECTOR_VARIABLE} --timeout=$KUBECTL_TIMEOUT
"
done
elif [ -z "$GLOBAL_MIDDLEWARE_COMPONENT_LIST" ];then warn no component, did you meain menu \#39? && return 1
else
while IFS= read -r component; do
  banner3 kubectl apply from argument: $component
done <<< "$GLOBAL_MIDDLEWARE_COMPONENT_LIST"
fi
)
}

function k8s_data {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace k8s_data
###################################
(
set -e
set -a
source ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv*.env || exit 1
set +a
component=data
runit "kubectl apply -f ./middleware/k8s/$GLOBAL_NAMESPACE/$component.yaml -f ./middleware/k8s/$GLOBAL_NAMESPACE/$component-ingress.yaml\
  && kubectl wait --namespace $GLOBAL_NAMESPACE\
    --for=condition=Ready pod -l app=$MIDDLEWARE_DATA_SELECTOR --timeout=$KUBECTL_TIMEOUT
"
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
# GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE k8s_secret_data
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

function k8s_secret_data {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace k8s_secret_data
###################################
(
set -e
MIDDLEWARE_CERTIFICATE_FILE_NAME=cert.pem
MIDDLEWARE_CERTIFICATE_KEY_FILE_NAME=key.pem
runit "kubectl create secret generic $MIDDLEWARE_SECRET\
    --from-file=$MIDDLEWARE_CERTIFICATE_FILE_NAME=./$CERTIFICATE_BUILD_DIRECTORY/$MIDDLEWARE_DATA_SELECTOR/$MIDDLEWARE_CERTIFICATE_FILE_NAME\
    --from-file=$MIDDLEWARE_CERTIFICATE_KEY_FILE_NAME=./$CERTIFICATE_BUILD_DIRECTORY/$MIDDLEWARE_DATA_SELECTOR/$MIDDLEWARE_CERTIFICATE_KEY_FILE_NAME
"
runit "kubectl create secret tls $MIDDLEWARE_TLS_SECRET\
    --cert=./$CERTIFICATE_BUILD_DIRECTORY/$MIDDLEWARE_DATA_SELECTOR/$MIDDLEWARE_CERTIFICATE_FILE_NAME\
    --key=./$CERTIFICATE_BUILD_DIRECTORY/$MIDDLEWARE_DATA_SELECTOR/$MIDDLEWARE_CERTIFICATE_KEY_FILE_NAME
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


function k8s_ingress {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace k8s_ingress
###################################
(
set -u
GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE k8s_ingress_web
GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE k8s_ingress_data
)
}


function k8s_ingress_data {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace k8s_ingress_data
###################################
(
component=data
set -e
set -a
source ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component-ingress.env || exit 1
set +a
runit "kubectl apply -f ./middleware/k8s/$GLOBAL_NAMESPACE/$component-ingress.yaml"
)
}


function k8s_ingress_web {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace k8s_ingress_web
###################################
(
component=web
set -e
set -a
source ./frontend/k8s/$GLOBAL_NAMESPACE/$sdenv-ingress.env || exit 1
set +a
runit "kubectl apply -f ./frontend/k8s/$GLOBAL_NAMESPACE/$component-ingress.yaml"
)
}


# . ./bootstrap-validate.sh 2>/dev/null || fail ./bootstrap-validate.sh not found... continuing


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
build_directory=backend
NOCACHE=
if [[ $sdenv = 'prod' ]];then NOCACHE=--no-cache;fi
appname=$BACKEND_APPNAME
echo -e \\nBuilding $appname:$image_version

set_registry
runit "docker build $NOCACHE\
  -t $appname:$image_version\
  $build_directory"\
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
runit "kubectl apply -f ./backend/k8s/postgres.yaml\
  && kubectl wait --namespace $GLOBAL_NAMESPACE --for=condition=Ready pod -l app=postgres --timeout=$KUBECTL_TIMEOUT
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
  && kubectl wait --namespace $GLOBAL_NAMESPACE --for=condition=Ready pod -l app=pgadmin --timeout=$KUBECTL_TIMEOUT\\\\\n\
  && kubectl port-forward svc/pgadmin 8080:80 -n $GLOBAL_NAMESPACE"
)
}

. ./npm-config-include.sh

function green { println '\e[32m%s\e[0m' "$*"; }
function yellow { println '\e[33m%s\e[0m' "$*"; }
function blue { println '\e[34m%s\e[0m' "$*"; }                                                                                    
function red { println '\e[31m%s\e[0m' "$*"; }
function banner1 { echo; echo "$(tput setaf 0;tput setab 6)$(date "+%Y-%m-%d %H:%M:%S") BANNER ${FUNCNAME[1]}::${*}$(tput sgr 0)"; }
function banner2 { echo; echo "$(tput setaf 0;tput setab 6)$(date "+%Y-%m-%d %H:%M:%S") BANNER ${FUNCNAME[2]}::${FUNCNAME[1]} ${*}$(tput sgr 0)"; }
function banner3 { echo; echo "$(tput setaf 0;tput setab 6)$(date "+%Y-%m-%d %H:%M:%S") BANNER ${FUNCNAME[3]}::${FUNCNAME[2]}::${FUNCNAME[1]} ${*}$(tput sgr 0)"; }
function banner_alt { echo; echo -n "$(tput setaf 0;tput setab 6)$(date "+%Y-%m-%d %H:%M:%S") BANNER ${FUNCNAME[2]}::${FUNCNAME[1]} ${*}$(tput sgr 0)"; }
function info    { echo; echo "$(tput setaf 0;tput setab 7)$(date "+%Y-%m-%d %H:%M:%S") INFO:$(tput sgr 0) ${*}"; }
function warn    { echo; echo "$(tput setaf 1;tput setab 3)$(date "+%Y-%m-%d %H:%M:%S") WARN:$(tput sgr 0) ${*}"; }
function pass    { echo; echo "$(tput setaf 0;tput setab 2)$(date "+%Y-%m-%d %H:%M:%S") PASS:$(tput sgr 0) ${*}"; }
function fail    { echo; echo "$(tput setaf 8;tput setab 1)$(date "+%Y-%m-%d %H:%M:%S") FAIL:$(tput sgr 0) ${*}"; }
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

delete_env_files() {
  local target_dir="$1"

  if [[ -z "$target_dir" ]]; then
    echo "Usage: ${FUNCNAME[0]} <directory>"
    return 1
  fi

  if [[ ! -d "$target_dir" ]]; then
    echo "Error: '$target_dir' is not a valid directory."
    return 1
  fi

  echo "Searching for .env files under: $target_dir"
  find "$target_dir" -type f -name "*.env" -print -exec rm -v {} \;
}

delete_yaml_files() {
  local target_dir="$1"

  if [[ -z "$target_dir" ]]; then
    echo "Usage: ${FUNCNAME[0]} <directory>"
    return 1
  fi

  if [[ ! -d "$target_dir" ]]; then
    echo "Error: '$target_dir' is not a valid directory."
    return 1
  fi

  echo "Deleting .yaml files (excluding *.template.yaml) under: $target_dir"
  find "$target_dir" -type f -name "*.yaml" ! -name "*.template.yaml" -print0 | xargs -0 rm -v
}

cleanup_yaml() {
  delete_env_files $1
  delete_yaml_files $1
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
CMD="openssl req -x509 -newkey rsa:4096 -nodes -keyout ./$dir/${APPNAME}-selfsigned-key-$STAMP.pem \
    -out ./$dir/${APPNAME}-selfsigned-cert-$STAMP.pem -days 365\
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
CMD="openssl req -x509 -newkey rsa:4096 -nodes -keyout ./$CERTIFICATE_BUILD_DIRECTORY/key.pem \
    -out ./$CERTIFICATE_BUILD_DIRECTORY/cert.pem -days 365\
    -config ./$CERTIFICATE_BUILD_DIRECTORY/$dir/openssl.cnf"
echo $CMD
if yesno "run openssl?";then
  eval $CMD
  echo ./$CERTIFICATE_BUILD_DIRECTORY: && /bin/ls -l ./$CERTIFICATE_BUILD_DIRECTORY/*.pem
fi
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

. ./chat-bootstrap.sh
