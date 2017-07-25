#! /bin/sh
if [ "$DEBUG" = "1" ]; then set -xe; else set -e; fi

export WRAPPER="`readlink -f "$0"`"
HERE="`dirname "$WRAPPER"`"

#
# @link https://docs.docker.com/engine/reference/commandline/service_create/
# @link https://docs.docker.com/engine/reference/commandline/service_update/
# @link https://docs.docker.com/engine/reference/commandline/service_inspect/
#

###################################################################################################
# Abstract; Copy this to start new apps
###################################################################################################

#
#  Create Abstract Service
#
abstract::web::create(){
    # pull image
    docker pull $DOCKER_IMAGE
    # create service
    docker service create \
        --hostname $DOCKER_HOSTNAME \
        --network web-network \
        --replicas $DOCKER_REPLICAS \
        $DOCKER_LOG_OPTIONS \
        $DOCKER_ADDITIONAL_CREATE \
        --name $DOCKER_SERVICE_NAME \
        $DOCKER_IMAGE
}

abstract::web::info(){
    local serviceName=$1
    if [ "$serviceName" = "" ]; then serviceName=$DOCKER_SERVICE_NAME; fi
    docker service ls | egrep "$serviceName"
    docker service inspect --pretty $serviceName;
    docker service ps $serviceName;
    docker ps -a | grep -v Exited |  egrep "$serviceName\.[0-9]+"
    docker ps -a | grep Exited |  egrep "$serviceName\.[0-9]+" || true
}

#
# Update Abstract Service
#
abstract::web::update(){
    docker service update \
        $ENV_UPDATE \
        --image $DOCKER_IMAGE \
        --replicas $DOCKER_REPLICAS \
        $DOCKER_ADDITIONAL_UPDATE \
        $DOCKER_SERVICE_NAME;
}


#
# Remove Abstract Service
#
abstract::web::remove(){
    local serviceName=${1:-$DOCKER_SERVICE_NAME}
    docker service rm $serviceName || true
}

#
# Test whether a php-fpm container has properly started.
#
abstract::php-fpm::test-running(){
    docker ps -a | grep -v Exited | egrep "$DOCKER_SERVICE_NAME\.[0-9]+" > /dev/null || echo 1

    docker ps -a | grep -v Exited \
        | egrep "$DOCKER_SERVICE_NAME\.[0-9]+" | awk -F" " '{print $NF}' \
        | while read container; do
            docker logs $container 2>&1 | grep "NOTICE: fpm is running" > /dev/null || echo 2
        done

    echo 0
}

################################################################################
# NGINX
################################################################################

nginx::create(){
    # pull image
    docker pull $DOCKER_IMAGE
    # DOCKER_ADDITIONAL_CREATE="--publish 80:80";
    docker service create \
        --hostname $DOCKER_HOSTNAME \
        --mount type=bind,source=$NGINX_HOME,destination=/etc/nginx/conf.d \
        --name $DOCKER_SERVICE_NAME \
        --network web-network \
        --replicas $DOCKER_REPLICAS \
        $DOCKER_LOG_OPTIONS \
        $DOCKER_ADDITIONAL_CREATE \
        $DOCKER_IMAGE;
}

nginx::info(){
    abstract::web::info
}

nginx::remove(){
    abstract::web::remove
}

nginx::update(){
    abstract::web::update
}

################################################################################
# NGINX Proxy
################################################################################

#
#
#
nginx-proxy::create(){
    # pull image
    docker pull $DOCKER_IMAGE
    # generate ssl
    openssl req -subj '/CN=qubestash.org/O=QubeStash ORG./C=RO' \
        -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout $NGINX_HOME_SSL/qubestash.key \
        -out $NGINX_HOME_SSL/qubestash.crt

    # DOCKER_ADDITIONAL_CREATE="--publish 80:80";
    docker service create \
        --env NGINX_CERTBOT_EMAIL="office@itmediaconnect.ro" \
        --hostname $DOCKER_HOSTNAME \
        --mount type=bind,source=$NGINX_HOME,destination=/etc/nginx/conf.d \
        --mount type=bind,source=$NGINX_HOME_CERTBOT,destination=/etc/letsencrypt \
        --mount type=bind,source=$NGINX_HOME_QUBE,destination=/var/qubestash \
        --mount type=bind,source=$NGINX_HOME_SSL,destination=/etc/nginx/ssl \
        --name $DOCKER_SERVICE_NAME \
        --network web-network \
        --replicas $DOCKER_REPLICAS \
        $DOCKER_LOG_OPTIONS \
        $DOCKER_ADDITIONAL_CREATE \
        $DOCKER_IMAGE;
}

