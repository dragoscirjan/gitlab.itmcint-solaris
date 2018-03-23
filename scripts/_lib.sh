#! /bin/sh
if [ "$DEBUG" = "1" ]; then set -xe; else set -e; fi

export WRAPPER="`readlink -f "$0"`"
HERE="`dirname "$WRAPPER"`"

#
# @link https://docs.docker.com/engine/reference/commandline/service_create/
# @link https://docs.docker.com/engine/reference/commandline/service_update/
# @link https://docs.docker.com/engine/reference/commandline/service_inspect/
#

DOCKER_LOG_OPTIONS=${DOCKER_LOG_OPTIONS:- --log-driver json-file --log-opt max-size=10m --log-opt max-file=3}

DOCKER_NGINX_REPLICAS=${DOCKER_NGINX_REPLICAS:-1}
DOCKER_CODEX_REPLICAS=${DOCKER_CODEX_REPLICAS:-1}

DOCKER_NGINX_IMAGE=${DOCKER_NGINX_IMAGE:-nginx:alpine}
# DOCKER_CODEX_IMAGE=${DOCKER_CODEX_IMAGE:-php:fpm-alpine}

APPLICATION_HOME=${APPLICATION_HOME:-$HERE/html}
APPLICATION_TLD=${APPLICATION_TLD:-domain.local www.domain.local}
APPLICATION_TLD_SSL=${APPLICATION_TLD_SSL:-domain.local}

APPLICATION_NGINX_NAME=${APPLICATION_NGINX_NAME:-application_nginx_name}
APPLICATION_CODEX_NAME=${APPLICATION_CODEX_NAME:-application_codex_name}

NGINX_CONFIG_HOME=${NGINX_CONFIG_HOME:-$HERE/data/http/nginx}

APPLICATION_NGINX_PROXY_NAME=global_nginx-proxy
NGINX_PROXY_CONFIG_HOME=${NGINX_PROXY_CONFIG_HOME:-$HERE/data/http/nginx-proxy}

#
# Test whether a php-fpm container has properly started.
#
php-fpm::test-running(){
    docker ps -a | grep -v Exited | egrep "$1\.[0-9]+" > /dev/null || echo 1

    docker ps -a | grep -v Exited \
        | egrep "$1\.[0-9]+" | awk -F" " '{print $NF}' \
        | while read container; do
            docker logs $container 2>&1 | grep "NOTICE: fpm is running" > /dev/null || echo 2
        done

    echo 0
}

# ###################################################################################################
# # Abstract; Copy this to start new apps
# ###################################################################################################

# env::update() {
#     sleep 1
#     export ENV_UPDATE="--env-add UPDATE=$(date +%s.%N)"
# }
# env::update

# #
# #  Create Abstract Service
# #
# abstract::web::create(){
#     # pull image
#     docker pull $DOCKER_IMAGE
#     # create service
#     docker service create \
#         --hostname $DOCKER_HOSTNAME \
#         --network web-network \
#         --replicas $DOCKER_REPLICAS \
#         $DOCKER_LOG_OPTIONS \
#         $DOCKER_ADDITIONAL_CREATE \
#         --name $DOCKER_SERVICE_NAME \
#         $DOCKER_IMAGE
# }

# abstract::web::info(){
#     local serviceName=$1
#     if [ "$serviceName" = "" ]; then serviceName=$DOCKER_SERVICE_NAME; fi
#     docker service ls | egrep "$serviceName"
#     docker service inspect --pretty $serviceName;
#     docker service ps $serviceName;
#     docker ps -a | grep -v Exited |  egrep "$serviceName\.[0-9]+"
#     docker ps -a | grep Exited |  egrep "$serviceName\.[0-9]+" || true
# }

# #
# # Update Abstract Service
# #
# abstract::web::update(){
#     env::update
#     docker service update \
#         $ENV_UPDATE \
#         --image $DOCKER_IMAGE \
#         --replicas $DOCKER_REPLICAS \
#         $DOCKER_ADDITIONAL_UPDATE \
#         $DOCKER_SERVICE_NAME;
# }


