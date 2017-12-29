#This is installation for OpenStack Pike Release.

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

#Add Repository and update
yum install centos-release-openstack-pike

#for Ubuntu
#apt install -y software-properties-common
#add-apt-repository -y cloud-archive:pike

yum upgrade

#openstack client 
yum install python-openstackclient

#security management
yum install openstack-selinux

