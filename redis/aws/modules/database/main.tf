#

resource "random_string" "password" {
  length           = 16
  special          = false
}

locals {
  data_json = jsonencode({
    uid                       = var.uid
    memory_size               = var.memory_size
    name                      = var.name
    port                      = var.port
    proxy_policy              = "all-master-shards"
    shards_count              = 1
    type                      = "redis"
    data_persistence          = "aof"
    aof_policy                = "appendfsync-every-sec"
    replication               = var.replication
    eviction_policy           = var.eviction ? "volatile-lru" : "noeviction"
    authentication_redis_pass = random_string.password.id
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
    user        = "ubuntu"
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
