#! /bin/bash
set -xe;

export WRAPPER="`readlink -f "$0"`"
HERE="`dirname "$WRAPPER"`"

. $HERE/_init.sh

#
# @link https://docs.docker.com/engine/reference/commandline/service_create/
# @link https://docs.docker.com/engine/reference/commandline/service_update/
# @link https://docs.docker.com/engine/reference/commandline/service_inspect/
#

docker service rm $APPLICATION_NGINX_NAME || true

docker service create \
    --hostname $APPLICATION_NGINX_NAME \
    --mount type=bind,source=$NGINX_CONFIG_HOME/default.conf,destination=/etc/nginx/conf.d/default.conf \
    --mount type=bind,source=$APPLICATION_HOME,destination=/usr/share/nginx/html \
    --network web-network \
    --replicas $DOCKER_NGINX_REPLICAS \
    $DOCKER_LOG_OPTIONS \
    $DOCKER_ADDITIONAL_CREATE \
    --name $APPLICATION_NGINX_NAME \
    $DOCKER_NGINX_IMAGE

sleep 5 

docker service ls
docker service inspect --pretty $APPLICATION_NGINX_NAME
docker service ps $APPLICATION_NGINX_NAME
docker ps -a | grep $APPLICATION_NGINX_NAME

cat $HERE/global-nginx-proxy-https-only.conf \
	| sed -e "s/localhost/$APPLICATION_TLD/g" \
	| sed -e "s/domain.local/$APPLICATION_TLD_SSL/g" \
	| sed -e "s/global_nginx/$APPLICATION_NGINX_NAME/g" \
	> $NGINX_PROXY_CONFIG_HOME/$(echo $APPLICATION_TLD | cut -f1 -d' ').conf

# bash $HERE/global-nginx-proxy.sh
docker service update \
    --env-add UPDATE=$(date +%s.%N) \
    $NGINX_PROXY_NAME