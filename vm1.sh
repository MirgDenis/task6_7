#!/bin/bash
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

exec 3>&1 1>>/etc/network/interfaces
source "$dir/vm1.config"
#Configure VLAN and Internal interface

echo -e "\n# Internal. Host-only"
echo "auto $INTERNAL_IF"
echo "iface $INTERNAL_IF inet static"
echo "address $(echo $INT_IP | cut -d / -f 1)"
echo "netmask $(echo $INT_IP | cut -d / -f 2)"
echo -e "\n# VLAN\nauto $INTERNAL_IF.$VLAN"
echo "iface $INTERNAL_IF.$VLAN inet static"
echo "address $(echo $VLAN_IP | cut -d / -f 1)"
echo "netmask $(echo $VLAN_IP | cut -d / -f 2)"
echo "vlan-raw-device $INTERNAL_IF"

#Checking DHCP or static and configure External

if [ "$EXT_IP" == DHCP ]
then
	echo -e "\n# External"
	echo "auto $EXTERNAL_IF"
	echo "iface $EXTERNAL_IF inet dhcp"
else
	echo -e "\n# External" 
	echo "auto $EXTERNAL_IF"
	echo "iface $EXTERNAL_IF inet static"
	echo "address $(echo $EXT_IP | cut -d / -f 1)"
	echo "netmask $(echo $EXT_IP | cut -d / -f 2)"
	echo "gateway $EXT_GW"
fi
exec 1>&3 3>&-

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




