#!/bin/bash
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$dir/vm1.config"
#Configure VLAN and Internal interface

exec 3>&1 1>>/etc/network/interfaces
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

#Creating root cert

openssl genrsa -out /etc/ssl/private/root-ca.key 2048
openssl req -x509 -new -key /etc/ssl/private/root-ca.key -days 365 -out /etc/ssl/certs/root-ca.crt -subj '/C=UA/ST=Kharkiv/L=Kharkiv/O=NURE/OU=Mirantis/CN=rootCA'

#Creating web cert singing request and sing

openssl genrsa -out /etc/ssl/private/web.key 2048
openssl req -new -key /etc/ssl/private/web.key -nodes -out /etc/ssl/certs/web.csr -subj "/C=UA/ST=Kharkiv/L=Karkiv/O=NURE/OU=Mirantis/CN=$(hostname -f)"

if [ "$EXT_IP" == DHCP ]
then
	IP=`ifconfig $EXTERNAL_IF | grep "inet addr:" | cut -d: -f2 | awk '{print $1}'`
	openssl x509 -req -extfile <(printf "subjectAltName=IP:$IP") -days 365 -in /etc/ssl/certs/web.csr -CA /etc/ssl/certs/root-ca.crt -CAkey /etc/ssl/private/root-ca.key -CAcreateserial -out /etc/ssl/certs/web.crt
else
	openssl x509 -req -extfile <(printf "subjectAltName=IP:$EXT_IP") -days 365 -in /etc/ssl/certs/web.csr -CA /etc/ssl/certs/root-ca.crt -CAkey /etc/ssl/private/root-ca.key -CAcreateserial -out /etc/ssl/certs/web.crt
fi

#Creating cert chain and moving to certs dir

cat /etc/ssl/certs/web.crt /etc/ssl/certs/root-ca.crt > web-bundle.crt
mv ./web-bundle.crt /etc/ssl/certs

#Install nginx and configure virtual hosts

apt-get -y install nginx
cat <<EOM >/etc/nginx/sites-available/default
server {
	listen $NGINX_PORT ssl;
	ssl on;
	ssl_certificate /etc/ssl/certs/web-bundle.crt;
	ssl_certificate_key /etc/ssl/private/web.key;

	location / {
		proxy_pass http://$APACHE_VLAN_IP;
	}
}
EOM
service nginx restart
