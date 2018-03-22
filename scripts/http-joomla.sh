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

DOCKER_CODEX_IMAGE=${DOCKER_CODEX_IMAGE:-php:fpm-alpine}

JOOMLA_MYSQL_DB=${JOOMLA_MYSQL_DB:-database}
JOOMLA_MYSQL_USER=${JOOMLA_MYSQL_USER:-user}
JOOMLA_MYSQL_PASS=${JOOMLA_MYSQL_PASS:-pass}
JOOMLA_MYSQL_HOST=${JOOMLA_MYSQL_HOST:-global_mysql}

bash $HERE/http-html.sh

docker service rm $APPLICATION_CODEX_NAME || true

sleep 5

docker volume rm $APPLICATION_CODEX_NAME || true

sleep 5

# pull image
docker pull $DOCKER_CODEX_IMAGE

# create volume
docker volume create --name $APPLICATION_CODEX_NAME

soureJContent=$APPLICATION_HOME
destiJContent=/usr/src/joomla
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
    --hostname $APPLICATION_CODEX_NAME \
    --name $APPLICATION_CODEX_NAME \
    --network web-network \
    --mount type=bind,source=$soureJContent,destination=$destiJContent \
    --mount type=bind,source=/etc/timezone,destination=/etc/timezone \
    --mount type=bind,source=/etc/localtime,destination=/etc/localtime \
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
cat $HERE/http-joomla.conf \
    | sed -e "s/domain.local/$APPLICATION_TLD/g" \
    | sed -e "s/php.local/$APPLICATION_CODEX_NAME/g" \
    | sed -e "s|__ROOT__|/usr/src/joomla|g" \
    > $NGINX_CONFIG_HOME/$APPLICATION_TLD_SSL.conf

# update nginx
docker service update \
    --env-add UPDATE=$(date +%s.%N) \
    --mount-add type=bind,source=$NGINX_CONFIG_HOME/$APPLICATION_TLD_SSL.conf,destination=/etc/nginx/conf.d/$APPLICATION_TLD_SSL.conf \
    --mount-add type=volume,source=$APPLICATION_CODEX_NAME,destination=$destiJContent \
    $APPLICATION_NGINX_NAME

# bash $HERE/global-nginx-proxy.sh
docker service update \
    --env-add UPDATE=$(date +%s.%N) \
    $APPLICATION_NGINX_PROXY_NAME










# APPLICATION_HOME=${APPLICATION_HOME:-$HERE/data/sites/$DOCKER_HOSTNAME}

# NGINX_HOME=${NGINX_HOME:-$HERE/data/http/nginx}
# NGINX_CONF=http-joomla.conf
# NGINX_HOME_PROXY=${NGINX_HOME_PROXY:-$HERE/data/http/nginx-proxy}

# mkdir -p $APPLICATION_HOME

# #
# # remove directive
# #
# if echo $* | grep "remove"; then
#     joomla::remove
#     sleep 10
# fi
# if echo $* | grep "remove-only"; then
#     exit 0
# fi

# #
# # create / update
# #
# if docker service ls | grep $DOCKER_SERVICE_NAME; then
#     joomla::update
# else
#     joomla::create
# fi;

# sleep 20

# docker service ls
# docker service inspect --pretty $DOCKER_SERVICE_NAME
# docker service inspect --pretty global_nginx
# docker service ps $DOCKER_SERVICE_NAME