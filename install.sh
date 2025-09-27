#!/bin/bash
GLOBAL_VERSION=$(date +%Y%m%d%H%M%s)

##########  CHEATSHEET  ###########
# GLOBAL_NAMESPACE=default install_postgres `stamp` && GLOBAL_NAMESPACE=default k8s_postgres
# GLOBAL_NAMESPACE=default k8s_webservice_update
# 
# 
# 
# GLOBAL_NAMESPACE=default pgadmin `stamp`
###################################

#############  HELPER FUNCTIONS AT TOP  #############
function green { println '\e[32m%s\e[0m' "$*"; }
function yellow { println '\e[33m%s\e[0m' "$*"; }
function blue { println '\e[34m%s\e[0m' "$*"; }                                                                                    
function red { println '\e[31m%s\e[0m' "$*"; }
function info { echo; echo "$(tput setaf 0;tput setab 7)$(date "+%Y-%m-%d %H:%M:%S") INFO: ${*}$(tput sgr 0)"; }
function pass { echo; echo "$(tput setaf 0;tput setab 2)$(date "+%Y-%m-%d %H:%M:%S") PASS: ${*}$(tput sgr 0)"; }
function fail { echo; echo "$(tput setaf 0;tput setab 1)$(date "+%Y-%m-%d %H:%M:%S") FAIL: ${*}$(tput sgr 0)"; }
function abort  { red "ABORT($1): $(date "+%Y-%m-%d %H:%M:%S")" && echo -e "\t${@:2}" && read -p "press CTRL+C or die" x && exit 1; }

##################  SETUP ENV  ##################
function setenv {
if [ -r ./$sdenv.env ];then
set -a
source ./$sdenv.env
set +a
else
abort "install.sh:$LINENO" ${FUNCNAME[0]}: file $sdenv.env not found in $PWD
fi
}
setenv

function configure {
set -u
(
image_version=$1
set_registry
set_keyvalue REPOSITORY $FRONTEND_APPNAME ./frontend/k8s/$sdenv.env
set_keyvalue REPOSITORY $MIDDLEWARE_APPNAME ./middleware/k8s/$sdenv.env
set_keyvalue REPOSITORY $BACKEND_APPNAME ./backend/k8s/$sdenv.env

GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE configure_webservice $image_version
GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE configure_api $image_version
GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE configure_postgres $image_version
)
}

##########  RUN COMMAND  ##########
# configure_default
###################################
function configure_default {
GLOBAL_NAMESPACE=default configure $GLOBAL_VERSION
}

function new_product_catalog {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=default new_product_catalog
###################################
set_registry
info ${FUNCNAME[0]}: callling backend $GLOBAL_VERSION\
  && backend\
  && info ${FUNCNAME[0]}: callling middleware $GLOBAL_VERSION\
  && middleware\
  && info ${FUNCNAME[0]}: callling frontend $GLOBAL_VERSION\
  && frontend\
  && info ${FUNCNAME[0]}: callling k8s $GLOBAL_VERSION\
  && k8s
}

function install_product_catalog {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=default install_product_catalog [IMAGE_VERSION]
###################################
set -u
set_registry
install_postgres $1\
  && install_api $1\
  && install_webservice $1\
  && k8s
}

function update_product_catalog {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=default update_product_catalog [IMAGE_VERSION]
###################################
set -u
set_registry
install_postgres $1\
  && install_api $1\
  && install_webservice $1\
  && k8s_update
}

function install_webservice {
set -u
info ${FUNCNAME[0]}: calling build_frontend $1\
  && build_frontend $1\
  && info ${FUNCNAME[0]}: calling configure_webservice $1\
  && configure_webservice $1
}

function install_api {
set -u
info ${FUNCNAME[0]}: calling build_middleware $1\
  && build_middleware $1\
  && info ${FUNCNAME[0]}: calling configure_api $1\
  && configure_api $1
}

function install_postgres {
set -u
info ${FUNCNAME[0]}: calling build_backend $1\
  && build_backend $1\
  && info ${FUNCNAME[0]}: calling configure_postgres $1\
  && configure_postgres $1
}

function k8s {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=<namespace> k8s
###################################
set_registry
k8s_postgres\
  && k8s_api\
  && k8s_webservice
}

