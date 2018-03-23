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

DOCKER_CODEX_IMAGE=${DOCKER_CODEX_IMAGE:-qubestash/wordpress:fpm-alpine}

# WORDPRESS_DOMAIN_PROTO=${WORDPRESS_DOMAIN_PROTO:-https}
WORDPRESS_MYSQL_DB=${WORDPRESS_MYSQL_DB:-database}
WORDPRESS_MYSQL_USER=${WORDPRESS_MYSQL_USER:-user}
WORDPRESS_MYSQL_PASS=${WORDPRESS_MYSQL_PASS:-pass}
WORDPRESS_MYSQL_HOST=${WORDPRESS_MYSQL_HOST:-global_mysql}
WORDPRESS_TABLE_PREFIX=${WORDPRESS_TABLE_PREFIX:-wp}
# WORDPRESS_PLUGINS=${WORDPRESS_PLUGINS:-};

bash $HERE/http-html.sh

docker service rm $APPLICATION_CODEX_NAME || true

sleep 5

docker volume rm $APPLICATION_CODEX_NAME || true

sleep 5

# pull image
docker pull $DOCKER_CODEX_IMAGE

# create volume
docker volume create --name $APPLICATION_CODEX_NAME

mkdir -p $APPLICATION_HOME/wp-content/plugins $APPLICATION_HOME/wp-content/themes $APPLICATION_HOME/wp-content/uploads $APPLICATION_HOME/wp-content/wflogs

# create service
soureWPContent=$APPLICATION_HOME/wp-content
destiWpContent=/usr/src/wordpress
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
    --hostname $APPLICATION_CODEX_NAME \
    --name $APPLICATION_CODEX_NAME \
    --network web-network \
    --mount type=bind,source=/etc/timezone,destination=/etc/timezone \
    --mount type=bind,source=/etc/localtime,destination=/etc/localtime \
    --mount type=volume,source=$APPLICATION_CODEX_NAME,destination=$destiWpContent \
    --mount type=bind,source=$soureWPContent/themes,destination=$destiWpContent/wp-content/themes \
    --mount type=bind,source=$soureWPContent/uploads,destination=$destiWpContent/wp-content/uploads \
    --mount type=bind,source=$soureWPContent/wflogs,destination=$destiWpContent/wp-content/wflogs \
    --replicas $DOCKER_CODEX_REPLICAS \
    $DOCKER_LOG_OPTIONS \
    $DOCKER_CODEX_ADDITIONAL_CREATE \
    $DOCKER_CODEX_IMAGE

sleep 5 

docker service ls
docker service inspect --pretty $APPLICATION_CODEX_NAME
docker service ps $APPLICATION_CODEX_NAME
docker ps -a | grep $APPLICATION_CODEX_NAME

# determine whether php-fpm was loaded properly, or wait for it ...
while [ "$(php-fpm::test-running $APPLICATION_CODEX_NAME)" != "0" ]; do
    echo "Waiting for Wordpress & php-fpm to start";
    sleep 10
done

# configure application config
cat $HERE/http-wordpress.conf \
    | sed -e "s/domain.local/$APPLICATION_TLD/g" \
    | sed -e "s/php.local/$APPLICATION_CODEX_NAME/g" \
    | sed -e "s|__ROOT__|$destiWpContent|g" \
    > $NGINX_CONFIG_HOME/$APPLICATION_TLD_SSL.conf

# update nginx
docker service update \
    --env-add UPDATE=$(date +%s.%N) \
    --mount-add type=bind,source=$NGINX_CONFIG_HOME/$APPLICATION_TLD_SSL.conf,destination=/etc/nginx/conf.d/$APPLICATION_TLD_SSL.conf \
    --mount-add type=volume,source=$APPLICATION_CODEX_NAME,destination=$destiWpContent \
    --mount-add type=bind,source=$soureWPContent/themes,destination=$destiWpContent/wp-content/themes \
    --mount-add type=bind,source=$soureWPContent/uploads,destination=$destiWpContent/wp-content/uploads \
    $APPLICATION_NGINX_NAME

# bash $HERE/global-nginx-proxy.sh
docker service update \
    --env-add UPDATE=$(date +%s.%N) \
    $APPLICATION_NGINX_PROXY_NAME
