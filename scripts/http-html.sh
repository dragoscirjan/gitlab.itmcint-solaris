#! /bin/bash
set -xe;

export WRAPPER="`readlink -f "$0"`"
HERE="`dirname "$WRAPPER"`"

#
# @link https://docs.docker.com/engine/reference/commandline/service_create/
# @link https://docs.docker.com/engine/reference/commandline/service_update/
# @link https://docs.docker.com/engine/reference/commandline/service_inspect/
#

DOCKER_SERVICE_NAME=${DOCKER_SERVICE_NAME:-global_nginx}

. $HERE/_init.sh

if [ "$APPLICATION_HOME" = "" ] || [ "$APPLICATION_TLD" = "" ]; then
	echo "One of the following are not set: "
	echo "APPLICATION_HOME=$APPLICATION_HOME"
	echo "APPLICATION_TLD=$APPLICATION_TLD"
	exit 1
fi

NGINX_HOME=${NGINX_HOME:-$HERE/data/http/nginx}
NGINX_CONF=http-html.conf
NGINX_HOME_PROXY=${NGINX_HOME_PROXY:-$HERE/data/http/nginx-proxy}

# ensure application folder exists
mkdir -p $APPLICATION_HOME

#
# remove directive
#
if echo $* | grep "remove"; then
    http-html::remove
fi
if echo $* | grep "remove-only"; then
    exit 0
fi

#
# create / update
#
# if docker service ls | grep $DOCKER_SERVICE_NAME; then
    http-html::update
# else
#     http-html::create
# fi;

sleep 20

docker service ls
docker service inspect --pretty $DOCKER_SERVICE_NAME
docker service ps $DOCKER_SERVICE_NAME