#!/bin/sh

source "${CONSUL_SCRIPT_DIR}"/consul.env
source "${CONSUL_SCRIPT_DIR}"/common_functions.sh

# Setup samba server
apk add samba openrc
mkdir /svr
chmod 0777 /srv

/etc/samba/smb.conf <<EOL
[global]
    workgroup = WORKGROUP
    dos charset = cp850
    unix charset = ISO-8859-1
    force user = username

 [storage]
    browseable = yes
    writeable = yes
    path = /svr
EOL

echo "password" | adduser samba_user
echo "password" | smbpasswd -a samba_user

rc-update add samba
rc-service samba start

filebrowser -d /root/.config/Filebrowser/filebrowser.db users update admin -p password
echo ls -r /home

exec /filebrowser
