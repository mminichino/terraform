## Sample REDB YAML

### Redis Database
```yaml
apiVersion: app.redislabs.com/v1alpha1
kind: RedisEnterpriseDatabase
metadata:
  name: redb1
  namespace: redis
  labels:
    app: redis-database
spec:
  databasePort: 12000
  databaseSecretName: redb1
  evictionPolicy: noeviction
  memorySize: 1GB
  modulesList:
    - name: ReJSON
    - name: search
    - name: timeseries
  persistence: aofEverySecond
  proxyPolicy: all-master-shards
  redisEnterpriseCluster:
    name: redis-enterprise-cluster
  replication: true
  shardCount: 1
  shardsPlacement: dense
  type: redis
```

### Redis Database Secret
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: redb1
  namespace: redis
type: Opaque
data:
  password: cGFzc3dvcmQ=
```
