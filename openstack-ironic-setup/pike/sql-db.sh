#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi


M_IP=
C_IP=
D_IP=
PASSWORD=PASS
SQL_CONF=/etc/my.cnf.d/openstack.cnf

# Install & Configure MYSQL
#sudo debconf-set-selections <<< "mariadb-server mysql-server/root_password password $PASSWORD"
#sudo debconf-set-selections <<< "mariadb-server mysql-server/root_password_again password $PASSWORD"

yum install mariadb mariadb-server python2-PyMySQL



touch $SQL_CONF
echo "[mysqld]
bind-address = $(C_IP)

default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8" >> $SQL_CONF

systemctl enable mariadb.service
systemctl start mariadb.service


echo -e "$PASSWORD\nn\ny\ny\ny\ny" | mysql_secure_installation


# Intall & Configure RabbitMQ

yum install rabbitmq-server

systemctl enable rabbitmq-server.service
systemctl start rabbitmq-server.service

rabbitmqctl add_user openstack $PASSWORD
rabbitmqctl set_permissions openstack ".*" ".*" ".*"


# Install & configure Memcached
yum install memcached python-memcached

sed -i "s/127.0.0.1/$C_IP/g" /etc/memcached.conf

systemctl enable memcached.service
systemctl start memcached.service

