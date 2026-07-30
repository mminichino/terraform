#!/bin/bash
set -euo pipefail

touch /tmp/redis_install.log && chmod 0666 /tmp/redis_install.log
exec > /tmp/redis_install.log 2>&1

INSTANCES_PER_NODE="${instances_per_node}"
BASE_PORT="${base_port}"
PASSWORD="${password}"
MAXMEMORY_BYTES="${maxmemory_bytes}"

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y lsb-release curl gpg ca-certificates xfsprogs parted

curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
chmod 644 /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" > /etc/apt/sources.list.d/redis.list

apt-get update -y
apt-get install -y redis

systemctl disable --now redis-server || true

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

  # Wait for partition device node
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

TOKEN=$(curl -sf -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
PRIVATE_IP=$(curl -sf -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/local-ipv4)

mkdir -p /etc/redis /var/run/redis
chown redis:redis /var/run/redis

echo "Configuring $INSTANCES_PER_NODE Redis instances with maxmemory=$${MAXMEMORY_BYTES} bytes"

for i in $(seq 0 $((INSTANCES_PER_NODE - 1))); do
  PORT=$((BASE_PORT + i))
  BUS_PORT=$((10000 + PORT))
  DIR="/data/redis-$${PORT}"
  CONF="/etc/redis/redis-$${PORT}.conf"
  SERVICE="redis-$${PORT}.service"

  mkdir -p "$DIR"
  chown redis:redis "$DIR"

  cat > "$CONF" <<EOF
bind 0.0.0.0
protected-mode no
port $${PORT}
tcp-backlog 511
timeout 0
tcp-keepalive 300

daemonize no
supervised systemd
pidfile /var/run/redis/redis-$${PORT}.pid
loglevel notice
logfile ""

dir $${DIR}
dbfilename dump.rdb

appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
aof-use-rdb-preamble yes

maxmemory $${MAXMEMORY_BYTES}
maxmemory-policy noeviction

requirepass $${PASSWORD}
masterauth $${PASSWORD}

cluster-enabled yes
cluster-config-file nodes-$${PORT}.conf
cluster-node-timeout 5000
cluster-announce-ip $${PRIVATE_IP}
cluster-announce-port $${PORT}
cluster-announce-bus-port $${BUS_PORT}
EOF

  chown redis:redis "$CONF"
  chmod 640 "$CONF"

  cat > "/etc/systemd/system/$${SERVICE}" <<EOF
[Unit]
Description=Redis OSS shard on port $${PORT}
After=network.target

[Service]
Type=notify
ExecStart=/usr/bin/redis-server /etc/redis/redis-$${PORT}.conf
ExecStop=/bin/kill -s TERM \$MAINPID
Restart=always
User=redis
Group=redis
RuntimeDirectory=redis
RuntimeDirectoryMode=0755
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable --now "$SERVICE"
done

echo "Waiting for local Redis shards..."
for i in $(seq 0 $((INSTANCES_PER_NODE - 1))); do
  PORT=$((BASE_PORT + i))
  for _ in $(seq 1 60); do
    if redis-cli -a "$PASSWORD" -p "$PORT" --no-auth-warning ping 2>/dev/null | grep -q PONG; then
      echo "Shard on port $PORT is ready"
      break
    fi
    sleep 2
  done
done

echo "Redis OSS install completed on $PRIVATE_IP"
