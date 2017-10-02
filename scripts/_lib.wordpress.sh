#! /bin/sh
if [ "$DEBUG" = "1" ]; then set -xe; else set -e; fi

export WRAPPER="`readlink -f "$0"`"
HERE="`dirname "$WRAPPER"`"

#
# Add Wordpress Instance Mounts to Nginx
#
wordpress::nginx::update() {
    local soureWPContent=$APPLICATION_HOME/wp-content
    local destiWpContent=/usr/src/wordpress/$DOCKER_SERVICE_NAME
    # update nginx application conf ...
    php-fpm::nginx::conf wordpress
    # determine whether php-fpm was loaded properly, or wait for it ...
    while [ "$(php-fpm::test-running)" != "0" ]; do
        echo "Waiting for Wordpress & php-fpm to start";
        sleep 10
    done
    # update nginx
    env::update
    docker service update \
        --mount-add type=volume,source=$DOCKER_SERVICE_NAME,destination=$destiWpContent \
        --mount-add type=bind,source=$soureWPContent/themes,destination=$destiWpContent/wp-content/themes \
        --mount-add type=bind,source=$soureWPContent/uploads,destination=$destiWpContent/wp-content/uploads \
        $ENV_UPDATE \
        global_nginx
}

# NO LONGER NEEDED
# #
# # Add Wordpress Instance to NGINX Proxy
# #
# wordpress::nginx-proxy::update(){
#     http-html::nginx-proxy::update
# }

#
# Start/Create Wordpress Instance
#
wordpress::create() {
    local soureWPContent=$APPLICATION_HOME/wp-content
    local destiWpContent=/usr/src/wordpress
    # pull image
    docker pull $DOCKER_IMAGE
    # create volume
    docker volume create --name $DOCKER_SERVICE_NAME
    # create service
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
        --mount type=volume,source=$DOCKER_SERVICE_NAME,destination=$destiWpContent \
        --mount type=bind,source=$soureWPContent/themes,destination=$destiWpContent/wp-content/themes \
        --mount type=bind,source=$soureWPContent/uploads,destination=$destiWpContent/wp-content/uploads \
        --replicas $DOCKER_REPLICAS \
        $DOCKER_LOG_OPTIONS \
        $DOCKER_ADDITIONAL_CREATE \
        $DOCKER_IMAGE
    # update serving system
    wordpress::nginx::update
    varnish::update
    http-html::nginx-proxy::update  
}

#
# Update Wordpress Instance
#
wordpress::update() {
    # update service
    abstract::web::update
    # update serving system
    wordpress::nginx::update
    varnish::update
    http-html::nginx-proxy::update
}

#
# Remove Wordpress Instance
#
wordpress::remove() {
    local destiWPContent=/usr/src/wordpress/$DOCKER_SERVICE_NAME
    # remove wordpress service
    abstract::web::remove
    # update nginx
    rm -rf $NGINX_HOME/$(echo $APPLICATION_TLD | cut -f1 -d' ').conf
    env::update
    docker service update \
        $ENV_UPDATE \
        --mount-rm $destiWpContent/wp-content/themes \
        --mount-rm $destiWpContent/wp-content/uploads \
        --mount-rm $destiWpContent \
        global_nginx
    # remove nginx-proxy config file
    rm -rf $NGINX_HOME_PROXY/$(echo $APPLICATION_TLD | cut -f1 -d' ').conf
    env::update
    docker service update $ENV_UPDATE global_nginx-proxy
}