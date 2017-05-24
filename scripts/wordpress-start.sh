#! /bin/sh
set -xe;

#
# @link https://docs.docker.com/engine/reference/commandline/service_create/
# @link https://docs.docker.com/engine/reference/commandline/service_update/
# @link https://docs.docker.com/engine/reference/commandline/service_inspect/
#

export DOCKER_SERVICE_NAME="andreiruse_hypera";
export DOCKER_HOSTNAME="hypera.global";

export DOCKER_LOG_OPTIONS="--log-driver json-file --log-opt max-size=10m --log-opt max-file=3";
export DOCKER_IMAGE="qubestash/wordpress:php-7.1.5-fpm-alpine";
export DOCKER_REPLICAS=1;

export WORDPRESS_MYSQL_DB=andreiruse_hypera;
export WORDPRESS_MYSQL_USER=andreiruse;
export WORDPRESS_MYSQL_PASS=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1);
export WORDPRESS_MYSQL_HOST=mysql.global;
export WORDPRESS_TABLE_PREFIX=wp;
export WORDPRESS_PLUGINS="addthis authors all-in-one-seo-pack better-delete-revision fd-footnotes maintenance page-links-to php-code-widget pixelstats post-reading-time regenerate-thumbnails side-matter smtp-mailer ultimate-posts-widget widget-title-links woocommerce wp-pagenavi widget-logic wordpress-popular-posts wp-super-cache wp-user-avatar";

export WORDPRESS_HOME=/data/sites/$DOCKER_HOSTNAME;

#
#
#

mkdir -p $WORDPRESS_HOME;

if docker service ls | grep $DOCKER_SERVICE_NAME; then
    docker service update \
        --image $DOCKER_IMAGE \
        --replicas $DOCKER_REPLICAS \
        $DOCKER_SERVICE_NAME;
else
    echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++";
    echo " mysql -u$WORDPRESS_MYSQL_USER \\ ";
    echo "       -p$WORDPRESS_MYSQL_PASS \\ ";
    echo "       -h$WORDPRESS_MYSQL_HOST ";
    echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++";

# https://wordpress.org/plugins/
# addthis                   https://downloads.wordpress.org/plugin/addthis.5.3.5.zip
# authors                   https://downloads.wordpress.org/plugin/authors.zip
# page-links-to             https://downloads.wordpress.org/plugin/page-links-to.2.9.9.zip
# post-reading-time         https://downloads.wordpress.org/plugin/post-reading-time.1.2.zip
# smtp-mailer               https://downloads.wordpress.org/plugin/smtp-mailer.zip
# widget-title-links        https://downloads.wordpress.org/plugin/widget-title-links.1.4.1.zip
# wordpress-popular-posts   https://downloads.wordpress.org/plugin/wordpress-popular-posts.3.3.4.zip

    docker service create \
        $DOCKER_LOG_OPTIONS \
        --replicas $DOCKER_REPLICAS \
        --env WORDPRESS_MYSQL_DB=$WORDPRESS_MYSQL_DB \
        --env WORDPRESS_MYSQL_USER=$WORDPRESS_MYSQL_USER \
        --env WORDPRESS_MYSQL_PASS=$WORDPRESS_MYSQL_PASS \
        --env WORDPRESS_MYSQL_HOST=$WORDPRESS_MYSQL_HOST \
        --env WORDPRESS_TABLE_PREFIX=$WORDPRESS_TABLE_PREFIX \
        --env WORDPRESS_PLUGINS="$WORDPRESS_PLUGINS" \
        --hostname $DOCKER_HOSTNAME \
        --mount type=bind,source=$WORDPRESS_HOME/wp-content/themes,destination=/usr/src/wordpress/wp-content/themes \
        --name $DOCKER_SERVICE_NAME $DOCKER_IMAGE;
fi;


sleep 20;

docker service ls;
docker service inspect --pretty $DOCKER_SERVICE_NAME;
docker service ps $DOCKER_SERVICE_NAME;