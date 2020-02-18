include Makefile.template

#
# Actual Action Definitions
#


init: ## (1) Init Nginx 
	@# https://dev.to/chrisme/setting-up-nginx-ingress-w-automatically-generated-letsencrypt-certificates-on-kubernetes-4f1k
	
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/cloud-generic.yaml
	sleep 5
	kubectl apply -f Service_ingress-nginx.yaml
	sleep 5
	kubectl get -n ingress-nginx service
	kubectl get pods -o wide --all-namespaces

cert-manager: ## Install & Configure Certificate Manager
	kubectl create namespace cert-manager
	kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.13.0/cert-manager.yaml
	sleep 5
	kubectl get pods --namespace cert-manager
	sleep 5
	kubectl apply -f ca/test.yaml
	kubectl describe certificate -n cert-manager-test
	sleep 5
	kubectl delete -f ca/test.yaml

init-demo: ## Echo Demo
	kubectl apply -f demo/demo1.yaml
	kubectl apply -f demo/demo2.yaml
	sleep 5
	kubectl get service
	kubectl get pods -o wide --all-namespaces
	sleep 5

	kubectl apply -f demo/ingress.yaml
	sleep 5
	kubectl get service
	kubectl get pods -o wide --all-namespaces

delete-demo:
	kubectl delete -f demo/ingress.yaml
	kubectl delete -f demo/demo1.yaml
	kubectl delete -f demo/demo2.yaml