#!/bin/bash

exec > /tmp/create_cluster.log 2>&1

private_ip=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
public_ip=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
availability_zone=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
echo "Current node IP: $private_ip"
echo "Current node public IP: $public_ip"
echo "Current node availability zone: $availability_zone"

cat <<EOF | curl -k -s -o - -I -H "Content-type: application/json" -X POST --data-binary @- https://localhost:9443/v1/bootstrap/create_cluster
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
    "license": ""
}
EOF

echo "Waiting for cluster initialization..."
sleep 30
