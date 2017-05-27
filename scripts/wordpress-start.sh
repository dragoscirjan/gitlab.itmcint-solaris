#! /bin/sh
set -xe;

export WRAPPER="`readlink -f "$0"`"
HERE="`dirname "$WRAPPER"`"

. $HERE/_init.sh

#
# @link https://docs.docker.com/engine/reference/commandline/service_create/
# @link https://docs.docker.com/engine/reference/commandline/service_update/
# @link https://docs.docker.com/engine/reference/commandline/service_inspect/
#

DOCKER_SERVICE_NAME=${DOCKER_SERVICE_NAME:-wordpress}
DOCKER_HOSTNAME=${DOCKER_HOSTNAME:-wordpress.local}

DOCKER_LOG_OPTIONS=${DOCKER_LOG_OPTIONS:- --log-driver json-file --log-opt max-size=10m --log-opt max-file=3}
DOCKER_IMAGE=${DOCKER_IMAGE:-qubestash/wordpress:php-7.1.5-fpm-alpine}
DOCKER_REPLICAS=${DOCKER_REPLICAS:-1}

MYSQL_HOME=${MYSQL_HOME:-$HERE/mysql}
MYSQL_LIB_HOME=${MYSQL_LIB_HOME:-$HERE/mysql/lib}

WORDPRESS_TLD=${WORDPRESS_TLD:-wordpress.local}

WORDPRESS_MYSQL_DB=${WORDPRESS_MYSQL_DB:-database}
WORDPRESS_MYSQL_USER=${WORDPRESS_MYSQL_USER:-user}
WORDPRESS_MYSQL_PASS=${WORDPRESS_MYSQL_PASS:-pass}
WORDPRESS_MYSQL_HOST=${WORDPRESS_MYSQL_HOST:-global_mysql}
WORDPRESS_TABLE_PREFIX=${WORDPRESS_TABLE_PREFIX:-wp}
# WORDPRESS_PLUGINS=${WORDPRESS_PLUGINS:-};

docker-ip() {
    docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
        $(docker ps -a | grep $DOCKER_SERVICE_NAME\. | cut -f1 -d' ');
}

WORDPRESS_HOME=${WORDPRESS_HOME:-$HERE/data/sites/$DOCKER_HOSTNAME}
NGINX_HOME=${NGINX_HOME:-$HERE/data/http/nginx}

###

mkdir -p $WORDPRESS_HOME/wp-content/plugins $WORDPRESS_HOME/wp-content/themes $WORDPRESS_HOME/wp-content/uploads

#
# Start/Create Wordpress Instance
#
wordpress::create(){
    # create volume
    docker volume create --name $DOCKER_SERVICE_NAME
    # create service
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
        $DOCKER_ADDITIONAL_START \
        $DOCKER_IMAGE
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
        $DOCKER_SERVICE_NAME
    # update nginx service
    wordpress::at-update::nignx
}

#
# Remove Wordpress Instance
#
wordpress::remove(){
    # remove service
    docker service rm $DOCKER_SERVICE_NAME
    # update nginx service
    wordpress::at-remove::nginx
    # remove volume
    docker volume rm $DOCKER_SERVICE_NAME
}

#
# Add Wordpress Instance Mounts to Nginx
#
wordpress::at-update::nginx(){
    local soureWPContent=$WORDPRESS_HOME/wp-content
    local destiWpContent=/usr/src/wordpress/$DOCKER_SERVICE_NAME
    docker service update \
        --mount-add type=volume,source=$DOCKER_SERVICE_NAME,destination=$destiWpContent \
        --mount-add type=bind,source=$soureWPContent/themes,destination=$destiWpContent/wp-content/themes \
        --mount-add type=bind,source=$soureWPContent/uploads,destination=$destiWpContent/wp-content/uploads \
        global_nginx
}

#
# Remove Wordpress Instance Mounts from Nginx
#
wordpress::at-remove::nginx(){
    docker service update \
        --mount-rm /usr/src/wordpress/$DOCKER_SERVICE_NAMEdestiWpContent/wp-content/themes \
        --mount-rm /usr/src/wordpress/$DOCKER_SERVICE_NAME/wp-content/uploads \
        --mount-rm /usr/src/wordpress/$DOCKER_SERVICE_NAME \
        global_nginx   
}

#
# remove directive
#
if echo $* | grep "remove"; then
    wordpress::remove
fi

#
# create / update
#
if docker service ls | grep $DOCKER_SERVICE_NAME; then
    wordpress:update
else
    wordpress::create
    sleep 10
    wordpress::update
fi;

sleep 20

docker service ls
docker service inspect --pretty $DOCKER_SERVICE_NAME
docker service ps $DOCKER_SERVICE_NAME

#
# configure nginx host and notify nginx
#
cat $HERE/wordpress.conf \
    | sed -e "s/wordpress.local/$WORDPRESS_TLD/g" \
    | sed -e "s/php.local/$DOCKER_SERVICE_NAME/g" \
    | sed -e "s/__ROOT__/\/usr\/src\/wordpress\/$DOCKER_SERVICE_NAME/g" \
    > $NGINX_HOME/$(echo $WORDPRESS_TLD | cut -f1 -d' ').conf
    # | sed -e "s/php.local/$(docker-ip)/g" \
    # | sed -e "s/\/usr\/src\/wordpress/\/usr\/src\/wordpress\/$DOCKER_SERVICE_NAME/g" \
docker service update $ENV_UPDATE global_nginx

sleep 20

docker service ls
docker service inspect --pretty $DOCKER_SERVICE_NAME
docker service ps $DOCKER_SERVICE_NAME
docker service ps global_nginx