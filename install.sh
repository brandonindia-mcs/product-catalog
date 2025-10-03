#!/bin/bash

##################  GLOBAL VARS  ##################
GLOBAL_VERSION=$(date +%Y%m%d%H%M%s)
alias stamp="echo \$(date +%Y%m%dT%H%M%S)"
export FRONTEND_APPNAME=product-catalog-frontend
export MIDDLEWARE_APPNAME=product-catalog-middleware
export MIDDLEWARE_API_RUN_PORT=3000
export MIDDLEWARE_API_SERVICE=api-service
export BACKEND_APPNAME=product-catalog-backend
export POSTGRE_SQL_RUN_PORT=5432

##########  CHEATSHEET  ###########
# GLOBAL_NAMESPACE=default (middleware SAMETAG && build_image_middleware SAMETAG && GLOBAL_NAMESPACE=default k8s_api)
# GLOBAL_NAMESPACE=default install_postgres `stamp`
# GLOBAL_NAMESPACE=default install_api `stamp`
# GLOBAL_NAMESPACE=default install_frontenc `stamp`
# GLOBAL_NAMESPACE=default k8s_webservice_update
# GLOBAL_NAMESPACE=default install_api `stamp`
# configure_default && GLOBAL_NAMESPACE=default k8s_api
# 
# 
# GLOBAL_NAMESPACE=default pgadmin `stamp`
###################################

#############  HELPER FUNCTIONS AT TOP  #############
function green { println '\e[32m%s\e[0m' "$*"; }
function yellow { println '\e[33m%s\e[0m' "$*"; }
function blue { println '\e[34m%s\e[0m' "$*"; }                                                                                    
function red { println '\e[31m%s\e[0m' "$*"; }
function banner { echo; echo "$(tput setaf 0;tput setab 6)$(date "+%Y-%m-%d %H:%M:%S") BANNER:${FUNCNAME[1]}: ${*}$(tput sgr 0)"; }
function info { echo; echo "$(tput setaf 0;tput setab 7)$(date "+%Y-%m-%d %H:%M:%S") INFO:$(tput sgr 0) ${*}"; }
function warn { echo; echo "$(tput setaf 1;tput setab 3)$(date "+%Y-%m-%d %H:%M:%S") WARN:$(tput sgr 0) ${*}"; }
function pass { echo; echo "$(tput setaf 0;tput setab 2)$(date "+%Y-%m-%d %H:%M:%S") PASS:$(tput sgr 0) ${*}"; }
function fail { echo; echo "$(tput setaf 8;tput setab 1)$(date "+%Y-%m-%d %H:%M:%S") FAIL:$(tput sgr 0) ${*}"; }
function abort_hard  { echo; red "**** ABORT($1): $(date "+%Y-%m-%d %H:%M:%S") **** " && echo -e "\t${@:2}\n" && read -p "press CTRL+C or die!" ; exit 1; }
function abort       { echo; red "**** ABORT($1): $(date "+%Y-%m-%d %H:%M:%S") ****" && echo -e "\t${@:2}\n"; }

##################  SETUP ENV  ##################
function setenv {
if [ -r ./$sdenv.env ];then
set -a
source ./$sdenv.env
set +a
else
abort_hard "install.sh:$LINENO"  ${FUNCNAME[0]}: file $sdenv.env not found in $PWD
fi
}
setenv

function default_product_catalog {
##########  RUN COMMAND  ##########
# default_product_catalog
###################################
(
product_catalog
)
}

function product_catalog {
##########  RUN COMMAND  ##########
# product_catalog
###################################
(
info ${FUNCNAME[0]}: callling backend\
  && backend\
  && info ${FUNCNAME[0]}: callling middleware\
  && middleware\
  && info ${FUNCNAME[0]}: callling frontend\
  && frontend
)
}

function install_product_catalog {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace install_product_catalog $image_version
###################################
(
set -u\
  && install_api $1\
  && install_webservice $1\
  && k8s
)
}

function update_product_catalog {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace update_product_catalog $image_version
###################################
(
set -u\
  && install_api $1\
  && install_webservice $1\
  && k8s_update
)
}

function install_webservice {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace install_webservice $image_version
###################################
(
set -u\
      && banner calling frontend\
  && frontend\
  \
      && banner calling build_image_frontend $1\
  && build_image_frontend $1\
  \
      && banner calling configure_webservice $1\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE configure_webservice $1\
  \
      && banner GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE calling k8s_webservice\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE k8s_webservice
)
}

