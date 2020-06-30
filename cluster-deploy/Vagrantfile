# use Ubuntu Desktop vagrant image from 'fasmat'

Vagrant.configure("2") do |config|
  config.vm.box = "fasmat/ubuntu2004-desktop"
  config.vm.box_version = "20.0606.1"
  config.vm.box_check_update = false

  # dimension the VM
  config.vm.provider "virtualbox" do |vb|
      # vb.linked_clone = true
      vb.cpus = 2
      vb.memory = 4096
  end
  
  # install tutorial prerequisites
  config.vm.provision :shell, path: "install.sh"

end
