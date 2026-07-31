#!/bin/bash
set -euo pipefail

exec > /tmp/init_replica_set.log 2>&1

MEMBERS="${members}"
REPL_SET_NAME="${repl_set_name}"
MONGO_PORT="${mongo_port}"
PASSWORD="${password}"
ADMIN_USER="${admin_user}"

IFS=',' read -r -a MEMBER_LIST <<< "$MEMBERS"

echo "Waiting for all replica set members to become reachable..."
for member in "$${MEMBER_LIST[@]}"; do
  host="$${member%%:*}"
  port="$${member##*:}"
  ready=0
  for _ in $(seq 1 90); do
    # ping does not require authentication
    if mongosh --quiet --host "$host" --port "$port" --eval 'db.runCommand({ ping: 1 }).ok' 2>/dev/null | grep -q 1; then
      echo "Ready: $member"
      ready=1
      break
    fi
    sleep 2
  done
  if [ "$ready" -ne 1 ]; then
    echo "Timeout waiting for $member"
    exit 1
  fi
done

mongosh_local() {
  mongosh --quiet --port "$MONGO_PORT" "$@"
}

mongosh_auth() {
  mongosh --quiet --port "$MONGO_PORT" \
    -u "$ADMIN_USER" -p "$PASSWORD" --authenticationDatabase admin "$@"
}

# Localhost exception only applies to 127.0.0.1 — use local port for bootstrap ops
echo "Checking replica set status on localhost:$MONGO_PORT..."

is_replica_set_ok() {
  local result
  result=$(mongosh_auth --eval 'try { rs.status().ok } catch(e) { 0 }' 2>/dev/null || true)
  if echo "$result" | grep -q 1; then
    return 0
  fi
  result=$(mongosh_local --eval 'try { rs.status().ok } catch(e) { 0 }' 2>/dev/null || true)
  echo "$result" | grep -q 1
}

if is_replica_set_ok; then
  echo "Replica set already initialized"
else
  echo "Initializing replica set $REPL_SET_NAME with members: $MEMBERS"

  MEMBERS_JS=""
  idx=0
  for member in "$${MEMBER_LIST[@]}"; do
    if [ -n "$MEMBERS_JS" ]; then
      MEMBERS_JS="$${MEMBERS_JS}, "
    fi
    MEMBERS_JS="$${MEMBERS_JS}{ _id: $${idx}, host: \"$${member}\" }"
    idx=$((idx + 1))
  done

  mongosh_local <<EOF
rs.initiate({
  _id: "$${REPL_SET_NAME}",
  members: [ $${MEMBERS_JS} ]
})
EOF

  echo "Waiting for PRIMARY election..."
  for _ in $(seq 1 90); do
    STATE=$(mongosh_local \
      --eval 'try { rs.isMaster().ismaster ? "PRIMARY" : "OTHER" } catch(e) { "OTHER" }' 2>/dev/null || echo "OTHER")
    if [ "$STATE" = "PRIMARY" ]; then
      echo "Node is PRIMARY"
      break
    fi
    sleep 2
  done
fi

echo "Ensuring admin user exists..."
if mongosh_auth --eval 'db.getSiblingDB("admin").getUser("'"$ADMIN_USER"'") != null' 2>/dev/null | grep -qi true; then
  echo "Admin user already exists"
else
  mongosh_local <<EOF
use admin
db.createUser({
  user: "$${ADMIN_USER}",
  pwd: "$${PASSWORD}",
  roles: [
    { role: "root", db: "admin" }
  ]
})
print("Created admin user")
EOF
fi

echo "Replica set status:"
mongosh_auth --eval 'rs.status().members.map(m => m.name + " " + m.stateStr).join("\n")'

echo "Replica set initialization completed"
