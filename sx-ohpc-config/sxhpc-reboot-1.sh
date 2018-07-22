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
for ((i=0; i<4; i++)) ; do
   ipmitool -E -I lanplus -H ${c_bmc[$i]} -U ${bmc_username} -P ${bmc_password} chassis power reset
done


