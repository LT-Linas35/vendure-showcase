output "db_instance_endpoint" {
  description = "The hostname of the PostgreSQL database instance, without port"
  value       = split(":", module.db.db_instance_endpoint)[0]
  sensitive   = true
}