function k8s_update {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=<namespace> k8s_update
###################################
set_registry
k8s_postgres\
  && k8s_api\
  && k8s_webservice_update
}

function set_keyvalue {
set -u
(
key=$1; value=$2; path=$3
if [ ! -f "$path" ]; then
  touch "$path"
fi
if [ -f "$path" ] && [ "$(tail -c1 "$path" | wc -l)" -eq 0 ]; then
  echo >>"$path"
fi
if grep -q "^$key=" "$path"; then 
  sed -i "s/^$key=.*/$key=$value/" "$path"
else
  echo "$key=$value" >>"$path"
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
docker run -d -p 5001:5000 --name registry registry:2 2>/dev/null || docker start registry
}

function set_registry {
set -u
set_keyvalue HUB $DOCKERHUB ./frontend/k8s/$sdenv.env
set_keyvalue HUB $DOCKERHUB ./middleware/k8s/$sdenv.env
set_keyvalue HUB $DOCKERHUB ./backend/k8s/$sdenv.env
local_registry
}

export FRONTEND_APPNAME=product-catalog-frontend
function frontend {
set -u
(
namespace=$GLOBAL_NAMESPACE
pushd ./frontend
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
npx -y create-react-app $FRONTEND_APPNAME && cd $_
cp ../package.json .
npm install react@18.2.0 react-dom@18.2.0 react-router-dom@6 axios --legacy-peer-deps
npm install
popd
info ${FUNCNAME[0]}: callling install_webservice $GLOBAL_VERSION
GLOBAL_NAMESPACE=$namespace install_webservice $GLOBAL_VERSION
)
}

function build_frontend {
set -u
(
image_version=$1
if [ -z "$image_version" ];then image_version=latest;fi
if [ ! -d ./frontend ];then echo must be at project root && return 1;fi
NOCACHE=
if [[ $sdenv = 'prod' ]];then NOCACHE=--no-cache;fi
appname=$FRONTEND_APPNAME
echo -e \\nBuilding $appname:$image_version
set_keyvalue REPOSITORY $appname ./frontend/k8s/$sdenv.env

# formatrun <<'EOF'
cp -rf ./frontend/src ./frontend/$appname/
cp -rf ./frontend/$sdenv.env ./frontend/$appname/.env
docker build -t $appname:$image_version $NOCACHE frontend\
  || return 1
# EOF

# formatrun <<'EOF'
docker tag $appname $DOCKERHUB/$appname
docker tag $appname:$image_version $DOCKERHUB/$appname:$image_version
docker push $DOCKERHUB/$appname
docker push $DOCKERHUB/$appname:$image_version 
# EOF

echo Pushed $DOCKERHUB/$appname:$image_version
)
}

function configure_webservice {
set -u
(
image_version=$1
set_keyvalue TAG $image_version ./frontend/k8s/$sdenv.env
set_keyvalue NAMESPACE $GLOBAL_NAMESPACE ./frontend/k8s/$sdenv.env
set_keyvalue REPLICAS 2 ./frontend/k8s/$sdenv.env
set -a
source ./frontend/k8s/$sdenv.env
set +a
# envsubst < ./frontend/k8s/web.template.yaml | kubectl apply -f -
envsubst >./frontend/k8s/web.yaml <./frontend/k8s/web.template.yaml
)
}


##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=default k8s_webservice
###################################
function k8s_webservice {
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

# echo -e "
# kubectl apply -f ./frontend/k8s/web.yaml\\\\\n\
#  && kubectl wait --namespace $GLOBAL_NAMESPACE --for=condition=Ready pod -l app=web --timeout=60s\\\\\n\
#  && kubectl port-forward --namespace $GLOBAL_NAMESPACE svc/web-service 8081:80
# "

}


##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=default k8s_webservice_update
###################################
function k8s_webservice_update {
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


export MIDDLEWARE_APPNAME=product-catalog-middleware
export MIDDLEWARE_API_PORT=3000
function middleware {
set -u
(
namespace=$GLOBAL_NAMESPACE
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
npm install fastify pg
npm install @fastify/cors
npm install
mkdir $MIDDLEWARE_APPNAME && cd $_
cp ../package.json .
npm install
popd
info ${FUNCNAME[0]}: callling install_api $GLOBAL_VERSION
GLOBAL_NAMESPACE=$namespace install_api $GLOBAL_VERSION
)
}

function build_middleware {
set -u
(
image_version=$1
if [ -z "$image_version" ];then image_version=latest;fi
if [ ! -d ./middleware ];then echo must be at project root && return 1;fi
NOCACHE=
if [[ $sdenv = 'prod' ]];then NOCACHE=--no-cache;fi
appname=$MIDDLEWARE_APPNAME
echo -e \\nBuilding $appname:$image_version
set_keyvalue REPOSITORY $appname ./middleware/k8s/$sdenv.env

# formatrun <<'EOF'
docker build $NOCACHE\
  -t $appname:latest\
  -t $appname:$image_version\
  --build-arg EXPOSE_PORT=$MIDDLEWARE_API_PORT\
  middleware\
  || return 1
# EOF

# formatrun <<'EOF'
docker tag $appname $DOCKERHUB/$appname
docker tag $appname:$image_version $DOCKERHUB/$appname:$image_version
docker push $DOCKERHUB/$appname
docker push $DOCKERHUB/$appname:$image_version
# EOF

echo Pushed $DOCKERHUB/$appname:$image_version
)
}

function configure_api {
set -u
(
image_version=$1
set_keyvalue TAG $image_version ./middleware/k8s/$sdenv.env
set_keyvalue NAMESPACE $GLOBAL_NAMESPACE ./middleware/k8s/$sdenv.env
set_keyvalue REPLICAS 2 ./middleware/k8s/$sdenv.env
set_keyvalue HUB $DOCKERHUB ./middleware/k8s/$sdenv.env
set_keyvalue REPOSITORY $MIDDLEWARE_APPNAME ./middleware/k8s/$sdenv.env
set_keyvalue PORT $MIDDLEWARE_API_PORT ./middleware/k8s/$sdenv.env
set -a
source ./middleware/k8s/$sdenv.env
set +a
# envsubst < ./middleware/k8s/api.template.yaml | kubectl apply -f -
envsubst >./middleware/k8s/api.yaml <./middleware/k8s/api.template.yaml
)
}


##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=default k8s_api
###################################
function k8s_api {
set -u
# formatrun <<'EOF'
# kubectl apply -f ./middleware/k8s/api.yaml\
#   && kubectl wait --namespace $GLOBAL_NAMESPACE --for=condition=Ready pod -l app=api --timeout=60s\
#   && kubectl port-forward --namespace $GLOBAL_NAMESPACE svc/api-service $MIDDLEWARE_API_PORT:$MIDDLEWARE_API_PORT

# EOF
logit "kubectl apply -f ./middleware/k8s/api.yaml\
  && kubectl wait --namespace $GLOBAL_NAMESPACE --for=condition=Ready pod -l app=api --timeout=60s\
  && kubectl port-forward --namespace $GLOBAL_NAMESPACE svc/api-service $MIDDLEWARE_API_PORT:$MIDDLEWARE_API_PORT
"

# echo -e "
# kubectl apply -f ./middleware/k8s/api.yaml\\\\\n\
#   && kubectl wait --namespace $GLOBAL_NAMESPACE --for=condition=Ready pod -l app=api --timeout=60s\\\\\n\
#   && kubectl port-forward --namespace $GLOBAL_NAMESPACE svc/api-service $MIDDLEWARE_API_PORT:$MIDDLEWARE_API_PORT
# "

validate_api
# kubectl rollout restart deployment api
}


function validate_api {
# formatrun <<'EOF'
# info http://localhost:$MIDDLEWARE_API_PORT/health/db\
#   && curl -s http://localhost:$MIDDLEWARE_API_PORT/health/db|jq\
#   && info http://localhost:$MIDDLEWARE_API_PORT/products\
#   && curl -s http://localhost:$MIDDLEWARE_API_PORT/products|jq\
#   && info http://localhost:$MIDDLEWARE_API_PORT/products/1\
#   && curl -s http://localhost:$MIDDLEWARE_API_PORT/products/1|jq\
#   && weblist=$(kubectl get pods --no-headers -o custom-columns=:metadata.name|/usr/bin/grep -E ^web) &&\
#   for pod in ${weblist[@]};do
#    info "$pod http://api-service:$MIDDLEWARE_API_PORT/health/db"\
#     && kubectl exec -it $pod -- curl -s http://api-service:$MIDDLEWARE_API_PORT/health/db|jq\
#     && info "$pod http://api-service:$MIDDLEWARE_API_PORT/products"\
#     && kubectl exec -it $pod -- curl -s http://api-service:$MIDDLEWARE_API_PORT/products|jq\
#    && info "$pod http://api-service:$MIDDLEWARE_API_PORT/products/1"\
#    && kubectl exec -it $pod -- curl -s http://api-service:$MIDDLEWARE_API_PORT/products/1|jq
#   done

# EOF
logit "info http://localhost:$MIDDLEWARE_API_PORT/health/db\
  && curl -s http://localhost:$MIDDLEWARE_API_PORT/health/db|jq\
  && info http://localhost:$MIDDLEWARE_API_PORT/products\
  && curl -s http://localhost:$MIDDLEWARE_API_PORT/products|jq\
  && info http://localhost:$MIDDLEWARE_API_PORT/products/1\
  && curl -s http://localhost:$MIDDLEWARE_API_PORT/products/1|jq\
  && weblist=\$(kubectl get pods --no-headers -o custom-columns=:metadata.name|/usr/bin/grep -E ^web) &&\
  for pod in \${weblist[@]};do
    info "\$pod http://api-service:$MIDDLEWARE_API_PORT/health/db"\
    && kubectl exec -it \$pod -- curl -s http://api-service:$MIDDLEWARE_API_PORT/health/db|jq\
    && info "\$pod http://api-service:$MIDDLEWARE_API_PORT/products"\
    && kubectl exec -it \$pod -- curl -s http://api-service:$MIDDLEWARE_API_PORT/products|jq\
    && info "\$pod http://api-service:$MIDDLEWARE_API_PORT/products/1"\
    && kubectl exec -it \$pod -- curl -s http://api-service:$MIDDLEWARE_API_PORT/products/1|jq
done
"

# echo -e "
# info http://localhost:$MIDDLEWARE_API_PORT/health/db\\\\\n\
#   && curl -s http://localhost:$MIDDLEWARE_API_PORT/health/db|jq\\\\\n\
#   && info http://localhost:$MIDDLEWARE_API_PORT/products\\\\\n\
#   && curl -s http://localhost:$MIDDLEWARE_API_PORT/products|jq\\\\\n\
#   && info http://localhost:$MIDDLEWARE_API_PORT/products/1\\\\\n\
#   && curl -s http://localhost:$MIDDLEWARE_API_PORT/products/1|jq\\\\\n\
#   && weblist=\$(kubectl get pods --no-headers -o custom-columns=":metadata.name"|$(which grep) -E ^web) &&\\\\\n\
# for pod in \${weblist[@]};do
#   info \"\$pod http://api-service:$MIDDLEWARE_API_PORT/health/db\"\\\\\n\
#   && kubectl exec -it \$pod -- curl -s http://api-service:$MIDDLEWARE_API_PORT/health/db|jq\\\\\n\
#   && info \"\$pod http://api-service:$MIDDLEWARE_API_PORT/products\"\\\\\n\
#   && kubectl exec -it \$pod -- curl -s http://api-service:$MIDDLEWARE_API_PORT/products|jq\\\\\n\
#   && info \"\$pod http://api-service:$MIDDLEWARE_API_PORT/products/1\"\\\\\n\
#   && kubectl exec -it \$pod -- curl -s http://api-service:$MIDDLEWARE_API_PORT/products/1|jq
# done
# "
}


export BACKEND_APPNAME=product-catalog-backend
function backend {
set -u
(
namespace=$GLOBAL_NAMESPACE
GLOBAL_NAMESPACE=$namespace install_postgres $GLOBAL_VERSION
)
}

function build_backend {
set -u
(
image_version=$1
if [ -z "$image_version" ];then image_version=latest;fi
if [ ! -d ./backend ];then echo must be at project root && return 1;fi
NOCACHE=
if [[ $sdenv = 'prod' ]];then NOCACHE=--no-cache;fi
appname=$BACKEND_APPNAME
echo -e \\nBuilding $appname:$image_version
set_keyvalue REPOSITORY $appname ./backend/k8s/$sdenv.env

# formatrun <<'EOF'
docker build -t $appname:$image_version $NOCACHE backend\
  || return 1
# EOF

# formatrun <<'EOF'
docker tag $appname $DOCKERHUB/$appname
docker tag $appname:$image_version $DOCKERHUB/$appname:$image_version
docker push $DOCKERHUB/$appname
docker push $DOCKERHUB/$appname:$image_version
# EOF

echo Pushed $DOCKERHUB/$appname:$image_version
)
}


function configure_postgres {
set -u
(
image_version=$1
set_keyvalue TAG $image_version ./backend/k8s/$sdenv.env
set_keyvalue NAMESPACE $GLOBAL_NAMESPACE ./backend/k8s/$sdenv.env
set -a
source ./backend/k8s/$sdenv.env
set +a
# envsubst < ./backend/k8s/postgres.template.yaml | kubectl apply -f -
envsubst >./backend/k8s/postgres.yaml <./backend/k8s/postgres.template.yaml
)
}


##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=default k8s_postgres
###################################
function k8s_postgres {
set -u

# formatrun <<'EOF'
# kubectl apply -f ./backend/k8s/postgres.yaml\
#   && kubectl wait --namespace $GLOBAL_NAMESPACE --for=condition=Ready pod -l app=postgres --timeout=60s

# EOF
logit "kubectl apply -f ./backend/k8s/postgres.yaml\
  && kubectl wait --namespace $GLOBAL_NAMESPACE --for=condition=Ready pod -l app=postgres --timeout=60s
"


# echo -e "
# kubectl apply -f ./backend/k8s/postgres.yaml\\\\\n\
#   && kubectl wait --namespace $GLOBAL_NAMESPACE --for=condition=Ready pod -l app=postgres --timeout=60s
# "
# kubectl rollout restart deployment postgres
}


function pgadmin() {
set -u
(
image_version=$1
set_keyvalue NAMESPACE $GLOBAL_NAMESPACE ./opt/pgadmin/k8s/$sdenv.env
set_keyvalue TAG $image_version ./opt/pgadmin/k8s/$sdenv.env
set -a
source ./opt/pgadmin/k8s/$sdenv.env
set +a
# envsubst < ./backend/k8s/postgres.template.yaml | kubectl apply -f -
envsubst >./opt/pgadmin/k8s/pgadmin.yaml <./opt/pgadmin/k8s/pgadmin.template.yaml
# kubectl rollout restart deployment api
)
# kubectl apply -f ./opt/pgadmin/k8s/pgamin.yaml -n $GLOBAL_NAMESPACE\
#   && kubectl port-forward svc/pgadmin 5050:80 -n $GLOBAL_NAMESPACE

echo -e "
kubectl apply -f ./opt/pgadmin/k8s/pgamin.yaml -n $GLOBAL_NAMESPACE\\\\\n\
  && kubectl wait --namespace $GLOBAL_NAMESPACE --for=condition=Ready pod -l app=pgadmin --timeout=30s\\\\\n\
  && kubectl port-forward svc/pgadmin 8080:80 -n $GLOBAL_NAMESPACE"
}

function install_nvm() {
  echo && blue "------------------ INSTALL NVM ------------------" && echo
  git clone https://github.com/nvm-sh/nvm.git $NVM_DIR
  echo $([ -s $NVM_DIR/nvm.sh ] && . $NVM_DIR/nvm.sh && [ -s $NVM_DIR/bash_completion ] && . $NVM_DIR/bash_completion && nvm install --lts)
}

function installnode() {
  echo && blue "------------------ NODE VIA NVM ------------------" && echo
  cyan "Updating nvm:" && echo $(pushd $NVM_DIR && git pull && popd || popd)
  if  ! command -v nvm >/dev/null; then
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
  fi
}

function nodever() {
  if [ ! -z $1 ]; then
    nvm install ${1} >/dev/null 2>&1 && nvm use ${_} > /dev/null 2>&1\
      && nvm alias default ${_} > /dev/null 2>&1; blue "Node:"; node -v; else
    yellow "INFORMATIONAL: Use nodever to install or switch node versions:" && echo -e "\tusage: nodever [ver]"
    blue "Node:" && node -v
    blue "npm:" && npm -v
    blue "nvm:" && nvm -v
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
openssl req -x509 -newkey rsa:4096 -nodes -keyout key.pem -out cert.pem -days 365 \
  -subj "/CN=api-service"

}
