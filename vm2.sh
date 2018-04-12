#!/bin/bash
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$dir/vm2.config"
modprobe 8021q

#Down
ifdown $INTERNAL_IF

#Configure VLAN and Internal interface

echo "
# Interfaces available
source /etc/network/interfaces.d/*

# Loopback
auto lo
iface lo inet loopback

# Internal. Host-only
auto $INTERNAL_IF
iface $INTERNAL_IF inet static
address $(echo $INTERNAL_IP | cut -d / -f 1)
netmask $(echo $INTERNAL_IP | cut -d / -f 2)
gateway $GW_IP
dns-nameservers 8.8.8.8

# VLAN
auto $INTERNAL_IF.$VLAN
iface $INTERNAL_IF.$VLAN inet static
address $(echo $APACHE_VLAN_IP | cut -d / -f 1)
netmask $(echo $APACHE_VLAN_IP | cut -d / -f 2)
vlan-raw-device $INTERNAL_IF" >/etc/network/interfaces

#Up

ifup $INTERNAL_IF
ifup $INTERNAL_IF.$VLAN

#Install and configure Apache2

apt-get -y install apache2
sed -i "s/Listen 80/Listen $(echo $APACHE_VLAN_IP | cut -d / -f 1):80/" /etc/apache2/ports.conf
service apache2 restart

