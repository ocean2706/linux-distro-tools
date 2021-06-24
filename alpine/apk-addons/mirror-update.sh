#!/bin/bash
#@todo update the code for busybox/sh

config_file=$(cat <<EOF

mirror=http://tux.rainside.sk/alpine
now=$(date +%Y-%m-%d-%H%M%S)
repo=/etc/apk/repositories
repoback=$repo-$now
#version
version=v3.13
EOF)
### generate /etc/apk/config
echo "$config_file" > /etc/apk/config

############### use /etc/apk/config to generate /etc/apk/repositories ( or whatever is set as repo on config file
########## @todo generate specific code
########## @todo parametrize the call in order to override config file and also to change

genmirror= $(cat <<EOF 
#!/bin/bash
. /etc/apk/config
cp $repo $repoback
echo $mirror/$version/main > $repo
echo $mirror/$version/community >> $repo
cat $repo
EOF)

echo "$genmirror" > /sbin/genapknmirror
chmod a+x /sbin/genapkmirror
#### usage : change required config options on /etc/apk/config and then call genapkmirror