function install_api {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace install_api $image_version
###################################
(
set -u\
      && banner calling middleware\
  && middleware\
  \
      && banner calling build_image_middleware $1\
  && build_image_middleware $1\
  \
      && banner calling GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE configure_api $1\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE configure_api $1\
  \
      && banner calling GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE k8s_api\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE k8s_api\
  \
      && banner calling validate_api\
  && validate_api

)
}

function install_postgres {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace install_postgres $image_version
###################################
(
set -u\
      && banner calling backend\
  && backend\
  \
      && banner calling calling build_image_backend $1\
  && build_image_backend $1\
  \
      && banner calling GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE calling configure_postgres $1\
  && GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE configure_postgres $1\
  \
      && banner calling kGLOBAL_NAMESPACE=$GLOBAL_NAMESPACE 8s_postgres\
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
set_keyvalue TAG $image_version ./frontend/k8s/$sdenv.env
set_keyvalue HUB $DOCKERHUB ./frontend/k8s/$sdenv.env
set_keyvalue NAMESPACE $GLOBAL_NAMESPACE ./frontend/k8s/$sdenv.env
set_keyvalue REPLICAS 2 ./frontend/k8s/$sdenv.env
set -a
source ./frontend/k8s/$sdenv.env
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
set_keyvalue RUNPORT $MIDDLEWARE_API_RUN_PORT ./middleware/k8s/$sdenv.env
set_keyvalue SERVICENAME $MIDDLEWARE_API_SERVICE ./middleware/k8s/$sdenv.env
set -a
source ./middleware/k8s/$sdenv.env
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
set_keyvalue RUNPORT $POSTGRE_SQL_RUN_PORT ./backend/k8s/$sdenv.env
set -a
source ./backend/k8s/$sdenv.env
set +a
# envsubst < ./backend/k8s/postgres.template.yaml | kubectl apply -f -
envsubst >./backend/k8s/postgres.yaml <./backend/k8s/postgres.template.yaml
)
}


