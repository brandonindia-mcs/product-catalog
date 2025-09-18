#!/bin/bash

function gitinit {
git init
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
build_frontend 1.12
}

function build_frontend {
image_version=$1
if [ ! -d ./frontend ];then echo must be at project root && return 1;fi
cp -rf ./frontend/src ./frontend/product-catalog-frontend/
docker build -t product-catalog-frontend:$image_version  --no-cache frontend
docker tag product-catalog-frontend $DOCKERHUB/product-catalog-frontend
docker tag product-catalog-frontend:$image_version $DOCKERHUB/product-catalog-frontend:$image_version
docker push $DOCKERHUB/product-catalog-frontend
docker push $DOCKERHUB/product-catalog-frontend::$image_version 
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
build_middleware 1.11

}

function build_middleware {
image_version=$1
if [ ! -d ./middleware ];then echo must be at project root && return 1;fi
docker build -t product-catalog-middleware:$image_version  --no-cache middleware
docker tag product-catalog-middleware $DOCKERHUB/product-catalog-middleware
docker tag product-catalog-middleware:$image_version $DOCKERHUB/product-catalog-middleware:$image_version
docker push $DOCKERHUB/product-catalog-middleware
docker push $DOCKERHUB/product-catalog-middleware::$image_version 
}



function build_backend {
image_version=$1
if [ ! -d ./backend ];then echo must be at project root && return 1;fi
docker build -t product-catalog-backend:$image_version  --no-cache backend
}





function k8s {
# Load local image into Docker Desktop's Kubernetes
kubectl apply -f backend/k8s/postgres.yaml 
kubectl apply -f middleware/k8s/api.yaml
kubectl apply -f frontend/k8s/web.yaml

kubectl get pods,svc

kubectl port-forward svc/web-service 8081:80
}


# function app_build {
# build_backend 1.11
# build_middleware 1.11
# build_frontend 1.12

# }


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

