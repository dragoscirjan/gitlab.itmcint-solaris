# Solaris Hosting Service 

> [back](../README.md)

## Installing NFS

Inspired from [Ubuntu Community Help](https://help.ubuntu.com) [Setting Up NFS How To](https://help.ubuntu.com/community/SettingUpNFSHowTo)

### Configuring NFS Server

For more details please read [NFS Server](https://help.ubuntu.com/community/SettingUpNFSHowTo#Pre-Installation_Setup) Section

```bash

# 
export NFS_CLIENT_IPS=""
#export NFS_CLIENT_NETWORK=""

## Configure Access

# Add the following line to /etc/hosts.deny:
echo "rpcbind mountd nfsd statd lockd rquotad : ALL" >> /etc/hosts.deny
# Now add the following line to /etc/hosts.allow:
echo "rpcbind mountd nfsd statd lockd rquotad : $NFS_CLIENT_IPS" >> /etc/hosts.allow

## Install tools

which apt-get > /dev/null && {
    apt-get install -y rpcbind nfs-kernel-server
}

## Configure exported paths

for ip in $NFS_CLIENT_IPS; do \
    echo "/home       $ip(rw,fsid=0,insecure,no_subtree_check,async)" >> /etc/exports; \
done

## restart NFS server

service nfs-kernel-server restart

```



### Configuring on both servers

#### /etc/idmapd.conf

Edit `/etc/idmapd.conf` to look like this.

```
[Mapping]

Nobody-User = nobody
Nobody-Group = nogroup
```

### Installing NFS Client