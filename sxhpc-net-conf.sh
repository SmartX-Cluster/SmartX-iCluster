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
   wwsh -y node new ${c_name[i]} --ipaddr=${m_ip[i]} --hwaddr=${m_mac[i]} -D ${eth_provision} --netmask=${m_netmask} --gateway=${m_gateway}

done

wwsh -y provision set "${compute_regex}" --vnfs=centos7.4 --bootstrap=`uname -r` --files=dynamic_hosts,passwd,group,shadow,slurm.conf,munge.key,network

echo "end of eth1"

for ((i=0; i<${num_computes}; i++)) ; do

   wwsh -y node set ${c_name[i]} -D eth1 --ipaddr=${c_ip[i]} --netmask=${m_netmask} --hwaddr=${c_mac[i]}
done


echo "end of eth0-2"

for ((i=0; i<${num_computes}; i++)) ; do

wwsh -y node set ${c_name[i]} -D eth2 --ipaddr=${d_ip[i]} --netmask=${m_netmask} --hwaddr=${d_mac[i]}

done



