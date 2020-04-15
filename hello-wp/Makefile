include Makefile.template

#
# Actual Action Definitions
#

_root_check:
	@echo "Need root to run Kubernetes Install." && [ "$$(whoami)" = "root" ]

SOLARIS_ENV=production

init: ## Init Hello World
	kubectl apply -f hello-world.yaml
ifneq ($(SOLARIS_ENV),production)
	kubectl apply -f hello-world-dev.yaml
endif

delete: ## Delete Hello World
	kubectl delete -f hello-world.yaml