nginx-proxy::info(){
    abstract::web::info
}

#
#
#
nginx-proxy::remove(){
    abstract::web::remove
}

#
# Remove NGINX Proxy service
#
nginx-proxy::update(){
    docker service update $ENV_UPDATE global_nginx-proxy
    sleep 10
    # it is not enough to update the global_nginx-proxy service, we need to re-initiate the containers as well
    docker ps -a | grep global_nginx-proxy | cut -f1 -d' ' | xargs docker rm -f
}

################################################################################
# Varnish Cache
################################################################################

#
# Varnish Instance Create
#
varnish::create(){
    # pull image
    docker pull $DOCKER_IMAGE
    # create config
    bash $HERE/varnish.vcl.sh > $VARNISH_HOME/config.vcl
    # service create
    DOCKER_ADDITIONAL_CREATE="$DOCKER_ADDITIONAL_CREATE \
        --env VCL_USE_CONFIG=yes \
        --mount type=bind,source=$VARNISH_HOME/config.vcl,destination=/etc/varnish/default.vcl \
    ";
    abstract::web::create
}

#
# Varnish Instance Info
#
varnish::info(){
    abstract::web::info
}

#
# Varnish Instace Update
#
varnish::update(){
    docker service update $ENV_UPDATE global_varnish-cache
}

#
# Varnish Instance Remove
#
varnish::remove(){
    abstract::web::remove
}

###################################################################################################
# http-html
###################################################################################################

#
# Add HTML Instance Mounts to Nginx
#
http-html::nginx::update() {
    # create nginx conf
    # 1 set application domain
    # 2 set application html path
    # 3 create nginx config file under ${domain}.conf
    cat $HERE/$NGINX_CONF \
        | sed -e "s/domain.local/$APPLICATION_TLD/g" \
        | sed -e "s/__ROOT__/\/var\/www\/html\/$(echo $APPLICATION_TLD | cut -f1 -d' ')/g" \
        > $NGINX_HOME/$(echo $APPLICATION_TLD | cut -f1 -d' ').conf

    # update nginx service with a new mount for the application
    docker service update \
        --mount-add type=bind,source=$APPLICATION_HOME,destination=/var/www/html/$(echo $APPLICATION_TLD | cut -f1 -d' ') \
        $ENV_UPDATE \
        global_nginx
}

#
# Add domain configuration to nginx proxy as well
#
http-html::nginx-proxy::update() {
    # create nginx-proxy conf
    cat $HERE/global-nginx-proxy-https-only.conf \
        | sed -e "s/localhost/$APPLICATION_TLD/g" \
        > $NGINX_HOME_PROXY/$(echo $APPLICATION_TLD | cut -f1 -d' ').conf
    nginx-proxy::update
}

#
# Create is not necesary for static websites. We will just update global_nginx service
#
http-html::create() {
    echo 
}

#
# Update Abstract Service
#
http-html::update() {
    http-html::nginx::update
    varnish::update
    http-html::nginx-proxy::update  
}


#
# Remove Abstract Service
#
http-html::remove() {
    rm -rf $NGINX_HOME/$(echo $APPLICATION_TLD | cut -f1 -d' ').conf
    rm -rf $NGINX_HOME_PROXY/$(echo $APPLICATION_TLD | cut -f1 -d' ').conf
    docker service update --mount-rm /var/www/html/$(echo $APPLICATION_TLD | cut -f1 -d' ') $ENV_UPDATE global_nginx
    varnish::update
    nginx-proxy::update
}

################################################################################
# Wordpress
################################################################################

#
# Add Joomla Instance Mounts to Nginx
#
joomla::nginx::update(){
    # create nginx conf
    # 1 set application domain
    # 2 set application html path
    # 3 create nginx config file under ${domain}.conf
    cat $HERE/$NGINX_CONF \
        | sed -e "s/wordpress.local/$APPLICATION_TLD/g" \
        | sed -e "s/php.local/$DOCKER_SERVICE_NAME/g" \
        | sed -e "s/__ROOT__/\/usr\/src\/wordpress\/$DOCKER_SERVICE_NAME/g" \
        > $NGINX_HOME/$(echo $APPLICATION_TLD | cut -f1 -d' ').conf
  
    while [ "$(abstract::php-fpm::test-running)" != "0" ]; do
        echo "Waiting for Wordpress & php-fpm to start";
        sleep 10
    done

    # update nginx
    local soureJContent=$APPLICATION_HOME
    local destiJContent=/usr/src/joomla/$DOCKER_SERVICE_NAME
    docker service update \
        --mount-add type=bind,source=$soureJContent/themes,destination=$destiJContent \
        $ENV_UPDATE \
        global_nginx
}

