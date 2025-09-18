#

output "operator_version" {
  value = helm_release.redis_operator.version
}
