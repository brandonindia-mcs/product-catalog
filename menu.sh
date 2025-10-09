#!/bin/bash

(  
  ##################  SETUP ENV  ##################
  function setenv {
    if [ -r ./$sdenv.env ];then
      set -a
      source ./$sdenv.env || exit 1
      set +a
    else
      abort_hard "go.sh"  ${FUNCNAME[0]}: file $sdenv.env not found in $PWD || exit 1
    fi
  }
  
  function version { echo $(date +%Y%m%d)$(echo -n `__git_ps1` | sed 's/[()\/]/-/g; s/--/-/g; s/^//')$(date +%H%M) ; }
  function run_install_all() {
    GLOBAL_NAMESPACE=$1 install_webservice $2\
      && GLOBAL_NAMESPACE=$1 install_api $2\
      && GLOBAL_NAMESPACE=$1 install_postgres $2
  }
  function run_system_check { system_check && echo -e "\n\tsdenv is $sdenv\n\tDOCKERHUB is $DOCKERHUB" ; }
  function system_check { . ./bootstrap.sh && setenv; }

  function run_configure_webservice() { GLOBAL_NAMESPACE=$1 configure_webservice $2 ; }
  function run_configure_api() { GLOBAL_NAMESPACE=$1 configure_api $2 ; }
  function run_configure_postgre() { GLOBAL_NAMESPACE=$1 configure_postgre $2 ; }

  function run_frontend_18() { frontend_18 ;}
  function run_middleware() { middleware ;}
  function run_backend() { echo && echo menu.js: not overwriting postgres && return 1; backend; }

  function run_build_image_frontend() { build_image_frontend $1; }
  function run_build_image_middleware() { build_image_middleware $1; }
  function run_build_image_backend() { build_image_backend $1; }

  function run_k8s_webservice() { GLOBAL_NAMESPACE=$1 k8s_webservice ; }
  function run_k8s_api() { GLOBAL_NAMESPACE=$1 k8s_api ; }
  function run_k8s_postgres() { GLOBAL_NAMESPACE=$1 k8s_postgres ; }

  
  function run_install_webservice() { GLOBAL_NAMESPACE=$1 install_webservice $2 ; }
  function run_update_webservice() { GLOBAL_NAMESPACE=$1 update_webservice $2 ; }
  function run_install_api() { GLOBAL_NAMESPACE=$1 install_api $2; }
  function run_install_postgres() { GLOBAL_NAMESPACE=$1 install_postgres $2; }
  # function run_validate_api() { validate_api; }

  function show_menu() {
    namespace=default && image_version="$namespace-$(version)"
    echo tag is: $image_version
    echo -e "\nSelect an option:"
    echo -e "10) sys_check \t*) Exit"
    echo -e "20) install_webservice \t21) frontend_18\t22) update_webservice\t23) image_frontend  \t24) configure_webservice \t25) k8s_webservice"
    echo -e "30) install_api        \t31) middleware \t32) validate_api     \t33) image_middleware\t34) configure_api        \t35) k8s_api"
    # echo -e "40) backend \t 41) install_postgres"
    echo -e "40) install_postgres   \t               \t                     \t43) image_backend    \t44) configure_postgre   \t45) k8s_postgre"
    # echo -e "90) net new install"
    echo && read -p "Enter choice or exit: " choice

    case $choice in
      10) run_system_check ;;
      21) system_check && run_frontend_18 ;;
      20) system_check && run_install_webservice $namespace $image_version ;;
      22) system_check && run_update_webservice $namespace $image_version ;;
      24) system_check && run_configure_webservice $namespace $image_version ;;
      25) system_check && run_k8s_webservice $namespace ;;
      23) system_check && run_build_image_frontend $image_version ;;
      31) system_check && run_middleware ;;
      30) system_check && run_install_api $namespace $image_version ;;
      32) system_check && run_validate_api ;;
      34) system_check && run_configure_api $namespace $image_version ;;
      35) system_check && run_k8s_api $namespace ;;
      33) system_check && run_build_image_middleware $image_version ;;
      41) system_check && run_backend $namespace $image_version ;;
      40) system_check && run_install_postgres $namespace $image_version ;;
      44) system_check && run_configure_postgre $namespace $image_version ;;
      45) system_check && run_k8s_postgres $namespace ;;
      43) system_check && run_build_image_backend $image_version ;;
      90) system_check && run_install_all $namespace $image_version ;;
      *) echo "Exiting..."; exit 0 ;;
    esac
  }



# Loop until user exits
while true; do
    show_menu
    echo ""
done
)



