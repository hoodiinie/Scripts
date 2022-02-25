#!/bin/bash
clear
tput setaf 7; read -p "Entrez le mot de passe pour la base de données Zabbix : " ZABBIX_DB_USER_PASSWORD
tput setaf 2; echo ""

addr_ip=$(hostname -I)


function install_docker ()
{
    tput setaf 6; echo ""

    apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
    curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable"
    apt-get update
    apt-get -y install docker-ce docker-compose
    systemctl enable docker
    systemctl start docker

    tput setaf 7; echo ""
}

function data ()
{
        if [[ ! -e /apps]] {
        then
                mkdir /apps
                
                if [[ ! -e /apps/zabbix ]]{
                then
                    mkdir /apps/zabbix
                    mkdir /apps/zabbix/db
                    mkdir /apps/zabbix/srv
                fi        
                }
        fi
        }
}

# Modification et lancement du docker-compose.yml
for file in ~/scripts/debian/zabbix-server/docker-compose.yml
do
  echo "Traitement de $file ..."
  sed -i -e "s/zabbix-bdd-password/$ZABBIX_DB_USER_PASSWORD/g" "$file"
done

data
install_docker
docker-compose up -d

clear
tput bold; tput setaf 7; echo "LISTES DES CONTAINERS EN COURS : "
tput setaf 3; echo ""
docker container ls
echo ""
tput setaf 7; echo "-------------------------------------------------"
tput setaf 7; echo ""
tput setaf 7; echo "   IP du serveur Zabbix : $addr_ip:8090      "
tput setaf 7; echo "         ID : Admin / MDP : zabbix             "
tput setaf 7; echo ""
tput setaf 7; echo "-------------------------------------------------"
tput setaf 2; echo ""

