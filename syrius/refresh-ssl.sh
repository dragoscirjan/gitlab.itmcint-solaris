#! /bin/bash
set -xe

export WRAPPER="`readlink -f "$0"`"
HERE="`dirname "$WRAPPER"`"

# TIMEOUT=$((2 * 24 * 60 * 60))
# openssl x509 -checkend $TIMEOUT -noout -in /etc/letsencrypt/live/itmcd.ro/cert.pem && exit 0

APPLICATION_NGINX_PROXY_NAME=global_nginx-proxy

# docker service rm $APPLICATION_NGINX_PROXY_NAME
docker service update --env-add UPDATE=$(date +%s.%N) --publish-rm 80:80 --publish-rm 443:443 $APPLICATION_NGINX_PROXY_NAME

bash /opt/solaris/scripts/global-ssl-refresh.sh

docker service update --env-add UPDATE=$(date +%s.%N) --publish-add 80:80 --publish-add 443:443 $APPLICATION_NGINX_PROXY_NAME

# export DOCKER_ADDITIONAL_CREATE="--publish 80:80 --publish 443:443" \
# && export NGINX_HOME=/data/http/nginx-proxy \
# && export NGINX_HOME_CERTBOT=/etc/letsencrypt \
# && export NGINX_HOME_QUBE=/data/qubestash \
# && export NGINX_HOME_SSL=/data/http/ssl \
# && bash /opt/solaris/scripts/global-nginx-proxy.sh