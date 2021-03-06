#!/bin/bash 
# Author: Rizal Fakhri <rizal@codehub.id>

. $HOME/auto-install/support/os-detector.sh

display_sshpanel_screen()
{
    echo -e "\e[91m #########################################################################\e[0m"
    echo -e "   \e[95m_______\e[0m  \e[95m_______\e[0m  __   __  _______  _______  __    _  _______  ___       "    
    echo -e "  |       ||       ||  | |  ||       ||   \e[91m_\e[0m   ||  |  | ||       ||   |      "   
    echo -e "  |  _____||  _____||  |_|  ||    \e[91m_\e[0m  ||  \e[91m|_|\e[0m  ||  |_|  ||    ___||   |      "   
    echo -e "  | |_____ | |_____ |       ||   \e[91m|_|\e[0m ||       ||       ||   |___ |   |      "  
    echo -e "  |_____  ||_____  ||       ||    ___||       ||  _    ||    ___||   |___   "
    echo -e "   _____| | _____| ||   _   ||   |    |   _   || | |   ||   |___ |       |  " 
    echo -e "  |\e[95m_______\e[0m||\e[95m_______\e[0m||__| |__||___|    |__| |__||_|  |__||_______||_______|  "
    echo -e "                                                              \e[105m*V2.1 rev 14\e[0m"
    echo -e "\e[91m #########################################################################\e[0m"
    echo -e "\e[95m [SSHPANEL SERVER #`echo $RANDOM` | $(os_detect)]\e[0m"
}