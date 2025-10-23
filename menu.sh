#!/bin/bash

(
  ##################  SETUP ENV  ##################
  function setenv {
    if [ -r ./$sdenv.env ];then
      set -a
      source ./$sdenv.env || exit 1
      set +a
    else
      abort_hard "menu.sh"  ${FUNCNAME[0]}: file $sdenv.env not found in $PWD || exit 1
    fi
  }
  function blue { println '\e[34m%s\e[0m' "$*"; }                                                                                    
  function cleanup_k8s_recordset {
  # Optional: set your namespace, or default to 'default'
  NAMESPACE="${1:-default}"
  echo "Scanning ReplicaSets in namespace: $NAMESPACE"

  # Get ReplicaSets with desired count 0
  kubectl get rs -n "$NAMESPACE" --no-headers \
    | awk '$2 == 0 {print $1}' \
    | while read -r rs_name; do
      echo "Deleting unused ReplicaSet: $rs_name"
      kubectl delete rs "$rs_name" -n "$NAMESPACE"
    done
  }

  function parent() { blue ${FUNCNAME[1]} ; }
  function version() { echo $(date +%Y%m%d)$(echo -n `__git_ps1` | sed 's/[()\/]/-/g; s/--/-/g; s/^//')$(date +%H%M) ; }
  function run_install_all() {
    GLOBAL_NAMESPACE=$1 update_webservice $2\
      && GLOBAL_NAMESPACE=$1 install_api $2\
      && GLOBAL_NAMESPACE=$1 install_postgres $2
  }
  function run_system_check() { parent && system_check && echo -e "\n\tsdenv is $sdenv\n\tDOCKERHUB is $DOCKERHUB" ; }
  function system_check() { setenv && . ./bootstrap.sh ; }

  function registry_local_images { curl -s http://localhost:5001/v2/_catalog | jq; }
  function registry_local_tags {
    REGISTRY_URL="http://localhost:5001"
    # Get list of repositories
    REPOS=$(curl -s ${REGISTRY_URL}/v2/_catalog | jq -r '.repositories[]')
    # Loop through each repo and get tags
    for repo in $REPOS; do
      echo "Repository: $repo"
      curl -s ${REGISTRY_URL}/v2/${repo}/tags/list | jq
      echo ""
    done
  }
  function registry_local_repository {
    REGISTRY_URL="http://localhost:5001"
    # Get list of repositories
    REPOS=$(curl -s ${REGISTRY_URL}/v2/_catalog | jq -r '.repositories[]')
    # Loop through each repo and get tags
      echo "Repository: $repo"
      curl -s ${REGISTRY_URL}/v2/$1/tags/list | jq
      echo ""
  }
  function run_configure_webservice() { parent && GLOBAL_NAMESPACE=$1 configure_webservice $2 ; }
  function run_configure_api() {        parent && GLOBAL_NAMESPACE=$1 configure_api $2 ; }
  function run_configure_postgres() {   parent && GLOBAL_NAMESPACE=$1 configure_postgres $2 ; }
  function run_configure() {        parent && GLOBAL_NAMESPACE=$1 configure $2 ; }

  function run_frontend_18() {  parent && echo menu disabled, manual run only: frontend_18 && return 1 ;}
  function run_middleware() {   parent && GLOBAL_NAMESPACE=$1 && middleware ;}
  function run_backend() {      parent && backend; }

  function run_image_frontend() {   parent && build_image_frontend $1; }
  function run_image_middleware() { parent && build_image_middleware $1; }
  function run_image_backend() {    parent && build_image_backend $1; }

  function run_k8s_webservice() { parent && run_image_frontend $2   &&  run_configure_webservice $1 $2  && GLOBAL_NAMESPACE=$1 k8s_webservice ; }
  function run_k8s_api() {        parent && run_image_middleware $2 &&  run_configure_api $1 $2         && GLOBAL_NAMESPACE=$1 k8s_api ; }
  function run_k8s_postgres() {   parent && run_image_backend $2    &&  run_configure_postgres $1 $2    && GLOBAL_NAMESPACE=$1 k8s_postgres ; }
  function run_redeploy_all() { run_k8s_webservice $1 $2 && run_k8s_api $1 $2 && run_k8s_postgres $1 $2; }
  function run_generate_selfsignedcert_cnf() { GLOBAL_NAMESPACE=$1 generate_selfsignedcert_cnf $3 ; }

  function run_product_catalog() {          parent && GLOBAL_NAMESPACE=$1 product_catalog $2 ; }
  function run_install_webservice() {       parent && echo menu disabled, manual run only: GLOBAL_NAMESPACE=$1 install_webservice $2 && return 1 ; }
  function run_update_webservice() {        parent && GLOBAL_NAMESPACE=$1 update_webservice $2 ; }
  function run_install_api() {              parent && GLOBAL_NAMESPACE=$1 install_api $2; }
  function run_install_postgres() {         parent && GLOBAL_NAMESPACE=$1 install_postgres $2; }
  function run_validate_api_k8s_http() {    parent && validate_api_k8s_http; }
  function run_validate_api_k8s_https() {   parent && validate_api_k8s_https; }
  function run_validate_api_web_https() {   parent && validate_api_web_https; }
  function run_validate_api() {             parent && validate_api; }
  function run_frontend_update() {          parent && frontend_update; }
  function run_k8s_nginx() {                parent && k8s_nginx; }
  function run_validate_service_endpoints { parent && validate_service_endpoints ; }
  function run_describe_service_endpoints { parent && describe_service_endpoints ; }
  function run_k8s_secrets() {              parent && GLOBAL_NAMESPACE=$1 middleware_secrets; }
  function web_out {
  echo get deployment web:
  kubectl get deployment web -o yaml | yq
  echo get svc web-service:
  kubectl get svc web-service -o yaml | yq
  echo kubectl describe svc web-service:
  kubectl describe svc web-service
  echo get ingress web-service-ingress:
  kubectl get ingress web-service-ingress -o yaml | yq
  }

  function api_out {
  echo get deployment api:
  kubectl get deployment api -o yaml | yq
  echo get svc api-service:
  kubectl get svc api-service -o yaml | yq
  echo kubectl describe svc api-service:
  kubectl describe svc api-service
  echo get ingress api-service-ingress:
  kubectl get ingress api-service-ingress -o yaml | yq
  }

  function postgres_out {
  echo get deployment postgre:
  kubectl get deployment postgre -o yaml | yq
  echo kubectl describe svc db-service:
  kubectl describe svc db-service
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

  function show_menu() {
    namespace=default && image_version="$namespace-$(version)"
    echo -e "
    Select an option (namespace: $namespace, tag: $image_version):
 0) sys_check\t3) Build & Deploy\t5) Deploy All\t7) secrets\t9) certs\t11) configure\t12) k8s_nginx\t*) Exit
