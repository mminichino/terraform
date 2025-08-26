#!/bin/bash

exec > /tmp/redis_cluster_setup.log 2>&1

echo "Waiting for Redis Enterprise to start..."
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
        echo "Timeout waiting for Redis Enterprise to start"
        exit 1
    fi
done

CURRENT_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
CURRENT_PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
CURRENT_AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
echo "Current node IP: $CURRENT_IP"
echo "Current node public IP: $CURRENT_PUBLIC_IP"
echo "Current node availability zone: $CURRENT_AZ"

NODE_IPS=(${node_ips})
PUBLIC_IPS=(${public_ips})
NODE_AZS=(${node_azs})
echo "All node IPs: $${NODE_IPS[*]}"
echo "All public IPs: $${PUBLIC_IPS[*]}"
echo "All zones: $${NODE_AZS[*]}"

FIRST_NODE_IP=$${NODE_IPS[0]}
echo "First node IP: $FIRST_NODE_IP"

if [ "$CURRENT_IP" = "$FIRST_NODE_IP" ]; then
    echo "This is the first node, creating cluster..."

    echo "Bootstrapping cluster on first node..."
    curl -k -s -H "Content-type: application/json" -X POST https://localhost:9443/v1/bootstrap/create_cluster -d \
    "{
    \"action\": \"create_cluster\",
    \"cluster\": {
        \"name\": \"${environment_name}\",
        \"nodes\": []
    },
    \"node\": {
        \"paths\": {
            \"persistent_path\": \"/var/opt/redislabs/persist\",
            \"ephemeral_path\": \"/var/opt/redislabs/tmp\"
        },
        \"identity\": {
            \"addr\": \"$CURRENT_IP\",
            \"external_addr\": [\"$CURRENT_PUBLIC_IP\"],
            \"rack_id\": \"$CURRENT_AZ\"
        }
    },
    \"policy\": {
        \"rack_aware\": true
    },
    \"dns_suffixes\": [
        {\"name\": \"${dns_suffix}\", \"cluster_default\": true},
        {\"name\": \"internal.${dns_suffix}\", \"use_internal_addr\": true}
    ],
    \"credentials\": {
        \"username\": \"admin@redislabs.com\",
        \"password\": \"${admin_password}\"
    },
    \"license\": \"\"
    }"

    echo "Waiting for cluster initialization..."
    sleep 30

    for i in $${!NODE_IPS[@]}; do
        node_ip="$${NODE_IPS[i]}"
        public_ip="$${PUBLIC_IPS[i]}"
        node_az="$${NODE_AZS[i]}"

        if [ "$node_ip" != "$CURRENT_IP" ]; then
            echo "Adding node $node_ip to cluster..."

            curl -k -s -H "Content-type: application/json" -X POST "https://$${node_ip}:9443/v1/bootstrap/join_cluster" -d \
            "{
            \"action\": \"join_cluster\",
            \"cluster\": {
                \"nodes\": [\"$CURRENT_IP\"]
            },
            \"node\": {
                \"paths\": {
                    \"persistent_path\": \"/var/opt/redislabs/persist\",
                    \"ephemeral_path\": \"/var/opt/redislabs/tmp\"
                },
                \"identity\": {
                    \"addr\": \"$node_ip\",
                    \"external_addr\": [\"$public_ip\"],
                    \"rack_id\": \"$node_az\"
                }
            },
            \"policy\": {
                \"rack_aware\": true
            },
            \"credentials\": {
                \"username\": \"admin@redislabs.com\",
                \"password\": \"${admin_password}\"
            }
            }"

            sleep 10
        fi
    done

    echo "Cluster creation completed!"

    echo "Cluster status:"
    curl -k -s -u "admin@redislabs.com:${admin_password}" \
        -X GET https://localhost:9443/v1/cluster \
        -H "Content-Type: application/json" | jq '.'

else
    echo "This is not the first node, waiting for cluster invitation..."
    sleep 60
fi

echo "Redis Enterprise cluster setup complete"
