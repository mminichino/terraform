#

resource "random_string" "password" {
  length           = 16
  special          = false
}

locals {
  data_json = jsonencode({
    uid                                     = var.uid
    memory_size                             = var.memory_size
    name                                    = var.name
    port                                    = var.port
    proxy_policy                            = var.proxy_policy
    shards_count                            = var.shards_count
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
    module_list      = [
      {
        module_name = "search"
        module_args = ""
      },
      {
        module_name = "ReJSON"
        module_args = ""
      }
    ]
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
    ]
  }

  provisioner "remote-exec" {
    when   = destroy
    inline = [
      "curl -k -s -u '${self.triggers.username}:${self.triggers.password}' -X DELETE https://localhost:9443/v1/bdbs/${self.triggers.uid}",
    ]
  }
}
