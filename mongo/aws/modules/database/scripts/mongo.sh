#!/bin/bash
set -euo pipefail

MONGODB_URL="${mongodb_url}"
MONGODB_VERSION="${mongodb_version}"
MONGOSH_URL="${mongosh_url}"
MONGOSH_VERSION="${mongosh_version}"
REPL_SET_NAME="${repl_set_name}"
MONGO_PORT="${mongo_port}"
KEYFILE_CONTENT="${keyfile}"

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y curl ca-certificates xfsprogs parted numactl libcurl4 libgomp1 libssl3

# --- Data volume ---
DEVICE=""
for candidate in /dev/nvme1n1 /dev/xvdb /dev/sdb; do
  if [ -b "$candidate" ]; then
    DEVICE="$candidate"
    break
  fi
done

if [ -z "$DEVICE" ]; then
  echo "No data volume device found"
  exit 1
fi

echo "Preparing data volume on $DEVICE"

if ! blkid "$DEVICE" >/dev/null 2>&1; then
  parted -s "$DEVICE" mklabel gpt
  parted -s "$DEVICE" mkpart primary xfs 0% 100%

  PARTITION="$${DEVICE}1"
  if [[ "$DEVICE" == *"nvme"* ]]; then
    PARTITION="$${DEVICE}p1"
  fi

  for _ in $(seq 1 30); do
    [ -b "$PARTITION" ] && break
    sleep 1
  done

  mkfs.xfs -f "$PARTITION"
else
  PARTITION="$DEVICE"
  if [[ "$DEVICE" == *"nvme"* ]] && [ -b "$${DEVICE}p1" ]; then
    PARTITION="$${DEVICE}p1"
  elif [ -b "$${DEVICE}1" ]; then
    PARTITION="$${DEVICE}1"
  fi
fi

mkdir -p /data
mountpoint -q /data || mount "$PARTITION" /data

UUID=$(blkid -s UUID -o value "$PARTITION")
if ! grep -q "$UUID" /etc/fstab; then
  echo "UUID=$UUID /data xfs defaults,nofail 0 2" >> /etc/fstab
fi

# --- MongoDB user / dirs ---
id -u mongod >/dev/null 2>&1 || useradd --system --home /var/lib/mongodb --shell /usr/sbin/nologin mongod

mkdir -p /data/db /data/log /etc/mongo /opt/mongodb
chown -R mongod:mongod /data/db /data/log

# --- Download and install Enterprise ---
cd /tmp
TARBALL=$(basename "$MONGODB_URL")
echo "Downloading $MONGODB_URL"
curl -fL -o "$TARBALL" "$MONGODB_URL"
tar -xzf "$TARBALL"

EXTRACTED=$(find /tmp -maxdepth 1 -type d -name "mongodb-linux-*-$${MONGODB_VERSION}" | head -n1)
if [ -z "$EXTRACTED" ]; then
  echo "Failed to locate extracted MongoDB directory"
  exit 1
fi

cp -a "$EXTRACTED"/. /opt/mongodb/
chown -R root:root /opt/mongodb
ln -sfn /opt/mongodb/bin/mongod /usr/local/bin/mongod
ln -sfn /opt/mongodb/bin/mongos /usr/local/bin/mongos

rm -rf "$TARBALL" "$EXTRACTED"

# mongosh is distributed separately from the server tarball
MONGOSH_TARBALL=$(basename "$MONGOSH_URL")
echo "Downloading $MONGOSH_URL"
curl -fL -o "$MONGOSH_TARBALL" "$MONGOSH_URL"
tar -xzf "$MONGOSH_TARBALL"
MONGOSH_DIR=$(find /tmp -maxdepth 1 -type d -name "mongosh-$${MONGOSH_VERSION}-*" | head -n1)
if [ -z "$MONGOSH_DIR" ] || [ ! -x "$MONGOSH_DIR/bin/mongosh" ]; then
  echo "Failed to locate mongosh binary"
  exit 1
fi
cp -a "$MONGOSH_DIR/bin/." /opt/mongodb/bin/
ln -sfn /opt/mongodb/bin/mongosh /usr/local/bin/mongosh
rm -rf "$MONGOSH_TARBALL" "$MONGOSH_DIR"

# --- Keyfile for replica-set auth ---
printf '%s' "$KEYFILE_CONTENT" > /etc/mongo/keyfile
chown mongod:mongod /etc/mongo/keyfile
chmod 400 /etc/mongo/keyfile

TOKEN=$(curl -sf -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
PRIVATE_IP=$(curl -sf -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/local-ipv4)

# --- mongod config ---
cat > /etc/mongod.conf <<EOF
systemLog:
  destination: file
  path: /data/log/mongod.log
  logAppend: true
storage:
  dbPath: /data/db
processManagement:
  timeZoneInfo: /usr/share/zoneinfo
net:
  port: $${MONGO_PORT}
  bindIp: 0.0.0.0
security:
  authorization: enabled
  keyFile: /etc/mongo/keyfile
replication:
  replSetName: $${REPL_SET_NAME}
EOF

chown mongod:mongod /etc/mongod.conf
chmod 640 /etc/mongod.conf

cat > /etc/systemd/system/mongod.service <<EOF
[Unit]
Description=MongoDB Enterprise Database Server
After=network.target

[Service]
User=mongod
Group=mongod
Environment="MONGODB_CONFIG_OVERRIDE_NOFORK=1"
ExecStart=/opt/mongodb/bin/mongod --config /etc/mongod.conf
Restart=always
LimitNOFILE=64000
LimitNPROC=64000

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now mongod

echo "Waiting for local mongod on port $MONGO_PORT..."
for _ in $(seq 1 60); do
  if mongosh --quiet --port "$MONGO_PORT" --eval 'db.runCommand({ ping: 1 }).ok' 2>/dev/null | grep -q 1; then
    echo "mongod is ready on $PRIVATE_IP:$MONGO_PORT"
    break
  fi
  sleep 2
done

echo "MongoDB Enterprise $MONGODB_VERSION install completed on $PRIVATE_IP"
