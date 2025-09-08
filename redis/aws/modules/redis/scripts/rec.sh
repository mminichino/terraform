#!/bin/bash

apt update -y
apt upgrade -y

apt install -y wget curl gnupg2 software-properties-common jq unzip zip openjdk-17-jre-headless python3-pip python3-venv python3-dev cmake

snap install astral-uv --classic

pip install hostinit

storagemgr -W -n 2
bundlemgr -b DataVolume
bundlemgr -b DisableDNSStub -D ${dns_server}
bundlemgr -b GenDBNode
bundlemgr -b AWSCLI

mkdir /tmp/redis
cd /tmp/redis || exit

echo "Installing Redis Enterprise"

echo "Copying installation tar file"
aws s3 cp s3://redis-enterprise-software/${redis_distribution} ./redis-enterprise.tar

tar -xf redis-enterprise.tar

if [ -f "install.sh" ]; then
    echo "Running installation script"
    ./install.sh -y
else
    echo "No recognized installation method found"
    exit 1
fi

cd /
rm -rf /tmp/redis

usermod -a -G redislabs ubuntu
cat <<EOF >> /home/ubuntu/.bashrc
export PATH=/opt/redislabs/bin:$PATH
EOF

mkdir -p /data/persistent
mkdir -p /data/temp
mkdir -p /data/flash
sudo chown -R redislabs:redislabs /data
