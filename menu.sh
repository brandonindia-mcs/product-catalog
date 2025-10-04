#!/bin/bash

. ./bootstrap.sh
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
  function run_system_check { system_check && echo -e "\n\tsdenv is $sdenv\n\tDOCKERHUB is $DOCKERHUB" ; }
  function system_check { setenv; }
  function run_upgrade_webservice() { GLOBAL_NAMESPACE=$1 upgrade_webservice $2; }
  function run_install_webservice() { GLOBAL_NAMESPACE=$1 install_webservice $2 ;}
  function run_frontend() { frontend ;}
  function run_middleware() { middleware ;}
  function run_install_api() { GLOBAL_NAMESPACE=$1 install_api $2; }
  function run_install_postgres() { GLOBAL_NAMESPACE=$1 install_postgres $2; }
  function run_install_all() {
    GLOBAL_NAMESPACE=$1 install_webservice $2\
      && GLOBAL_NAMESPACE=$1 install_api $2\
      && GLOBAL_NAMESPACE=$1 install_postgres $2
  }
  
  function show_menu() {
    namespace=default && image_version="$namespace-$(version)"
    echo tag is: $image_version && echo

    echo "Select an option:"
    echo "1) system_check"
    echo "2) install_webservice"
    echo "3) upgrade_webservice"
    echo "4) install_api"
    echo "5) install_postgres"
    echo "6) frontend"
    echo "7) middleware"
    echo "50) net new install"
    echo "*) Exit"
    read -p "Enter choice or exit: " choice

    case $choice in
      1) run_system_check ;;
      2) system_check && run_install_webservice $namespace $image_version ;;
      3) system_check && run_upgrade_webservice $namespace $image_version ;;
      4) system_check && run_install_api $namespace $image_version ;;
      5) system_check && run_install_postgres $namespace $image_version ;;
      6) system_check && run_frontend ;;
      7) system_check && run_middleware ;;
      50) system_check && run_install_all $namespace $image_version ;;
      *) echo "Exiting..."; exit 0 ;;
    esac
  }



# Loop until user exits
while true; do
    show_menu
    echo ""
done
)