# #
# # Remove Abstract Service
# #
# abstract::web::remove(){
#     local serviceName=${1:-$DOCKER_SERVICE_NAME}
#     docker service rm $serviceName || true
# }

# ################################################################################
# # NGINX
# ################################################################################

# #
# # Remove NGINX Service
# #
# nginx::create(){
#     # pull image
#     docker pull $DOCKER_IMAGE
#     # DOCKER_ADDITIONAL_CREATE="--publish 80:80";
#     docker service create \
#         --hostname $DOCKER_HOSTNAME \
#         --mount type=bind,source=$NGINX_HOME,destination=/etc/nginx/conf.d \
#         --name global_nginx \
#         --network web-network \
#         --replicas $DOCKER_REPLICAS \
#         $DOCKER_LOG_OPTIONS \
#         $DOCKER_ADDITIONAL_CREATE \
#         $DOCKER_IMAGE;
# }

# #
# #
# #
# # nginx::info(){
# #     abstract::web::info
# # }

# nginx::remove(){
#     env::update
#     docker service update $ENV_UPDATE global_nginx
#     sleep 1
#     # it is not enough to update the global_nginx-proxy service, we need to re-initiate the container(s) as well
#     docker ps -a | grep global_nginx | grep -v proxy | cut -f1 -d' ' | xargs docker rm -f
# }

# nginx::update(){
#     abstract::web::update
# }

# ################################################################################
# # NGINX Proxy
# ################################################################################

# #
# # Create NGINX Proxy Service
# #
# nginx-proxy::create(){
#     # pull image
#     docker pull $DOCKER_IMAGE
#     # generate ssl
#     openssl req -subj '/CN=qubestash.org/O=QubeStash ORG./C=RO' \
#         -x509 -nodes -days 365 -newkey rsa:2048 \
#         -keyout $NGINX_HOME_SSL/qubestash.key \
#         -out $NGINX_HOME_SSL/qubestash.crt

#     # DOCKER_ADDITIONAL_CREATE="--publish 80:80";
#     docker service create \
#         --env NGINX_CERTBOT_EMAIL="office@itmediaconnect.ro" \
#         --hostname $DOCKER_HOSTNAME \
#         --mount type=bind,source=$NGINX_HOME,destination=/etc/nginx/conf.d \
#         --mount type=bind,source=$NGINX_HOME_CERTBOT,destination=/etc/letsencrypt \
#         --mount type=bind,source=$NGINX_HOME_QUBE,destination=/var/qubestash \
#         --mount type=bind,source=$NGINX_HOME_SSL,destination=/etc/nginx/ssl \
#         --name global_nginx-proxy \
#         --network web-network \
#         --replicas $DOCKER_REPLICAS \
#         $DOCKER_LOG_OPTIONS \
#         $DOCKER_ADDITIONAL_CREATE \
#         $DOCKER_IMAGE;
# }

# #
# #
# #
# # nginx-proxy::info(){
# #     abstract::web::info
# # }

# #
# # Remove NGINX Proxy Service
# #
# nginx-proxy::remove(){
#     docker service rm global_nginx-proxy
# }

# #
# # Update NGINX Proxy Service
# #
# nginx-proxy::update(){
#     env::update
#     docker service update $ENV_UPDATE global_nginx-proxy
#     sleep 1
#     # it is not enough to update the global_nginx-proxy service, we need to re-initiate the container(s) as well
#     docker ps -a | grep global_nginx-proxy | cut -f1 -d' ' | xargs docker rm -f
# }

# ################################################################################
# # Varnish Cache
# ################################################################################

# #
# # Varnish Instance Create
# #
# varnish::create(){
#     # pull image
#     docker pull $DOCKER_IMAGE
#     # create config
#     bash $HERE/varnish.vcl.sh > $VARNISH_HOME/config.vcl
#     # service create
#     export DOCKER_ADDITIONAL_CREATE="$DOCKER_ADDITIONAL_CREATE \
#         --env VCL_USE_CONFIG=yes \
#         --mount type=bind,source=$VARNISH_HOME/config.vcl,destination=/etc/varnish/default.vcl \
#     ";
#     abstract::web::create
# }

