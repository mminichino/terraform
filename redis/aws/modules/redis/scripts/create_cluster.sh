#!/bin/bash

exec > /tmp/create_cluster.log 2>&1

TOKEN=$(curl -sf -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
if [ -z "$TOKEN" ]; then
  echo "Failed to retrieve IMDSv2 token"
  exit 1
fi

private_ip=$(curl -sf -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/local-ipv4)
public_ip=$(curl -sf -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/public-ipv4 || true)
availability_zone=$(curl -sf -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/availability-zone)

if [ -z "$public_ip" ]; then
  public_ip="$private_ip"
fi

echo "Current node IP: $private_ip"
echo "Current node public IP: $public_ip"
echo "Current node availability zone: $availability_zone"

if [ -z "$private_ip" ] || [ -z "$availability_zone" ]; then
  echo "Failed to retrieve required instance metadata"
  exit 1
fi

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

echo "Creating cluster"
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
        "rack_id": "$availability_zone"
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
    "license": "${license}"
}
EOF

echo "Waiting for bootstrap to complete..."
timeout=300
counter=0
while true; do
    current_state=$(curl -k -s -u "${admin_user}:${password}" https://localhost:9443/v1/bootstrap 2>&1 | jq -R -r 'fromjson? | .bootstrap_status.state' 2>&1)
    if [ "$current_state" = "completed" ]; then
      break
    fi
    if [ "$current_state" = "error" ]; then
      echo "Bootstrap failed."
      curl -k -s -u "${admin_user}:${password}" https://localhost:9443/v1/bootstrap
      exit 2
    fi
    sleep 5
    counter=$((counter + 5))
    if [ $counter -ge $timeout ]; then
        echo "Timeout waiting for bootstrap to complete"
        exit 1
    fi
done

echo "Bootstrap completed successfully."
