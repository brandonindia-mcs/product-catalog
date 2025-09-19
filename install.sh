#!/bin/bash


function setenv {
set -a
source ./$sdenv.env
set +a
}
setenv

function gitinit {
git init
}

function update_tag() {
  sed -i "s/^TAG=.*/TAG=$1/" .env
}

function set_keyvalue {
set -u
(
key=$1
value=$2
path=$3
sed -i "s/^$key=.*/$key=$value/" $path
)
}

function frontend {
pushd ./frontend
export NVM_HOME=$(pwd)/.nvm
export NVM_DIR=$(pwd)/.nvm
echo NVM_HOME is $NVM_HOME
if [ ! -d $NVM_DIR ];then
    install_nvm;
    installnode;
    nodever 18;
fi
npx -y create-react-app product-catalog-frontend && cd $_
cp ../package.json .
npm install react@18.2.0 react-dom@18.2.0 react-router-dom@6 axios --legacy-peer-deps
npm install
popd
build_frontend
}

function build_frontend {
set -u
(
image_version=$1
if [ -z "$image_version" ];then image_version=latest;fi
if [ ! -d ./frontend ];then echo must be at project root && return 1;fi
NOCACHE=
if [[ $sdenv = 'prod' ]];then NOCACHE=--no-cache;fi
cp -rf ./frontend/src ./frontend/product-catalog-frontend/
docker build -t product-catalog-frontend:$image_version $NOCACHE frontend\
  || return 1

docker tag product-catalog-frontend $DOCKERHUB/product-catalog-frontend
docker tag product-catalog-frontend:$image_version $DOCKERHUB/product-catalog-frontend:$image_version
docker push $DOCKERHUB/product-catalog-frontend
docker push $DOCKERHUB/product-catalog-frontend:$image_version 

echo Pushed $DOCKERHUB/product-catalog-frontend:$image_version
)
}

function deploy_webservice {
set -u
(
image_version=$1
set_keyvalue TAG $image_version ./frontend/k8s/$sdenv.env
set -a
source ./frontend/k8s/$sdenv.env
set +a
# envsubst < ./frontend/k8s/web.template.yaml | kubectl apply -f -
envsubst >./frontend/k8s/web.yaml <./frontend/k8s/web.template.yaml
# kubectl apply -f frontend/k8s/web.yaml
# kubectl port-forward svc/web-service 8081:80
# kubectl rollout restart deployment web
)
}


function install_webservice {
set -u
build_frontend $1\
  && deploy_webservice $1
}



function middleware {
pushd ./middleware
export NVM_HOME=$(pwd)/.nvm
export NVM_DIR=$(pwd)/.nvm
echo NVM_HOME is $NVM_HOME
if [ ! -d $NVM_DIR ];then
    install_nvm;
    installnode;
    nodever 18;
fi
mkdir product-catalog-middleware && cd $_
cp ../package.json .
npm install fastify pg
npm install
popd
build_middleware

}

function build_middleware {
(
image_version=$1
if [ -z "$image_version" ];then image_version=latest;fi
if [ ! -d ./middleware ];then echo must be at project root && return 1;fi
NOCACHE=
if [[ $sdenv = 'prod' ]];then NOCACHE=--no-cache;fi
docker build -t product-catalog-middleware:$image_version $NOCACHE middleware\
  || return 1

docker tag product-catalog-middleware $DOCKERHUB/product-catalog-middleware
docker tag product-catalog-middleware:$image_version $DOCKERHUB/product-catalog-middleware:$image_version
docker push $DOCKERHUB/product-catalog-middleware
docker push $DOCKERHUB/product-catalog-middleware:$image_version

echo Pushed $DOCKERHUB/product-catalog-middleware:$image_version
)
}

function deploy_api {
set -u
(
image_version=$1
set_keyvalue TAG $image_version ./middleware/k8s/$sdenv.env
set -a
source ./middleware/k8s/$sdenv.env
set +a
# envsubst < ./middleware/k8s/api.template.yaml | kubectl apply -f -
envsubst >./middleware/k8s/api.yaml <./middleware/k8s/api.template.yaml
# kubectl apply -f middleware/k8s/api.yaml
# kubectl port-forward svc/api-service 3000:3000
# kubectl rollout restart deployment api
)
}


function install_api {
set -u
build_middleware $1\
  && deploy_api $1
}

function build_backend {
image_version=$1
if [ -z "$image_version" ];then image_version=latest;fi
if [ ! -d ./backend ];then echo must be at project root && return 1;fi
NOCACHE=--no-cache 
docker build -t product-catalog-backend:$image_version $NOCACHE backend\
  || return 1

docker tag product-catalog-backend $DOCKERHUB/product-catalog-backend
docker tag product-catalog-backend:$image_version $DOCKERHUB/product-catalog-backend:$image_version
docker push $DOCKERHUB/product-catalog-backend
docker push $DOCKERHUB/product-catalog-backend:$image_version

echo Pushed $DOCKERHUB/product-catalog-backend:$image_version
}




function k8s {
# Load local image into Docker Desktop's Kubernetes
kubectl apply -f backend/k8s/postgres.yaml 
kubectl apply -f middleware/k8s/api.yaml
deploy_webservice

kubectl get pods,svc,deployment

kubectl port-forward svc/api-service 3000:3000

kubectl rollout restart deployment api

curl http://localhost:3000/health/db
curl http://localhost:3000/products

}


function local_registry {
docker run -d -p 5001:5000 --name registry registry:2
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

