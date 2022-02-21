#!/bin/bash
### linode
### Install OpenLiteSpeed and NodeJS
bash <( curl -sk https://raw.githubusercontent.com/litespeedtech/ls-cloud-image/master/Setup/nodejssetup.sh )
### Regenerate password for Web Admin, Database, setup Welcome Message
bash <( curl -sk https://raw.githubusercontent.com/litespeedtech/ls-cloud-image/master/Cloud-init/per-instance.sh )


# apt-get
sudo apt-get -y -o Acquire::ForceIPv4=true -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Acquire::ForceIPv4=true -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

apt-get -y install mongodb

