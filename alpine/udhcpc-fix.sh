#!/bin/sh
#### fix udhcp conf
#### more explanation on https://wiki.alpinelinux.org/wiki/Udhcpc and
### https://www.busybox.net/downloads/BusyBox.html
mkdir -p /etc/udhcpc/
if [ -f /etc/udhcpc/udhcpc.conf ] then
    echo "Config already exists"
 else 
# set dns to google
  echo 'dns="8.8.8.8 8.8.4.4"' > /etc/udhcpc/udhcpc.conf
fi 
