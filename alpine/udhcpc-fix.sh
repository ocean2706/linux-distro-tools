#!/bin/sh
#### fix udhcp conf
#### more explanation on https://wiki.alpinelinux.org/wiki/Udhcpc
mkdir -p /etc/udhcpd/
if [ -f /etc/udhcpd/udhcpd.conf ] then
    echo "Config already exists"
 else 
  echo "dns=8.8.8.8 8.8.4.4" > /etc/udhcpd/udhcpd.conf
 fi 
