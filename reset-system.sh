#!/usr/bin/env -S sh -c 'cat $0 | unshare -m'
UDA=/tmp/huskyos/@userdata;
[ "" == "$BTR" ] && exit 1;

mkdir -p /tmp
mount -t tmpfs tmpfs /tmp
mkdir /tmp/huskyos &&
mount -o subvol=@huskyos "$BTR" /tmp/huskyos || exit 1;

btrfs subvolume delete $UDA &&
btrfs subvolume create $UDA && exit 0 || 
echo an error occured resetting the subvolume && exit 1;