20) frontend_update\t21) update_webservice\t          \t23) image_frontend  \t24) configure_webservice\t25) k8s_webservice
30) middleware     \t31) install_api\t50) validate_api\t33) image_middleware\t34) configure_api       \t35) k8s_api
                   \t2131)          \t51) validate_api_web_https\t53) validate_web
                   \t               \t52) validate_api_k8s_https\t54) validate_ingress
64) valid api
40) install_postgres\t              \t                \t43) image_backend    \t44) configure_postgres\t45) k8s_postgres
71) reg_local_front \t72) reg_local_middle\t73) reg_local_back                      \tweb 1000/1001) info 1002) secrets
80) web_out\t81) api_out\t82) postgres_out\t75) endpoints\t76) describe\t           \tapi 2000/2001) info 2002) secrets
\tclear 90) web, api, ingress 91) web 92) api 93) ingress 94) postgres            \t\t pg 3000/3002) info
\t\t                                                                                \t 0000) all secrets
"
    read -p "Enter choice or exit: " choice

    case $choice in
       0) run_system_check ;;
       1) system_check && run_install_all $namespace $image_version ;;
       3) system_check && run_product_catalog $namespace $image_version ;;
       5) system_check && run_redeploy_all $namespace $image_version ;;
       7) system_check && run_k8s_secrets $namespace $image_version ;;
       8) system_check && run_generate_selfsignedcert_cnf $namespace $image_version web ;;
       9) system_check && run_generate_selfsignedcert_cnf $namespace $image_version api ;;
      12) system_check && run_k8s_nginx ;;
      11) system_check && run_configure $namespace $image_version ;;
      20) system_check && run_frontend_update $namespace $image_version ;;
      21) system_check && run_update_webservice $namespace $image_version ;;
      24) system_check && run_configure_webservice $namespace $image_version ;;
      25) system_check && run_k8s_webservice $namespace $image_version ;;
      23) system_check && run_image_frontend $namespace $image_version ;;
      30) system_check && run_middleware $namespace $image_version ;;
      31) system_check && run_install_api $namespace $image_version ;;
      51) system_check && run_validate_api_web_https ;;
      52) system_check && run_validate_api_k8s_https ;;
      53) system_check && validate_web ;;
      53) system_check && validate_ingress ;;
      50) system_check && run_validate_api ;;
      34) system_check && run_configure_api $namespace $image_version ;;
      35) system_check && run_k8s_api $namespace $image_version ;;
      33) system_check && run_image_middleware $image_version ;;
      41) system_check && run_backend $namespace $image_version ;;
      40) system_check && run_install_postgres $namespace $image_version ;;
      44) system_check && run_configure_postgres $namespace $image_version ;;
      45) system_check && run_k8s_postgres $namespace $image_version ;;
      43) system_check && run_image_backend $image_version ;;
      64) system_check && curl -vk https://product-catalog.progress.me:32443/products \
                            --resolve product-catalog.progress.me:32443:127.0.0.1 | jq ;;
      71) system_check && registry_local_repository product-catalog-frontend ;;
      72) system_check && registry_local_repository product-catalog-middleware ;;
      73) system_check && registry_local_repository product-catalog-backend ;;
      80) system_check && web_out ;;
      81) system_check && api_out ;;
      82) system_check && postgres_out ;;
      75) system_check && run_validate_service_endpoints ;;
      76) system_check && run_describe_service_endpoints ;;
      90) system_check && kubectl delete deploy api web ; kubectl delete svc api-service web-service ; kubectl delete ingress api-service-ingress web-service-ingress ;;
      92) system_check && kubectl delete deploy api ; kubectl delete svc api-service ; kubectl delete ingress api-service-ingress ;;
      91) system_check && kubectl delete deploy web ; kubectl delete svc web-service ; kubectl delete ingress web-service-ingress ;;
      93) system_check && kubectl delete ingress api-service-ingress web-service-ingress ;;
      94) system_check && kubectl delete deploy postgres ; kubectl delete svc db-service ;;
      2131) system_check && run_install_api $namespace $image_version && run_update_webservice $namespace $image_version ;;
      0000) system_check && kubectl describe secret ;;
      1000) system_check && kubectl logs -l app=web ;;
      1001) system_check && kubectl describe svc web-service ;;
      1002) system_check && kubectl describe secret $FRONTEND_TLS_SECRET-tls ;;
      2000) system_check && kubectl logs -l app=api ;;
      2001) system_check && kubectl describe svc api-service ;;
      2002) system_check && kubectl describe secret $MIDDLEWARE_TLS_SECRET $MIDDLEWARE_TLS_SECRET-tls ;;
      3001) system_check && kubectl describe svc db-service ;;
      3000) system_check && kubectl logs -l app=postgres ;;
      *) echo "invalid entry..."; exit 0 ;;
    esac
  cleanup_k8s_recordset >/dev/null 2>&1 & 
  }

# Loop until user exits
while true; do
    show_menu
    echo ""
done


)



