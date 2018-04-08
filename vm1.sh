#!/bin/bash
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$dir/vm1.config"
#Configure VLAN and Internal interface

echo -e "\n# Internal. Host-only\nauto $INTERNAL_IF\niface $INTERNAL_IF inet static\naddress $(echo $INT_IP | cut -d / -f 1)\nnetmask $(echo $INT_IP | cut -d / -f 2)" >> /etc/network/interfaces
echo -e "\n# VLAN\nauto $INTERNAL_IF.$VLAN\niface $INTERNAL_IF.$VLAN inet static\naddress $(echo $VLAN_IP | cut -d / -f 1)\nnetmask $(echo $VLAN_IP | cut -d / -f 2)\nvlan-raw-device $INTERNAL_IF" >> /etc/network/interfaces

#Checking DHCP or static and configure External

if [ "$EXT_IP" == DHCP ]
then
	echo -e "\n# External\nauto $EXTERNAL_IF\niface $EXTERNAL_IF inet dhcp" >> /etc/network/interfaces
else
	echo -e "\n# External \nauto $EXTERNAL_IF\niface $EXTERNAL_IF inet static\naddress $(echo $EXT_IP | cut -d / -f 1)\nnetmask $(echo $EXT_IP | cut -d / -f 2)\ngateway $EXT_GW" >> /etc/network/interfaces
fi

#Configure Manage interface



#Restart Up Down

ifdown $INTERNAL_IF && ifup $INTERNAL_IF
ifdown $INTERNAL_IF.$VLAN && ifup $INTERNAL_IF.$VLAN
ifdown $EXTERNAL_IF && ifup $EXTERNAL_IF
#ifdown $MANAGMENT_IF && ifup $MANAGMENT_IF

#Iptables for access to internet from VM2

sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl --system
iptables -t nat -A POSTROUTING -o $EXTERNAL_IF -j MASQUERADE




