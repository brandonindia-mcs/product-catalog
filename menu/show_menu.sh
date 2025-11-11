

  function yellow { println '\e[0;33m%s\e[0m' "$*"; }
  function show_menu() {
    menutop
    namespace=$GLOBAL_NAMESPACE
    # namespace=notls && export GLOBAL_NAMESPACE=$namespace
    read -p "Enter choice or exit ($(yellow $namespace)): " choice
    image_version="$namespace-$(version)"
    banner "choice #$choice (namespace: $namespace, tag: $image_version)"
    case $choice in
       frontend*)system_check && list="$(echo "$choice" | awk '{for (i=2; i<=NF; i++) print $i}')" run_frontend_update_c $namespace $image_version ;;
     middleware*)system_check && list="$(echo "$choice" | awk '{for (i=2; i<=NF; i++) print $i}')" run_middleware_c $namespace $image_version ;;
      #  mdw*)system_check && list="$(echo "$choice" | awk '{for (i=2; i<=NF; i++) print $i}')" && run_configure_${list} $namespace $image_version && run_configure_ingress $namespace $image_version && list=${list} run_middleware_c $namespace $image_version && build_image_middleware_${list} $image_version && run_k8s_${list} $namespace $image_version ;;
       mdw*)system_check && list="$(echo "$choice" | awk '{for (i=2; i<=NF; i++) print $i}')" && run_configure_${list} $namespace $image_version && run_configure_ingress $namespace $image_version && list=${list} run_middleware_c $namespace $image_version && configure_ingress_middleware_${list} $namespace $image_version && build_image_middleware_${list} $image_version ;;
       clr*)system_check && list="$(echo "$choice" | awk '{for (i=2; i<=NF; i++) print $i}')" && delete_component $list ;;
    deploy*)system_check && list="$(echo "$choice" | awk '{for (i=2; i<=NF; i++) print $i}')" && list=${list} && run_configure_${list} $namespace $image_version && run_k8s_${list} $namespace $image_version ;;
    # ns*)system_check && list="$(echo "$choice" | awk '{for (i=2; i<=NF; i++) print $i}')" && kubectl config set-context --current --namespace $list && export GLOBAL_NAMESPACE=$list ;;
       0)   run_system_check ;;
       3)   system_check && run_product_catalog $namespace $image_version ;;
      01)   system_check && run_install_all $namespace $image_version ;;
      05)   system_check && run_k8s_all $namespace $image_version ;;
      06)   system_check && run_chat_secrets $namespace $image_version ;;
      07)   system_check && run_k8s_secrets $namespace $image_version ;;
      08)   system_check && run_generate_selfsignedcert_cnf $namespace $image_version product-catalog-frontend ;;
      #  9)   system_check && run_generate_selfsignedcert_cnf $namespace $image_version product-catalog-middleware ;;
     001)   if [ -r ~/devnet/offline-product-catalog/DOCKER_LOGIN  ];then rm -rf ~/.docker && /bin/bash ~/devnet/offline-product-catalog/DOCKER_LOGIN;fi ;;
      12)   system_check && run_k8s_nginx ;;
      11)   system_check && run_configure $namespace $image_version ;;
      20)   system_check && run_frontend_update $namespace $image_version ;;
      21)   system_check && run_update_webservice $namespace $image_version ;;
      23)   system_check && run_image_frontend $namespace $image_version ;;
      24)   system_check && run_configure_webservice $namespace $image_version ;;
      25)   system_check && run_k8s_webservice $namespace $image_version ;;
      30)   system_check && run_middleware $namespace $image_version ;;
      31)   system_check && run_install_middleware $namespace $image_version ;;
      31.1) system_check && list=data run_middleware_c $namespace $image_version && build_image_middleware_data $image_version && run_configure_data $namespace $image_version && run_k8s_data $namespace $image_version ;;
      33)   system_check && run_deploy_middleware $namespace $image_version ;;
      34)   system_check && run_configure_middleware $namespace $image_version ;;
      34.1) system_check && run_configure_data $namespace $image_version ;;
     35.1)  system_check && run_k8s_data $namespace $image_version ;;
      35)   system_check && run_k8s_middleware $namespace $image_version ;;
      40)   system_check && run_install_postgres $namespace $image_version ;;
    40.0)   system_check && delete_postgres $namespace $image_version ;;
      41)   system_check && run_backend $namespace $image_version ;;
      43)   system_check && run_image_backend $image_version ;;
      44)   system_check && run_configure_postgres $namespace $image_version ;;
      45)   system_check && run_k8s_postgres $namespace $image_version ;;
      51)   system_check && run_validate_api_web_https ;;
      52)   system_check && run_validate_middleware_k8s_https ;;
      53)   system_check && validate_web ;;
      504)  system_check && ns=ingress-nginx validate_ingress controller; pause ;;
      514)  system_check && kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx; pause ;;
      524)  system_check && kubectl logs -n ingress-nginx -f pod/ingress-nginx-controller-8656776dfc-hbt8f --tail=50 ;;
      64)   system_check && run_configure_ingress $namespace $image_version ;;
      64.1) system_check && curl -vk https://product-catalog.progress.notls:32080/products \
                            --resolve product-catalog.progress.notls:32080:127.0.0.1 | jq ;;
      64.2) system_check && curl -v https://product-catalog.progress.notls:32080/products \
                            --resolve product-catalog.progress.notls:32080:127.0.0.1 | jq ;;
      64.3) system_check && curl -vk https://product-catalog.progress.notls:32000/chat \
                            --resolve product-catalog.progress.notls:32000:127.0.0.1 | jq ;;
      64.4) system_check && curl -v https://product-catalog.progress.notls:32000/chat \
                            --resolve product-catalog.progress.notls:32000:127.0.0.1 | jq ;;
      69)   system_check && run_k8s_ingress $namespace $image_version ;;
      69.1) system_check && k8s_ingress_web $namespace $image_version ;;
      69.2) system_check && k8s_ingress_data $namespace $image_version ;;
      71.1) system_check && registry_local_repository product-catalog-frontend; pause ;;
      71.2) system_check && registry_local_repository product-catalog-middleware; pause ;;
      71.3) system_check && registry_local_repository product-catalog-backend; pause ;;
      71.4) system_check && registry_local_images; pause ;;
      tag*) system_check && repo="$(echo "$choice" | awk '{for (i=2; i<=NF; i++) print $i}')" && registry_local_tags $repo; pause ;;
      75)   system_check && run_validate_service_endpoints; pause ;;
      76)   system_check && run_describe_service_endpoints; pause ;;
      77.1) system_check && pod="$(get_last_pod web)" && kubectl describe pod $pod; pause ;;
      77.2) system_check && kubectl describe deploy web; pause ;;
      77.3) system_check && kubectl logs -f pod/$(get_last_pod web) --tail=50; pause ;;
      77.4) system_check && web_out ;;
      78.1) system_check && pod="$(get_last_pod data)" && kubectl describe pod $pod; pause ;;
      78.2) system_check && kubectl describe deploy data; pause ;;
      78.3) system_check && kubectl logs -f pod/$(get_last_pod data) --tail=50; pause ;; 
      78.4) system_check && data_out ;;
      90)   system_check && delete_all ;;
      91)   system_check && delete_component web ;;
      92)   system_check && delete_component data ;;
      97)   system_check && delete_ingress web ;delete_ingress data;   ;;
      97.1) system_check && delete_ingress web   ;;
      97.2) system_check && delete_ingress data  ;;
      # 98)   system_check && kubectl delete deploy postgres ; kubectl delete svc db-service ;;
      98)   system_check && delete_component postgres ; delete_component db ;;
      99)   system_check && clear_local_registry_images ;;
      2030) system_check && run_middleware $namespace $image_version && run_frontend_update $namespace $image_version ;;
      2131) system_check && run_install_middleware $namespace $image_version && run_update_webservice $namespace $image_version ;;
      0000) system_check && kubectl describe secret; pause ;;
      0001) system_check && kubectl describe secret $FRONTEND_TLS_SECRET-tls; pause ;;
      0002) system_check && kubectl describe secret $MIDDLEWARE_TLS_SECRET $MIDDLEWARE_TLS_SECRET-tls; pause ;;
      1000) system_check && kubectl logs -l app=web; pause ;;
      1001) system_check && kubectl describe svc web-service; pause ;;
      2000) system_check && kubectl logs -l app=data; pause ;;
      2001) system_check && kubectl describe svc data-service; pause ;;
      3000) system_check && kubectl logs -l app=postgres; pause ;;
      3001) system_check && kubectl describe svc db-service; pause ;;
      *) echo "invalid entry..."; exit 0 ;;
    esac
  cleanup_k8s_recordset >/dev/null 2>&1 & 
  }
