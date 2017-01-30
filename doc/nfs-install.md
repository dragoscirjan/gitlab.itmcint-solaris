
# Solaris Hosting Service 

> [back](../README.md)

## Installing NFS

Inspired from [Ubuntu Community Help](https://help.ubuntu.com) [Setting Up NFS How To](https://help.ubuntu.com/community/SettingUpNFSHowTo)

### Installing NFS Server

For more details please read [NFS Server](https://help.ubuntu.com/community/SettingUpNFSHowTo#Pre-Installation_Setup) Section

```bash

# 
export NFS_CLIENT_IPS=""
# Add the following line to /etc/hosts.deny:
echo "rpcbind mountd nfsd statd lockd rquotad : ALL" >> /etc/hosts.deny
# Now add the following line to /etc/hosts.allow:
echo "rpcbind mountd nfsd statd lockd rquotad : $NFS_CLIENT_IPS" >> /etc/hosts.allow

```

### Installing NFS Client