#!/bin/bash

# <UDF name="USER_PASSWORD" Label="Password for user account" />

# All done
echo "Starting Setup!"

set -e

# Save stdout and stderr
exec 6>&1
exec 5>&2

# Redirect stdout and stderr to a file
exec > /root/StackScript.out
exec 2>&1

# apt-get
sudo apt-get -y -o Acquire::ForceIPv4=true -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Acquire::ForceIPv4=true -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

# Project specific vars
GITHUB_USER="wonglok"
GITHUB_REPO="personal-metaverse"

# SSH
echo 'AddressFamily inet' | sudo tee -a /etc/ssh/sshd_config
sed -re 's/^(\#)(PasswordAuthentication)([[:space:]]+)(.*)/\2\3\4/' -i.'' /etc/ssh/sshd_config
sed -re 's/^(PasswordAuthentication)([[:space:]]+)yes/\1\2no/' -i.'' /etc/ssh/sshd_config
sed -re 's/^(UsePAM)([[:space:]]+)yes/\1\2no/' -i.'' /etc/ssh/sshd_config
sed -re 's/^(PermitRootLogin)([[:space:]]+)yes/\1\2no/' -i.'' /etc/ssh/sshd_config
sudo systemctl restart sshd

apt-get -y install mongodb

# nvm/npm/pm2
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

nvm install 16
nvm use 16
npm install -g pm2

# Add user
# cp /root/.bashrc /etc/skel/.bashrc
# adduser --disabled-password --gecos "" --shell /bin/bash $GITHUB_USER
# usermod -aG sudo $GITHUB_USER
# # echo "$GITHUB_USER:$USER_PASSWORD" | sudo chpasswd
# mkdir -p /home/$GITHUB_USER/.ssh
# cat /root/.ssh/authorized_keys >> /home/$GITHUB_USER/.ssh/authorized_keys
# chown -R "$GITHUB_USER":"$GITHUB_USER" /home/$GITHUB_USER/.ssh

# Install app
APP_DIR="/root/$GITHUB_REPO"
curl -L https://github.com/$GITHUB_USER/$GITHUB_REPO/tarball/master | tar zx
mkdir -p $APP_DIR
mv -T $GITHUB_USER-$GITHUB_REPO-* $APP_DIR
cd $APP_DIR
npm install

# # App env
# echo "TWITTER_KEY=$TWITTER_KEY" >> .env
# echo "TWITTER_SECRET=$TWITTER_SECRET" >> .env
# echo "TWITTER_TOKEN=$TWITTER_TOKEN" >> .env
# echo "TWITTER_TOKEN_SECRET=$TWITTER_TOKEN_SECRET" >> .env
# echo "POSTGRES_URL=$POSTGRES_URL" >> .env

# Make it user accessible
# chown -R "$GITHUB_USER":"$GITHUB_USER" $APP_DIR/

pm2 start app.js -f

# All done
echo "Success!"

# Restore stdout and stderr
exec 1>&6 6>&-
exec 2>&5 5>&-