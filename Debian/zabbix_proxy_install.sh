#!/bin/bash

WORKSPACE="/tmp"
VERSIONDEB=$(. /etc/os-release; echo "$VERSION_ID")

OPT1="$1"
VERSIONZBX="$2"


verif_script()
{
	if [ -z "$OPT1" ]
	then
		if [[ "$OPT1" != '-v' ]]
		then
			echo "ERREUR : Veuillez indiquer l'option -v suivi du numéro de version de Zabbix (Exemple : 6.4)"
			exit
		fi
	fi
}


##START

sources_download()
{
	wget https://repo.zabbix.com/zabbix/"$VERSIONZBX"/debian/pool/main/z/zabbix-release/zabbix-release_"$VERSIONZBX"-1+debian"$VERSIONDEB"_all.deb > $WORKSPACE/zabbix-release_"$VERSIONZBX"-1+debian"$VERSIONDEB"_all.deb
	dpkg -i $WORKSPACE/zabbix-release_"$VERSIONZBX"-1+debian"$VERSIONDEB"_all.deb
	apt update
}

packages_installation()
{
    apt install -y
    apt install -y zabbix-proxy-sqlite3
}

setup_conf()
{
    mkdir /var/lib/sqlite
    chown -R zabbix:zabbix /var/lib/sqlite

    mv /etc/zabbix/zabbix_proxy.conf /etc/zabbix/zabbix_proxy.conf/bak
    touch /etc/zabbix/zabbix_proxy.conf

    echo -e "Server=$SERVERIP
            \nHostname=$NAMEPROXY
            \nLogFile=/var/log/zabbix/zabbix_proxy.log
            \nLogFileSize=0
            \nSocketDir=/run/zabbix
            \nPidFile=/run/zabbix/zabbix_proxy.pid
            \nDBName=/var/lib/sqlite/zabbix.db
            \nDBUser=zabbix
            \nFpingLocation=/usr/bin/fping
            \nFping6Location=/usr/bin/fping6
            \nLogSlowQueries=3000
            \nStatsAllowedIP=127.0.0.1" >> /etc/zabbix/zabbix_proxy.conf
}

setup_services()
{
	systemctl restart zabbix-proxy
	systemctl enable zabbix-proxy 
}

main()
{
    verif_script
    sources_download
    packages_installation
    setup_conf
    setup_services
}

main $OPT1 $VERSIONZBX
