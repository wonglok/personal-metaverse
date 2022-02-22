#!/bin/bash

# <UDF name="USER_PASS" Label="NodeJS Linux User Password" />

# All done
echo "Starting Setup!"

set -e

# # Save stdout and stderr
exec 6>&1
exec 5>&2

# # Redirect stdout and stderr to a file
exec > /root/StackScript.out
exec 2>&1

# apt-get
sudo apt-get -y -o Acquire::ForceIPv4=true -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Acquire::ForceIPv4=true -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

echo "Starting setup mongodb!"

apt-get -y install mongodb

# Project specific vars
GITHUB_USER="wonglok"
GITHUB_REPO="personal-metaverse"

NODE_USER="mynode"


# SSH
echo 'AddressFamily inet' | sudo tee -a /etc/ssh/sshd_config
sed -re 's/^(\#)(PasswordAuthentication)([[:space:]]+)(.*)/\2\3\4/' -i.'' /etc/ssh/sshd_config
sed -re 's/^(PasswordAuthentication)([[:space:]]+)yes/\1\2no/' -i.'' /etc/ssh/sshd_config
sed -re 's/^(UsePAM)([[:space:]]+)yes/\1\2no/' -i.'' /etc/ssh/sshd_config
sed -re 's/^(PermitRootLogin)([[:space:]]+)yes/\1\2no/' -i.'' /etc/ssh/sshd_config
sudo systemctl restart sshd

echo "Starting setup nvm!"

# nvm/npm/pm2
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

nvm install 16
nvm use 16
npm install -g pm2

echo "Starting setup user!"

# Add user
cp /root/.bashrc /etc/skel/.bashrc
adduser --disabled-password --gecos "" --shell /bin/bash $NODE_USER
usermod -aG sudo $NODE_USER
echo "$NODE_USER:$USER_PASS" | sudo chpasswd
mkdir -p /home/$NODE_USER/.ssh
cat /root/.ssh/authorized_keys >> /home/$NODE_USER/.ssh/authorized_keys
chown -R "$NODE_USER":"$NODE_USER" /home/$NODE_USER/.ssh

echo "Adding App Files"

# Install app
APP_DIR="/home/$NODE_USER/$GITHUB_REPO"
curl -L https://github.com/$GITHUB_USER/$GITHUB_REPO/tarball/master | tar zx
mkdir -p $APP_DIR
mv -T $GITHUB_USER-$GITHUB_REPO-* $APP_DIR
cd $APP_DIR
npm install

openssl genrsa 4096 > account.key

# Make it user accessible
chown -R "$NODE_USER":"$NODE_USER" $APP_DIR/


echo "Starting Setup App!"


# node setup.js
pm2 start app.js -f

# All done
echo "Success!"

# # Restore stdout and stderr
exec 1>&6 6>&-
exec 2>&5 5>&-
