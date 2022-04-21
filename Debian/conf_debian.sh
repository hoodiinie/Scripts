#!/bin/bash

IPV6="$1"
NTP="$2"
SRVNTP="$3"
DOCKER="$4"
ZABBIX="$5"
SRVZBX="$6"
LOG="$7"
SRVLOG="$8"

function verif-system {
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

function disableipv6 {
    echo -e "\n#Désactivation IPV6\nnet.ipv6.conf.all.disable_ipv6 = 1\nnet.ipv6.conf.all.autoconf = 0\nnet.ipv6.conf.default.disable_ipv6 = 1\nnet.ipv6.conf.default.autoconf = 0" >> /etc/sysctl.conf
    sysctl -p >> /dev/null
}

function set_ntp {
    echo -e "NTP=$SRVNTP" >> /etc/systemd/timesyncd.conf
    systemctl restart systemd-timesyncd
}

function update {
    tput setaf 1; apt update 
    tput setaf 1; apt -y full-upgrade
    tput setaf 1; apt install -y ufw open-vm-tools  
}

function rzo {
    tput setaf 6; read -p "Voulez vous confgurer votre carte reseau ? (oui/non)" REPONSE

    while [ "$REPONSE" = "oui" ] || [ "$RECOMMENCER" = "oui" ] || [ "$AUTRE" = "oui" ]
    do

    ls /sys/class/net

        if [ "$REPONSE" = "oui" ] || [ "$AUTRE" -eq "oui" ]
        then
                tput setaf 6; read -p "Nom de la carte reseau : " CARTE
                echo -e "allow-hotplug $CARTE" >> /etc/network/interfaces
                tput setaf 6; read -p "Voulez vous configurer manuellement cette interface ? (oui/non)" MANUEL

                if [ "$MANUEL" = "oui" ]
                    then
                        echo -e "iface $CARTE inet static" >> /etc/network/interfaces
                        sed -i 's/dhcp/static/g' /etc/network/interfaces
                        read -p "Address IP : " IP
                        echo -e "\taddress $IP" >> /etc/network/interfaces
                        read -p "Masque reseau : " MASQUE
                        echo -e "\tnetmask $MASQUE" >> /etc/network/interfaces
                        read -p "Passerelle :" GATEWAY
                        echo -e "\tgateway $GATEWAY" >> /etc/network/interfaces

                        echo "Adresse IP : "$IP
                        echo "Masque : "$MASQUE
                        echo "Passerelle : "$GATEWAY

                        tput setaf 6; read -p "La configuartion reseau est-elle bonne ? (oui/non)" TEST
                        if [ "$TEST" = "non" ]
                            then
                                sed 's/address*/d' /etc/network/interfaces
                                sed 's/netmask*/d' /etc/network/interfaces
                                sed 's/gateway*/d' /etc/network/interfaces
                                sed -i 's/static/dhcp/g' /etc/network/interfaces
                        fi
                    else
                        echo -e "iface $CARTE inet dhcp" >> /etc/network/interfaces
                fi
        fi

        tput setaf 6; read -p "Voulez-vous recommencer la configuration ? (oui/non)" RECOMMENCER

        if [ "$RECOMMENCER" = "non" ]
            then
                tput setaf 6; read -p "Voulez-vous configurer une autre interface reseau ? (oui/non)" AUTRE
        fi

        REPONSE=0
    done
}

function rsyslog_server {
    touch /etc/rsyslog.d/graylog.conf
    echo -e "*.* @@$SRVLOG:34247;RSYSLOG_SyslogProtocol23Format" > /etc/rsyslog.d/graylog.conf
    systemctl restart rsyslog.service
}

function install_zabbix {
    tput setaf 6; read -p "Voulez vous installer l'agent Zabbix ? (oui/non)" REPONSE

    if [ "$REPONSE" = "oui" ]
        then

        wget https://repo.zabbix.com/zabbix/5.5/debian/pool/main/z/zabbix-release/zabbix-release_5.5-1%2Bdebian10_all.deb > /tmp
        dpkg -i /tmp/zabbix-release_5.5-1+debian10_all.deb
        apt update
        apt install zabbix-agent

        NAME_SERVER=$(hostname)

        rm /etc/zabbix/zabbix_agentd.conf
        touch /etc/zabbix/zabbix_agentd.conf
        echo -e "\nPidFile=/var/run/zabbix/zabbix_agentd.pid\nLogFile=/var/log/zabbix/zabbix_agentd.log\nLogFileSize=0\nServer=$SRVZBX\nHostname=$NAME_SERVER\nTLSConnect=psk\nTLSAccept=psk\nTLSPSKIdentity=$NAME_SERVER\nTLSPSKFile=/usr/local/etc/zabbix_agentd.psk" > /etc/zabbix/zabbix_agentd.conf

        ALEATOIRE="openssl rand -hex 32"
        touch /usr/local/etc/zabbix_agentd.psk
        $ALEATOIRE >> /usr/local/etc/zabbix_agentd.psk

        systemctl restart zabbix_agentd
    fi
}

function install_docker {
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
tput setaf 1; verif-system
sleep 4
tput setaf 6; echo "Vérification du système ................................................................. OK"
sleep 2
echo ""


if [ "$IPV6" -eq "-6" ]
then
    tput setaf 6; echo "Désactivation IPV6 ...................................................................... En cours"
    tput setaf 1; disableipv6
    sleep 4
    tput setaf 6; echo "Désactivation IPV6 ...................................................................... OK"
    sleep 2
    echo ""
fi

if [ "$NTP" -eq "-n" ]
then
    tput setaf 6; echo "Configuration NTP ....................................................................... En cours"
    tput setaf 1; set_ntp
    sleep 4
    tput setaf 6; echo "Configuration NTP ....................................................................... OK"
    sleep 2
    echo ""
fi

tput setaf 6; echo "Mise à jour et installation logiciels indispensable ..................................... En cours"
tput setaf 1; update
sleep 4
tput setaf 6; echo "Mise à jour et installation logiciels indispensable ..................................... OK"
sleep 2
echo ""

if [ "$DOCKER" -eq "-d" ]
then
    tput setaf 6; echo "Installation Docker ..................................................................... En cours"
    tput setaf 1; install_docker
    sleep 4
    tput setaf 6; echo "Installation Docker ..................................................................... OK"
fi
sleep 2
echo ""

tput setaf 6; echo "Configuration réseau .................................................................... En cours"
tput setaf 1; rzo
sleep 4
tput setaf 6; echo "Configuration réseau .................................................................... OK"
sleep 2
echo ""

if [ "$ZABBIX" -eq "-z"]
then
    tput setaf 6; echo "Installation agent Zabbix ............................................................... En cours"
    tput setaf 1; install_zabbix
    sleep 4
    tput setaf 6; echo "Installation agent Zabbix ............................................................... OK"
    sleep 2
    echo ""
fi

if [ "$LOG" -eq "-l"]
then
    tput setaf 6; echo "Configuration envoie journaux d'événements .............................................. En cours"
    tput setaf 1; rsyslog_server
    sleep 4
    tput setaf 6; echo "Configuration envoie journaux d'événements .............................................. OK"
    sleep 2
    echo ""
fi

NOM=$(hostname)
ADDRIP=$(hostname -I)
VERSION_DEB=$(lsb_release -ds)
tput setaf 1; echo "--------------------------------------------------------------------------------------------------"
tput bold; tput setaf 6; echo "                                                                                       "
tput bold; tput setaf 6; echo "                              => PREPARATION TERMINEE <=                               "
tput bold; tput setaf 6; echo "                                                                                       "
tput bold; tput setaf 6; echo "                                 Nom du serveur: $NOM                                  "
tput bold; tput setaf 6; echo "                                  Adresse ip: $ADDRIP                                   "
tput bold; tput setaf 6; echo "                                  $VERSION_DEB                                         "
tput bold; tput setaf 6; echo "                                                                                       "
tput setaf 1; echo "--------------------------------------------------------------------------------------------------"
sleep 5
echo ""



