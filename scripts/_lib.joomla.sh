#! /bin/sh
if [ "$DEBUG" = "1" ]; then set -xe; else set -e; fi

export WRAPPER="`readlink -f "$0"`"
HERE="`dirname "$WRAPPER"`"

#
# Add Joomla Instance Mounts to Nginx
#
joomla::nginx::update() {
    local soureJContent=$APPLICATION_HOME
    local destiJContent=/usr/src/joomla/$DOCKER_SERVICE_NAME
    # update nginx application conf ...
    php-fpm::nginx::conf joomla
    # determine whether php-fpm was loaded properly, or wait for it ...
    while [ "$(php-fpm::test-running)" != "0" ]; do
        echo "Waiting for Wordpress & php-fpm to start";
        sleep 10
    done
    # update nginx
    env::update
    docker service update \
        --mount-add type=bind,source=$soureJContent,destination=$destiJContent \
        $ENV_UPDATE \
        global_nginx
}

# NOT NEEDED; it's similar with http-html::nginx-proxy::update
# #
# # Add Joomla Instance to NGINX Proxy
# #
# joomla::nginx-proxy::update() {
#     http-html::nginx-proxy::update
# }

#
# Start/Create Joomla Instance
#
joomla::create() {
    local soureJContent=$APPLICATION_HOME
    local destiJContent=/usr/src/joomla/$DOCKER_SERVICE_NAME
    # default docker image
    DOCKER_IMAGE=${DOCKER_IMAGE:-php:fpm-alpine}
    # pull image
    docker pull $DOCKER_IMAGE
    # create service
    docker service create \
        --env JOOMLA_MYSQL_DB=$JOOMLA_MYSQL_DB \
        --env JOOMLA_MYSQL_USER=$JOOMLA_MYSQL_USER \
        --env JOOMLA_MYSQL_PASS=$JOOMLA_MYSQL_PASS \
        --env JOOMLA_MYSQL_HOST=$JOOMLA_MYSQL_HOST \
        --env SQL_1="mysql -u$JOOMLA_MYSQL_USER -p$JOOMLA_MYSQL_PASS -h$JOOMLA_MYSQL_HOST" \
        --env SQL_2="CREATE USER IF NOT EXISTS $JOOMLA_MYSQL_USER@'%' IDENTIFIED BY '$JOOMLA_MYSQL_PASS'" \
        --env SQL_3="CREATE DATABASE IF NOT EXISTS $JOOMLA_MYSQL_DB" \
        --env SQL_4="GRANT ALL PRIVILEGES ON $JOOMLA_MYSQL_DB.* TO '$JOOMLA_MYSQL_USER'@'%'" \
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
    # update serving system
    joomla::nginx::update
    varnish::update
    http-html::nginx-proxy::update  
}

#
# Update Joomla Instance
#
joomla::update(){
    # update service
    abstract::web::update
    # update serving system
    joomla::nginx::update
    varnish::update
    http-html::nginx-proxy::update
}

#
# Remove Joomla Instance
#
joomla::remove(){
    local destiJContent=/usr/src/joomla/$DOCKER_SERVICE_NAME
    # remove joomla service
    abstract::web::remove
    # update nginx
    rm -rf $NGINX_HOME/$(echo $APPLICATION_TLD | cut -f1 -d' ').conf
    env::update
    docker service update $ENV_UPDATE --mount-rm $destiJContent global_nginx
    # remove nginx-proxy config file
    rm -rf $NGINX_HOME_PROXY/$(echo $APPLICATION_TLD | cut -f1 -d' ').conf
    http-html::nginx-proxy::update
}