# #
# # Varnish Instance Info
# #
# varnish::info(){
#     abstract::web::info
# }

# #
# # Varnish Instace Update
# #
# varnish::update(){
#     env::update
#     docker service update $ENV_UPDATE global_varnish-cache
# }

# #
# # Varnish Instance Remove
# #
# varnish::remove(){
#     docker service rm global_varnish-cache
# }

# ###################################################################################################
# # http-html
# ###################################################################################################

# http-html::nginx::conf() {
#     # domain.local sed will set the proper domain
#     # __ROOT__ set will set the proper site root
#     cat $HERE/$NGINX_CONF \
#         | sed -e "s/domain.local/$APPLICATION_TLD/g" \
#         | sed -e "s/__ROOT__/\/var\/www\/html\/$(echo $APPLICATION_TLD | cut -f1 -d' ')/g" \
#         > $NGINX_HOME/$(echo $APPLICATION_TLD | cut -f1 -d' ').conf
# }

# #
# # Add HTML Instance Mounts to Nginx
# #
# http-html::nginx::update() {
#     local destiContent=/var/www/html/$(echo $APPLICATION_TLD | cut -f1 -d' ')
#     # update nginx application conf
#     http-html::nginx::conf
#     # update nginx service with a new mount for the application
#     env::update
#     docker service update \
#         --mount-add type=bind,source=$APPLICATION_HOME,destination=$destiContent \
#         $ENV_UPDATE \
#         global_nginx
# }

# #
# # Add domain configuration to nginx proxy as well
# #
# http-html::nginx-proxy::update() {
#     # create nginx-proxy conf
#     cat $HERE/global-nginx-proxy-https-only.conf \
#         | sed -e "s/localhost/$APPLICATION_TLD/g" \
#         > $NGINX_HOME_PROXY/$(echo $APPLICATION_TLD | cut -f1 -d' ').conf
#     # update nginx proxy
#     env::update
#     nginx-proxy::update
# }

# #
# # Create is not necesary for static websites. We will just update global_nginx service
# #
# http-html::create() {
#     echo 
# }

# #
# # Update Abstract Service
# #
# http-html::update() {
#     http-html::nginx::update
#     varnish::update
#     http-html::nginx-proxy::update  
# }


# #
# # Remove Abstract Service
# #
# http-html::remove() {
#     local destiContent=/var/www/html/$(echo $APPLICATION_TLD | cut -f1 -d' ')
#     # remove nginx config
#     rm -rf $NGINX_HOME/$(echo $APPLICATION_TLD | cut -f1 -d' ').conf
#     env::update
#     docker service update --mount-rm $destiContent $ENV_UPDATE global_nginx
#     # remove nginx-proxy config
#     rm -rf $NGINX_HOME_PROXY/$(echo $APPLICATION_TLD | cut -f1 -d' ').conf
#     nginx-proxy::update
# }

# ################################################################################
# # php-fpm
# ################################################################################

# #
# # Write NGINX Config for global_nginx service && php-fpm applicatiosns
# #
# php-fpm::nginx::conf() {
#     # domain.local sed will set the proper domain
#     # php.local sed is for php services only 
#     # __ROOT__ set will set the proper site root
#     echo $NGINX_HOME/$(echo $APPLICATION_TLD | cut -f1 -d' ').conf
#     [ -f $NGINX_CONF ] || NGINX_CONF=$HERE/$NGINX_CONF
#     cat $NGINX_CONF \
#         | sed -e "s/domain.local/$APPLICATION_TLD/g" \
#         | sed -e "s/php.local/$DOCKER_SERVICE_NAME/g" \
#         | sed -e "s/__ROOT__/\/usr\/src\/${1:-html}\/$DOCKER_SERVICE_NAME/g" \
#         > $NGINX_HOME/$(echo $APPLICATION_TLD | cut -f1 -d' ').conf
# }


