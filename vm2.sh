#!/bin/bash
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$dir/vm2.config"
source <(grep 'INT_IP=.*' $dir/vm1.config)
exec 3>&1 1>>/etc/network/interfaces
#Configure VLAN and Internal interface
echo -e "\n# Internal. Host-only"
echo "auto $INTERNAL_IF"
echo "iface $INTERNAL_IF inet static"
echo "address $(echo $INTERNAL_IP | cut -d / -f 1)"
echo "netmask $(echo $INTERNAL_IP | cut -d / -f 2)"
echo "gateway $(echo $INT_IP | cut -d / -f 1)"
echo "dns-nameservers 8.8.8.8"
echo -e "\n# VLAN"
echo "auto $INTERNAL_IF.$VLAN"
echo "iface $INTERNAL_IF.$VLAN inet static"
echo "address $(echo $APACHE_VLAN_IP | cut -d / -f 1)"
echo "netmask $(echo $APACHE_VLAN_IP | cut -d / -f 2)"
echo "vlan-raw-device $INTERNAL_IF"
exec 1>&3 3>&-

#Configure Manage interface



#Restart Down Up

ifdown $INTERNAL_IF && ifup $INTERNAL_IF
ifdown $INTERNAL_IF.$VLAN && ifup $INTERNAL_IF.$VLAN
#ifdown $MANAGMENT_IF && ifup $MANAGMENT_IF

#Install and configure Apache2

apt-get -y install apache2
sed -i '/<Directory \/>/a Order Allow,Deny\nAllow from 10.0.1.1' /etc/apache2/apache2.conf
service apache2 restart

