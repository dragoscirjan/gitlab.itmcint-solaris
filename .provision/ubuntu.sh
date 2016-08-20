# #! /bin/bash

#
# Install Ansible
# @see http://docs.ansible.com/ansible/intro_installation.html
#
sudo apt-get update
sudo apt-get install -y python-pip python-simplejson
pip install -U paramiko PyYAML Jinja2 httplib2 six markupsafe ansible  # -U --upgrade
ansible --version

# #
# # Install Docker
# # @link https://docs.docker.com/engine/installation/linux/ubuntulinux/
# #

sudo apt-get update
dpkg -l | grep linux-image-extra-$(uname -r) || {
    sudo apt-get install -y linux-image-extra-$(uname -r)
    echo "Please restart virtual machine and run vagrant provision in order to continue with installer."
    exit 1
}

sudo apt-get install -y apt-transport-https ca-certificates bridge-utils
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
lsb_release -a | grep Release | grep 14 && {
    sudo echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" > /etc/apt/sources.list.d/docker.list
}
lsb_release -a | grep Release | grep 16 && {
    sudo echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" > /etc/apt/sources.list.d/docker.list
}
sudo apt-get purge -y lxc-docker || true

sudo apt-get update
sudo apt-cache policy docker-engine
sudo apt-get install -y docker-engine
sudo service docker restart

# # #
# # # Install Kubernetes
# # # @link http://kubernetes.io/docs/getting-started-guides/docker/
# # #

# # which systemd > /dev/null && {
# #     DOCKER_CONF=$(systemctl cat docker | head -1 | awk '{print $2}') sed -i.bak 's/^\(MountFlags=\).*/\1shared/' $DOCKER_CONF
# #     systemctl daemon-reload
# #     systemctl restart docker
# # }

# # which systemd > /dev/null || {
# #     mkdir -p /var/lib/kubelet; mount --bind /var/lib/kubelet /var/lib/kubelet; mount --make-shared /var/lib/kubelet
# # }

# # export K8S_VERSION=$(curl -sS https://storage.googleapis.com/kubernetes-release/release/stable.txt)
# # # export K8S_VERSION=$(curl -sS https://storage.googleapis.com/kubernetes-release/release/latest.txt)

# # export ARCH=amd64

# # docker run -d --volume=/sys:/sys:rw --volume=/var/lib/docker/:/var/lib/docker:rw --volume=/var/lib/kubelet/:/var/lib/kubelet:rw,shared --volume=/var/run:/var/run:rw --net=host --pid=host --privileged gcr.io/google_containers/hyperkube-${ARCH}:${K8S_VERSION} /hyperkube kubelet --hostname-override=127.0.0.1 --api-servers=http://localhost:8080 --config=/etc/kubernetes/manifests --cluster-dns=10.0.0.10 --cluster-domain=cluster.local --allow-privileged --v=2

# # wget http://storage.googleapis.com/kubernetes-release/release/v1.3.0/bin/linux/amd64/kubectl -O /sbin/kubectl
# # chmod +x /sbin/kubectl

# # #
# # # Install GCloud
# # # @link https://cloud.google.com/sdk/downloads#linux
# # #

# # echo "Installing gcloud and kubectl must be done individualy on any machine unfortunately ... "
# # echo "curl https://sdk.cloud.google.com | bash"
# # echo "exec -l \$SHELL"
# # echo "gcloud init"
# # echo "gcloud components install kubectl"

# # # Using this will work, however won't let you install kubectl in the end (kinda sux)
# # # @link https://code.google.com/p/google-cloud-sdk/issues/detail?id=336
# # # However, you could always uncomment the wget/chmod lines above and this should bring everything on the right path.

# # # Create an environment variable for the correct distribution
# # export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
# # # Add the Cloud SDK distribution URI as a package source
# # echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
# # # Import the Google Cloud public key
# # curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
# # # Update and install the Cloud SDK
# # sudo apt-get update && sudo apt-get install google-cloud-sdk
# # # Run gcloud init to get started
# # # gcloud init


# # kubectl config set-cluster test-doc --server=http://localhost:8080
# # kubectl config set-context test-doc --cluster=test-doc
# # kubectl config use-context test-doc

# # docker run -t -p 80:80 nginx
# # docker ps | grep nginx | awk -F ' ' '{ print $1 }' | while read line; do
# #   docker stop $line
# # done

# # curl http://localhost

# # kubectl run hello-node --image=nginx --port=8080
# # kubectl get deployments
# # kubectl get pods
# # kubectl get services

# # kubectl cluster-info

# # kubectl expose deployment hello-node --type="LoadBalancer"
# # kubectl get services hello-node

# # kubectl scale deployment hello-node --replicas=4
# # kubectl get deployments
# # kubectl get pods
# # kubectl get services
