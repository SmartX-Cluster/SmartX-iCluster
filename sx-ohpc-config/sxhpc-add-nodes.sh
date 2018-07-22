#!/bin/bash

inputFile=${OHPC_INPUT_LOCAL:-./input-smartx.local}

if [ ! -e ${inputFile} ];then
   echo "Error: Unable to access local input file -> ${inputFile}"
   exit 1
else
   . ${inputFile} || { echo "Error sourcing ${inputFile}"; exit 1; }
fi

# --------------------------------
# Boot compute nodes (Section 3.9)
# --------------------------------
for ((i=0; i<${num_computes}; i++)) ; do
   wwsh -y node new ${c_name[i]} --ipaddr=${c_ip[i]} --hwaddr=${c_mac[i]} -D ${eth_provision} --netmask=${c_netmask} 
done


wwsh file import /home/lucas/sx-hpc-config/ifcfg-eth0.ww --path=/etc/sysconfig/network-scripts/ifcfg-eth0 --name m-network
wwsh file import /home/lucas/sx-hpc-config/ifcfg-eth2.ww --path=/etc/sysconfig/network-scripts/ifcfg-eth2 --name d-network



for ((i=0; i<${num_computes}; i++)) ; do
   wwsh -y node set ${c_name[i]} -D eth0 --ipaddr=${m_ip[i]} --netmask=${m_netmask} --hwaddr=${m_mac[i]}
done


for ((i=0; i<${num_computes}; i++)) ; do
   wwsh -y node set ${c_name[i]} -D eth2 --ipaddr=${d_ip[i]} --netmask=${m_netmask} --hwaddr=${d_mac[i]}

done

wwsh -y provision set "${compute_regex}" --vnfs=centos7.4 --bootstrap=`uname -r` --files=dynamic_hosts,passwd,group,shadow,slurm.conf,munge.key,network,m-network,d-network


