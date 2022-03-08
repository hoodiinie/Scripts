#!/bin/bash

function VERIF-SYSTEM {
  if [ $(whoami) != "root" ]
    then
    tput setaf 5; echo "ERREUR : Veuillez exécuter le script en tant que Root !"
    exit
  fi

  if [[ $(arch) != *"64" ]]
    then
    tput setaf 5; echo "ERREUR : Veuillez installer une version x64 !"
    exit
  fi
}

function IPV6 {
    echo -e "\n#Désactivation IPV6\nnet.ipv6.conf.all.disable_ipv6 = 1\nnet.ipv6.conf.all.autoconf = 0\nnet.ipv6.conf.default.disable_ipv6 = 1\nnet.ipv6.conf.default.autoconf = 0" >> /etc/sysctl.conf
    sysctl -p >> /dev/null
}

function SET_NTP {
    echo -e "NTP=172.30.5.193" >> /etc/systemd/timesyncd.conf
    systemctl restart systemd-timesyncd
}

function DEPOT {
    cp /etc/apt/sources.list /etc/apt/sources.list.bak
    rm /etc/apt/sources.list
    touch /etc/apt/sources.list
    echo -e "deb [arch=amd64 trusted=yes] http://10.1.199.5/debian/mirror/ftp.fr.debian.org/debian/ bullseye main\ndeb [arch=amd64 trusted=yes] http://10.1.199.5/debian/mirror/security.debian.org/debian-security/ bullseye-security main\ndeb [arch=amd64 trusted=yes] http://10.1.199.5/debian/mirror/ftp.fr.debian.org/debian/ bullseye-updates main" >> /etc/apt/sources.list
}

function UPDATE {
    tput setaf 1; apt update 
    tput setaf 1; apt -y full-upgrade
    tput setaf 1; apt install -y ufw open-vm-tools  
}

function RZO {
    tput setaf 6; read -p "Voulez vous confgurer votre carte reseau ? (oui/non)" reponse

    while [ "$reponse" = "oui" ] || [ "$recommencer" = "oui" ] || [ "$autre" = "oui" ]
    do

    ls /sys/class/net

        if [ $autre = "oui" ]
            then
                tput setaf 6; read -p "Nom de la carte reseau : " carte
                echo -e "allow -hotplug $carte" >> /etc/network/interfaces
                tput setaf 6; read -p "Voulez vous configurer manuellement cette interface ? (oui/non)" manuel
            
                if [ "$manuel" = "oui" ]
                    then
                        echo -e "iface $carte inet static" >> /etc/network/interfaces
                    else
                        echo -e "iface $carte inet dhcp" >> /etc/network/interfaces
                fi   
        fi
            
        sed -i 's/dhcp/static/g' /etc/network/interfaces
        read -p "address IP : " ip
        echo -e "\taddress $ip" >> /etc/network/interfaces
        read -p "Masque reseau : " masque
        echo -e "\tnetmask $masque" >> /etc/network/interfaces
        read -p "Passerelle : " gateway
        echo -e "\tgateway $gateway" >> /etc/network/interfaces
    
        echo "Adresse IP : "$ip
        echo "Masque : "$masque
        echo "Passerelle : "$gateway
    
        tput setaf 6; read -p "La configuartion reseau est-elle bonne ? (oui/non)" test
        if [ "$test$" = "non" ]
            then
                sed 's/address*/d' /etc/network/interfaces
                sed 's/netmask*/d' /etc/network/interfaces
                sed 's/gateway*/d' /etc/network/interfaces
                sed -i 's/static/dhcp/g' /etc/network/interfaces
            
                tput setaf 6; read -p "Voulez-vous recommencer la configuration ? (oui/non)" recommencer
        fi
    
        if [ "$recommencer" = "non"]
            then
                tput setaf 6; read -p "Voulez-vous configurer une autre interface reseau ? (oui/non)" autre
        fi        
      
    done

    service networking restart   
}

function GRAYLOG {
    touch /etc/rsyslog.d/graylog.conf
    echo -e "*.* @@172.30.10.15:34247;RSYSLOG_SyslogProtocol23Format" > /etc/rsyslog.d/graylog.conf
    systemctl restart rsyslog.service
}

