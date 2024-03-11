#!/bin/bash

WORKSPACE="/tmp/"
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
	cd $WORKSPACE
	wget https://repo.zabbix.com/zabbix/"$VERSIONZBX"/debian/pool/main/z/zabbix-release/zabbix-release_"$VERSIONZBX"-1+debian"$VERSIONDEB"_all.deb
	dpkg -i zabbix-release_"$VERSIONZBX"-1+debian"$VERSIONDEB"_all.deb
	apt update
}

packages_installation()
{
    apt install zabbix-proxy-sqlite3
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
    setup_services
}

main $OPT1 $VERSIONZBX