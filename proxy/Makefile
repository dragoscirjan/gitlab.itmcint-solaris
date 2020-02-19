include Makefile.template

#
# Actual Action Definitions
#

INGRESS_NGINX_URL = https://github.com/nginxinc/kubernetes-ingress/raw/master/deployments

init-nginx-ingress: ## Init Ingress (NginxInc) https://www.youtube.com/user/vipinwipl007/videos
	# 1 https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-manifests/#configure-rbac
	kubectl apply -f $(INGRESS_NGINX_URL)/common/ns-and-sa.yaml
	kubectl apply -f $(INGRESS_NGINX_URL)/rbac/rbac.yaml
	sleep 5
	# 2 https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-manifests/#create-the-default-secret-customization-configmap-and-custom-resource-definitions
	kubectl apply -f $(INGRESS_NGINX_URL)/common/default-server-secret.yaml
	kubectl apply -f $(INGRESS_NGINX_URL)/common/nginx-config.yaml
	kubectl apply -f $(INGRESS_NGINX_URL)/common/custom-resource-definitions.yaml
	sleep 5
	# 3 https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-manifests/#deploy-the-ingress-controller
	kubectl apply -f $(INGRESS_NGINX_URL)/daemon-set/nginx-ingress.yaml
	kubectl apply -f $(INGRESS_NGINX_URL)/daemon-set/nginx-ingress.yaml
	sleep 5
	kubectl get pods --namespace=nginx-ingress
	# 4 https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-manifests/#get-access-to-the-ingress-controller
	kubectl apply -f $(INGRESS_NGINX_URL)/service/nodeport.yaml
	sleep 5
	kubectl apply -f $(INGRESS_NGINX_URL)/common/nginx-config.yaml
	sleep 5
	kubectl get all --all-namespaces

INGRESS_K8S_URL = https://raw.githubusercontent.com/kubernetes/ingress-nginx/master

init-k8s-ingress: ## Init Ingress (Kubernetes) https://bit.ly/2SI7uKP
	kubectl apply -f $(INGRESS_K8S_URL)/deploy/static/mandatory.yaml
	kubectl apply -f $(INGRESS_K8S_URL)/deploy/static/provider/cloud-generic.yaml
	sleep 5
	kubectl apply -f Service_ingress-nginx.yaml
	sleep 5
	kubectl get all --all-namespaces

delete-k8s-ingress: ## Delete Ingress (Kubernetes)
	kubectl delete -f Service_ingress-nginx.yaml
	kubectl delete -f $(INGRESS_K8S_URL)/deploy/static/provider/cloud-generic.yaml
	kubectl delete -f $(INGRESS_K8S_URL)/deploy/static/mandatory.yaml
	sleep 5
	kubectl get all --all-namespaces