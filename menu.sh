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
  function run_upgrade_webservice() { GLOBAL_NAMESPACE=$1 upgrade_webservice $2 ; }
  function run_install_webservice() { GLOBAL_NAMESPACE=$1 install_webservice $2 ; }
  function run_configure_webservice() { GLOBAL_NAMESPACE=$1 configure_webservice $2 ; }
  function run_frontend() { frontend ;}
  function run_middleware() { middleware ;}
  function run_install_api() { GLOBAL_NAMESPACE=$1 install_api $2; }
  function run_configure_api() { GLOBAL_NAMESPACE=$1 configure_api $2 ; }
  function run_validate_api() { validate_api; }
  function run_backend() { echo && echo menu.js: not overwriting postgres && return 1; backend; }
  function run_install_postgres() { echo && echo menu.js: not overwriting postgres && return 1; GLOBAL_NAMESPACE=$1 install_postgres $2; }
  function run_configure_postgre() { GLOBAL_NAMESPACE=$1 configure_postgre $2 ; }
  
  function show_menu() {
    namespace=default && image_version="$namespace-$(version)"
    echo tag is: $image_version
    echo -e "\nSelect an option:"
    echo -e "10) sys_check \t*) Exit"
    echo -e "20) frontend \t21) install_webservice \t22) upgrade_webservice \t23) configure_webservice"
    echo -e "30) middleware \t31) install_api \t32) validate_api \t33) configure_api"
    # echo -e "40) backend \t 41) install_postgres"
    echo -e "43) run_configure_postgre"
    # echo -e "90) net new install"
    read -p "Enter choice or exit: " choice

    case $choice in
      10) run_system_check ;;
      20) system_check && run_frontend ;;
      21) system_check && run_install_webservice $namespace $image_version ;;
      22) system_check && run_upgrade_webservice $namespace $image_version ;;
      23) system_check && run_configure_webservice $namespace $image_version ;;
      30) system_check && run_middleware ;;
      31) system_check && run_install_api $namespace $image_version ;;
      32) system_check && run_validate_api ;;
      33) system_check && run_configure_api $namespace $image_version ;;
      40) system_check && run_backend $namespace $image_version ;;
      41) system_check && run_install_postgres $namespace $image_version ;;
      43) system_check && run_configure_postgre $namespace $image_version ;;
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



