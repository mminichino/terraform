#!/bin/bash

mount_data_volume() {
  local device=""
  if compgen -G "/dev/nvme*n1" >/dev/null; then
    for nv in /dev/nvme*n1; do
      if dev=$(sudo python3 /tmp/ebsnvme.py -b "$nv" 2>/dev/null); then
        if [[ "$dev" == "sdb" ]]; then
          device="$nv"
          break
        fi
      fi
    done
    if [[ -z "$device" ]]; then
      echo "Could not resolve NVMe device that maps to sdb."
      return 1
    fi
  else
    device="/dev/xvdb"
    if [[ ! -b "$device" ]]; then
      echo "Expected non-NVMe device $device not found."
      return 1
    fi
  fi

  echo "Resolved sdb device: $device"

  if [[ "$device" == *"nvme"* ]]; then
    part="$${device}p1"
  else
    part="$${device}1"
  fi

  if [[ ! -b "$part" ]]; then
    echo "Creating GPT partition on $device ..."
    sudo parted -s "$device" mklabel gpt
    sudo parted -s "$device" mkpart primary ext4 0% 100%
    sudo partprobe "$device"
    echo "Creating ext4 filesystem on $part ..."
    sudo mkfs.ext4 -F -m 0 -L data "$part"
  else
    echo "Partition $part already exists."
  fi

  sudo mkdir -p /data

  uuid=$(blkid -s UUID -o value "$part")
  if [[ -z "$uuid" ]]; then
    echo "$part /data ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab >/dev/null
  else
    echo "UUID=$uuid /data ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab >/dev/null
  fi

  sudo mount -a
  echo "Data volume mounted at /data"
  sudo mkdir -p /data/persistent
  sudo mkdir -p /data/temp
  sudo mkdir -p /data/flash
  echo "Created data volume directory structure"
  sudo chown -R redislabs:redislabs /data
  echo "Set data volume ownership"
}

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

mount_data_volume || exit 1

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
        \"bigstore_enabled\": true,
        \"paths\": {
            \"persistent_path\": \"/data/persistent\",
            \"ephemeral_path\": \"/data/temp\",
            \"bigstore_path\": \"/data/flash\"
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
        \"username\": \"${admin_user}\",
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
