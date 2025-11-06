# (
. ./bootstrap.sh


GLOBAL_NAMESPACE=algorithmic-hue
DOCKERHUB=localhost
HUBPORT=5001
# image_version=$(date +%Y%m%d%H%M%S)


function build_web {
(
node_version=22
component=web
appname=algorithmic-hue
project=frontend
image=$appname$component

rm -rf ./$project/$appname
mkdir -p ./$project/$appname/$component
cp ./$project/src/$node_version/src/$appname/$component/* ./$project/$appname/$component/
cp -r ./$project/src/$node_version/src/$appname/$component/src ./$project/$appname/$component/
cp -r ./$project/src/20/src/pages/api/* ./$project/$appname/$component/src/api/

WEB_FRONTEND_RUNPORT_K8S=3000
# NOCACHE=--no-cache
docker build $NOCACHE\
  -t $image:$image_version\
  --build-arg EXPOSE_PORT=$WEB_FRONTEND_RUNPORT_K8S\
  $project
docker tag $image:$image_version $DOCKERHUB:$HUBPORT/$image:$image_version
docker push $DOCKERHUB:$HUBPORT/$image:$image_version

kubectl set image deployment/$image $image=$DOCKERHUB:$HUBPORT/$REPOSITORY:$TAG -n $GLOBAL_NAMESPACE\
  || echo No image to replace
)
}
##### CONFIGURE

export FRONTEND_WEB_SERVICE=web-service
export FRONTEND_WEB_SERVICE_INGRESS=$FRONTEND_WEB_SERVICE-ingress
export FRONTEND_WEB_SELECTOR=web
export FRONTEND_api_SELECTOR=web
export FRONTEND_WEB_DEPLOYMENT=algorithmic-hueweb
export FRONTEND_WEB_POD_TEMPLATE=web
export WEB_FRONTEND_RUNPORT_K8S=3000
export WEB_FRONTEND_HOSTNAME=algorithmic-hue.local

export MIDDLEWARE_DATA_ACCESS_SERVICE=data-access-service
export MIDDLEWARE_DATA_ACCESS_SERVICE_INGRESS=$MIDDLEWARE_DATA_ACCESS_SERVICE-ingress
export MIDDLEWARE_DATA_ACCESS_SELECTOR=data-access
export FRONTEND_api_SELECTOR=data-access
export MIDDLEWARE_DATA_ACCESS_DEPLOYMENT=data-access
export MIDDLEWARE_DATA_ACCESS_POD_TEMPLATE=data-access
export DATA_ACCESS_MIDDLEWARE_RUNPORT_K8S=3001
export DATA_ACCESS_MIDDLEWARE_HOSTNAME=algorithmic-hue.local
function configure_web {
(
component=web
appname=algorithmic-hue
project=frontend
pushd ./$project/k8s/$appname/$component
image=$appname$component
replicas=1
properties_file=./properties/$sdenv$component.env
>$properties_file
set_keyvalue HUB $DOCKERHUB:$HUBPORT $properties_file
set_keyvalue REPOSITORY $image $properties_file
set_keyvalue TAG $image_version $properties_file
set_keyvalue NAMESPACE $GLOBAL_NAMESPACE $properties_file
set_keyvalue REPLICAS $replicas $properties_file
set_keyvalue CONTAINER $image $properties_file

set_keyvalue SERVICE $FRONTEND_WEB_SERVICE $properties_file
set_keyvalue SELECTOR $FRONTEND_WEB_SELECTOR $properties_file
set_keyvalue DEPLOYMENT $FRONTEND_WEB_DEPLOYMENT $properties_file
set_keyvalue POD_TEMPLATE $FRONTEND_WEB_POD_TEMPLATE $properties_file

set_keyvalue RUNPORT $WEB_FRONTEND_RUNPORT_K8S $properties_file

set -a
source $properties_file || exit 1
set +a
# envsubst < ./$appname$component.template.yaml | kubectl apply -f -
envsubst >./$appname$component.yaml <./template/$appname$component.template.yaml
sed -i '/^[[:space:]]*#/d' ./$appname$component.yaml
# popd >/dev/null

# component=web
# appname=algorithmic-hue
# project=frontend
# pushd ./$project/k8s/$appname/$component
properties_file=./properties/$sdenv$component-ingress.env
>$properties_file
set_keyvalue HUB $DOCKERHUB:$HUBPORT $properties_file
set_keyvalue TAG $image_version $properties_file
set_keyvalue NAMESPACE $GLOBAL_NAMESPACE $properties_file
set_keyvalue HOSTNAME_ROOT_PATH $WEB_FRONTEND_HOSTNAME $properties_file
set_keyvalue RUNPORT_WEB_SERVICE $WEB_FRONTEND_RUNPORT_K8S $properties_file
set_keyvalue RUNPORT_DATA_ACCESS_SERVICE $DATA_ACCESS_MIDDLEWARE_RUNPORT_K8S $properties_file

set -a
source $properties_file || exit 1
set +a
envsubst >./$appname$component-ingress.yaml <./template/$appname$component-ingress.template.yaml
sed -i '/^[[:space:]]*#/d' ./$appname$component-ingress.yaml

##### K8S
kubectl apply -f ./$appname$component.yaml && green "kubectl apply -f ./$appname$component.yaml"
kubectl apply -f ./$appname$component-ingress.yaml && green "kubectl apply -f ./$appname$component-ingress.yaml"
popd >/dev/null
)
}



##### BUILD
function build_data-access {
(
component=data-access
appname=algorithmic-hue
project=middleware
rm -rf ./$project/$appname
mkdir -p ./$project/$appname/$component
component_source=$project/src/22/src/$appname/$component
cp ./$component_source/* ./$project/$appname/$component
image=$appname$component
DATAACCESS_MIDLEWARE_RUNPORT_K8S=3001

cp -p $project/src/etc/Dockerfile.$appname$component $project/Dockerfile
# NOCACHE=--no-cache
docker build $NOCACHE\
  -t $image:$image_version\
  --build-arg EXPOSE_PORT=$DATAACCESS_MIDLEWARE_RUNPORT_K8S\
  $project
docker tag $image:$image_version $DOCKERHUB:$HUBPORT/$image:$image_version
docker push $DOCKERHUB:$HUBPORT/$image:$image_version

kubectl set image deployment/$component $component=$DOCKERHUB:$HUBPORT/$REPOSITORY:$TAG -n $GLOBAL_NAMESPACE\
  || echo No image to replace
)
}


function configure_data-access {
(
component=data-access
appname=algorithmic-hue
project=middleware
pushd ./$project/k8s/$appname/$component
image=$appname$component
replicas=1
properties_file=./properties/$sdenv$component.env
>$properties_file
set_keyvalue HUB $DOCKERHUB:$HUBPORT $properties_file
set_keyvalue REPOSITORY $image $properties_file
set_keyvalue TAG $image_version $properties_file
set_keyvalue NAMESPACE $GLOBAL_NAMESPACE $properties_file
set_keyvalue REPLICAS $replicas $properties_file
set_keyvalue CONTAINER $component $properties_file

set_keyvalue SERVICE $MIDDLEWARE_DATA_ACCESS_SERVICE $properties_file
set_keyvalue SELECTOR $MIDDLEWARE_DATA_ACCESS_SELECTOR $properties_file
set_keyvalue DEPLOYMENT $MIDDLEWARE_DATA_ACCESS_DEPLOYMENT $properties_file
set_keyvalue POD_TEMPLATE $MIDDLEWARE_DATA_ACCESS_POD_TEMPLATE $properties_file

set_keyvalue RUNPORT $DATA_ACCESS_MIDDLEWARE_RUNPORT_K8S $properties_file

set -a
source $properties_file || exit 1
set +a
envsubst >./$appname$component.yaml <./template/$appname$component.template.yaml
sed -i '/^[[:space:]]*#/d' ./$appname$component.yaml

##### K8S
kubectl apply -f ./$appname$component.yaml && green "kubectl apply -f ./$appname$component.yaml"
popd >/dev/null
# }

)
}


function create_namespace {
(
component=namespace
appname=algorithmic-hue
project=middleware
pushd ./$project/k8s/$appname
properties_file=./properties/$sdenv$component.env
>$properties_file
set_keyvalue NAMESPACE $GLOBAL_NAMESPACE $properties_file

set -a
source $properties_file || exit 1
set +a
envsubst >./$appname$component.yaml <./template/$appname$component.template.yaml
sed -i '/^[[:space:]]*#/d' ./$appname$component.yaml

kubectl apply -f ./$appname$component.yaml && green "kubectl apply -f ./$appname$component.yaml"
popd >/dev/null
)
}

function _backend_ {
(
image_version=$(date +%Y%m%d%H%M%S)
GLOBAL_NAMESPACE=$GLOBAL_NAMESPACE install_postgres $image_version
)
}

# build_web
# configure_web
function _frontend_ {
image_version=$(date +%Y%m%d%H%M%S)
build_web
configure_web
}

# build_data-access
# configure_data-access
function _middleware_ {
image_version=$(date +%Y%m%d%H%M%S)
build_data-access
configure_data-access
}

function chat {
  _frontend_
  _middleware_
}
# appbuild
# )
