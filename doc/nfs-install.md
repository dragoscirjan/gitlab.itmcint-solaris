# Solaris Hosting Service 

> [back](../README.md)

## Installing NFS

> Inspired from [Ubuntu Community Help](https://help.ubuntu.com) [Setting Up NFS How To](https://help.ubuntu.com/community/SettingUpNFSHowTo)

> Explained caching in [RHEL Storage_Administration_Guide](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Storage_Administration_Guide/fscachenfs.html) and [Understanding NFS Caching](https://www.avidandrew.com/understanding-nfs-caching.html).

> 

### Configuring NFS Server

For more details please read [NFS Server](https://help.ubuntu.com/community/SettingUpNFSHowTo#Pre-Installation_Setup) Section

```bash

# 
export NFS_CLIENT_IPS=""
# i.e. export NFS_CLIENT_IPS="$(host terra.itmcd.ro | cut -f4 -d' ')"

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

> Please note there may be different nobody/nogroup users for different distros. Please read the documentation.

```
[Mapping]

Nobody-User = nobody
Nobody-Group = nogroup
```

### Installing NFS Client


```bash

##

export NFS_SERVER_IP=""
# i.e. export NFS_SERVER_IP="$(host terra.itmcd.ro | cut -f4 -d' ')"

## Install necesary packages

which apt-get > /dev/null && {
    apt-get install -y rpcbind nfs-common
}

## Manage hosts.deny

echo "rpcbind : ALL" >> /etc/hosts.deny

## Manage hosts.allow

echo "rpcbind : $NFS_SERVER_IP 127.0.0.1" >> /etc/hosts.allow

## Prepare your mount folder

mkdir -p /home/exports

## Test mounting 

mount $NFS_SERVER_IP:/home /home/exports && ls -la

## Umount and 

umount /home/exports

## Prepare /etc/fstab
 
echo "$NFS_SERVER_IP:home /home/export nfs rw,hard,intr 0 0" >> /etc/fstab
mount -a

```