# OpenStack Neutron for Flat (Provider) networking on CentOS 7

#!/bin/bash


if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

M_IP=
C_IP=
D_IP=
PASSWORD=PASS

# for VM networking,
#sed -i "/#kernel.domainname = example.com/a\
#net.ipv4.ip_forward=1\n\
#net.ipv4.conf.all.rp_filter=0\n\
#net.ipv4.conf.default.rp_filter=0" /etc/sysctl.conf



#1.To create the database, complete these steps:
cat << EOF | mysql -uroot -p$PASSWORD
CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '$PASSWORD';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '$PASSWORD';
quit
EOF

#2.Source the admin credentials to gain access to admin-only CLI commands:
source admin-openrc.sh

#3.To create the service credentials, complete these steps:
#◦Create the neutron user:
openstack user create --domain default --password $PASSWORD neutron

#◦Add the admin role to the neutron user:
openstack role add --project service --user neutron admin

#◦Create the neutron service entity:
openstack service create --name neutron \
  --description "OpenStack Networking" network


#4.Create the Networking service API endpoints:
openstack endpoint create --region RegionOne \
  network public http://$M_IP:9696

openstack endpoint create --region RegionOne \
  network internal http://$C_IP:9696

openstack endpoint create --region RegionOne \
  network admin http://$C_IP:9696


#Install the components
yum install openstack-neutron openstack-neutron-ml2 \
  openstack-neutron-linuxbridge ebtables


##•Edit the /etc/neutron/neutron.conf file and complete the following actions:
sed -i "s/connection = sqlite:\/\/\/\/var\/lib\/neutron\/neutron.sqlite/connection = mysql+pymysql:\/\/neutron:$PASSWORD@$C_IP\/neutron/g" /etc/neutron/neutron.conf

sed -i "s/#core_plugin =/core_plugin = ml2\n\
rpc_backend = rabbit\n\
auth_strategy = keystone\n\
notify_nova_on_port_status_changes = True\n\
notify_nova_on_port_data_changes = True/g" /etc/neutron/neutron.conf

#◦In the [DEFAULT] section, configure RabbitMQ message queue access:
sed -i "s/#transport_url = <None>/transport_url = rabbit:\/\/openstack:$PASSWORD@$C_IP/g" /etc/neutron/neutron.conf

sed -i "s/#auth_uri = <None>/auth_uri = http:\/\/$C_IP:5000\n\
auth_url = http:\/\/$C_IP:35357\n\
memcached_servers = $C_IP:11211\n\
auth_type = password\n\
project_domain_name = default\n\
user_domain_name = default\n\
project_name = service\n\
username = neutron\n\
password = $PASSWORD/g" /etc/neutron/neutron.conf


sed -i "s/#auth_url = <None>/auth_url = http:\/\/$C_IP:35357\n\
auth_type = password\n\
project_domain_name = default\n\
user_domain_name = default\n\
region_name = RegionOne\n\
project_name = service\n\
username = nova\n\
password = $PASSWORD/g" /etc/neutron/neutron.conf

#•Edit the /etc/neutron/plugins/ml2/ml2_conf.ini file and complete the following actions:
sed -i "s/#type_drivers = local,flat,vlan,gre,vxlan,geneve/type_drivers = flat,vlan\n\
tenant_network_types = \n\
mechanism_drivers = linuxbridge\n\
extension_drivers = port_security\n\
enable_ipset = true/g" /etc/neutron/plugins/ml2/ml2_conf.ini

#sed -i "s/#vxlan_group = <None>/#vxlan_group = <None>\n\
#vni_ranges = 1:1000/g" /etc/neutron/plugins/ml2/ml2_conf.ini

sed -i "s/#flat_networks = \*/flat_networks = provider/g" /etc/neutron/plugins/ml2/ml2_conf.ini

sed -i "s/#firewall_driver = <None>/firewall_driver = iptables_hybrid\n\
enable_ipset = True/g" /etc/neutron/plugins/ml2/ml2_conf.ini


#.In the openvswitch_agent.ini file, configure the Open vSwitch agent:
#sed -i "s/#local_ip = <None>/local_ip = $D_IP/g" /etc/neutron/plugins/ml2/openvswitch_agent.ini
#sed -i "s/#tunnel_types =/tunnel_types = vxlan\n\l2_population = True/g" /etc/neutron/plugins/ml2/openvswitch_agent.ini
#sed -i "s/#firewall_driver = <None>/firewall_driver = iptables_hybrid\n\enable_security_group = true/g" /etc/neutron/plugins/ml2/openvswitch_agent.ini
#sed -i "s/#arp_responder = false/arp_responder = True/g" /etc/neutron/plugins/ml2/openvswitch_agent.ini
#sed -i "s/#enable_distributed_routing = false/enable_distributed_routing = True/g" /etc/neutron/plugins/ml2/openvswitch_agent.ini
#sed -i "s/#bridge_mappings =/bridge_mappings = external:br-ex/g" /etc/neutron/plugins/ml2/openvswitch_agent.ini


