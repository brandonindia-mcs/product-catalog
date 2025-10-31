

  function show_menu() {
    menutop
    read -p "Enter choice or exit: " choice
    namespace=default && image_version="$namespace-$(version)"
    banner "choice #$choice (namespace: $namespace, tag: $image_version)"
    case $choice in
       middleware*)system_check && list="$(echo "$choice" | awk '{for (i=2; i<=NF; i++) print $i}')" run_middleware_c $namespace $image_version ;;
       mdw*)system_check && list="$(echo "$choice" | awk '{for (i=2; i<=NF; i++) print $i}')" && run_configure_${list} $namespace $image_version && run_configure_ingress $namespace $image_version && list=${list} run_middleware_c $namespace $image_version && build_image_middleware_${list} $image_version && run_k8s_${list} $namespace $image_version ;;
       dep*)system_check && list="$(echo "$choice" | awk '{for (i=2; i<=NF; i++) print $i}')" && list=${list} && run_configure_${list} $namespace $image_version && run_k8s_${list} $namespace $image_version ;;
       0)   run_system_check ;;
       1)   system_check && run_install_all $namespace $image_version ;;
       3)   system_check && run_product_catalog $namespace $image_version ;;
       5)   system_check && run_k8s_all $namespace $image_version ;;
       6)   system_check && run_chat_secrets $namespace $image_version ;;
       7)   system_check && run_k8s_secrets $namespace $image_version ;;
       8)   system_check && run_generate_selfsignedcert_cnf $namespace $image_version product-catalog-frontend ;;
      #  9)   system_check && run_generate_selfsignedcert_cnf $namespace $image_version product-catalog-middleware ;;
       9)   system_check && node_version=20 && working_directory=middleware && GLOBAL_NAMESPACE=$namespace middleware_certificate ;;
    #  9.2)   system_check && node_version=20 && working_directory=middleware && GLOBAL_NAMESPACE=$namespace middleware_certificate ;;
    #  9.3)   system_check && node_version=20 && working_directory=middleware && GLOBAL_NAMESPACE=$namespace middleware_certificate ;;
      12)   system_check && run_k8s_nginx ;;
      11)   system_check && run_configure $namespace $image_version ;;
      20)   system_check && run_frontend_update $namespace $image_version ;;
      21)   system_check && run_update_webservice $namespace $image_version ;;
      23)   system_check && run_image_frontend $namespace $image_version ;;
      24)   system_check && run_configure_webservice $namespace $image_version ;;
      25)   system_check && run_k8s_webservice $namespace $image_version ;;
      30)   system_check && run_middleware $namespace $image_version ;;
      31)   system_check && run_install_middleware $namespace $image_version ;;
      31.1) system_check && list=api run_middleware_c $namespace $image_version && build_image_middleware_api $image_version && run_configure_api $namespace $image_version && run_k8s_api $namespace $image_version ;;
      31.2) system_check && list=chat run_middleware_c $namespace $image_version && build_image_middleware_chat $image_version && run_configure_chat $namespace $image_version && run_k8s_chat $namespace $image_version ;;
      31.3) system_check && list=apt run_middleware_c $namespace $image_version && build_image_middleware_apt $image_version && run_configure_apt $namespace $image_version && run_k8s_apt $namespace $image_version ;;
      33)   system_check && run_deploy_middleware $namespace $image_version ;;
      34)   system_check && run_configure_middleware $namespace $image_version ;;
      34.1) system_check && run_configure_api $namespace $image_version ;;
      34.2) system_check && run_configure_chat $namespace $image_version ;;
      34.3) system_check && run_configure_apt $namespace $image_version ;;
      # 341*) system_check && image_version=$(echo "$choice" | awk '{for (i=2; i<=NF; i++) print $i}') && run_configure_api $namespace $image_version ;;
      # 342*) system_check && run_configure_chat $namespace ;;
     35.1)  system_check && run_k8s_api $namespace $image_version ;;
     35.2)  system_check && run_k8s_chat $namespace $image_version ;;
     35.3)  system_check && run_k8s_apt $namespace $image_version ;;
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
      64.1) system_check && curl -vk https://product-catalog.progress.me:32443/products \
                            --resolve product-catalog.progress.me:32443:127.0.0.1 | jq ;;
      64.2) system_check && curl -v https://product-catalog.progress.me:32443/products \
                            --resolve product-catalog.progress.me:32443:127.0.0.1 | jq ;;
      64.3) system_check && curl -vk https://product-catalog.progress.me:32000/chat \
                            --resolve product-catalog.progress.me:32000:127.0.0.1 | jq ;;
      64.4) system_check && curl -v https://product-catalog.progress.me:32000/chat \
                            --resolve product-catalog.progress.me:32000:127.0.0.1 | jq ;;
      69)   system_check && run_k8s_ingress $namespace $image_version ;;
      69.1) system_check && k8s_ingress_web $namespace $image_version ;;
      69.2) system_check && k8s_ingress_api $namespace $image_version ;;
      69.3) system_check && k8s_ingress_apt $namespace $image_version ;;
      71)   system_check && registry_local_repository product-catalog-frontend ;;
      72)   system_check && registry_local_repository product-catalog-middleware ;;
      73)   system_check && registry_local_repository product-catalog-backend ;;
      74)   system_check && registry_local_images ;;
      75)   system_check && run_validate_service_endpoints; pause ;;
      76)   system_check && run_describe_service_endpoints; pause ;;
      77.1) system_check && pod="$(get_last_pod web)" && kubectl describe pod $pod; pause ;;
      77.2) system_check && kubectl describe deploy web; pause ;;
      77.3) system_check && kubectl logs -f pod/$(get_last_pod web) --tail=50; pause ;;
      77.4) system_check && web_out ;;
      78.1) system_check && pod="$(get_last_pod api)" && kubectl describe pod $pod; pause ;;
      78.2) system_check && kubectl describe deploy api; pause ;;
      78.3) system_check && kubectl logs -f pod/$(get_last_pod api) --tail=50; pause ;; 
      78.4) system_check && api_out ;;
      79.1) system_check && pod="$(get_last_pod apt)" && kubectl describe pod $pod; pause ;;
      79.2) system_check && kubectl describe deploy apt; pause ;;
      79.3) system_check && kubectl logs -f pod/$(get_last_pod apt) --tail=100; pause ;;
      79.4) system_check && chat_out ;;
      79.5) system_check && validate_insecure_chat; pause ;; #
      90)   system_check && delete_all ;;
      91)   system_check && delete_component web ;;
      92)   system_check && delete_component api ;;
      93)   system_check && delete_component chat ;;
      97)   system_check && delete_ingress web ;delete_ingress api; delete_ingress chat;delete_ingress apt;   ;;
      97.1) system_check && delete_ingress web   ;;
      97.2) system_check && delete_ingress api  ;;
      97.3) system_check && delete_ingress chat ;;
      # 98)   system_check && kubectl delete deploy postgres ; kubectl delete svc db-service ;;
      98)   system_check && delete_component postgres ; delete_component db ;;
      99)   system_check && clear_local_registry_images ;;
      2030) system_check && run_middleware $namespace $image_version && run_frontend_update $namespace $image_version ;;
      2131) system_check && run_install_middleware $namespace $image_version && run_update_webservice $namespace $image_version ;;
      0000) system_check && kubectl describe secret; pause ;;
      1000) system_check && kubectl logs -l app=web; pause ;;
      1001) system_check && kubectl describe svc web-service; pause ;;
      1002) system_check && kubectl describe secret $FRONTEND_TLS_SECRET-tls; pause ;;
      2000) system_check && kubectl logs -l app=api; pause ;;
      2001) system_check && kubectl describe svc api-service; pause ;;
      2002) system_check && kubectl describe secret $MIDDLEWARE_TLS_SECRET $MIDDLEWARE_TLS_SECRET-tls; pause ;;
      3001) system_check && kubectl describe svc db-service; pause ;;
      3000) system_check && kubectl logs -l app=postgres; pause ;;
      *) echo "invalid entry..."; exit 0 ;;
    esac
  cleanup_k8s_recordset >/dev/null 2>&1 & 
  }