function frontend {
##########  RUN COMMAND  ##########
# frontend <$node_version> - optional
###################################
(
node_version=${1:-18}
pushd ./frontend
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

(
if [ -d $FRONTEND_APPNAME ];then
warn $(yellow ${FUNCNAME[0]}: $FRONTEND_APPNAME found, not craeting a new react app)
return 1
fi
echo && blue "------------------ NEW REACT APP ------------------" && echo
npx -y create-react-app $FRONTEND_APPNAME
)
cd $FRONTEND_APPNAME && cp ../package.json .
npm install --legacy-peer-deps
cp ../src/* ./src/
cp ../$sdenv.env ./.env
npm run build
popd
)
}

function frontend_upgrade {
##########  RUN COMMAND  ##########
# frontend_upgrade <$node_version> - optional
###################################
(
node_version=${1:-20}
pushd ./frontend
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

(
if [ -d $FRONTEND_APPNAME ];then
rm -rf $FRONTEND_APPNAME/node_modules
rm $FRONTEND_APPNAME/package-lock.json
npm uninstall react-scripts
npm install

# find src -type f -name "*.js" -exec bash -c 'for f; do echo mv "$f" "${f%.js}.jsx"; done' _ {} +
find src -type f -name "*.js" -exec bash -c 'for f; do echo mv "./$f" "./${f%.js}.jsx" && echo mv "./$FRONTEND_APPNAME/$f" "./$FRONTEND_APPNAME/${f%.js}.jsx"; done' _ {} +

# find ./src -type f -name "*.js" -exec bash -c 'for f; do      mv "$f" "${f%.js}.jsx"; done' _ {} +
find src -type f -name "*.js" -exec bash -c 'for f; do mv "./$f" "./${f%.js}.jsx" && mv "./$FRONTEND_APPNAME/$f" "./$FRONTEND_APPNAME/${f%.js}.jsx"; done' _ {} +

cd $FRONTEND_APPNAME
cp ../package.json .
rm -rf ./node_modules ./package-lock.json
cp ../index.html ./index.html
cp ../vite.config.js ./vite.config.js
cp ../src/* ./src/
cp ../$sdenv.env ./.env
npm install
npm run build

fi
)
build_image_frontend $image_version
GLOBAL_NAMESPACE=$namespace configure_webservice $image_version
GLOBAL_NAMESPACE=$namespace k8s_webservice
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

# echo -e "
# kubectl apply -f ./frontend/k8s/web.yaml\\\\\n\
#  && kubectl wait --namespace $GLOBAL_NAMESPACE --for=condition=Ready pod -l app=web --timeout=60s\\\\\n\
#  && kubectl port-forward --namespace $GLOBAL_NAMESPACE svc/web-service 8081:80
# "
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
logit "kubectl set image deployment/web web=$HUB/$REPOSITORY:$TAG\
  && kubectl rollout status deployment/web
"

# echo -e "
# kubectl set image deployment/web web=$HUB/$REPOSITORY:$TAG\\\\\n\
#  && kubectl rollout status deployment/web
# "

)
}


function middleware {
##########  RUN COMMAND  ##########
# middleware
###################################
(
echo && blue "------------------ GENERATING SELF-SIGNED CERT ------------------" && echo
generate_selfsignedcert $MIDDLEWARE_API_SERVICE
set_keyvalue KEY_NAME key.pem ./middleware/k8s/$sdenv.env
set_keyvalue CERT_NAME cert.pem ./middleware/k8s/$sdenv.env
pushd ./middleware
export NVM_HOME=$(pwd)/.nvm
export NVM_DIR=$(pwd)/.nvm
echo NVM_HOME is $NVM_HOME
if [ ! -d $NVM_DIR ];then
    install_nvm;
fi
if [ -d $NVM_DIR ];then
    installnode;
    nodever 18;
fi
mkdir -p $MIDDLEWARE_APPNAME && cd $_
cp ../package.json .
cp -r ../src/* ./
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
  --build-arg EXPOSE_PORT=$MIDDLEWARE_API_RUN_PORT\
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
#   && kubectl port-forward --namespace $GLOBAL_NAMESPACE svc/$MIDDLEWARE_API_SERVICE $MIDDLEWARE_API_RUN_PORT:$MIDDLEWARE_API_RUN_PORT

# EOF
set -a
source ./middleware/k8s/$sdenv.env
set +a
logit "kubectl apply -f ./middleware/k8s/api.yaml\
  && kubectl wait --namespace $GLOBAL_NAMESPACE\
    --for=condition=Ready pod -l app=api --timeout=60s\
  && kubectl port-forward --namespace $GLOBAL_NAMESPACE\
    svc/$MIDDLEWARE_API_SERVICE $MIDDLEWARE_API_RUN_PORT:$MIDDLEWARE_API_RUN_PORT
"

runit "kubectl apply -f ./middleware/k8s/api.yaml\
  && kubectl wait --namespace $GLOBAL_NAMESPACE\
    --for=condition=Ready pod -l app=api --timeout=60s
"

# echo -e "
# kubectl apply -f ./middleware/k8s/api.yaml\\\\\n\
#   && kubectl wait --namespace $GLOBAL_NAMESPACE --for=condition=Ready pod -l app=api --timeout=60s\\\\\n\
#   && kubectl port-forward --namespace $GLOBAL_NAMESPACE svc/$MIDDLEWARE_API_SERVICE $MIDDLEWARE_API_RUN_PORT:$MIDDLEWARE_API_RUN_PORT
# "

# validate_api
# kubectl rollout restart deployment api
)
}


function validate_api {
# formatrun <<'EOF'
# info http://localhost:$MIDDLEWARE_API_RUN_PORT/health/db\
#   && curl -s http://localhost:$MIDDLEWARE_API_RUN_PORT/health/db|jq\
#   && info http://localhost:$MIDDLEWARE_API_RUN_PORT/products\
#   && curl -s http://localhost:$MIDDLEWARE_API_RUN_PORT/products|jq\
#   && info http://localhost:$MIDDLEWARE_API_RUN_PORT/products/1\
#   && curl -s http://localhost:$MIDDLEWARE_API_RUN_PORT/products/1|jq\
#   && weblist=$(kubectl get pods --no-headers -o custom-columns=:metadata.name|/usr/bin/grep -E ^web) &&\
#   for pod in ${weblist[@]};do
#    info "$pod http://$MIDDLEWARE_API_SERVICE:$MIDDLEWARE_API_RUN_PORT/health/db"\
#     && kubectl exec -it $pod -- curl -s http://$MIDDLEWARE_API_SERVICE:$MIDDLEWARE_API_RUN_PORT/health/db|jq\
#     && info "$pod http://$MIDDLEWARE_API_SERVICE:$MIDDLEWARE_API_RUN_PORT/products"\
#     && kubectl exec -it $pod -- curl -s http://$MIDDLEWARE_API_SERVICE:$MIDDLEWARE_API_RUN_PORT/products|jq\
#    && info "$pod http://$MIDDLEWARE_API_SERVICE:$MIDDLEWARE_API_RUN_PORT/products/1"\
#    && kubectl exec -it $pod -- curl -s http://$MIDDLEWARE_API_SERVICE:$MIDDLEWARE_API_RUN_PORT/products/1|jq
#   done

# EOF
set -a
source ./middleware/k8s/$sdenv.env
set +a
logit "info http://localhost:$MIDDLEWARE_API_RUN_PORT/health/db\
  && curl -s http://localhost:$MIDDLEWARE_API_RUN_PORT/health/db|jq\
  && info http://localhost:$MIDDLEWARE_API_RUN_PORT/products\
  && curl -s http://localhost:$MIDDLEWARE_API_RUN_PORT/products|jq\
  && info http://localhost:$MIDDLEWARE_API_RUN_PORT/products/1\
  && curl -s http://localhost:$MIDDLEWARE_API_RUN_PORT/products/1|jq\
  && weblist=\$(kubectl get pods --no-headers -o custom-columns=:metadata.name|/usr/bin/grep -E ^web) &&\
  for pod in \${weblist[@]};do
    info "Connection tests $MIDDLEWARE_API_SERVICE:$MIDDLEWARE_API_RUN_PORT for \$pod, press Enter"  && read x;\
    info "\$pod http://$MIDDLEWARE_API_SERVICE:$MIDDLEWARE_API_RUN_PORT/health/db"\
    && kubectl exec -it \$pod -- curl -s http://$MIDDLEWARE_API_SERVICE:$MIDDLEWARE_API_RUN_PORT/health/db|jq\
    && info "\$pod http://$MIDDLEWARE_API_SERVICE:$MIDDLEWARE_API_RUN_PORT/products"\
    && kubectl exec -it \$pod -- curl -s http://$MIDDLEWARE_API_SERVICE:$MIDDLEWARE_API_RUN_PORT/products|jq\
    && info "\$pod http://$MIDDLEWARE_API_SERVICE:$MIDDLEWARE_API_RUN_PORT/products/1"\
    && kubectl exec -it \$pod -- curl -s http://$MIDDLEWARE_API_SERVICE:$MIDDLEWARE_API_RUN_PORT/products/1|jq
  done
"

# runit "info http://localhost:$MIDDLEWARE_API_RUN_PORT/health/db\
#   && curl -s http://localhost:$MIDDLEWARE_API_RUN_PORT/health/db|jq\
#   && info http://localhost:$MIDDLEWARE_API_RUN_PORT/products\
#   && curl -s http://localhost:$MIDDLEWARE_API_RUN_PORT/products|jq\
#   && info http://localhost:$MIDDLEWARE_API_RUN_PORT/products/1\
#   && curl -s http://localhost:$MIDDLEWARE_API_RUN_PORT/products/1|jq\
#   && weblist=\$(kubectl get pods --no-headers -o custom-columns=:metadata.name|/usr/bin/grep -E ^web) &&\
#   for pod in \${weblist[@]};do
#     info "Connection tests $MIDDLEWARE_API_SERVICE:$MIDDLEWARE_API_RUN_PORT for \$pod, press Enter"  && read x;\
#     && info "\$pod http://$MIDDLEWARE_API_SERVICE:$MIDDLEWARE_API_RUN_PORT/health/db"\
#     && kubectl exec -it \$pod -- curl -s http://$MIDDLEWARE_API_SERVICE:$MIDDLEWARE_API_RUN_PORT/health/db|jq\
#     && info "\$pod http://$MIDDLEWARE_API_SERVICE:$MIDDLEWARE_API_RUN_PORT/products"\
#     && kubectl exec -it \$pod -- curl -s http://$MIDDLEWARE_API_SERVICE:$MIDDLEWARE_API_RUN_PORT/products|jq\
#     && info "\$pod http://$MIDDLEWARE_API_SERVICE:$MIDDLEWARE_API_RUN_PORT/products/1"\
#     && kubectl exec -it \$pod -- curl -s http://$MIDDLEWARE_API_SERVICE:$MIDDLEWARE_API_RUN_PORT/products/1|jq
#   done
# "

# echo -e "
# info http://localhost:$MIDDLEWARE_API_RUN_PORT/health/db\\\\\n\
#   && curl -s http://localhost:$MIDDLEWARE_API_RUN_PORT/health/db|jq\\\\\n\
#   && info http://localhost:$MIDDLEWARE_API_RUN_PORT/products\\\\\n\
#   && curl -s http://localhost:$MIDDLEWARE_API_RUN_PORT/products|jq\\\\\n\
#   && info http://localhost:$MIDDLEWARE_API_RUN_PORT/products/1\\\\\n\
#   && curl -s http://localhost:$MIDDLEWARE_API_RUN_PORT/products/1|jq\\\\\n\
#   && weblist=\$(kubectl get pods --no-headers -o custom-columns=":metadata.name"|$(which grep) -E ^web) &&\\\\\n\
# for pod in \${weblist[@]};do
#   info \"\$pod http://$MIDDLEWARE_API_SERVICE:$MIDDLEWARE_API_RUN_PORT/health/db\"\\\\\n\
#   && kubectl exec -it \$pod -- curl -s http://$MIDDLEWARE_API_SERVICE:$MIDDLEWARE_API_RUN_PORT/health/db|jq\\\\\n\
#   && info \"\$pod http://$MIDDLEWARE_API_SERVICE:$MIDDLEWARE_API_RUN_PORT/products\"\\\\\n\
#   && kubectl exec -it \$pod -- curl -s http://$MIDDLEWARE_API_SERVICE:$MIDDLEWARE_API_RUN_PORT/products|jq\\\\\n\
#   && info \"\$pod http://$MIDDLEWARE_API_SERVICE:$MIDDLEWARE_API_RUN_PORT/products/1\"\\\\\n\
#   && kubectl exec -it \$pod -- curl -s http://$MIDDLEWARE_API_SERVICE:$MIDDLEWARE_API_RUN_PORT/products/1|jq
# done
# "
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


# echo -e "
# kubectl apply -f ./backend/k8s/postgres.yaml\\\\\n\
#   && kubectl wait --namespace $GLOBAL_NAMESPACE --for=condition=Ready pod -l app=postgres --timeout=60s
# "
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
source ./opt/pgadmin/k8s/$sdenv.env
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
  echo installing mvn @ $NVM_DIR
  git clone https://github.com/nvm-sh/nvm.git $NVM_DIR
  echo $([ -s $NVM_DIR/nvm.sh ] && . $NVM_DIR/nvm.sh && [ -s $NVM_DIR/bash_completion ] && . $NVM_DIR/bash_completion && nvm install --lts)
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
    blue "Node: $(node -v)"
    blue "npm: $(npm -v)"
    blue "nvm: $(nvm -v)"
  fi
}

function getyarn() {
  echo && blue "------------------ YARN - NEEDS NVM ------------------" && echo
  if ! command -v yarn >/dev/null 2>&1; then grey "Getting yarn: " && npm install --global yarn >/dev/null; fi
}


function formatrun {
(
# local raw_cmd
raw_cmd=$(cat)
# CMD=$(echo "$raw_cmd" | sed -E ':a;N;$!ba;s/\\\s*\n/ /g')
# eval "$CMD"

### UNCOMMENT WHEN READY
# runit "$(echo "$raw_cmd" | sed -E ':a;N;$!ba;s/\\\s*\n/ /g')"
logit "$raw_cmd"
)
}

function runit {
eval "$*"
}

function logit {
echo -e "$*"
}

function generate_selfsignedcert {
(
set -u
canonical_name=$1
# mkdir -p ./certs &&\
  openssl req -x509 -newkey rsa:4096 -nodes -keyout ./key.pem \
    -out ./cert.pem -days 365 \
    -subj "/CN=$canonical_name"

  # openssl req -x509 -newkey rsa:4096 -nodes -keyout ./certs/$canonical_name-x509-key.pem \
  #   -out ./certs/$canonical_name-x509-cert.pem -days 365 \
  #   -subj "/CN=$canonical_name"

)
}
