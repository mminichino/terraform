#!/bin/bash
set -euo pipefail

exec > /tmp/create_cluster.log 2>&1

ENDPOINTS="${endpoints}"
PASSWORD="${password}"
REPLICAS_PER_MASTER="${replicas_per_master}"

echo "Waiting for all cluster endpoints to become reachable..."
for endpoint in $ENDPOINTS; do
  host="$${endpoint%%:*}"
  port="$${endpoint##*:}"
  ready=0
  for _ in $(seq 1 90); do
    if redis-cli -h "$host" -p "$port" -a "$PASSWORD" --no-auth-warning ping 2>/dev/null | grep -q PONG; then
      echo "Ready: $endpoint"
      ready=1
      break
    fi
    sleep 2
  done
  if [ "$ready" -ne 1 ]; then
    echo "Timeout waiting for $endpoint"
    exit 1
  fi
done

FIRST_ENDPOINT=$(echo "$ENDPOINTS" | awk '{print $1}')
FIRST_HOST="$${FIRST_ENDPOINT%%:*}"
FIRST_PORT="$${FIRST_ENDPOINT##*:}"

# Skip create if a usable cluster already exists
if redis-cli -h "$FIRST_HOST" -p "$FIRST_PORT" -a "$PASSWORD" --no-auth-warning cluster info 2>/dev/null | grep -q "cluster_state:ok"; then
  echo "Cluster already initialized and healthy"
  exit 0
fi

echo "Creating Redis OSS cluster with endpoints: $ENDPOINTS"
echo "Replicas per master: $REPLICAS_PER_MASTER"
# shellcheck disable=SC2086
redis-cli -a "$PASSWORD" --no-auth-warning --cluster create $ENDPOINTS \
  --cluster-replicas "$REPLICAS_PER_MASTER" --cluster-yes

echo "Waiting for cluster_state:ok..."
for _ in $(seq 1 60); do
  if redis-cli -h "$FIRST_HOST" -p "$FIRST_PORT" -a "$PASSWORD" --no-auth-warning cluster info 2>/dev/null | grep -q "cluster_state:ok"; then
    echo "Cluster is healthy"
    redis-cli -h "$FIRST_HOST" -p "$FIRST_PORT" -a "$PASSWORD" --no-auth-warning cluster nodes
    exit 0
  fi
  sleep 2
done

echo "Cluster did not become healthy in time"
redis-cli -h "$FIRST_HOST" -p "$FIRST_PORT" -a "$PASSWORD" --no-auth-warning cluster info || true
exit 1
