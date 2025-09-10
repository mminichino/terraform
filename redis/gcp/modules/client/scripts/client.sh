#!/bin/bash

exec > /var/log/host_init.log 2>&1

FLAG_FILE="/etc/default/.host_init_complete"

if [ -f "$FLAG_FILE" ]; then
  echo "Init script finished, skipping."
  exit 0
fi

apt update -y
apt upgrade -y

apt install -y wget curl gnupg2 software-properties-common awscli jq unzip zip openjdk-17-jre-headless python3-pip python3-dev cmake

snap install astral-uv --classic

curl -OLs --output-dir /tmp https://github.com/asdf-vm/asdf/releases/download/v0.18.0/asdf-v0.18.0-linux-amd64.tar.gz
tar xzvf /tmp/asdf-v0.18.0-linux-amd64.tar.gz -C /usr/local/bin
rm /tmp/asdf-v0.18.0-linux-amd64.tar.gz

curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
apt install -y nodejs
npm install -g pm2

curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/redis.list

apt update
apt install -y redis

pip install hostinit

bundlemgr -b GenAppNode
bundlemgr -b GCPCLI

touch "$FLAG_FILE"
