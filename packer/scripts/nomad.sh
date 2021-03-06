#!/bin/bash

set -ex


NOMAD_VERSION=0.5.0-rc1

INSTANCE_PRIVATE_IP=$(ifconfig eth0 | grep "inet addr" | awk '{ print substr($2,6) }')

#######################################
# NOMAD INSTALL
#######################################

# install dependencies
echo "Installing dependencies..."
sudo apt-get install -qq -y wget build-essential curl git-core mercurial bzr libpcre3-dev pkg-config zip default-jre qemu libc6-dev-i386 silversearcher-ag jq htop vim unzip liblxc1 lxc-dev docker.io

# install nomad
echo "Fetching nomad..."
cd /tmp/

wget -q https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip -O nomad.zip

echo "Installing nomad..."
unzip nomad.zip
rm nomad.zip
sudo chmod +x nomad
sudo mv nomad /usr/bin/nomad
sudo mkdir -pm 0600 /etc/nomad.d

# setup nomad directories
sudo mkdir -pm 0600 /opt/nomad
sudo mkdir -p /opt/nomad/data

echo "Nomad installation complete."

# MOVE THIS TO PACKER
sudo tee /etc/systemd/system/nomad.service > /dev/null <<EOF
[Unit]
Description=nomad agent
Requires=network-online.target
After=network-online.target
[Service]
EnvironmentFile=-/etc/sysconfig/nomad
Restart=on-failure
ExecStart=/usr/bin/nomad agent $NOMAD_FLAGS -config=/etc/systemd/system/nomad.d/
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
[Install]
WantedBy=multi-user.target
EOF

sudo chmod 0644 /etc/systemd/system/nomad.service
