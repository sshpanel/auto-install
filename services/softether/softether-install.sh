#!/bin/bash
# Autoscript dropbear by: VPN Panel & SSH Panel.

. $HOME/auto-install/support/app-check.sh
. $HOME/auto-install/support/os-detector.sh
. $HOME/auto-install/support/string-helper.sh
. $HOME/auto-install/support/welcome-screen.sh


# Detect Debian users running the script with "sh" instead of bash
if readlink /proc/$$/exe | grep -q "dash"; then
	danger "This script needs to be run with bash!, not sh"
	exit
fi

if [[ "$EUID" -ne 0 ]]; then
	danger "Sorry, you need to run this as root!"
	exit
fi

if [[ -e /etc/debian_version ]]; then
	OS=debian
	GROUPNAME=nogroup
	RCLOCAL='/etc/rc.local'
elif [[ -e /etc/centos-release || -e /etc/redhat-release ]]; then
	OS=centos
	GROUPNAME=nobody
	RCLOCAL='/etc/rc.d/rc.local'
else
	danger "You aren't running this installer on Debian, Ubuntu or CentOS, Aborting!"
	exit
fi

info "Installing L2TP..."

if [[ "$OS" = "debian" ]]; then
	apt-get -y update upgrade
	apt-get install build-essential wget sed -y
	wget http://www.softether-download.com/files/softether/v4.22-9634-beta-2016.11.27-tree/Linux/SoftEther_VPN_Server/64bit_-_Intel_x64_or_AMD64/softether-vpnserver-v4.22-9634-beta-2016.11.27-linux-x64-64bit.tar.gz
	tar xzf softether-vpnserver-v4.22-9634-beta-2016.11.27-linux-x64-64bit.tar.gz
	cd vpnserver
	printf "1\n1\n1\n" | sudo make
	./vpnserver start
	cd ..
	mv vpnserver /usr/local/vpnserver
	cd /usr/local/vpnserver
	sudo chmod 600 *
	sudo chmod 700 vpnserver
	sudo chmod 700 vpncmd

	cat <<EOF > /lib/systemd/system/vpnserver.service
[Unit]
Description=SoftEther VPN Server
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/vpnserver/vpnserver start
ExecStop=/usr/local/vpnserver/vpnserver stop

[Install]
WantedBy=multi-user.target
EOF

	systemctl start vpnserver

fi 	

if [[ "$OS" = "centos" ]]; then
	yum -y install git
fi

