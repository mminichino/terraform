#!/bin/bash

exec > /var/log/host_init.log 2>&1

FLAG_FILE="/etc/default/.host_init_complete"

if [ -f "$FLAG_FILE" ]; then
  echo "Init script finished, skipping."
  exit 0
fi

apt update -y
apt upgrade -y

apt install -y wget curl gnupg2 software-properties-common jq unzip zip

parted /dev/sdb --script mklabel gpt
parted /dev/sdb --script mkpart primary ext4 0% 100%

mkfs.ext4 -F /dev/sdb1

mkdir -p /data

mount /dev/sdb1 /data

UUID=$(blkid -s UUID -o value /dev/sdb1)
echo "UUID=$UUID /data ext4 defaults,nofail 0 2" >> /etc/fstab

cat >> /etc/systemd/resolved.conf << EOF
[Resolve]
DNSStubListener=no
EOF

systemctl restart systemd-resolved

mkdir /tmp/redis
cd /tmp/redis || exit

echo "Installing Redis Enterprise"

echo "Copying installation tar file"
gcloud storage cp gs://redis-software/${redis_distribution} ./redis-enterprise.tar

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

touch "$FLAG_FILE"
