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
NGINX_HOME_PROXY=${NGINX_HOME:-$HERE/data/http/nginx-proxy}

###

mkdir -p $WORDPRESS_HOME/wp-content/plugins $WORDPRESS_HOME/wp-content/themes $WORDPRESS_HOME/wp-content/uploads

#
# remove directive
#
if echo $* | grep "remove"; then
    wordpress::remove
fi
if echo $* | grep "remove-only"; then
    exit 0
fi

#
# create / update
#
if docker service ls | grep $DOCKER_SERVICE_NAME; then
    wordpress::update
else
    wordpress::create
fi;

sleep 20

docker service ls
docker service inspect --pretty $DOCKER_SERVICE_NAME
docker service ps $DOCKER_SERVICE_NAME



# cat $HERE/website.proxy.conf \
#     | sed -e "s/domain.local/$WORDPRESS_TLD/g" \
#     > $NGINX_HOME_PROXY/$(echo $WORDPRESS_TLD | cut -f1 -d' ').conf

# sleep 20

# docker service ls
# docker service inspect --pretty $DOCKER_SERVICE_NAME
# docker service inspect --pretty global_nginx
# docker service ps $DOCKER_SERVICE_NAME
# docker service ps global_nginx