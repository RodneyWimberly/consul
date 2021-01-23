#!/bin/sh

source "${CONSUL_SCRIPT_DIR}"/consul.env
source "${CONSUL_SCRIPT_DIR}"/common_functions.sh

log "Installing Samba Server and OpenRC"
# Setup samba server
apk add samba openrc
mkdir /svr
chmod 0777 /srv

log_detail "Configuring Samba Server"
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

log_detail "Creating user for Samba Server Service"
echo "password" | adduser samba_user
echo "password" | smbpasswd -a samba_user

log_detail "Setting up the Samba Server Service"
rc-update add samba
rc-service samba start

log_detail "Updating the user name and password for the file browser web site"
filebrowser -d /root/.config/Filebrowser/filebrowser.db users update admin -p password
echo ls -r /home

log_detail "Starting the file browser web site"
exec /filebrowser
