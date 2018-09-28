#! /bin/bash

chains="$1"

mydir=$(dirname $0)

cd $mydir

conf_file="Vagrantfile"
if [ -f "${conf_file}" ]; then
  rm ${conf_file}
  touch ${conf_file}
fi

bash -c "cat > ${conf_file}" <<EOF
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|

  config.vm.box = 'vbng'

  config.vm.synced_folder './shared', '/vagrant'
EOF

for i in $(seq 1 ${chains}); do
bash -c "cat >> ${conf_file}" <<EOF
  config.vm.define vm_name = 'v${i}Edge' do |v${i}Edge|
    v${i}Edge.vm.hostname = vm_name
    v${i}Edge.vm.provider :libvirt do |v|
      v.cpus = 3
      v.numa_nodes = [
        {:cpus => '0-2', :memory => '4096'}
      ]
      v.memorybacking :hugepages
      v.memorybacking :access, :mode => 'shared'
    end
  end
EOF
done

echo "end" >> ${conf_file}

exit 0  
