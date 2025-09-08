#!/bin/bash

dnf update -y

dnf config-manager --set-enabled crb
dnf install -y epel-release
dnf upgrade -y

dnf install -y wget curl gnupg2 jq unzip zip java-17-openjdk-headless python3-pip python3-devel cmake snapd

systemctl enable --now snapd.socket
systemctl enable --now snapd
ln -s /var/lib/snapd/snap /snap

sleep 5

snap install astral-uv --classic

pip install hostinit

storagemgr -W -n 3
bundlemgr -b Swap
bundlemgr -b DataVolume
bundlemgr -b GenDBNode
bundlemgr -b AWSCLI
