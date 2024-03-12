#!/bin/bash


WORKSPACE="/tmp/"
QUI=$(whoami)
VERSIONDEB=$(. /etc/os-release; echo "$VERSION_ID")
IPADDR=$(hostname -I | awk '{print $1}')

OPT1="$1"
VERSIONZBX="$2"
OPT2="$3"
PASSWORD="$4"


verif_script()
{
	if [ "$QUI" = "root" ]
	then
		echo "ERREUR : Veuillez exécuter le script avec un utilisateur présent dans le fichier /etc/sudoers"
		exit
	fi

	if [ -z "$OPT1" ]
	then
		if [[ "$OPT1" != '-v' ]]
		then
			echo "ERREUR : Veuillez indiquer l'option -v suivi du numéro de version de Zabbix (Exemple : 6.4)"
			exit
		fi
	fi

	if [ -z "$VERSIONZBX" ]
	then
		echo "ERREUR : Veuillez indiquer le numéro de version de Zabbix (Exemple : 6.4)"
		exit
	fi

	if [ -z "$OPT2" ]
	then
		if [[ "$OPT2" != '-p' ]]
		then
			echo "ERREUR : Veuillez indiquer l'option -p suivi du mot de passe de la base de données"
			exit
		fi
	fi

	if [ -z "$PASSWORD" ]
	then
		echo "ERREUR : Veuillez indiquer le mot de passe de la base de données"
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
	sudo apt install -y postgresql
	sudo apt install -y zabbix-server-pgsql zabbix-frontend-php php8.2-pgsql zabbix-nginx-conf zabbix-sql-scripts zabbix-agent
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
	sudo sed -i 's/#        server_name     example.com;/	server_name '$IPADDR';/g' /etc/zabbix/nginx.conf
}

setup_services()
{
	sudo systemctl restart zabbix-server zabbix-agent nginx php8.2-fpm
	sudo systemctl enable zabbix-server zabbix-agent nginx php8.2-fpm
}

main()
{
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
	main $OPT1 $VERSIONZBX $OPT2 $PASSWORD

	tput setaf 1; echo "--------------------------------------------------------------------------------------------------"
	tput bold; tput setaf 6; echo "                                                                                       "
	tput bold; tput setaf 6; echo "                              => Installation Done <=                                  "
	tput bold; tput setaf 6; echo "                                                                                       "
	tput bold; tput setaf 6; echo "                            Link : http://"$IPADDR":8080                               "
	tput bold; tput setaf 6; echo "                          Login : Admin / Password : zabbix                            "
	tput bold; tput setaf 6; echo "                                                                                       "
	tput setaf 1; echo "--------------------------------------------------------------------------------------------------"
	echo ""
}

output
