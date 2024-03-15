#!/bin/bash

WORKSPACE="/etc/sysctl.conf"
QUI=$(whoami)

verif_script()
{
	if [ "$QUI" != "root" ]
	then
		echo "ERREUR : Veuillez exécuter le script en mode root"
		exit
	fi
}

disable_ipv6()
{
    TEXT="net.ipv6.conf.all.disable_ipv6 = 1"
    IPV6=$(grep "$TEXT" $WORKSPACE)
    if [ "$IPV6" != "$TEXT" ]
    then
        echo "$TEXT" > $WORKSPACE
    fi

    TEXT="net.ipv6.conf.all.autoconf = 0"
    IPV6=$(grep "$TEXT" $WORKSPACE)
    if [ "$IPV6" != "$TEXT" ]
    then
        echo "$TEXT" > $WORKSPACE
    fi

    TEXT="net.ipv6.conf.default.disable_ipv6 = 1"
    IPV6=$(grep "$TEXT" $WORKSPACE)
    if [ "$IPV6" != "$TEXT" ]
    then
        echo "$TEXT" > $WORKSPACE
    fi

    TEXT="net.ipv6.conf.default.autoconf = 0"
    IPV6=$(grep "$TEXT" $WORKSPACE)
    if [ "$IPV6" != "$TEXT" ]
    then
        echo "$TEXT" > $WORKSPACE
    fi

    service networking restart
}

main()
{
    verif_script
    disable_ipv6
    sysctl -p
}

main