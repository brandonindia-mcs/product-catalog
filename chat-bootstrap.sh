
function configure_middleware_chat {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace configure_middleware_chat $image_version
###################################
(
set -u
# component=chat
image_version=$1
set_keyvalue REPOSITORY $MIDDLEWARE_APPNAME-$component ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue TAG $image_version ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue HUB $DOCKERHUB:$HUBPORT ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue NAMESPACE $GLOBAL_NAMESPACE ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue REPLICAS $MIDDLEWARE_CHAT_REPLICAS ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env

set_keyvalue HTTP_PORT $CHAT_HTTP_PORT_K8S_MIDDLEWARE ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue HTTP_PORT_NAME $CHAT_HTTP_PORTNAME_K8S_MIDDLEWARE ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue HTTP_TARGET_PORT $CHAT_HTTP_RUNPORT_K8S_MIDDLEWARE ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue CONTAINER_PORT $CHAT_HTTP_RUNPORT_K8S_MIDDLEWARE ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue HTTP_NODE_PORT $CHAT_HTTP_NODEPORT_K8S_MIDDLEWARE ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue LISTEN_PORT_HTTP $CHAT_HTTP_RUNPORT_K8S_MIDDLEWARE ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env

set_keyvalue SERVICE $MIDDLEWARE_CHAT_SERVICE ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue SELECTOR $MIDDLEWARE_CHAT_SELECTOR ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue DEPLOYMENT $MIDDLEWARE_CHAT_DEPLOYMENT ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue POD_TEMPLATE $MIDDLEWARE_CHAT_POD_TEMPLATE ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue CONTAINER $MIDDLEWARE_CHAT_DEPLOYMENT ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env

set_keyvalue CORS_ORIGIN $CORS_ORIGIN_HTTP ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue TLS_MOUNT_PATH $MIDDLEWARE_TLS_MOUNT_PATH ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue TLS_CERT_VOLUME $MIDDLEWARE_TLS_CERT_VOLUME ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue SECRET $MIDDLEWARE_SECRET ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue TLS_SECRET $MIDDLEWARE_TLS_SECRET ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue CERTIFICATE cert.pem ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env
set_keyvalue CERTIFICATE_KEY key.pem ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env

set_keyvalue LOG_LEVEL $MIDDLEWARE_LOGLEVEL ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component.env

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

function configure_ingress_middleware_chat {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace configure_ingress_middleware_data $image_version
###################################
# read -p "at ${FUNCNAME[0]}"
(
set -u
# component=chat
set_keyvalue SERVICE $MIDDLEWARE_CHAT_SERVICE ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component-ingress.env
set_keyvalue INGRESS $MIDDLEWARE_CHAT_SERVICE_INGRESS ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component-ingress.env

set_keyvalue CHAT_HOSTNAME $MIDDLEWARE_CHAT_INGRESS_HOSTNAME ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component-ingress.env
set_keyvalue CHAT_PORT $CHAT_HTTP_PORT_K8S_MIDDLEWARE ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component-ingress.env
set_keyvalue CHAT_URI $CHAT_HTTP_URI_K8S_MIDDLEWARE ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component-ingress.env

set_keyvalue TLS_SECRET $MIDDLEWARE_TLS_SECRET ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component-ingress.env
set_keyvalue SSL_TRUEFALSE $MIDDLEWARE_CHAT_SERVICE_IS_TLS ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv$component-ingress.env

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

function build_image_middleware_chat {
##########  RUN COMMAND  ##########
# build_image_middleware_chat $image_version
###################################
(
image_version=$1
# component=chat
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

set_registry
runit "docker build $NOCACHE\
  -t $image:$image_version\
  --build-arg EXPOSE_PORT_HTTP=$CHAT_HTTP_NODEPORT_K8S_MIDDLEWARE\
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


function k8s_chat {
##########  RUN COMMAND  ##########
# GLOBAL_NAMESPACE=$namespace k8s_chat
###################################
(
set -e
set -a
source ./middleware/k8s/$GLOBAL_NAMESPACE/properties/$sdenv*.env || exit 1
set +a
# component=chat
runit "kubectl apply -f ./middleware/k8s/$GLOBAL_NAMESPACE/$component.yaml -f ./middleware/k8s/$GLOBAL_NAMESPACE/$component-ingress.yaml"\
    && kubectl wait --for=condition=available deployment/$component --timeout=60s
)
}

component=chat
MIDDLEWARE_CHAT_REPLICAS=1
CHAT_HTTP_PORTNAME_K8S_MIDDLEWARE=http
CHAT_HTTP_PORT_K8S_MIDDLEWARE=80
CHAT_HTTP_RUNPORT_K8S_MIDDLEWARE=2001
CHAT_HTTP_NODEPORT_K8S_MIDDLEWARE=32001
MIDDLEWARE_CHAT_SERVICE=chat-service
MIDDLEWARE_CHAT_SELECTOR=chat
MIDDLEWARE_CHAT_DEPLOYMENT=chat
MIDDLEWARE_CHAT_POD_TEMPLATE=chat

MIDDLEWARE_CHAT_SERVICE_INGRESS=$MIDDLEWARE_CHAT_SERVICE-ingress
MIDDLEWARE_CHAT_INGRESS_HOSTNAME=$DOMAIN_HOSTNAME
MIDDLEWARE_CHAT_SERVICE_IS_TLS=false
CHAT_HTTP_URI_K8S_MIDDLEWARE=/chat

#url -v -X POST $PRODUCT_CATALOG_SECURE_API_FQDN/api/chat   -H "Content-Type: application/json"   -d '{"messages":[{"role":"system","content":"You are a helpful assistant."},{"role":"user","content":"Hello"}]}'
# 

# kubectl set image deployment/$component $component=$DOCKERHUB:$HUBPORT/$REPOSITORY:$TAG -n $GLOBAL_NAMESPACE
# kubectl rollout status deployment/<deployment-name>
# runit "kubectl wait --namespace $GLOBAL_NAMESPACE\
#     --for=condition=Ready pod -l app=$MIDDLEWARE_CHAT_SELECTOR --timeout=$KUBECTL_TIMEOUT
# "