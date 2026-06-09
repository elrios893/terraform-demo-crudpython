variable "key_name" {
  description = "Nombre del key pair EC2 para SSH"
  type        = string
  default     = "serverDocker"
}

variable "vpc_name" {
  description = "Nombre tag de la VPC existente"
  type        = string
  default     = "vpc-iue-vpc"
}

variable "db_password" {
  description = "Contraseña de MySQL"
  type        = string
  sensitive   = true
  default     = "root"
}

variable "db_name" {
  description = "Nombre de la base de datos MySQL"
  type        = string
  default     = "crud_db"
}
