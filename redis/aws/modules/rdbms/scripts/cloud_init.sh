#!/bin/bash

err_exit() {
   if [ -n "$1" ]; then
      echo "[!] Error: $1"
   fi
   exit 1
}

source /etc/os-release
OS_MAJOR_REV=$(echo "$VERSION_ID" | cut -d. -f1)
OS_MINOR_REV=$(echo "$VERSION_ID" | cut -d. -f2)
export OS_MAJOR_REV OS_MINOR_REV ID
echo "Linux type $ID - $NAME version $OS_MAJOR_REV"

case ${ID:-null} in
ol)
  dnf update -y
  dnf config-manager --set-enabled ol8_codeready_builder
  dnf install -y oracle-epel-release-el8
  dnf upgrade -y
  dnf install -y wget curl gnupg2 jq unzip zip java-17-openjdk-headless python39 python39-pip python39-devel cmake snapd git
  systemctl enable --now snapd.socket
  systemctl enable --now snapd
  ln -s /var/lib/snapd/snap /snap
  update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 10
  update-alternatives --set python3 /usr/bin/python3.9
  python3 -m pip install --upgrade pip setuptools wheel
;;
centos|rhel)
  dnf update -y
  dnf config-manager --set-enabled crb
  dnf install -y epel-release
  dnf upgrade -y
  dnf install -y wget curl gnupg2 jq unzip zip java-17-openjdk-headless python3-pip python3-devel cmake snapd git
  systemctl enable --now snapd.socket
  systemctl enable --now snapd
  ln -s /var/lib/snapd/snap /snap
;;
ubuntu)
  apt update -y
  apt upgrade -y
  apt install -y wget curl gnupg2 software-properties-common jq unzip zip openjdk-17-jre-headless python3-pip python3-venv python3-dev cmake
  snap install astral-uv --classic
;;
*)
  err_exit "Unknown Linux distribution $ID"
;;
esac

sleep 5

snap install astral-uv --classic

python3 -m pip install hostinit

storagemgr -W -n 3
bundlemgr -b Swap
bundlemgr -b DataVolume
bundlemgr -b GenDBNode
bundlemgr -b AWSCLI
