#!/bin/bash

exec > /tmp/create_cluster.log 2>&1

private_ip=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
public_ip=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
zone=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone)
zone=$(basename "$zone")
echo "Current node IP: $private_ip"
echo "Current node public IP: $public_ip"
echo "Current node zone: $zone"

echo "Waiting for Redis Enterprise API..."
timeout=300
counter=0
while true; do
    current_state=$(curl -k -s https://localhost:9443/v1/bootstrap 2>&1 | jq -R -r 'fromjson? | .bootstrap_status.state' 2>&1)
    if [ "$current_state" = "idle" ]; then
      break
    fi
    sleep 5
    counter=$((counter + 5))
    if [ $counter -ge $timeout ]; then
        echo "Timeout waiting for Redis Enterprise API"
        exit 1
    fi
done

cat <<EOF | curl -k -s -w "Status: %%{http_code}\n" -H "Content-type: application/json" -X POST --data-binary @- https://localhost:9443/v1/bootstrap/create_cluster
{
    "action": "create_cluster",
    "cluster": {
      "name": "${cluster_name}",
      "nodes": []
    },
    "node": {
      "bigstore_enabled": true,
      "paths": {
        "persistent_path": "/data/persistent",
        "ephemeral_path": "/data/temp",
        "bigstore_path": "/data/flash"
      },
      "identity": {
        "addr": "$private_ip",
        "external_addr": [
            "$public_ip"
        ],
        "rack_id": "$zone"
      }
    },
    "policy": {
      "rack_aware": true
    },
    "dns_suffixes": [
      {
        "name": "${domain_name}",
        "cluster_default": true
      },
      {
        "name": "internal.${domain_name}",
        "use_internal_addr": true
      }
    ],
    "credentials": {
      "username": "${admin_user}",
      "password": "${password}"
    },
    "license": ""
}
EOF

echo "Waiting for bootstrap to complete..."
timeout=300
counter=0
while true; do
    current_state=$(curl -k -s -u "${admin_user}:${password}" https://localhost:9443/v1/bootstrap 2>&1 | jq -R -r 'fromjson? | .bootstrap_status.state' 2>&1)
    if [ "$current_state" = "completed" ] || [ "$current_state" = "error" ]; then
      break
    fi
    sleep 5
    counter=$((counter + 5))
    if [ $counter -ge $timeout ]; then
        echo "Timeout waiting for bootstrap to complete"
        exit 1
    fi
done