#.In the l3_agent.ini file, configure the L3 agent:
#sed -i "s/#interface_driver = <None>/interface_driver = openvswitch/g" /etc/neutron/l3_agent.ini
#sed -i "s/#external_network_bridge =/external_network_bridge = /g" /etc/neutron/l3_agent.ini
#sed -i "s/#agent_mode = legacy/agent_mode = dvr_snat/g" /etc/neutron/l3_agent.ini


#configure Linux Bridge
sed -i "s/physical_interface_mappings =/physical_interface_mappings = provider:$D_IF" /etc/neutron/plugins/ml2/linuxbridge_agent.ini

sed -i "s/enable_vxlan = false/enable_vxlan = true" /etc/neutron/plugins/ml2/linuxbridge_agent.ini
sed -i "s/enable_security_group = true \n
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver" /etc/neutron/plugins/ml2/linuxbridge_agent.ini



#.In the dhcp_agent.ini file, configure the DHCP agent:
sed -i "s/#enable_isolated_metadata = false/enable_isolated_metadata = True/g" /etc/neutron/dhcp_agent.ini

sed -i "s/#interface_driver = <None>/interface_driver = linuxbridge/g" /etc/neutron/dhcp_agent.ini
sed -i "s/#dhcp_driver = <None>/dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq/g" /etc/neutron/dhcp_agent.ini

#touch /etc/neutron/dnsmasq-neutron.conf
#echo "dhcp-option-force=26,1400" >> /etc/neutron/dnsmasq-neutron.conf

#sed -i "s/#dnsmasq_config_file =/dnsmasq_config_file = \/etc\/neutron\/dnsmasq-neutron.conf/g" /etc/neutron/dhcp_agent.ini

#pkill dnsmasq




#•Edit the /etc/neutron/plugins/ml2/ml2_conf.ini file and complete the following actions:
sed -i "s/#type_drivers = local,flat,vlan,gre,vxlan,geneve/type_drivers = flat,vlan,vxlan\n\
tenant_network_types = vxlan\n\
mechanism_drivers = openvswitch,l2population\n\
extension_drivers = port_security/g" /etc/neutron/plugins/ml2/ml2_conf.ini

sed -i "s/#vxlan_group = <None>/#vxlan_group = <None>\n\
vni_ranges = 1:1000/g" /etc/neutron/plugins/ml2/ml2_conf.ini

sed -i "s/#flat_networks = \*/flat_networks = external/g" /etc/neutron/plugins/ml2/ml2_conf.ini

sed -i "s/#firewall_driver = <None>/firewall_driver = iptables_hybrid\n\
enable_ipset = True/g" /etc/neutron/plugins/ml2/ml2_conf.ini


#.In the dhcp_agent.ini file, configure the DHCP agent:
sed -i "s/#enable_isolated_metadata = false/enable_isolated_metadata = True/g" /etc/neutron/dhcp_agent.ini

sed -i "s/#interface_driver = <None>/interface_driver = openvswitch/g" /etc/neutron/dhcp_agent.ini

touch /etc/neutron/dnsmasq-neutron.conf
echo "dhcp-option-force=26,1400" >> /etc/neutron/dnsmasq-neutron.conf

sed -i "s/#dnsmasq_config_file =/dnsmasq_config_file = \/etc\/neutron\/dnsmasq-neutron.conf/g" /etc/neutron/dhcp_agent.ini

pkill dnsmasq



#.In the metadata_agent.ini file, configure the metadata agent:
sed -i "s/#nova_metadata_host = 127.0.0.1/nova_metadata_host = $C_IP/g" /etc/neutron/metadata_agent.ini

sed -i "s/#metadata_proxy_shared_secret =/metadata_proxy_shared_secret = METADATA_SECRET/g" /etc/neutron/metadata_agent.ini


#•Edit the /etc/nova/nova.conf file and complete the following actions:
#◦In the [neutron] section, configure access parameters:

sed -i "s/#url = http:\/\/127.0.0.1:9696/url = http:\/\/$C_IP:9696\n\
auth_url = http:\/\/$C_IP:35357\n\
auth_type = password\n\
project_domain_name = default\n\
user_domain_name = default\n\
region_name = RegionOne\n\
project_name = service\n\
username = neutron\n\
password = $PASSWORD\n\
service_metadata_proxy = true\n\
metadata_proxy_shared_secret = METADATA_SECRET/g" /etc/nova/nova.conf



#Finalize installation
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

#Restart the Compute service:
systemctl restart openstack-nova-api.service

systemctl enable neutron-server.service \
  neutron-linuxbridge-agent.service neutron-dhcp-agent.service \
  neutron-metadata-agent.service
systemctl start neutron-server.service \
  neutron-linuxbridge-agent.service neutron-dhcp-agent.service \
  neutron-metadata-agent.service

