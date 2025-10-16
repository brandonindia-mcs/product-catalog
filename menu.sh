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
  function run_configure_api() { parent && GLOBAL_NAMESPACE=$1 configure_api $2 ; }
  function run_configure_postgres() { parent && GLOBAL_NAMESPACE=$1 configure_postgres $2 ; }

  function run_frontend_18() { parent && echo menu disabled, manual run only: frontend_18 && return 1 ;}
  function run_middleware() { parent && middleware ;}
  function run_backend() { parent && backend; }

  function run_image_frontend() { parent && build_image_frontend $1; }
  function run_image_middleware() { parent && build_image_middleware $1; }
  function run_image_backend() { parent && build_image_backend $1; }

  function run_k8s_webservice() { parent && run_image_frontend $2 &&    run_configure_webservice $1 $2 && GLOBAL_NAMESPACE=$1 k8s_webservice ; }
  function run_k8s_api() {        parent && run_image_middleware $2 &&  run_configure_api $1 $2 &&        GLOBAL_NAMESPACE=$1 k8s_api ; }
  function run_k8s_postgres() {   parent && run_image_backend $2 &&     run_configure_postgres $1 $2 &&   GLOBAL_NAMESPACE=$1 k8s_postgres ; }
  function run_redeploy() { run_k8s_webservice $1 $2 && run_k8s_api $1 $2 && run_k8s_postgres $1 $2; }
  function run_generate_selfsignedcert_cnf() { generate_selfsignedcert_cnf $1 ; }

  function run_product_catalog() { parent && GLOBAL_NAMESPACE=$1 product_catalog $2 ; }
  function run_install_webservice() { parent && echo menu disabled, manual run only: GLOBAL_NAMESPACE=$1 install_webservice $2 && return 1 ; }
  function run_update_webservice() { parent && GLOBAL_NAMESPACE=$1 update_webservice $2 ; }
  function run_install_api() { parent && GLOBAL_NAMESPACE=$1 install_api $2; }
  function run_install_postgres() { parent && GLOBAL_NAMESPACE=$1 install_postgres $2; }
  function run_validate_api_k8s_http() { parent && validate_api_k8s_http; }
  function run_validate_api_k8s_https() { parent && validate_api_k8s_https; }
  function run_validate_api_web_https() { parent && validate_api_web_https; }
  function run_validate_api() { parent && validate_api; }
  function run_frontend_update() { parent && frontend_update; }
  function run_k8s_nginx() { parent && k8s_nginx; }

  function show_menu() {
    namespace=default && image_version="$namespace-$(version)"
    echo -e "\nSelect an option (namespace: $namespace, tag: $image_version):"
    echo -e " 1) sys_check \t9) certificates\t3) deploy \t5) Build & Deploy\t 11) k8s_nginx\t*) Exit"
    echo -e "20) frontend_update\t22) update_webservice\t          \t23) image_frontend  \t24) configure_webservice\t25) k8s_webservice"
    echo -e "30) middleware     \t31) install_api\t50) validate_api\t33) image_middleware\t34) configure_api       \t35) k8s_api"
    echo -e "                   \t               \t51) validate_api_web_https"
    echo -e "                   \t               \t52) validate_api_k8s_https"
    # echo -e "40) backend \t 41) install_postgres"
    echo -e "40) install_postgres\t              \t                     \t43) image_backend   \t44) configure_postgres   \t45) k8s_postgres"
    echo -e "61) reg_local_front \t62) reg_local_middle\t63) reg_local_back \t"
    # echo -e "90) net new install"
    echo && read -p "Enter choice or exit: " choice

    case $choice in
       1) run_system_check ;;
       3) system_check && run_redeploy $namespace $image_version ;;
       5) system_check && run_product_catalog $namespace $image_version ;;
       9) system_check && run_generate_selfsignedcert_cnf build_cert && ls ./build_cert ;;
      11) system_check && run_k8s_nginx ;;
      20) system_check && run_frontend_update $namespace $image_version ;;
      22) system_check && run_update_webservice $namespace $image_version ;;
      24) system_check && run_configure_webservice $namespace $image_version ;;
      25) system_check && run_k8s_webservice $namespace $image_version ;;
      23) system_check && run_image_frontend $image_version ;;
      30) system_check && run_middleware ;;
      31) system_check && run_install_api $namespace $image_version ;;
      51) system_check && run_validate_api_web_https ;;
      52) system_check && run_validate_api_k8s_https ;;
      50) system_check && run_validate_api ;;
      34) system_check && run_configure_api $namespace $image_version ;;
      35) system_check && run_k8s_api $namespace $image_version ;;
      33) system_check && run_image_middleware $image_version ;;
      41) system_check && run_backend $namespace $image_version ;;
      40) system_check && run_install_postgres $namespace $image_version ;;
      44) system_check && run_configure_postgres $namespace $image_version ;;
      45) system_check && run_k8s_postgres $namespace $image_version ;;
      43) system_check && run_image_backend $image_version ;;
      61) system_check && registry_local_repository product-catalog-frontend ;;
      62) system_check && registry_local_repository product-catalog-middleware ;;
      63) system_check && registry_local_repository product-catalog-backend ;;
      90) system_check && run_install_all $namespace $image_version ;;
      *) echo "Exiting..."; exit 0 ;;
    esac
  cleanup_k8s_recordset >/dev/null 2>&1 & 
  }



# Loop until user exits
while true; do
    show_menu
    echo ""
done
)



