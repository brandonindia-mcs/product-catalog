
function watch_ingress {
(namespace=${1:-default} &&
  info_ingress $namespace &&
  kubectl get ingress --namespace $namespace -o wide
)
}
function watch_pod {
(namespace=${1:-default} &&
  info_pod $namespace &&
  kubectl get pod --namespace $namespace -o wide|awk '{print $1" "$2" "$3" "$4" "$5" "$6" "$7}'|column -t
)
}
function watch_service {
(namespace=${1:-default} &&
  info_service $namespace &&
  kubectl get svc --namespace $namespace -o wide
)
}
function watch_ingress_nginx {
(namespace=${1:-ingress-nginx} &&
  echo -e "\n$(blue Service in $namespace)"
  kubectl get svc -n $namespace
)
}
function watch_deployment {
(namespace=${1:-default} &&
 info_deployment $namespace &&
  (echo -e "NAME\tREADY\tAGE\tCONTAINERS\tSELECTOR"
  kubectl get deployments --namespace $namespace -o json | jq -r '
    .items[] |
    . as $d |
    ($d.metadata.creationTimestamp | strptime("%Y-%m-%dT%H:%M:%SZ") | mktime) as $created |
    (now - $created) as $age_sec |
    ($age_sec / 86400) as $age_days |
    ($age_days >= 1
      | if . then "\($age_days | floor)d"
        else "\($age_sec / 3600 | floor)h"
      end) as $age |
    "\($d.kind).\($d.apiVersion)/\($d.metadata.name)\t\($d.status.readyReplicas)/\($d.spec.replicas)\t\($age)\t\($d.spec.template.spec.containers[].name)\t\($d.spec.selector.matchLabels | to_entries[] | "\(.key)=\(.value)")"
  ' 
) | column -t)
}
function banner_alt { echo; echo -n "$(tput setaf 0;tput setab 6)$(date "+%Y-%m-%d %H:%M:%S") BANNER ${FUNCNAME[2]}::${FUNCNAME[1]} ${*}$(tput sgr 0)"; }
function watch_namespace {
(namespace=${1:-default} && timeout=${2:-7} &&
 while true; do banner_alt\
                && watch_pod $namespace\
                && watch_service $namespace\
                && watch_deployment $namespace\
                && watch_ingress $namespace\
                && watch_ingress_nginx
 sleep $timeout
 done
)
}
function info_ingress {
(namespace=${1:-default} &&
  echo -e "\n$(blue Ingress in $namespace)"
)
}

function info_pod {
(namespace=${1:-default} &&
  echo -e "\n$(blue Pods in $namespace)"
)
}

function info_service {
(namespace=${1:-default} &&
  echo -e "\n$(blue Service in $namespace)"
)
}

function info_deployment {
(namespace=${1:-default} &&
  echo -e "\n$(blue Deployments in $namespace)"
)
}


function watch_deployment_2 {
(
  echo -e "TYPE/DEPLOYMENT\tNAME\tREADY\tUP-TO-DATE\tAVAILABLE\tAGE\tCONTAINERS\tSELECTOR"
  kubectl get deployments -o json | jq -r '
    .items[] |
    . as $d |
    ($d.metadata.creationTimestamp | strptime("%Y-%m-%dT%H:%M:%SZ") | mktime) as $created |
    (now - $created) as $age_sec |
    ($age_sec / 86400) as $age_days |
    ($age_days >= 1
      | if . then "\($age_days | floor)d"
        else "\($age_sec / 3600 | floor)h"
      end) as $age |
    "\($d.kind).\($d.apiVersion)/\($d.metadata.name)\t\($d.metadata.name)\t\($d.status.readyReplicas)/\($d.spec.replicas)\t\($d.status.updatedReplicas)\t\($d.status.availableReplicas)\t\($age)\t\($d.spec.template.spec.containers[].name)\t\($d.spec.selector.matchLabels | to_entries[] | "\(.key)=\(.value)")"
  '
) | column -t
}

function watch_product_catalog_2 {
(namespace=${1:-default} &&
 while true; do blue "$namespace namespace" && echo && watch_deployment && echo
# (echo "NAME READY UP-TO-DATE AVAILABLE AGE CONTAINERS SELECTOR"; kubectl get deployments --namespace $namespace -o wide --no-headers=true | awk '{print $1, $2, $3, $4, $5, $6, $8}') | column -t
 kubectl get pod,svc,ingress --namespace $namespace -o wide && sleep 7;done
)
}

  function get_pod { kubectl get pod -n $NS -l app=$1 -o jsonpath='{.items[0].metadata.name}' ; }
  function getpod { NS=$NS get_pod $1 ; }
  function getlabels { kubectl get deployment -n $NS $1 -o jsonpath="{.spec.selector.matchLabels}" ; }
  function get_last_pod { kubectl get pods -n $NS -l app=$1 --sort-by=.metadata.creationTimestamp -o jsonpath="{.items[-1].metadata.name}" ; }
  function get_last_pod_ip { kubectl get pod -n $NS $(get_last_pod $1) -o jsonpath='{.status.podIP}' ; }
  # function get_last_nginx_ip { $(NS=ingress-nginx get_last_pod ingress-nginx-controller)   --sort-by=.metadata.creationTimestamp   -o jsonpath='{.items[-1].status.podIP}' ; }
  function get_last_running_pod_ip {  kubectl get pod -n $NS --field-selector=status.phase=Running -o jsonpath='{.items[0].status.podIP}' ; }
