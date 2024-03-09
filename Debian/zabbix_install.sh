#!/bin/bash

##VARIABLES

WORKSPACE="/tmp/"
QUI=$(whoami)
VERSIONDEB=$(. /etc/os-release; echo "$VERSION_ID")

PASS=$1
WEB=$2


##VERIF

if [ $QUI = "root" ]
then
	echo "ERREUR : Veuillez exécuter le script avec un utilisateur présent dans le fichier /etc/sudoers"
	exit
fi

if [[ -z $PASS ]]
then
	echo "ERREUR : Veuillez indiquer le mot de passe de la base de données"	
	exit
fi

if [[ -z $WEB ]]
then
	echo "ERREUR : Veuillez indiquer l'adresse IP ou le nom de domaine de l'interface Web"
	exit
fi


##START

read -p "Quelle version de Zabbix souhaitez-vous installer ? " VERSIONZBX

cd $WORKSPACE

wget https://repo.zabbix.com/zabbix/"$VERSIONZBX"/debian/pool/main/z/zabbix-release/zabbix-release_"$VERSIONZBX"-1+debian"$VERSIONDEB"_all.deb
sudo dpkg -i zabbix-release_"$VERSIONZBX"-1+debian"$VERSIONDEB"_all.deb
sudo apt update

sudo apt install postgresql
sudo apt install zabbix-server-pgsql zabbix-frontend-php php8.2-pgsql zabbix-nginx-conf zabbix-sql-scripts zabbix-agent

sudo -u postgres createuser --pwprompt zabbix
sudo -u postgres createdb -O zabbix zabbix

zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix

sudo sed -i 's/# DBPassword=/DBPassword='$PASS'/g' /etc/zabbix/zabbix_server.conf
sudo sed -i 's/#        listen          8080;/	listen 8080;/g' /etc/zabbix/nginx.conf
sudo sed -i 's/#        server_name     example.com;/	server_name '$WEB';/g' /etc/zabbix/nginx.conf

sudo systemctl restart zabbix-server zabbix-agent nginx php8.2-fpm
sudo systemctl enable zabbix-server zabbix-agent nginx php8.2-fpmtput setaf 


##END

tput setaf 1; echo "--------------------------------------------------------------------------------------------------"
tput bold; tput setaf 6; echo "                                                                                       "
tput bold; tput setaf 6; echo "                              => Installation Done <=                                  "
tput bold; tput setaf 6; echo "                                                                                       "
tput bold; tput setaf 6; echo "                            Link : http://"$WEB":8080                                  "
tput bold; tput setaf 6; echo "                          Login : Admin / Password : zabbix                            "
tput bold; tput setaf 6; echo "                                                                                       "
tput setaf 1; echo "--------------------------------------------------------------------------------------------------"
echo ""

