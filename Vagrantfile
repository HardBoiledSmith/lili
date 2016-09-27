# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/xenial64"

  config.vm.provider "virtualbox" do |v|
    v.cpus = 1
    v.memory = 256
  end

  config.vm.provision "shell", path: "provisioning.sh"
  config.vm.network "private_network", ip: "192.168.100.100"
end
