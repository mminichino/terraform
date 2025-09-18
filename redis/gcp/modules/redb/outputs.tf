#

output "database_password" {
  value = random_string.password.id
}
