#! /bin/sh
set -xe

export WRAPPER="`readlink -f "$0"`"
HERE="`dirname "$WRAPPER"`"

. $HERE/_init.sh

DOCKER_HOSTNAME=${DOCKER_HOSTNAME:-nginx-proxy.local};
DOCKER_IMAGE=${DOCKER_IMAGE:-qubestash/nginx:alpine};
DOCKER_LOG_OPTIONS=${DOCKER_LOG_OPTIONS:- --log-driver json-file --log-opt max-size=10m --log-opt max-file=3};
DOCKER_REPLICAS=${DOCKER_REPLICAS:-1};
DOCKER_SERVICE_NAME=${DOCKER_SERVICE_NAME:-global_nginx-proxy};

NGINX_HOME=${NGINX_HOME:-$HERE/data/http/nginx-proxy};
NGINX_HOME_CERTBOT=${NGINX_HOME:-$HERE/data/certbot};
NGINX_HOME_QUBE=${NGINX_HOME:-$HERE/data/qubestash};
NGINX_HOME_SSL=${NGINX_HOME:-$HERE/data/http/ssl};

###

mkdir -p $NGINX_HOME $NGINX_HOME_SSL $NGINX_HOME_QUBE $NGINX_HOME_CERTBOT;

#
# remove directive
#
if echo $* | grep "remove"; then
    nginx-proxy::remove
fi
if echo $* | grep "remove-only"; then
    exit 0
fi

#
# create/update
#
if docker service ls | grep $DOCKER_SERVICE_NAME; then
    nginx-proxy::update
else
    nginx-proxy::create
fi

sleep 20;

nginx-proxy::info