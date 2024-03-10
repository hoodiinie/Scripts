#!/bin/bash


WORKSPACE="/tmp/"
QUI=$(whoami)
VERSIONDEB=$(. /etc/os-release; echo "$VERSION_ID")


verif_script()
{
	if [ $QUI = "root" ]
	then
		echo "ERREUR : Veuillez exécuter le script avec un utilisateur présent dans le fichier /etc/sudoers"
		exit
	fi

	if [[ -z $OPT_1 ]] || [[ $OPT_1 != "-z" ]]
	then
		echo "ERREUR : Veuillez indiquer l'option -z suivi du numéro de version de Zabbix (Exemple : 6.4)"
		exit
	fi

	if [[ -z $VERSIONZBX ]]
	then
		echo "ERREUR : Veuillez indiquer le numéro de version de Zabbix (Exemple : 6.4)"
		exit
	fi

	if [[ -z $OPT_2 ]] || [[ $OPT_2 != "-p" ]]
	then
		echo "ERREUR : Veuillez indiquer l'option -p suivi du mot de passe de la base de données"
		exit
	fi

	if [[ -z $PASSWORD ]]
	then
		echo "ERREUR : Veuillez indiquer le mot de passe de la base de données"
		exit
	fi

	if [[ -z $OPT_3 ]] || [[ $OPT_3 != "-w" ]]
	then
		echo "ERREUR : Veuillez indiquer l'option -w suivi de l'adresse IP ou le nom de domaine de l'interface Web"
		exit
	fi

	if [[ -z $WEB ]]
	then
		echo "ERREUR : Veuillez indiquer l'adresse IP ou le nom de domaine de l'interface Web"
		exit
	fi
}

##START

sources_download()
{
	cd $WORKSPACE
	wget https://repo.zabbix.com/zabbix/"$VERSIONZBX"/debian/pool/main/z/zabbix-release/zabbix-release_"$VERSIONZBX"-1+debian"$VERSIONDEB"_all.deb
	sudo dpkg -i zabbix-release_"$VERSIONZBX"-1+debian"$VERSIONDEB"_all.deb
	sudo apt update
}

packages_installation()
{
	sudo apt install postgresql
	sudo apt install zabbix-server-pgsql zabbix-frontend-php php8.2-pgsql zabbix-nginx-conf zabbix-sql-scripts zabbix-agent
}

setup_database()
{
	sudo -u postgres createuser --pwprompt zabbix
	sudo -u postgres createdb -O zabbix zabbix
	zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix
}

setup_conf()
{
	sudo sed -i 's/# DBPassword=/DBPassword='$PASSWORD'/g' /etc/zabbix/zabbix_server.conf
	sudo sed -i 's/#        listen          8080;/	listen 8080;/g' /etc/zabbix/nginx.conf
	sudo sed -i 's/#        server_name     example.com;/	server_name '$WEB';/g' /etc/zabbix/nginx.conf
}

setup_services()
{
	sudo systemctl restart zabbix-server zabbix-agent nginx php8.2-fpm
	sudo systemctl enable zabbix-server zabbix-agent nginx php8.2-fpmtput setaf 
}

main()
{
	OPT_1=$1
	VERSIONZBX=$2
	OPT_2=$3
	PASSWORD=$4
	OPT_3=$5
	WEB=$6

	verif_script
	sources_download
	packages_installation
	setup_database
	setup_conf
	setup_services
}

##END

output()
{
	main

	tput setaf 1; echo "--------------------------------------------------------------------------------------------------"
	tput bold; tput setaf 6; echo "                                                                                       "
	tput bold; tput setaf 6; echo "                              => Installation Done <=                                  "
	tput bold; tput setaf 6; echo "                                                                                       "
	tput bold; tput setaf 6; echo "                            Link : http://"$WEB":8080                                  "
	tput bold; tput setaf 6; echo "                          Login : Admin / Password : zabbix                            "
	tput bold; tput setaf 6; echo "                                                                                       "
	tput setaf 1; echo "--------------------------------------------------------------------------------------------------"
	echo ""
}

output
