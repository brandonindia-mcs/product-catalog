#!/bin/bash
GLOBAL_VERSION=$(date +%Y%m%d%H%M)00

function setenv {
set -a
source ./$sdenv.env
set +a
}
setenv

##########  CHEATSHEET  ###########
# GLOBAL_NAMESPACE=default install_postgres `stamp` && GLOBAL_NAMESPACE=default k8s_postgres
# GLOBAL_NAMESPACE=default k8s_webservice_update
# 
# 
# 
# GLOBAL_NAMESPACE=default pgadmin `stamp`
###################################

##########  RUN COMMAND  ##########
# configure_default
###################################
function configure_default {
  GLOBAL_NAMESPACE=default configure_webservice $GLOBAL_VERSION
  GLOBAL_NAMESPACE=default configure_api $GLOBAL_VERSION
  GLOBAL_NAMESPACE=default configure_postgres $GLOBAL_VERSION
}

function new_product_catalog {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=default new_product_catalog
###################################
backend\
  && middleware\
  && frontend\
  && k8s
}

function product_catalog {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=default product_catalog
###################################
set -u
install_postgres $1\
  && install_api $1\
  && install_webservice $1\
  && k8s_update
}

function install_webservice {
set -u
build_frontend $1\
  && configure_webservice $1
}

function install_api {
set -u
build_middleware $1\
  && configure_api $1
}

function install_postgres {
set -u
build_backend $1\
  && configure_postgres $1
}

function k8s {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=<namespace> k8s
###################################
k8s_postgres\
  && k8s_api\
  && k8s_webservice
}

function k8s_update {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=<namespace> k8s_update
###################################
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

function local_registry {
docker run -d -p 5001:5000 --name registry registry:2
}

export FRONTEND_APPNAME=product-catalog-frontend
function frontend {
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
install_webservice $GLOBAL_VERSION
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

cp -rf ./frontend/src ./frontend/$appname/
cp -rf ./frontend/$sdenv.env ./frontend/$appname/.env
docker build -t $appname:$image_version $NOCACHE frontend\
  || return 1

docker tag $appname $DOCKERHUB/$appname
docker tag $appname:$image_version $DOCKERHUB/$appname:$image_version
docker push $DOCKERHUB/$appname
docker push $DOCKERHUB/$appname:$image_version 

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
formatrun <<'EOF'
kubectl apply -f ./frontend/k8s/web.yaml\
  && kubectl wait --namespace $GLOBAL_NAMESPACE --for=condition=Ready pod -l app=web --timeout=60s\
  && kubectl port-forward --namespace $GLOBAL_NAMESPACE svc/web-service 8081:80
EOF

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
formatrun <<'EOF'
kubectl set image deployment/web web=$HUB/$REPOSITORY:$TAG\
  && kubectl rollout status deployment/web
EOF

# echo -e "
# kubectl set image deployment/web web=$HUB/$REPOSITORY:$TAG\\\\\n\
#  && kubectl rollout status deployment/web
# "

)
}


export MIDDLEWARE_APPNAME=product-catalog-middleware
function middleware {
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
install_api $GLOBAL_VERSION

}

function build_middleware {
(
image_version=$1
if [ -z "$image_version" ];then image_version=latest;fi
if [ ! -d ./middleware ];then echo must be at project root && return 1;fi
NOCACHE=
if [[ $sdenv = 'prod' ]];then NOCACHE=--no-cache;fi
appname=$MIDDLEWARE_APPNAME
echo -e \\nBuilding $appname:$image_version

docker build -t $appname:$image_version $NOCACHE middleware\
  || return 1

docker tag $appname $DOCKERHUB/$appname
docker tag $appname:$image_version $DOCKERHUB/$appname:$image_version
docker push $DOCKERHUB/$appname
docker push $DOCKERHUB/$appname:$image_version

echo Pushed $DOCKERHUB/$appname:$image_version
)
}