#
# Add Joomla Instance to NGINX Proxy
#
joomla::nginx-proxy::update(){
    http-html::nginx-proxy::update
}

#
# Start/Create Joomla Instance
#
joomla::create(){
    local soureJContent=$APPLICATION_HOME
    local destiJContent=/usr/src/joomla/$DOCKER_SERVICE_NAME
    # default docker image
    DOCKER_IMAGE=${DOCKER_IMAGE:-php:fpm-alpine}
    # pull image
    docker pull $DOCKER_IMAGE
    # create volume
    docker volume create --name $DOCKER_SERVICE_NAME
    docker service create \
        --env JOOMLA_MYSQL_DB=$JOOMLA_MYSQL_DB \
        --env JOOMLA_MYSQL_USER=$JOOMLA_MYSQL_USER \
        --env JOOMLA_MYSQL_PASS=$JOOMLA_MYSQL_PASS \
        --env JOOMLA_MYSQL_HOST=$JOOMLA_MYSQL_HOST \
        --env SQL_1="mysql -u$JOOMLA_MYSQL_USER -p$JOOMLA_MYSQL_PASS -h$JOOMLA_MYSQL_HOST" \
        --env SQL_2="CREATE USER IF NOT EXISTS $JOOMLA_MYSQL_USER@'%' IDENTIFIED BY '$JOOMLA_MYSQL_PASS'" \
        --env SQL_3="CREATE DATABASE IF NOT EXISTS $JOOMLA_MYSQL_DB" \
        --env SQL_4="GRANT ALL PRIVILEGES ON $WORDPRESS_MYSQL_DB.* TO '$JOOMLA_MYSQL_USER'@'%'" \
        --env SQL_5="ALTER USER $JOOMLA_MYSQL_USER@'%' IDENTIFIED BY '$JOOMLA_MYSQL_PASS' " \
        --hostname $DOCKER_HOSTNAME \
        --name $DOCKER_SERVICE_NAME \
        --network web-network \
        --mount type=bind,source=$soureJContent,destination=$destiJContent \
        --mount type=bind,source=/etc/timezone,destination=/etc/timezone \
        --mount type=bind,source=/etc/localtime,destination=/etc/localtime \
        --replicas $DOCKER_REPLICAS \
        $DOCKER_LOG_OPTIONS \
        $DOCKER_ADDITIONAL_CREATE \
        $DOCKER_IMAGE

    wordpress::nginx::update
    varnish::update
    joomla::nginx-proxy::update  
}

#
# Update Joomla Instance
#
joomla::update(){
    # update service
    abstract::web::update
    # update nginx
    joomla::nginx::update
    # update varnis
    varnish::update
    # update nginx-proxy
    joomla::nginx-proxy::update
}

#
# Remove Joomla Instance
#
joomla::remove(){
    # remove joomla service
    abstract::web::remove

    # remove nginx config file
    rm -rf $NGINX_HOME/$(echo $APPLICATION_TLD | cut -f1 -d' ').conf
    # update nginx
    docker service update \
        $ENV_UPDATE \
        --mount-rm /usr/src/joomla/$DOCKER_SERVICE_NAME \
        global_nginx

    # remove nginx-proxy config file
    rm -rf $NGINX_HOME_PROXY/$(echo $APPLICATION_TLD | cut -f1 -d' ').conf
    joomla::nginx-proxy::update
}


################################################################################
# Wordpress
################################################################################

#
# Add Wordpress Instance Mounts to Nginx
#
wordpress::nginx::update(){
    # create nginx conf
    # 1 set application domain
    # 2 set application html path
    # 3 create nginx config file under ${domain}.conf
    cat $HERE/$NGINX_CONF \
        | sed -e "s/wordpress.local/$APPLICATION_TLD/g" \
        | sed -e "s/php.local/$DOCKER_SERVICE_NAME/g" \
        | sed -e "s/__ROOT__/\/usr\/src\/wordpress\/$DOCKER_SERVICE_NAME/g" \
        > $NGINX_HOME/$(echo $APPLICATION_TLD | cut -f1 -d' ').conf
  
    while [ "$(abstract::php-fpm::test-running)" != "0" ]; do
        echo "Waiting for Wordpress & php-fpm to start";
        sleep 10
    done

    # update nginx
    local soureWPContent=$APPLICATION_HOME/wp-content
    local destiWpContent=/usr/src/wordpress/$DOCKER_SERVICE_NAME
    docker service update \
        --mount-add type=volume,source=$DOCKER_SERVICE_NAME,destination=$destiWpContent \
        --mount-add type=bind,source=$soureWPContent/themes,destination=$destiWpContent/wp-content/themes \
        --mount-add type=bind,source=$soureWPContent/uploads,destination=$destiWpContent/wp-content/uploads \
        $ENV_UPDATE \
        global_nginx
}

