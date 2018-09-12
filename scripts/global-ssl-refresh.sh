#! /bin/bash

HOSTNAME=$(hostname)

[ $HOSTNAME != 'tiamat' ] && ( docker service rm global_nginx-proxy || true ) && sleep 10

[ $HOSTNAME != 'tiamat' ] && ( docker ps -a | grep global_nginx-proxy && exit 100 )

#CERTBOT_DEV_OPTIONS="--dry-run --quiet"
CERTBOT_OPTIONS="--non-interactive --force-renewal --standalone --agree-tos $CERTBOT_DEV_OPTIONS --email office@itmediaconnect.ro"

DOMAIN_FILE="/tmp/domains.txt"

[ $HOSTNAME != 'tiamat' ] && cat > $DOMAIN_FILE <<DOMAINS
# Andrei Ruse
andreiruse.ro www.andreiruse.ro
arthouselucrezia.ro www.arthouselucrezia.ro
hyperliteratura.ro www.hyperliteratura.ro
# Stefan Mitran
casacontelui.ro www.casacontelui.ro
# Dragos Cirjan
# lunaticthinker.me
# IT Media Connect
itmcd.ro dragosc.itmcd.ro www.dragosc.itmcd.ro galatea.itmcd.ro www.galatea.itmcd.ro syrius.itmcd.ro www.syrius.itmcd.ro www.itmcd.ro
DOMAINS

[ $HOSTNAME == 'tiamat' ] && cat > $DOMAIN_FILE <<DOMAINS
tiamat.itmcd.ro
DOMAINS

cat $DOMAIN_FILE | grep -v "#" | while read DOMAIN; do
	DOMAIN1=$(echo $DOMAIN | awk -F' ' '{print $1}')
    # @see https://certbot.eff.org/docs/using.html#id17
    
    CERTBOT_COMMAND="certbot certonly $CERTBOT_OPTIONS --cert-name $DOMAIN1 -d $(echo $DOMAIN | sed -e 's/ /,/g')"
    echo $CERTBOT_COMMAND
    $CERTBOT_COMMAND
    
    [ $HOSTNAME != 'tiamat' ] &&  for SUBDOMAIN in $DOMAIN; do
    	echo "$SUBDOMAIN"
    	if [ -f /data/http/nginx-proxy/$SUBDOMAIN.conf ]; then
        	CHAIN=$(find /etc/letsencrypt/live/ -type l -or -type f | grep $DOMAIN1 | grep chain | tail -n 1)
            PRIVKEY=$(find /etc/letsencrypt/live/ -type l -or -type f | grep $DOMAIN1 | grep privkey | tail -n 1)
        	echo /data/http/nginx-proxy/$SUBDOMAIN.conf
    		cat /data/http/nginx-proxy/$SUBDOMAIN.conf \
            	| sed -e "s|ssl_certificate .*|ssl_certificate $CHAIN;|g" \
            	| sed -e "s|ssl_certificate_key .*|ssl_certificate_key $PRIVKEY;|g" > /tmp/$SUBDOMAIN
                
            diff /data/http/nginx-proxy/$SUBDOMAIN.conf /tmp/$SUBDOMAIN
            cp /tmp/$SUBDOMAIN /data/http/nginx-proxy/$SUBDOMAIN.conf
        fi
	done
done

[ $HOSTNAME == 'tiamat' ] && exit 0

JENKINS_PORT=$((8000 + $(date +%d | sed -e "s/^0\+//g") + $(date +%m | sed -e "s/^0\+//g")))
JENKINS_DOMAIN=syrius.itmcd.ro:$JENKINS_PORT
JENKINS_USER=dragosc
JENKINS_TOKEN=8620e5d374438e39893955a29642163c
JENKINS_PROJECT_NAME=SYRIUS_NGINX_PROXY
JENKINS_PROJECT_TOKEN=SYRIUS_NGINX_PROXY
JENKINS_CRUMB=$(curl -s "http://$JENKINS_USER:$JENKINS_TOKEN@$JENKINS_DOMAIN/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")
curl -X POST -H "$JENKINS_CRUMB" http://$JENKINS_USER:$JENKINS_TOKEN@$JENKINS_DOMAIN/job/$JENKINS_PROJECT_NAME/build?token=$JENKINS_PROJECT_TOKEN
