include Makefile.template

#
# Actual Action Definitions
#

INGRESS_NGINX_URL = https://github.com/nginxinc/kubernetes-ingress/
INGRESS_NGINX_VERSION = v1.6.2

init-nginx-ingress: ## Init Ingress (NginxInc) https://www.youtube.com/user/vipinwipl007/videos
	git clone $(INGRESS_NGINX_URL)
	cd kubernetes-ingress
	git checkout $(INGRESS_NGINX_VERSION)
	cd deployments
	# 1 https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-manifests/#configure-rbac
	kubectl apply -f common/ns-and-sa.yaml
	kubectl apply -f rbac/rbac.yaml
	sleep 5
	# 2 https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-manifests/#create-the-default-secret-customization-configmap-and-custom-resource-definitions
	kubectl apply -f common/default-server-secret.yaml
	kubectl apply -f common/nginx-config.yaml
	kubectl apply -f common/custom-resource-definitions.yaml
	sleep 5
	# 3 https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-manifests/#deploy-the-ingress-controller
	kubectl apply -f deployment/nginx-ingress.yaml
	# kubectl apply -f daemon-set/nginx-ingress.yaml
	sleep 5
	kubectl get pods --namespace=nginx-ingress
	# 4 https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-manifests/#get-access-to-the-ingress-controller
	kubectl apply -f service/nodeport.yaml
	sleep 5
	kubectl apply -f common/nginx-config.yaml
	sleep 5
	kubectl get all --all-namespaces

delete-nginx-ingress: ## Delete Ingress (NginxInc)
	kubectl delete namespace nginx-ingress
	kubectl delete clusterrole nginx-ingress
	kubectl delete clusterrolebinding nginx-ingress

INGRESS_K8S_URL = https://github.com/kubernetes/ingress-nginx
INGRESS_K8S_VERSION = nginx-0.29.0

init-k8s-ingress: ## Init Ingress (Kubernetes) https://bit.ly/2SI7uKP
	git clone $(INGRESS_K8S_URL)
	cd ingress-nginx
	git checkout $(INGRESS_K8S_VERSION)

	kubectl apply -f deploy/static/mandatory.yaml
	kubectl apply -f deploy/static/provider/cloud-generic.yaml
	sleep 5
	kubectl apply -f Service_ingress-nginx.yaml
	sleep 5
	kubectl get all --all-namespaces

delete-k8s-ingress: ## Delete Ingress (Kubernetes)
	kubectl delete -f Service_ingress-nginx.yaml
	kubectl delete -f deploy/static/provider/cloud-generic.yaml
	kubectl delete -f deploy/static/mandatory.yaml
	sleep 5
	kubectl get all --all-namespaces