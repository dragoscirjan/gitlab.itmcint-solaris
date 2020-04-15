include Makefile.template

#
# Actual Action Definitions
#

LXC_SLAVE=1

init: ## Create LXC Kube Containers
	mkdir -p $$HOME/.lxcfs
	make lxc-k8s-master

lxc-create: 
	mkdir -p $$HOME/.lxcfs/$(LXC_NAME)
	# lxc-create -t download -n $(LXC_NAME) --dir=$$HOME/.lxcfs/$(LXC_NAME) -- -d ubuntu -r bionic -a amd64 -
	lxc-create -t download -n $(LXC_NAME) -- -d ubuntu -r bionic -a amd64 -

lxc-k8s-master: ## Create Kubernetest Master
	make lxc-create LXC_NAME=k8s-master

	lxc-start -n k8s-master

	sleep 10
	# lxc-attach -n k8s-master apt-get -- install -y openssh-server

lxc-k8s-slave: ## Create Kubernetes Slave LXC_SLAVE=1
	make lxc-create LXC_NAME=k8s-slave-$(LXC_SLAVE)
	