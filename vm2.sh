#!/bin/bash
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$dir/vm2.config"
#Configure VLAN and Internal interface
echo -e "\n# Internal. Host-only\nauto $INTERNAL_IF\niface $INTERNAL_IF inet static\naddress $(echo $INT_IP | cut -d / -f 1)\nnetmask $(echo $INT_IP | cut -d / -f 2)\ndns-nameservers 8.8.8.8" >> /etc/network/interfaces
echo -e "\n# VLAN\nauto $INTERNAL_IF.$VLAN\niface $INTERNAL_IF.$VLAN inet static\naddress $(echo $VLAN_IP | cut -d / -f 1)\nnetmask $(echo $VLAN_IP | cut -d / -f 2)\nvlan-raw-device $INTERNAL_IF" >> /etc/network/interfaces

#Configure Manage interface



#Restart Down Up

ifdown $INTERNAL_IF && ifup $INTERNAL_IF
ifdown $INTERNAL_IF.$VLAN && ifup $INTERNAL_IF.$VLAN
#ifdown $MANAGMENT_IF && ifup $MANAGMENT_IF

#Install and configure Apache2

apt-get -y install apache2
sed -i '/<Directory \/>/a Order Allow,Deny\nAllow from 10.0.1.1' /etc/apache2/apache2.conf
service apache2 restart

