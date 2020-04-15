include Makefile.template

#
# Actual Action Definitions
#

SOLARIS_ENV=production

REGISTRY_USER=admin
REGISTRY_PASS=weltest

REGISTRY_CERT_DOMAIN=docker-registry.itmediaconnect.ro
REGISTRY_CERT_EMAIL=webmaster@itmediaconnect.ro

# init-registry: rootcheck ## Init Docker Registry SOLARIS_ENV=production
# 	mkdir -p /opt/docker-registry/auth
# 	docker run --entrypoint htpasswd registry:latest -Bbn $(REGISTRY_USER) $(REGISTRY_PASS) > /opt/docker-registry/auth/htpasswd

# 	mkdir -p /opt/docker-registry/cert
# ifeq ($(SOLARIS_ENV),production)
# 	docker run certbot/certbot certonly \
# 		--standalone --preferred-challenges http \
# 		--non-interactive  --staple-ocsp --agree-tos \
# 		-m $(REGISTRY_CERT_EMAIL) -d $(REGISTRY_CERT_DOMAIN)
# else
# 	openssl req -x509 \
# 		-out /opt/docker-registry/cert/cert.crt \
# 		-keyout /opt/docker-registry/cert/cert.key \
# 		-newkey rsa:2048 -nodes -sha256 \
# 		-subj '/CN=$(REGISTRY_CERT_DOMAIN)' #-extensions EXT -config <(printf "[dn]\nCN=$(REGISTRY_CERT_DOMAIN)\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:$(REGISTRY_CERT_DOMAIN)\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
# endif


sync-makefile-template:
	find . -mindepth 2 -iname "Makefile.template" | while read f; do cp Makefile.template $$f; done