function configure_api {
set -u
(
image_version=$1
set_keyvalue TAG $image_version ./middleware/k8s/$sdenv.env
set_keyvalue NAMESPACE $GLOBAL_NAMESPACE ./middleware/k8s/$sdenv.env
set_keyvalue REPLICAS 2 ./frontend/k8s/$sdenv.env
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
formatrun <<'EOF'
kubectl apply -f ./middleware/k8s/api.yaml\
  && kubectl wait --namespace $GLOBAL_NAMESPACE --for=condition=Ready pod -l app=api --timeout=60s\
  && kubectl port-forward --namespace $GLOBAL_NAMESPACE svc/api-service 3000:3000
EOF

# echo -e "
# kubectl apply -f ./middleware/k8s/api.yaml\\\\\n\
#   && kubectl wait --namespace $GLOBAL_NAMESPACE --for=condition=Ready pod -l app=api --timeout=60s\\\\\n\
#   && kubectl port-forward --namespace $GLOBAL_NAMESPACE svc/api-service 3000:3000
# "

validate_api
# kubectl rollout restart deployment api
}


function validate_api {
formatrun <<'EOF'
info http://localhost:3000/health/db\
  && curl -s http://localhost:3000/health/db|jq\
  && info http://localhost:3000/products\
  && curl -s http://localhost:3000/products|jq\
  && info http://localhost:3000/products/1\
  && curl -s http://localhost:3000/products/1|jq\
  && weblist=$(kubectl get pods --no-headers -o custom-columns=:metadata.name|/usr/bin/grep -E ^web) &&\
for pod in ${weblist[@]};do
  info "$pod http://api-service:3000/health/db"\
  && kubectl exec -it $pod -- curl -s http://api-service:3000/health/db|jq\
  && info "$pod http://api-service:3000/products"\
  && kubectl exec -it $pod -- curl -s http://api-service:3000/products|jq\
  && info "$pod http://api-service:3000/products/1"\
  && kubectl exec -it $pod -- curl -s http://api-service:3000/products/1|jq
done
EOF

# echo -e "
# info http://localhost:3000/health/db\\\\\n\
#   && curl -s http://localhost:3000/health/db|jq\\\\\n\
#   && info http://localhost:3000/products\\\\\n\
#   && curl -s http://localhost:3000/products|jq\\\\\n\
#   && info http://localhost:3000/products/1\\\\\n\
#   && curl -s http://localhost:3000/products/1|jq\\\\\n\
#   && weblist=\$(kubectl get pods --no-headers -o custom-columns=":metadata.name"|$(which grep) -E ^web) &&\\\\\n\
# for pod in \${weblist[@]};do
#   info \"\$pod http://api-service:3000/health/db\"\\\\\n\
#   && kubectl exec -it \$pod -- curl -s http://api-service:3000/health/db|jq\\\\\n\
#   && info \"\$pod http://api-service:3000/products\"\\\\\n\
#   && kubectl exec -it \$pod -- curl -s http://api-service:3000/products|jq\\\\\n\
#   && info \"\$pod http://api-service:3000/products/1\"\\\\\n\
#   && kubectl exec -it \$pod -- curl -s http://api-service:3000/products/1|jq
# done
# "
}


export BACKEND_APPNAME=product-catalog-backend
function backend {
install_postgres $GLOBAL_VERSION
}

function build_backend {
(
image_version=$1
if [ -z "$image_version" ];then image_version=latest;fi
if [ ! -d ./backend ];then echo must be at project root && return 1;fi
NOCACHE=
if [[ $sdenv = 'prod' ]];then NOCACHE=--no-cache;fi
appname=$BACKEND_APPNAME
echo -e \\nBuilding $appname:$image_version

docker build -t $appname:$image_version $NOCACHE backend\
  || return 1

docker tag $appname $DOCKERHUB/$appname
docker tag $appname:$image_version $DOCKERHUB/$appname:$image_version
docker push $DOCKERHUB/$appname
docker push $DOCKERHUB/$appname:$image_version

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

formatrun <<'EOF'
kubectl apply -f ./backend/k8s/postgres.yaml\
  && kubectl wait --namespace $GLOBAL_NAMESPACE --for=condition=Ready pod -l app=postgres --timeout=60s
EOF

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

function green { println '\e[32m%s\e[m' "$*"; }
function yellow { println '\e[33m%s\e[m' "$*"; }
function blue { println '\e[34m%s\e[m' "$*"; }                                                                                    
function red { println '\e[31m%s\e[m' "$*"; }
function info { echo; echo "$(tput setaf 0;tput setab 3)$(date "+%Y-%m-%d %H:%M:%S") INFO: ${*}$(tput sgr 0)"; }
function pass { echo; echo "$(tput setaf 0;tput setab 2)$(date "+%Y-%m-%d %H:%M:%S") PASS: ${*}$(tput sgr 0)"; }
function fail { echo; echo "$(tput setaf 0;tput setab 1)$(date "+%Y-%m-%d %H:%M:%S") FAIL: ${*}$(tput sgr 0)"; }

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
