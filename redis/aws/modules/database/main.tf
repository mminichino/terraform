#

resource "random_string" "password" {
  length           = 16
  special          = false
}

locals {
  external_endpoint = "redis-${var.port}.${var.cluster_domain}"
  internal_endpoint = "redis-${var.port}.internal.${var.cluster_domain}"
  workers = max(1, round(var.cpu_count * 0.66666667))
  data_json = jsonencode(
    merge(
      {
        uid                                     = var.uid
        memory_size                             = var.memory_size
        name                                    = var.name
        port                                    = var.port
        proxy_policy                            = var.proxy_policy
        shards_count                            = var.shards_count
        sharding                                = var.shards_count > 1
        shards_placement                        = var.shards_placement
        type                                    = var.database_type
        data_persistence                        = var.data_persistence
        aof_policy                              = var.aof_policy
        oss_cluster                             = var.oss_cluster
        oss_cluster_api_preferred_endpoint_type = var.oss_cluster_endpoint
        oss_cluster_api_preferred_ip_type       = var.oss_cluster_type
        replication                             = var.replication
        eviction_policy                         = var.eviction ? "volatile-lru" : "noeviction"
        authentication_redis_pass               = random_string.password.id
        search = {
          search-workers = local.workers
        }
      },
      var.shards_count > 1 ? {
        shard_key_regex = [
          {
            "regex": ".*\\{(?<tag>.*)\\}.*"
          },
          {
            "regex": "(?<tag>.*)"
          }
        ]
      } : {}
    )
  )
  proxy_json = jsonencode({
    proxy = {
      threads = 8
    }
  })
}

resource "null_resource" "database" {
  triggers = {
    uid         = var.uid
    private_key = var.private_key_file
    public_ip   = var.public_ip
    username    = var.username
    password    = var.password
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/${self.triggers.private_key}")
    host        = self.triggers.public_ip
  }

  provisioner "remote-exec" {
    when   = create
    inline = [
      "curl -k -s -u '${self.triggers.username}:${self.triggers.password}' -X POST -H 'Content-Type: application/json' --data-raw '${local.data_json}' https://localhost:9443/v1/bdbs",
      "curl -k -s -u '${self.triggers.username}:${self.triggers.password}' -X PUT -H 'Content-Type: application/json' --data-raw '${local.proxy_json}' https://localhost:9443/v1/proxies/${var.uid}"
    ]
  }

  provisioner "remote-exec" {
    when   = destroy
    inline = [
      "curl -k -s -u '${self.triggers.username}:${self.triggers.password}' -X DELETE https://localhost:9443/v1/bdbs/${self.triggers.uid}",
    ]
  }
}
