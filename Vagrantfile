Vagrant.configure(2) do |config|

  (1..2).each do |i|
    config.vm.define "k8s#{i}" do |s|
      s.ssh.forward_agent = true
      # s.vm.box = "ubuntu/bionic64"
      s.vm.box = "debian/stretch64"
      s.vm.box_version = "9.4.0"
      if i == 1
        s.vm.hostname = "k8smaster"
      else
        s.vm.hostname = "k8snode#{i}"
      end

      # s.vm.network "private_network", ip: "192.168.56.10#{i}", netmask: "255.255.255.0", auto_config: true, virtualbox__intnet: "k8s-net"
      s.vm.network "public_network", ip: "192.168.1.23#{i}", netmask: "255.255.255.0", auto_config: true, bridge: "enp6s0"
      s.vm.provider "virtualbox" do |v|
        v.name = "k8s#{i}"
        v.cpus = 2
        v.memory = 3072
        v.gui = false
      end

      s.vm.synced_folder ".", "/vagrant"

      s.vm.provision "shell", inline: <<-SCRIPT

echo "192.168.1.23#{i} #{s.vm.hostname} #{s.vm.hostname}" >> /etc/hosts

apt-get update
apt-get install -y git make

git clone https://github.com/dragoscirjan/configs
# cd configs/docker
# make i

# usermod -G docker vagrant

# make ki
SCRIPT

      # if i == 1
      #   s.vm.provision :shell, path: "scripts/bootstrap_master.sh"
      # else
      #   s.vm.provision :shell, path: "scripts/bootstrap_worker.sh"
      # end
    end
  end

end