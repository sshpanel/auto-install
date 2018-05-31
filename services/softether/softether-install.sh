#!/bin/bash
# Autoscript dropbear by: VPN Panel & SSH Panel.

. $HOME/auto-install/support/app-check.sh
. $HOME/auto-install/support/os-detector.sh
. $HOME/auto-install/support/string-helper.sh
. $HOME/auto-install/support/welcome-screen.sh

HUB_PASSWORD=$(LC_CTYPE=C tr -dc 'A-HJ-NPR-Za-km-z2-9' < /dev/urandom | head -c 16)
ADMIN_PASSWORD=$(LC_CTYPE=C tr -dc 'A-HJ-NPR-Za-km-z2-9' < /dev/urandom | head -c 16)
L2TP_IPSEC=$(LC_CTYPE=C tr -dc 'A-HJ-NPR-Za-km-z2-9' < /dev/urandom | head -c 9)

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
	rm soft*
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

	# installing required packages
	yum update -y
	yum install gcc zlib-devel openssl-devel readline-devel ncurses-devel wget tar dnsmasq net-tools iptables-services system-config-firewall-tui nano -y
	yum groupinstall "Development Tools" -y
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

	# preparing firewall & iptables rule
	systemctl disable firewalld
	systemctl stop firewalld
	systemctl status firewalld
	service iptables save
	service iptables stop
	chkconfig iptables off

	# downloadi & unpack software
	cd /usr/src
	wget www.softether-download.com/files/softether/v4.20-9608-rtm-2016.04.17-tree/Linux/SoftEther_VPN_Server/64bit_-_Intel_x64_or_AMD64/softether-vpnserver-v4.20-9608-rtm-2016.04.17-linux-x64-64bit.tar.gz
	tar xzvf softether-vpnserver-v4.20-9608-rtm-2016.04.17-linux-x64-64bit.tar.gz -C /usr/local
	
	# start services & configuring
	cd /usr/local/vpnserver
	printf "1\n1\n1\n" | make

	# creating systemctl daemon
	cat <<EOF > /etc/init.d/vpnserver
#!/bin/sh
### BEGIN INIT INFO
# Provides: vpnserver
# Required-Start: $remote_fs $syslog
# Required-Stop: $remote_fs $syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Start daemon at boot time
# Description: Enable Softether by daemon.
### END INIT INFO
DAEMON=/usr/local/vpnserver/vpnserver
LOCK=/var/lock/subsys/vpnserver
TAP_ADDR=192.168.7.1

test -x $DAEMON || exit 0
case "$1" in
start)
$DAEMON start
touch $LOCK
sleep 1
/sbin/ifconfig tap_soft $TAP_ADDR
;;
stop)
$DAEMON stop
rm $LOCK
;;
restart)
$DAEMON stop
sleep 3
$DAEMON start
sleep 1
/sbin/ifconfig tap_soft $TAP_ADDR
;;
*)
echo "Usage: $0 {start|stop|restart}"
exit 1
esac
exit 0
EOF

	# starting systemctl
	chmod +x /etc/init.d/vpnserver
	/etc/init.d/vpnserver start
	systemctl enable vpnserver

fi

# setup last required actions
# SETTING UP ADMIN PASSWORD

cd /usr/local/vpnserver
./vpncmd localhost /SERVER /CMD: ServerPasswordSet $(echo $ADMIN_PASSWORD)

# CREATE NEW VIRTUAL HUB

cd /usr/local/vpnserver
./vpncmd localhost /SERVER /PASSWORD:$(echo $ADMIN_PASSWORD) /CMD: HubCreate VPNPANEL /PASSWORD: $(echo $HUB_PASSWORD)

# ENABLE L2TP/IPSec
 
cd /usr/local/vpnserver
./vpncmd localhost /SERVER /PASSWORD:$(echo $ADMIN_PASSWORD) /CMD: IPsecEnable /L2TP:yes /L2TPRAW:yes /PSK:$(echo $L2TP_IPSEC) /DEFAULTHUB:VPNPANEL


cat <<EOF >> ~/auto-install/creds

#####################################################
#                SoftEther DETAILS                  #
#####################################################
#                                                   #
#	Software : SoftEther                            #
#   Port     : 443, 992, 8888, 500, 1194            #
#   Command  : netstat -nltp | grep softether       #
#                                                   #
#   HUB Details   :                                 #
#		Name      : VPNPANEL                        #
#		Password  : $(echo $HUB_PASSWORD)           #
#                                                   #
#   ADMIN Details :                                 #
#       Password  : $(echo $ADMIN_PASSWORD)         #
#####################################################


EOF
