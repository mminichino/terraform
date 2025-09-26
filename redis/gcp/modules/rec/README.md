## Sample REC YAML

### With Nginx ingress
```yaml
apiVersion: app.redislabs.com/v1
kind: RedisEnterpriseCluster
metadata:
  labels:
    app: redis
  name: redis-enterprise-cluster
  namespace: redis
spec:
  certificates:
    proxyCertificateSecretName: proxy-cert-secret
  ingressOrRouteSpec:
    apiFqdnUrl: redis-api.cluster.example.com
    dbFqdnSuffix: cluster.example.com
    ingressAnnotations:
      kubernetes.io/ingress.class: nginx
      nginx.ingress.kubernetes.io/ssl-passthrough: "true"
    method: ingress
  nodes: 3
  persistentSpec:
    enabled: true
    storageClassName: premium-rwo
    volumeSize: 32Gi
  redisEnterpriseNodeResources:
    limits:
      cpu: "4"
      memory: 8Gi
    requests:
      cpu: "4"
      memory: 8Gi
  services:
    apiService:
      type: ClusterIP
  servicesRiggerSpec:
    databaseServiceType: cluster_ip,headless
    serviceNaming: bdb_name
  uiServiceType: ClusterIP
  username: demo@redis.com
```

### Using GKE GCP load balancer integration
```yaml
apiVersion: app.redislabs.com/v1
kind: RedisEnterpriseCluster
metadata:
  labels:
    app: redis
  name: redis-enterprise-cluster
  namespace: redis
spec:
  certificates:
    proxyCertificateSecretName: proxy-cert-secret
  nodes: 3
  persistentSpec:
    enabled: true
    storageClassName: premium-rwo
    volumeSize: 32Gi
  redisEnterpriseNodeResources:
    limits:
      cpu: "4"
      memory: 8Gi
    requests:
      cpu: "4"
      memory: 8Gi
  services:
    apiService:
      type: LoadBalancer
  servicesRiggerSpec:
    databaseServiceType: load_balancer,cluster_ip
    serviceNaming: bdb_name
  uiServiceType: LoadBalancer
  username: demo@redis.com
```
