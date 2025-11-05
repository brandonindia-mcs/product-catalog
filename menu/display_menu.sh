
function menutop {
    menutop_2
}

function menutop_2 {
(
  function blue { println '\e[4;34m%s\e[0m' "$*"; }
  function cyan { println '\e[4;36m%s\e[0m' "$*"; }
  

echo -e "
$(cyan NPM \& Install)            $(cyan Build \(npm\))         $(cyan Ingress)        $(cyan Configure)           $(cyan k8s)            $(cyan sys)
  21)webservice_update  20)frontend_update  69)deploy all    24)webservice      5)all          0)sys_check      
  31)middleweare        30)middleware       64)configure     34)middleware     25)webservice   3)Build+Deploy 
                   middleware)build *      504)nginx         64)ingress        35)middleware   6)chat secrets
 mdw)install *                             514)logs         34.1)api         35.1)api          7)secrets              
                          $(cyan Install)          524)follow logs  34.2)chat        35.2)chat         8)generate_selfsignedcert_cnf product-catalog-frontend
 40)postgres            33)middleware      69.1)web         34.3)apt         35.3)apt          649)middleware_certificate 
40.0)delete_postgres                       69.2)api                                          11)configure
                                           69.3)apt                                        0000)show all secrets

  $(cyan Clear)       $(cyan frontend web)   $(cyan api)            $(cyan "chat/apt")      $(cyan ingress)        $(cyan backend)
  90)all      77.1)desc      78.1)desc      79.1)desc     76.1)logs      82)postgres_out
  91)web      77.2)deploy    78.2)deploy    79.2)deploy   76.3)logs
  92)api      77.3)logs      78.3)logs      79.3)logs       75)endpoints
  93)chat     77.4)out       78.4)out       79.4)out              $(cyan "           Validation           ")
  97)ingress                                79.5)mock                 51)web_https  53)web  
97.1)web                                                              52)api_https  76)describe
97.2)api                                                              64.1)validate API w/ Trusted 
97.3)chat                                                             64.2)validate API w/ resolver

$(cyan Registry): 71.1)front    71.2)middle    71.3)back  71.4)get images  tag)repo *  99)clear images
"
#       98)postgres
# web 1000/1001)info 1002)secrets
                                                                                # api 2000/2001)info 2002)secrets
# 
#  40)install_postgres   43)image_backend 44)configure_postgres  45)k8s_postgres   pg 3000/3002)info
# "
)
}

function menutop_1 {
echo -e "
    Select an option:
 0)sys_check 3)Build+Deploy   5)k8s_all   6)chat secrets 7)secrets 8/9)certs 11)configure
20)frontend   (npm)   21)update_webservice  23)image_frontend     24)config_webservice              25)k8s_webservice
30)middleware (npm)   31)install_middleware 33)image_middleware   34)config_middleware              35)k8s_middleware
2030)                 2131)                                      341)configure_middleware_api     35.1)k8s_api
middleware <PROJ>)    31.1)install_api                           342)configure_middleware_chat    35.2)k8s_chat
                      31.2)install_chat
frontend                                                         64)configure_ingress               69)k8s_ingress
web  77.1)desc 77.2)deploy    77.3)logs   77.4)web_out
                                                                web 1000/1001)info 1002)secrets
                                                                api 2000/2001)info 2002)secrets
middleware
api   78.1)desc 78.2)deploy   78.3)logs   78.4)api_out                        backend
chat  79.1)desc 79.2)deploy   79.3)logs   79.4)chat_out  79.5)mock            82)postgres_out
                                                          
ingress                                                      
76.1)logs     76.3)logs               64.1)validate API w/ Trusted      53)validate_web    
                                      64.2)validate API w/ resolver     54)validate_ingress
                                           
50)validate_api  51)validate_web_https  0000)show all secrets
52)validate_api_https  75)endpoints     76)describe
               
Clear 90)all    91)web  92)api  93)chat                           
    Ingress 97  .1)web  .2)api  .3)chat
"
#       98)postgres

# 71)reg_local_front     72)reg_local_middle 73)reg_local_back  74)get images  99)clear images
#  40)install_postgres   43)image_backend 44)configure_postgres  45)k8s_postgres   pg 3000/3002)info
# "
}
