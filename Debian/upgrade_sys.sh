#!/bin/bash

# VARIABLES
WORKSPACE="/tmp"
DETECT_V=$(lsb_release -cs)
NAME_SE="stretch"
NAME_BU="buster"
NAME_BO="bookworm"

# COULEURS
RED="tput setaf 1"
GREEN="tput setaf 2"
YELLOW="tput setaf 3"
NC="tput setaf 7"


function root_test()
    {
        if [ "$(id -u)" -ne 0 ]; then
            $RED;echo -e "Ce script doit être exécuté avec les privilèges root"
            $NC;echo ""
            exit 1
        fi

    }

function detect()
    {
        VERSION=$(cat /etc/debian_version)

        if [ $DETECT_V = $NAME_BO ]
        then
            $GREEN;echo "Votre système est à jour"
            $NS;echo ""
            exit 1
        elif [ $DETECT_V != $NAME_BO ]
        then
            $RED;echo "Votre système est encore en version $VERSION ($DETECT_V), vous devez le mettre à jour"
            sleep 1
            $NC;echo ""
        fi
    }

function change_list()
    {
        SOURCES="/etc/apt/sources.list"
        SOURCES_D="$SOURCES.d/*.list"

        cp $SOURCES $SOURCES.bak
        cp $SOURCES_D $SOURCES_D.bak

        if [ $DETECT_V = $NAME_SE ]
        then
            sed -i '/debian-security/d' $SOURCES
            sed -i 's/archive.debian.org/deb.debian.org/g' $SOURCES
            sed -i "s/$DETECT_V/$NAME_BU/g" $SOURCES

            echo "deb http://security.debian.org/ buster/updates main non-free contrib" >> $SOURCES
        else
            sed -i '/buster/updates/d' $SOURCES
            sed -i 's/archive.debian.org/deb.debian.org/g' $SOURCES  
                      
            echo "deb http://security.debian.org/debian-security bookworm-security main non-free-firmware" >> $SOURCES
            sed -i "s/$DETECT_V/$NAME_BO/g" $SOURCES

            if [ -d $SOURCES.D ]
            then
                sed -i "s/$DETECT_V/$NAME_BO/g" $SOURCES_D
            fi
        fi
    }

function upgrade_light()
    {
        apt clean
        $GREEN;apt update
        $YELLOW;apt upgrade --without-new-pkgs
        apt --fix-broken install
        $NC;echo ""
    }

function full()
    {
        $YELLOW;apt full-upgrade
        apt --fix-broken install
        $NC;echo ""
    }

function dist()
    {
        $RED;apt dist-upgrade
        $NC;echo ""
    }

function purge()
    {
        $YELLOW;apt --purge autoremove
        apt clean
        $NC;echo ""
    }

function prepa()
    {
        root_test
        detect
        upgrade_light

        if [ $DETECT_V = $NAME_BU ]
        then
            cd /tmp
            apt download libcrypt1
            dpkg-deb -x libcrypt1_1%3a4.4.33-2_amd64.deb .
            cp -av lib/x86_64-linux-gnu/* /lib/x86_64-linux-gnu/
        fi
    }

function main()
    {
        prepa
        full
        change_list
        upgrade_light
        full
        dist
        purge
    }

main