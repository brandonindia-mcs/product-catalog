#!/bin/bash

function gitinit {
git init
}
function middleware {
pushd $MIDDLEWARE
export NVM_HOME=$MIDDLEWARE/.nvm

echo NVM_HOME is $NVM_HOME
if [ ! -d $NVM_HOME ];then
    install_nvm;
fi
if [ -d $NVM_HOME ];then
    installnode;
fi

npm init -y
npm install fastify pg
popd
docker build -t product-catalog-middleware:latest middleware

}

function frontend {
pushd $FRONTEND
export NVM_HOME=$FRONTEND/.nvm

echo NVM_HOME is $NVM_HOME
if [ ! -d $NVM_HOME ];then
    install_nvm;
fi
if [ -d $NVM_HOME ];then
    installnode;
fi
npx -y create-react-app .
npm install @reach/router axios
popd
}
function backend {
docker build -t product-catalog-backend:latest backend
}
function k8s {
# from project root
docker build -t product-catalog-backend:latest backend
docker build -t product-catalog-middleware:latest middleware
docker build -t product-catalog-frontend:latest frontend

kubectl apply -f backend/k8s
kubectl apply -f middleware/k8s
kubectl apply -f frontend/k8s

kubectl get pods,svc

}

gitinit
middleware
frontend