#
# Add Wordpress Instance to NGINX Proxy
#
wordpress::nginx-proxy::update(){
    http-html::nginx-proxy::update
}

#
# Start/Create Wordpress Instance
#
wordpress::create(){
    # pull image
    docker pull $DOCKER_IMAGE
    # create volume
    docker volume create --name $DOCKER_SERVICE_NAME
    docker service create \
        --env WORDPRESS_DOMAIN_PROTO=$WORDPRESS_DOMAIN_PROTO \
        --env WORDPRESS_MYSQL_DB=$WORDPRESS_MYSQL_DB \
        --env WORDPRESS_MYSQL_USER=$WORDPRESS_MYSQL_USER \
        --env WORDPRESS_MYSQL_PASS=$WORDPRESS_MYSQL_PASS \
        --env WORDPRESS_MYSQL_HOST=$WORDPRESS_MYSQL_HOST \
        --env WORDPRESS_TABLE_PREFIX=$WORDPRESS_TABLE_PREFIX \
        --env WORDPRESS_PLUGINS="$WORDPRESS_PLUGINS" \
        --env SQL_1="mysql -u$WORDPRESS_MYSQL_USER -p$WORDPRESS_MYSQL_PASS -h$WORDPRESS_MYSQL_HOST" \
        --env SQL_2="CREATE USER IF NOT EXISTS $WORDPRESS_MYSQL_USER@'%' IDENTIFIED BY '$WORDPRESS_MYSQL_PASS'" \
        --env SQL_3="CREATE DATABASE IF NOT EXISTS $WORDPRESS_MYSQL_DB" \
        --env SQL_4="GRANT ALL PRIVILEGES ON $WORDPRESS_MYSQL_DB.* TO '$WORDPRESS_MYSQL_USER'@'%'" \
        --env SQL_5="ALTER USER $WORDPRESS_MYSQL_USER@'%' IDENTIFIED BY '$WORDPRESS_MYSQL_PASS' " \
        --hostname $DOCKER_HOSTNAME \
        --name $DOCKER_SERVICE_NAME \
        --network web-network \
        --mount type=volume,source=$DOCKER_SERVICE_NAME,destination=/usr/src/wordpress \
        --mount type=bind,source=$APPLICATION_HOME/wp-content/themes,destination=/usr/src/wordpress/wp-content/themes \
        --mount type=bind,source=$APPLICATION_HOME/wp-content/uploads,destination=/usr/src/wordpress/wp-content/uploads \
        --replicas $DOCKER_REPLICAS \
        $DOCKER_LOG_OPTIONS \
        $DOCKER_ADDITIONAL_CREATE \
        $DOCKER_IMAGE

    wordpress::nginx::update
    varnish::update
    wordpress::nginx-proxy::update  
}

#
# Update Wordpress Instance
#
wordpress::update(){
    # update service
    docker service update \
        $ENV_UPDATE \
        --image $DOCKER_IMAGE \
        --mount-add type=bind,source=$APPLICATION_HOME/wp-content/themes,destination=/usr/src/wordpress/wp-content/themes \
        --mount-add type=bind,source=$APPLICATION_HOME/wp-content/uploads,destination=/usr/src/wordpress/wp-content/uploads \
        --replicas $DOCKER_REPLICAS \
        $DOCKER_ADDITIONAL_UPDATE \
        $DOCKER_SERVICE_NAME

    wordpress::nginx::update
    varnish::update
    wordpress::nginx-proxy::update  
}

#
# Remove Wordpress Instance
#
wordpress::remove(){
    # remove wordpress service
    abstract::web::remove

    # remove nginx config file
    rm -rf $NGINX_HOME/$(echo $APPLICATION_TLD | cut -f1 -d' ').conf
    # update nginx
    docker service update \
        $ENV_UPDATE \
        --mount-rm /usr/src/wordpress/$DOCKER_SERVICE_NAME/wp-content/themes \
        --mount-rm /usr/src/wordpress/$DOCKER_SERVICE_NAME/wp-content/uploads \
        --mount-rm /usr/src/wordpress/$DOCKER_SERVICE_NAME \
        global_nginx

    # remove nginx-proxy config file
    rm -rf $NGINX_HOME_PROXY/$(echo $APPLICATION_TLD | cut -f1 -d' ').conf
    docker service update $ENV_UPDATE global_nginx-proxy

    # remove wordpress volume
    # sleep 10
    # docker volume rm $DOCKER_SERVICE_NAME
}