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
	apt-get -y install git
fi

if [[ "$OS" = "centos" ]]; then
	yum -y install git
fi

cd ~
git clone https://github.com/sshpanel/setup-ipsec-vpn
cd setup-ipsec-vpn
bash configure

cat <<EOF >> ~/auto-install/creds

#####################################################
#               L2TP/IPSec DETAILS                  #
#####################################################
#                                                   #
#	Software : L2TP/IPSec                           #
#   Port     : 1701                                 #
#   Command  : netstat -nltp | grep 1701            #
#                                                   #
#####################################################


EOF
