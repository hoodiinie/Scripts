#!/bin/bash

QUI=$(whoami)
WORKSPACE="/etc/network"
INTERFACES="$WORKSPACE/interfaces"

OPT1="$1"
INT="$2"
OPT2="$3"
TYPE="$4"
OPT3="$5"
IP="$6"
OPT4="$7"
GATEWAY="$8"

INTERFACESD="$WORKSPACE/interfaces.d/$INT"

function verif_script()
{
    if [ "$QUI" != "root" ]
	then
		echo "ERREUR : Veuillez exécuter le script en mode root"
		exit
	fi

    if [ -f "$INTERFACESD" ]
    then
        cp "$INTERFACESD" "$INTERFACESD.bak"
        touch "$INTERFACESD"
    fi

    TEXT=$(grep "$INT" "$INTERFACES")
    if [ "$TEXT" = "$INT" ]
    then
        cp "$INTERFACES" "$INTERFACES.bak"
        sed -i '/'$INT'/d' "$INTERFACES"
    fi
}

function verif_options()
{
    if [[ "$OPT1" != '-i' ]]
    then
        echo "ERREUR : Veuillez indiquer l'option -i suivi du nom de l'interface"
        exit
    fi

    if [ -z "$INT" ]
    then
        echo "ERREUR : Veuillez indiquer le nom de l'interface"
        exit
    fi

    if [[ "$OPT2" != '-t' ]]
    then
        echo "ERREUR : Veuillez indiquer l'option -t suivi du type de configuration (DHCP ou STATIC)"
        exit
    fi

    if [ -z "$TYPE" ]
    then
        echo "ERREUR : Veuillez indiquer le type de configuration voulu (DHCP ou STATIC)"
        exit
    fi
}

function verif_options_static()
{
    if [[ "$OPT3" != '-a' ]]
    then
        echo "ERREUR : Veuillez indiquer l'option -a suivi de l'adresse IP avec le masque CIDR (/8,/16,/24)"
        exit
    fi

    if [ -z "$IP" ]
    then
        echo "ERREUR : Veuillez indiquer l'adresse IP suivi du masque CIDR (/8,/16,/24)"
        exit
    fi

    if [[ "$OPT4" != '-g' ]]
    then
        echo "ERREUR : Veuillez indiquer l'option -g suivi de la passerelle du réseau"
        exit
    fi

    if [ -z "$GATEWAY" ]
    then
        echo "ERREUR : Veuillez indiquer l'adresse de la passerelle du réseau"
        exit
    fi
}

function configuration_dhcp()
{
    echo -e "allow-hotplug $INT
iface $INT inet dhcp" > "$INTERFACESD"

    systemctl restart networking
}

configuration_static()
{
    echo -e "allow-hotplug $INT
iface $INT inet static
    address $IP
    gateway $GATEWAY" > "$INTERFACESD"

    systemctl restart networking
}

function main()
{
    verif_script
    verif_options

    if [ "$TYPE" = 'DHCP' ] || [ "$TYPE" = 'dhcp' ]
    then
        configuration_dhcp
    elif [ "$TYPE" = 'STATIC' ] || [ "$TYPE" = 'static' ]
    then
        verif_options_static
        configuration_static
    fi

    cat "$INTERFACESD"
}

main $OPT1 $INT $OPT2 $TYPE $OPT3 $IP $OPT4 $GATEWAY