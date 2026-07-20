#!/bin/sh
[ "" == "$BTR" ] && exit 1;

unshare -m /bin/sh << 'EOF'

    mkdir -p /tmp
    mount -t tmpfs tmpfs /tmp
    mkdir /tmp/huskyos &&
    mount -o subvol=@huskyos "$BTR" /tmp/huskyos || exit 1;
    [ "$(realpath /tmp/huskyos/@userdata)" == "$(realpath /tmp/huskyos/@userdata-A)" ] && NEXT=B || NEXT=A ;
    UDA=/tmp/huskyos/@userdata-$NEXT;
    UNEXT=/tmp/huskyos/@userdata-next;
    btrfs subvolume delete $UDA || true;
    btrfs subvolume create $UDA || exit 1;
    rm $UNEXT 2>/tmp/devnull || true;
    [ -e "$UNEXT" ] && echo "@userdata-next wasnt deleted successfully" && exit 1;
    ln -snf @userdata-$NEXT $UNEXT &&
    mv -Tf $UNEXT /tmp/huskyos/@userdata || exit 1;
    true;

EOF
