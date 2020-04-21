include Makefile.template

#
# Actual Action Definitions
#

SOLARIS_ENV = production

INGRESS_NGINX_YAML_PATH = kubernetes-ingress/deployments
INGRESS_NGINX_URL = https://github.com/nginxinc/kubernetes-ingress/
INGRESS_NGINX_VERSION = v1.6.2

init-nginx-ingress: ## Init Ingress (NginxInc) https://www.youtube.com/user/vipinwipl007/videos
	git clone --single-branch --branch $(INGRESS_NGINX_VERSION) $(INGRESS_NGINX_URL)
	# 1 https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-manifests/#configure-rbac
	kubectl apply -f $(INGRESS_NGINX_YAML_PATH)/common/ns-and-sa.yaml
	kubectl apply -f $(INGRESS_NGINX_YAML_PATH)/rbac/rbac.yaml
	sleep 5
	# 2 https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-manifests/#create-the-default-secret-customization-configmap-and-custom-resource-definitions
	kubectl apply -f $(INGRESS_NGINX_YAML_PATH)/common/default-server-secret.yaml
	kubectl apply -f $(INGRESS_NGINX_YAML_PATH)/common/nginx-config.yaml
	kubectl apply -f $(INGRESS_NGINX_YAML_PATH)/common/custom-resource-definitions.yaml
	sleep 5
	# 3 https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-manifests/#deploy-the-ingress-controller
	kubectl apply -f $(INGRESS_NGINX_YAML_PATH)/deployment/nginx-ingress.yaml
	# kubectl apply -f daemon-set/nginx-ingress.yaml
	sleep 5
	kubectl get pods --namespace=nginx-ingress
	# 4 https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-manifests/#get-access-to-the-ingress-controller
	kubectl apply -f $(INGRESS_NGINX_YAML_PATH)/service/nodeport.yaml
	sleep 5
	kubectl apply -f $(INGRESS_NGINX_YAML_PATH)/common/nginx-config.yaml

delete-nginx-ingress: ## Delete Ingress (NginxInc)
	kubectl delete namespace nginx-ingress
	kubectl delete clusterrole nginx-ingress
	kubectl delete clusterrolebinding nginx-ingress

INGRESS_K8S_YAML_PATH = ingress-nginx
INGRESS_K8S_URL = https://github.com/kubernetes/ingress-nginx
INGRESS_K8S_VERSION = nginx-0.29.0

init-k8s-ingress: ## Init Ingress (Kubernetes) https://bit.ly/2SI7uKP
	rm -rf ./ingress-nginx
	git clone --single-branch --branch $(INGRESS_K8S_VERSION)  $(INGRESS_K8S_URL)

	kubectl apply -f $(INGRESS_K8S_YAML_PATH)/deploy/static/mandatory.yaml
	kubectl apply -f $(INGRESS_K8S_YAML_PATH)/deploy/static/provider/cloud-generic.yaml

delete-k8s-ingress: ## Delete Ingress (Kubernetes)
	# kubectl delete -f Service_ingress-nginx.yaml
	kubectl delete -f $(INGRESS_K8S_YAML_PATH)/deploy/static/provider/cloud-generic.yaml
	kubectl delete -f $(INGRESS_K8S_YAML_PATH)/deploy/static/mandatory.yaml

init-demo: ## Init Ingress Demo
	kubectl apply -f demo/demo1.yaml
	kubectl apply -f demo/demo2.yaml
	kubectl apply -f demo/ingress.yaml

	kubectl get all --namespace default
	kubectl get all --namespace nginx-ingress

delete-demo: ## Delete Ingress Demo
	kubectl delete -f demo/ingress.yaml
	kubectl delete -f demo/demo1.yaml
	kubectl delete -f demo/demo2.yaml