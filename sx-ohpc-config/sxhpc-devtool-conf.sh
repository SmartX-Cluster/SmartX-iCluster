#!/bin/bash
# -----------------------------------------------------------------------------------------
#  Example Installation Script Template
#  
#  This convenience script encapsulates command-line instructions highlighted in
#  the OpenHPC Install Guide that can be used as a starting point to perform a local
#  cluster install beginning with bare-metal. Necessary inputs that describe local
#  hardware characteristics, desired network settings, and other customizations
#  are controlled via a companion input file that is used to initialize variables 
#  within this script.
#   
#  Please see the OpenHPC Install Guide for more information regarding the
#  procedure. Note that the section numbering included in this script refers to
#  corresponding sections from the install guide.
# -----------------------------------------------------------------------------------------

inputFile=${OHPC_INPUT_LOCAL:-./input-smartx.local}

if [ ! -e ${inputFile} ];then
   echo "Error: Unable to access local input file -> ${inputFile}"
   exit 1
else
   . ${inputFile} || { echo "Error sourcing ${inputFile}"; exit 1; }
fi

# ---------------------------------------
# Install Development Tools (Section 4.1)
# ---------------------------------------
yum -y install ohpc-autotools
yum -y install EasyBuild-ohpc
yum -y install hwloc-ohpc
yum -y install spack-ohpc
yum -y install valgrind-ohpc

# -------------------------------
# Install Compilers (Section 4.2)
# -------------------------------
yum -y install gnu7-compilers-ohpc
yum -y install llvm5-compilers-ohpc

if [[ ${enable_mpi_defaults} -eq 1 && ${enable_pmix} -eq 0 ]];then
     yum -y install openmpi3-gnu7-ohpc mpich-gnu7-ohpc
elif [[ ${enable_mpi_defaults} -eq 1 && ${enable_pmix} -eq 1 ]];then
     yum -y install openmpi3-pmix-slurm-gnu7-ohpc mpich-gnu7-ohpc
fi

if [[ ${enable_ib} -eq 1 ]];then
     yum -y install mvapich2-gnu7-ohpc
fi
if [[ ${enable_opa} -eq 1 ]];then
     yum -y install mvapich2-psm2-gnu7-ohpc
fi


