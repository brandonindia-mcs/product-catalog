#!/bin/bash

function gitinit {
git init
}

function frontend {
pushd $FRONTEND
export NVM_HOME=$FRONTEND/.nvm
export NVM_DIR=$NVM_HOME/.nvm
echo NVM_HOME is $NVM_HOME
if [ ! -d $NVM_DIR ];then
    install_nvm;
fi
if [ -d $NVM_DIR ];then
    installnode;
    getyarn;
    nodever 18;
    nodever;
fi
npx -y create-react-app product-catalog-frontend && cd $_
npm install react@18.2.0 react-dom@18.2.0 --legacy-peer-deps
# npm install @reach/router axios --legacy-peer-deps
npm install axios --legacy-peer-deps
# npm uninstall @reach/router
npm install react-router-dom@6 --legacy-peer-deps
popd
docker build -t product-catalog-frontend:latest frontend
}

function middleware {
pushd $MIDDLEWARE
export NVM_HOME=$MIDDLEWARE/.nvm
export NVM_DIR=$NVM_HOME/.nvm
echo NVM_HOME is $NVM_HOME
if [ ! -d $NVM_DIR ];then
    install_nvm;
fi
if [ -d $NVM_DIR ];then
    installnode;
    getyarn;
    nodever 18;
    nodever;
fi
mkdir create-react-app product-catalog-middleware && cd $_
npm init -y
npm install fastify pg
popd
docker build -t product-catalog-middleware:latest middleware

}

function backend {
docker build -t product-catalog-backend:latest backend
}

function container_build {
docker build -t product-catalog-backend:latest backend
docker build -t product-catalog-middleware:latest middleware
docker build -t product-catalog-frontend:latest frontend
}
function k8s {
kubectl apply -f backend/k8s
kubectl apply -f middleware/k8s
kubectl apply -f frontend/k8s

kubectl get pods,svc

}

gitinit
middleware
frontend
