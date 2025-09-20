#!/bin/bash


function setenv {
set -a
source ./$sdenv.env
set +a
}
setenv

function set_keyvalue {
set -u
(
key=$1
value=$2
path=$3
sed -i "s/^$key=.*/$key=$value/" $path
)
}

export FRONTEND_APPNAME=product-catalog-frontend
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
npx -y create-react-app $FRONTEND_APPNAME && cd $_
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
appname=$FRONTEND_APPNAME
echo -e \\n Building $appname:$image_version

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
k8s_webservice
)
}

function k8s_webservice {
# kubectl apply -f ./frontend/k8s/web.yaml\
#   && kubectl wait  --namespace default --for=condition=Ready pod -l app=web --timeout=60s\
#   && kubectl port-forward svc/web-service 8081:80

echo -e "
kubectl apply -f ./frontend/k8s/web.yaml\\\\\n\
 && kubectl wait  --namespace default --for=condition=Ready pod -l app=web --timeout=60s\\\\\n\
 && kubectl port-forward svc/web-service 8081:80
"
# kubectl rollout restart deployment web
}

export MIDDLEWARE_APPNAME=product-catalog-middleware
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
npm install fastify pg
npm install @fastify/cors
npm install
mkdir $MIDDLEWARE_APPNAME && cd $_
cp ../package.json .
npm install
popd
build_middleware latest

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
# kubectl rollout restart deployment api
k8s_api
)
}

function k8s_api {
echo -e "
kubectl apply -f ./middleware/k8s/api.yaml\\\\\n\
  && kubectl wait  --namespace default --for=condition=Ready pod -l app=api --timeout=60s\\\\\n\
  && kubectl port-forward svc/api-service 3000:3000
"
# kubectl apply -f ./middleware/k8s/api.yaml\
#   && kubectl wait  --namespace default --for=condition=Ready pod -l app=api --timeout=60s\
#   && kubectl port-forward svc/api-service 3000:3000
validate_api
# kubectl rollout restart deployment api
}

function validate_api {
echo -e "
curl http://localhost:3000/health/db\\\\\n\
&& curl http://localhost:3000/products\\\\\n\
&& curl http://localhost:3000/products/1\\\\\n\
&& weblist=\$(kubectl get pods --no-headers -o custom-columns=":metadata.name"|$(which grep) -E ^web) &&\\\\\n\
for pod in \${weblist[@]};do
  echo -e \"\\\\n\$pod http://api-service:3000/products\"
  kubectl exec -it \$pod -- curl http://api-service:3000/products|jq
  kubectl exec -it \$pod -- curl http://api-service:3000/products/1|jq
done
"
# curl http://localhost:3000/health/db\
# && curl http://localhost:3000/products\
# && curl http://localhost:3000/products/1\
# && weblist=$(kubectl get pods --no-headers -o custom-columns=:metadata.name|/usr/bin/grep -E ^web) &&\
# for pod in ${weblist[@]};do
#   echo -e "\n$pod http://api-service:3000/products"
#   kubectl exec -it $pod -- curl http://api-service:3000/products|jq
#   kubectl exec -it $pod -- curl http://api-service:3000/products/1|jq
# done
}


function watch_productcatelog {
while true; do echo && blue $(date) && kubectl get all -o wide && sleep 5;done
}
function install_webservice {
set -u
build_frontend $1\
  && deploy_webservice $1
}

function install_api {
set -u
build_middleware $1\
  && deploy_api $1
}

function go {
set -u
install_webservice $1\
  && install_api $1
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
install_api
install_webservice

kubectl get pods,svc,deployment -o wide


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

