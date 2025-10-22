#!/bin/bash

yum update -y
yum upgrade -y

yum install -y wget curl gnupg2 jq unzip zip

DEVICE=""

if [ -e /dev/xvdb ]; then
    DEVICE="/dev/xvdb"
elif [ -e /dev/nvme1n1 ]; then
    DEVICE="/dev/nvme1n1"
elif [ -e /dev/sdb ]; then
    DEVICE="/dev/sdb"
fi

if [ -z "$DEVICE" ]; then
    echo "No device found for sdb"
    exit 1
fi

echo "Creating partition on $DEVICE"

parted -s "$DEVICE" mklabel gpt
parted -s "$DEVICE" mkpart primary xfs 0% 100%

PARTITION="${DEVICE}1"
if [[ $DEVICE == *"nvme"* ]]; then
    PARTITION="${DEVICE}p1"
fi

mkfs.xfs "$PARTITION"

mkdir -p /data

mount "$PARTITION" /data

echo "Mounted $PARTITION on /data"

UUID=$(blkid -s UUID -o value "$PARTITION")
echo "UUID=$UUID /data xfs defaults,nofail 0 2" >> /etc/fstab
echo "Added entry to /etc/fstab"

mkdir /tmp/redis
cd /tmp/redis || exit

echo "Installing Redis Enterprise"

echo "Copying installation tar file"
aws s3 cp "s3://${bucket}/${redis_distribution}" ./redis-enterprise.tar

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

usermod -a -G redislabs ec2-user
cat <<EOF >> /home/ec2-user/.bashrc
export PATH=/opt/redislabs/bin:$PATH
EOF

mkdir -p /data/persistent
mkdir -p /data/temp
mkdir -p /data/flash
sudo chown -R redislabs:redislabs /data
