#! /bin/sh
if [ "$DEBUG" = "1" ]; then set -xe; else set -e; fi

export WRAPPER="`readlink -f "$0"`"
HERE="`dirname "$WRAPPER"`"

#
# @link https://docs.docker.com/engine/reference/commandline/service_create/
# @link https://docs.docker.com/engine/reference/commandline/service_update/
# @link https://docs.docker.com/engine/reference/commandline/service_inspect/
#

#
#  Create Abstract Service
#
abstract::web::create(){
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
    local serviceName=$1
    if [ "$serviceName" = "" ]; then serviceName=$DOCKER_SERVICE_NAME; fi
    docker service rm $serviceName
}

################################################################################
# NGINX
################################################################################

nginx::create(){
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
#
#
nginx-proxy::update(){
    abstract::web::update
}

################################################################################
# Varnish Cache
################################################################################

#
# Varnish Instance Create
#
varnish::create(){
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
    abstract::web::update
}

#
# Varnish Instance Remove
#
varnish::remove(){
    abstract::web::remove
}

################################################################################
# Wordpress
################################################################################

#
# Add Wordpress Instance Mounts to Nginx
#
wordpress::nginx::update(){
    # create nginx conf
    cat $HERE/wordpress.conf \
        | sed -e "s/wordpress.local/$WORDPRESS_TLD/g" \
        | sed -e "s/php.local/$DOCKER_SERVICE_NAME/g" \
        | sed -e "s/__ROOT__/\/usr\/src\/wordpress\/$DOCKER_SERVICE_NAME/g" \
        > $NGINX_HOME/$(echo $WORDPRESS_TLD | cut -f1 -d' ').conf
    # update nginx
    while [ "$(wordpress::test-running)" != "0" ]; do
        echo "Waiting for Wordpress & php-fpm to start";
        sleep 10
    done

    local soureWPContent=$WORDPRESS_HOME/wp-content
    local destiWpContent=/usr/src/wordpress/$DOCKER_SERVICE_NAME
    docker service update \
        --mount-add type=volume,source=$DOCKER_SERVICE_NAME,destination=$destiWpContent \
        --mount-add type=bind,source=$soureWPContent/themes,destination=$destiWpContent/wp-content/themes \
        --mount-add type=bind,source=$soureWPContent/uploads,destination=$destiWpContent/wp-content/uploads \
        $ENV_UPDATE \
        global_nginx
}

wordpress::nginx-proxy::update(){
    # create nginx-proxy conf
    cat $HERE/data/http/nginx-proxy/http-only.conf \
        | sed -e "s/localhost/$WORDPRESS_TLD/g" \
        > $NGINX_HOME_PROXY/$(echo $WORDPRESS_TLD | cut -f1 -d' ').conf

    docker service update $ENV_UPDATE global_nginx-cache
}

#
# Start/Create Wordpress Instance
#
wordpress::create(){
    # create volume
    docker volume create --name $DOCKER_SERVICE_NAME
    # create service
        # --env WORDPRESS_USE_EXTERNAL_VOLUME=yes \
    docker service create \
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
        --hostname $DOCKER_HOSTNAME \
        --name $DOCKER_SERVICE_NAME \
        --network web-network \
        --mount type=volume,source=$DOCKER_SERVICE_NAME,destination=/usr/src/wordpress \
        --mount type=bind,source=$WORDPRESS_HOME/wp-content/themes,destination=/usr/src/wordpress/wp-content/themes \
        --mount type=bind,source=$WORDPRESS_HOME/wp-content/uploads,destination=/usr/src/wordpress/wp-content/uploads \
        --replicas $DOCKER_REPLICAS \
        $DOCKER_LOG_OPTIONS \
        $DOCKER_ADDITIONAL_CREATE \
        $DOCKER_IMAGE

    # update nginx
    wordpress::nginx::update

    # update nginx-proxy
    wordpress::nginx-proxy::update
}

wordpress::test-running(){
    docker ps -a | grep -v Exited | egrep "$DOCKER_SERVICE_NAME\.[0-9]+" > /dev/null || echo 1

    docker ps -a | grep -v Exited \
        | egrep "$DOCKER_SERVICE_NAME\.[0-9]+" | awk -F" " '{print $NF}' \
        | while read container; do
            docker logs $container 2>&1 | grep "NOTICE: fpm is running" > /dev/null || echo 2
        done

    echo 0
}

#
# Remove Wordpress Instance
#
wordpress::remove(){
    # remove wordpress service
    abstract::web::remove

    # remove nginx config file
    rm $NGINX_HOME/$(echo $WORDPRESS_TLD | cut -f1 -d' ').conf

    # update nginx
    docker service update \
        --mount-rm /usr/src/wordpress/$DOCKER_SERVICE_NAME/wp-content/themes \
        --mount-rm /usr/src/wordpress/$DOCKER_SERVICE_NAME/wp-content/uploads \
        --mount-rm /usr/src/wordpress/$DOCKER_SERVICE_NAME \
        global_nginx

    # remove wordpress volume
    # docker volume rm $DOCKER_SERVICE_NAME
}

#
# Update Wordpress Instance
#
wordpress::update(){
    # update service
    docker service update \
        $ENV_UPDATE \
        --image $DOCKER_IMAGE \
        --mount-add type=bind,source=$WORDPRESS_HOME/wp-content/themes,destination=/usr/src/wordpress/wp-content/themes \
        --mount-add type=bind,source=$WORDPRESS_HOME/wp-content/uploads,destination=/usr/src/wordpress/wp-content/uploads \
        --replicas $DOCKER_REPLICAS \
        $DOCKER_ADDITIONAL_UPDATE \
        $DOCKER_SERVICE_NAME
    # update nginx service
    wordpress::nginx::update
}