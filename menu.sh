#!/bin/bash

(

####################  ONE OFFS ################## 
  # function get_last_nginx_ip { kubectl get pods -n ingress-nginx   -l app.kubernetes.io/name=ingress-nginx   --sort-by=.metadata.creationTimestamp   -o jsonpath='{.items[-1].status.podIP}' ; }
  function web_out {
  pause  "kubectl describe svc web-service"
    kubectl describe svc web-service
  pause  "kubectl get deployment web -o yaml"
    kubectl get deployment web -o yaml | yq
  pause  "kubectl get svc web-service -o yaml"
    kubectl get svc web-service -o yaml | yq
  pause  "kubectl get ingress web-service-ingress -o yaml"
    kubectl get ingress web-service-ingress -o yaml | yq
  }

  function api_out {
  pause  "kubectl describe svc api-service"
    kubectl describe svc api-service
  pause  "kubectl get deployment api -o yaml"
    kubectl get deployment api -o yaml | yq
  pause  "kubectl get svc api-service -o yaml"
    kubectl get svc api-service -o yaml | yq
  pause  "kubectl get ingress api-service-ingress -o yaml"
    kubectl get ingress api-service-ingress -o yaml | yq
  }
  
  function chat_out {
  pause  "kubectl describe svc apt-service"
    kubectl describe svc apt-service
  pause  "kubectl get deployment apt -o yaml"
    kubectl get deployment apt -o yaml | yq
  pause  "kubectl get svc apt-service -o yaml"
    kubectl get svc apt-service -o yaml | yq
  pause  "kubectl get ingress apt-service-ingress -o yaml"
    kubectl get ingress apt-service-ingress -o yaml | yq
  }

  function postgres_out {
  pause "kubectl describe svc db-service"
    kubectl describe svc db-service
  echo get deployment postgre:
  kubectl get deployment postgre -o yaml | yq
  echo  get svc db-service:
  kubectl get svc db-service -o yaml | yq
  }

  function poll_for_deleted() {
    for kind in "$@"; do
  for name in api web api-service web-service api-service-ingress web-service-ingress; do
    echo "Waiting for $kind/$name..."
    while kubectl get "$kind" "$name" &> /dev/null; do sleep 1; done
    echo "$kind/$name deleted."
  done
    done
  }

  global_component_list=( api apt web chat )
  function delete_all {
    (
    for component in ${global_component_list[@]};do
    kubectl delete deploy $component 2>/dev/null
    kubectl delete svc $component-service 2>/dev/null
    kubectl delete ingress $component-service-ingress 2>/dev/null
    done
    )
  }

  function delete_component {
    (
    set -u
    component_list=( $1 )
    for component in ${component_list[@]};do
    kubectl delete deploy $component 2>/dev/null
    kubectl delete svc $component-service 2>/dev/null
    kubectl delete ingress $component-service-ingress 2>/dev/null
    done
    )
  }

  function delete_ingress {
    (
    set -u
    component_list=( $1 )
    for component in ${component_list[@]};do
    kubectl delete ingress $component-service-ingress 2>/dev/null
    done
    )
  }

  function delete_postgres {
    (
    for component in postgtes db;do
    kubectl delete deploy $component 2>/dev/null
    kubectl delete svc $component-service 2>/dev/null
    kubectl delete ingress $component-service-ingress 2>/dev/null
    done
    )
  }

  # function banner { echo; echo -n "$(tput setaf 0;tput setab 6)$(date "+%Y-%m-%d %H:%M:%S") BANNER ${FUNCNAME[2]}::${FUNCNAME[1]} ${*}$(tput sgr 0)"; }
  function blue { println '\e[34m%s\e[0m' "$*"; }
  function banner { echo && echo -e "$(tput setaf 0;tput setab 2) ${*}\t\t$(date "+%Y-%m-%d %H:%M:%S")$(tput sgr 0)";}
  function pause {( x=${1:-"press enter to continue"} && info $x && read x) ; }
####################  SETUP ENV  ##################
  function setenv {
    if [ -r $HOME/bin/backup-env.sh ];then bakenv;fi
    if [ -r ./$sdenv.env ];then
      set -a
      source ./$sdenv.env || exit 1
      set +a
    else
      abort_hard "menu.sh"  ${FUNCNAME[0]}: file $sdenv.env not found in $PWD || exit 1
    fi
  }
  function bakenv {
    /bin/bash $HOME/bin/backup-env.sh /home/developer/devnet/offline-product-catalog/env.backup /home/developer/product-catalog
  }
  function version() { echo $(date +%Y%m%d)$(echo -n `__git_ps1` | sed 's/[()\/]/-/g; s/--/-/g; s/^//')$(date +%H%M) ; }
  function parent() { green ${FUNCNAME[1]} ; }
  function run_system_check() { parent && system_check && echo -e "\n\tsdenv is $sdenv\n\tDOCKERHUB is $DOCKERHUB" ; }
  function system_check() { setenv && . ./bootstrap.sh && . ./bootstrap-validate.sh 2>/dev/null || echo ./bootstrap-validate.sh not found... continuing ; }

. ./menu/registry_helpers.sh
. ./menu/display_menu.sh
. ./menu/show_menu.sh
####################  RUN METHODS ARE DRIVERS FOR BOOTSTRAP  ##################
  function run_install_all() {
    GLOBAL_NAMESPACE=$1 update_webservice $2\
      && GLOBAL_NAMESPACE=$1 install_middleware $2\
      && GLOBAL_NAMESPACE=$1 install_postgres $2
  }
  function run_configure_webservice() { parent && GLOBAL_NAMESPACE=$1 configure_webservice $2 ; }
  function run_configure_middleware() { parent && GLOBAL_NAMESPACE=$1 configure_middleware $1 $2 ; }
  function run_configure_api() {        parent && GLOBAL_NAMESPACE=$1 configure_middleware_api $2 ; }
  function run_configure_chat() {       parent && GLOBAL_NAMESPACE=$1 configure_middleware_chat $2 ; }
  function run_configure_apt() {        parent && GLOBAL_NAMESPACE=$1 configure_middleware_apt $2 ; }
  function run_configure_data() {       parent && GLOBAL_NAMESPACE=$1 configure_middleware_data $2 ; }
  function run_configure_postgres() {   parent && GLOBAL_NAMESPACE=$1 configure_postgres $2 ; }
  function run_configure_ingress() {    parent && GLOBAL_NAMESPACE=$1 configure_ingress $2 ; }
  function run_configure() {            parent && GLOBAL_NAMESPACE=$1 configure $2 ; }

  function run_frontend_18() {          parent && echo menu disabled, manual run only: frontend_18 && return 1 ;}
  function run_middleware() {           parent && GLOBAL_NAMESPACE=$1 middleware ;}
  function run_middleware_c() {         parent && GLOBAL_MIDDLEWARE_COMPONENT_LIST=$list middleware ;}
  function run_frontend_update() {      parent && frontend_update ; }
  function run_frontend_update_c() {    parent && GLOBAL_FRONTEND_COMPONENT_LIST=$list frontend_update ;}
  function run_backend() {              parent && backend; }

  function run_image_frontend() {       parent && build_image_frontend $2   && run_configure_webservice $1 $2 ; }
  function run_image_middleware() {     parent && build_image_middleware $2 && run_configure_middleware $1 $2 ; }
  function run_image_backend() {        parent && build_image_backend $2  && run_configure_postgres $1 $2 ; }

  function run_k8s_all() { run_k8s_webservice $1 $2 && run_k8s_api && run_configure_api $1 $2 && run_k8s_apt && run_configure_apt $1 $2 && run_k8s_postgres $1 $2; }
  function run_k8s_ingress() {    parent &&                             run_configure_ingress $1 $2     && GLOBAL_NAMESPACE=$1 k8s_ingress ; }
  # function run_k8s_webservice() { parent && run_image_frontend $2   &&  run_configure_webservice $1 $2  && GLOBAL_NAMESPACE=$1 k8s_webservice ; }
  function run_k8s_webservice() { parent                                                                       && GLOBAL_NAMESPACE=$1 k8s_webservice ; }
  function run_k8s_middleware() { parent && run_image_middleware $1 $2 &&  run_configure_middleware $1 $2  && GLOBAL_NAMESPACE=$1 k8s_middleware ; }

  # function run_k8s_api() {    parent && build_image_middleware_api  $2 &&  run_configure_api $1 $2    &&  configure_ingress_middleware_api  $1 $2 && GLOBAL_NAMESPACE=$1 k8s_api ; }
  # function run_k8s_chat() {   parent && build_image_middleware_chat $2 &&  run_configure_chat $1 $2   &&  configure_ingress_middleware_chat $1 $2 && GLOBAL_NAMESPACE=$1 k8s_chat ; }
  function run_k8s_api() {        parent    &&  configure_ingress_middleware_api  $1 $2 && GLOBAL_NAMESPACE=$1 k8s_api ; }
  function run_k8s_chat() {       parent    &&  configure_ingress_middleware_chat $1 $2 && GLOBAL_NAMESPACE=$1 k8s_chat ; }
  function run_k8s_apt() {        parent    &&  configure_ingress_middleware_apt  $1 $2 && GLOBAL_NAMESPACE=$1 k8s_apt ; }
  function run_k8s_data() {       parent    &&  configure_ingress_middleware_data  $1 $2 && GLOBAL_NAMESPACE=$1 k8s_data ; }

  function run_k8s_postgres() {   parent && run_image_backend $2    &&  run_configure_postgres $1 $2    && GLOBAL_NAMESPACE=$1 k8s_postgres ; }

  function run_generate_selfsignedcert_cnf() { GLOBAL_NAMESPACE=$1 generate_selfsignedcert_cnf $3 ; }
  function run_k8s_secrets() {              parent && GLOBAL_NAMESPACE=$1 middleware_secrets; }
  function run_chat_secrets() {             parent && GLOBAL_NAMESPACE=$1 chat_secrets; }

  function run_product_catalog() {          parent && GLOBAL_NAMESPACE=$1 product_catalog $2 ; }
  function run_install_webservice() {       parent && echo menu disabled, manual run only: GLOBAL_NAMESPACE=$1 install_webservice $2 && return 1 ; }
  function run_update_webservice() {        parent && GLOBAL_NAMESPACE=$1 update_webservice $2 ; }
  function run_install_middleware() {       parent && GLOBAL_NAMESPACE=$1 install_middleware $2; }
  function run_install_postgres() {         parent && GLOBAL_NAMESPACE=$1 install_postgres $2 ; }
  function run_validate_api_k8s_http() {    parent && validate_api_k8s_http ; pause; }
  function run_validate_middleware_k8s_https() {   parent && validate_middleware_k8s_https ; pause; }
  function run_validate_api_web_https() {   parent && validate_api_web_https ; pause; }
  function run_k8s_nginx() {                parent && k8s_nginx; }
  function run_validate_service_endpoints { parent && validate_service_endpoints ; }
  function run_describe_service_endpoints { parent && describe_service_endpoints ; }

  function run_deploy_middleware() { parent && run_configure_ingress $1 $2 && run_configure_middleware $1 $2 && build_image_middleware $2 && (k8s_api $2 ; k8s_apt $2) &  }


# Loop until user exits
while true; do
    show_menu
    info completed $choice @ $(date)
done


)



