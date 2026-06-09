output "mysql_public_ip" {
  description = "IP publica de la instancia MySQL"
  value       = aws_instance.mysql.public_ip
}

output "mysql_private_ip" {
  description = "IP privada de la instancia MySQL (usada por la app)"
  value       = aws_instance.mysql.private_ip
}

output "ecr_repository_url" {
  description = "URL del repositorio ECR"
  value       = data.aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  description = "Nombre del cluster ECS"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Nombre del servicio ECS"
  value       = aws_ecs_service.app.name
}