function INSTALL-ZABBIXAGENT {
    tput setaf 6; read -p "Voulez vous installer l'agent Zabbix ? (oui/non)" reponse

    if [ "$reponse" = "oui" ]
        then

        wget https://repo.zabbix.com/zabbix/5.5/debian/pool/main/z/zabbix-release/zabbix-release_5.5-1%2Bdebian10_all.deb > /tmp
        dpkg -i /tmp/zabbix-release_5.5-1+debian10_all.deb
        apt update
        apt install zabbix-agent

        name_server=$(hostname)

        rm /etc/zabbix/zabbix_agentd.conf
        touch /etc/zabbix/zabbix_agentd.conf
        echo -e "\nPidFile=/var/run/zabbix/zabbix_agentd.pid\nLogFile=/var/log/zabbix/zabbix_agentd.log\nLogFileSize=0\nServer=172.30.10.12\nHostname=$name_server\nTLSConnect=psk\nTLSAccept=psk\nTLSPSKIdentity=$name_server\nTLSPSKFile=/usr/local/etc/zabbix_agentd.psk" > /etc/zabbix/zabbix_agentd.conf

        aleatoire="openssl rand -hex 32"
        touch /usr/local/etc/zabbix_agentd.psk
        $aleatoire >> /usr/local/etc/zabbix_agentd.psk

        systemctl restart zabbix_agentd
    fi
}

function INSTALL-DOCKER {
    tput setaf 1; apt install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
    curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable"
    tput setaf 1; apt update
    tput setaf 1; apt -y install docker-ce docker-compose
    systemctl enable docker
    systemctl start docker
}

echo ""
tput setaf 6; echo "--------------------------------------------------------------------------------------------------"
tput setaf 6; echo "                                          Début du script                                         "
tput setaf 6; echo "                                      Configuration Debian 11                                     "
tput setaf 6; echo "--------------------------------------------------------------------------------------------------"
sleep 2
echo ""

tput setaf 6; echo "Vérification du système ................................................................. En cours"
tput setaf 1; VERIF-SYSTEM
sleep 4
tput setaf 6; echo "Vérification du système ................................................................. OK"
sleep 2
echo ""

tput setaf 6; echo "Désactivation IPV6 ...................................................................... En cours"
tput setaf 1; IPV6
sleep 4
tput setaf 6; echo "Désactivation IPV6 ...................................................................... OK"
sleep 2
echo ""

tput setaf 6; echo "Configuration NTP ....................................................................... En cours"
tput setaf 1; SET_NTP
sleep 4
tput setaf 6; echo "Configuration NTP ....................................................................... OK"
sleep 2
echo ""

tput setaf 6; echo "Configuration des dépots APT ............................................................ En cours"
tput setaf 1; DEPOT
sleep 4
tput setaf 6; echo "Configuration des dépots APT ............................................................ OK"
sleep 2
echo ""

tput setaf 6; echo "Mise à jour et installation logiciels indispensable ..................................... En cours"
tput setaf 1; UPDATE
sleep 4
tput setaf 6; echo "Mise à jour et installation logiciels indispensable ..................................... OK"
sleep 2
echo ""

tput setaf 6; read -p "Souhaitez vous installer Docker ? (y/n)  " install_docker
if [ $install_docker = "oui" ]
    then
    tput setaf 6; echo "Installation Docker ..................................................................... En cours"
    tput setaf 1; INSTALL-DOCKER
    sleep 4
    tput setaf 6; echo "Installation Docker ..................................................................... OK"
fi
sleep 2
echo ""

tput setaf 6; echo "Configuration réseau .................................................................... En cours"
tput setaf 1; RZO
sleep 4
tput setaf 6; echo "Configuration réseau .................................................................... OK"
sleep 2
echo ""

tput setaf 6; echo "Installation agent Zabbix ............................................................... En cours"
tput setaf 1; INSTALL-ZABBIXAGENT
sleep 4
tput setaf 6; echo "Installation agent Zabbix ............................................................... OK"
sleep 2
echo ""

tput setaf 6; echo "Configuration envoie journaux d'événements .............................................. En cours"
tput setaf 1; GRAYLOG
sleep 4
tput setaf 6; echo "Configuration envoie journaux d'événements .............................................. OK"
sleep 2
echo ""

nom=$(hostname)
adrip=$(hostname -I)
version_deb=$(lsb_release -ds)
tput setaf 1; echo "--------------------------------------------------------------------------------------------------"
tput bold; tput setaf 6; echo "                                                                                       "
tput bold; tput setaf 6; echo "                              => PREPARATION TERMINEE <=                               "
tput bold; tput setaf 6; echo "                                                                                       "
tput bold; tput setaf 6; echo "                                 Nom du serveur: $nom                                  "
tput bold; tput setaf 6; echo "                                  Adresse ip: $adrip                                   "
tput bold; tput setaf 6; echo "                                  $version_deb                                         "
tput bold; tput setaf 6; echo "                                                                                       "
tput setaf 1; echo "--------------------------------------------------------------------------------------------------"
sleep 5
echo ""



