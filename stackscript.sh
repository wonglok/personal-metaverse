#!/bin/bash

# <UDF name="USER_PASS" Label="NodeJS Runtime Password" />


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

# add-apt-repository ppa:certbot/certbot
# apt-get install certbot

echo "Starting setup certbot!"
sudo snap install core;
sudo snap refresh core;
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot

echo "Starting setup mongodb!"
apt-get -y install mongodb

echo "Starting setup nginx!"
apt-get -y install nginx
sudo systemctl start nginx
sudo systemctl enable nginx

cat > /etc/nginx/sites-available/default << EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server ipv6only=on;

    location / {
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-NginX-Proxy true;
      proxy_pass http://localhost:3000;
      proxy_set_header Host $http_host;
      proxy_cache_bypass $http_upgrade;
      proxy_redirect off;
    }
}
EOF

sudo nginx -t
sudo systemctl restart nginx

# Project specific vars
NODE_USER="nodejs"
GITHUB_USER="wonglok"
GITHUB_REPO="personal-metaverse"

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

echo "Starting setup nodejs!"

# Add user
cp /root/.bashrc /etc/skel/.bashrc
adduser --disabled-password --gecos "" --shell /bin/bash $NODE_USER
usermod -aG sudo $NODE_USER
echo "$NODE_USER:$USER_PASS" | sudo chpasswd
mkdir -p /home/$NODE_USER/.ssh
cat /root/.ssh/authorized_keys >> /home/$NODE_USER/.ssh/authorized_keys
chown -R "$NODE_USER":"$NODE_USER" /home/$NODE_USER/.ssh

echo "installing nodejs setup!"

# Install app
APP_DIR="/$NODE_USER/$GITHUB_REPO"
curl -L https://github.com/$GITHUB_USER/$GITHUB_REPO/tarball/master | tar zx
mkdir -p $APP_DIR
mv -T $GITHUB_USER-$GITHUB_REPO-* $APP_DIR
cd $APP_DIR
npm install

# Make it user accessible
chown -R "$NODE_USER":"$NODE_USER" $APP_DIR/

echo "Starting Setup App!"

# node setup.js
pm2 start app.js -f
pm2 startup ubuntu

# All done
echo "Success!"

# # Restore stdout and stderr
exec 1>&6 6>&-
exec 2>&5 5>&-


# pm2 stop app.js
# certbot certonly --standalone --domains metaverse.thankyoudb.com -n --agree-tos -m yellowhappy831@gmail.com
# pm2 start app.js -f