#! /bin/sh
set -xe;

export WRAPPER="`readlink -f "$0"`"
HERE="`dirname "$WRAPPER"`"

#
# @link https://docs.docker.com/engine/reference/commandline/service_create/
# @link https://docs.docker.com/engine/reference/commandline/service_update/
# @link https://docs.docker.com/engine/reference/commandline/service_inspect/
#

DOCKER_SERVICE_NAME=${DOCKER_SERVICE_NAME:-joomla}
DOCKER_HOSTNAME=${DOCKER_HOSTNAME:-joomla.local}

DOCKER_LOG_OPTIONS=${DOCKER_LOG_OPTIONS:- --log-driver json-file --log-opt max-size=10m --log-opt max-file=3}
DOCKER_IMAGE=${DOCKER_IMAGE:-php:fpm-alpine}
DOCKER_REPLICAS=${DOCKER_REPLICAS:-1}

MYSQL_HOME=${MYSQL_HOME:-$HERE/mysql}
MYSQL_LIB_HOME=${MYSQL_LIB_HOME:-$HERE/mysql/lib}

APPLICATION_TLD=${APPLICATION_TLD:-joomla.local}

JOOMLA_MYSQL_DB=${JOOMLA_MYSQL_DB:-database}
JOOMLA_MYSQL_USER=${JOOMLA_MYSQL_USER:-user}
JOOMLA_MYSQL_PASS=${JOOMLA_MYSQL_PASS:-pass}
JOOMLA_MYSQL_HOST=${JOOMLA_MYSQL_HOST:-global_mysql}

. $HERE/_init.sh

docker-ip() {
    docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
        $(docker ps -a | grep $DOCKER_SERVICE_NAME\. | cut -f1 -d' ');
}

APPLICATION_HOME=${APPLICATION_HOME:-$HERE/data/sites/$DOCKER_HOSTNAME}

NGINX_HOME=${NGINX_HOME:-$HERE/data/http/nginx}
NGINX_CONF=http-joomla.conf
NGINX_HOME_PROXY=${NGINX_HOME_PROXY:-$HERE/data/http/nginx-proxy}

mkdir -p $APPLICATION_HOME


#
# remove directive
#
if echo $* | grep "remove"; then
    joomla::remove
    sleep 10
fi
if echo $* | grep "remove-only"; then
    exit 0
fi

#
# create / update
#
if docker service ls | grep $DOCKER_SERVICE_NAME; then
    joomla::update
else
    joomla::create
fi;

sleep 20

docker service ls
docker service inspect --pretty $DOCKER_SERVICE_NAME
docker service inspect --pretty global_nginx
docker service ps $DOCKER_SERVICE_NAME