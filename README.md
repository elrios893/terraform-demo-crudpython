# Terraform - Infraestructura CRUD Python en AWS

## Arquitectura

```
EC2 MySQL (t2.micro)
  ├── Docker + MySQL (puerto 3306)
  └── Security Group: 3306 desde VPC

ECS Cluster (cluster-iue)
  ├── Launch Template + ASG (1-3 t2.micro)
  ├── Task Definition (td-iue-ecr) → imagen desde ECR
  └── Service (svc-iue) → 1 tarea deseada

ECR Repository (iue-repo) → imagen Docker de la app Flask
```

## Prerrequisitos

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configurado (`aws configure`)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado y corriendo
- Python 3.x + pip (para desarrollo local)
- Key pair EC2 `serverDocker` existente en AWS us-east-1

## Estructura de Archivos

```
terraform/
├── backend.tf          # Backend S3 para el estado
├── provider.tf         # Config AWS provider
├── variables.tf        # Variables
├── data.tf             # Data sources (VPC, subnets, ECR, AMIs, IAM)
├── sg.tf               # Security groups
├── ec2-mysql.tf        # Instancia EC2 para MySQL
├── ecs-cluster.tf      # Cluster ECS + Launch Template + ASG
├── ecs-task-def.tf     # Task definition
├── ecs-service.tf      # ECS Service
├── docker-build.tf     # Build y push de imagen Docker a ECR
├── outputs.tf          # Outputs
├── crud-python/        # Código fuente de la aplicación
│   ├── app.py
│   ├── dockerfile
│   ├── requirements.txt
│   ├── templates/index.html
│   └── .env            # Solo para desarrollo local
└── README.md           # Esta guía
```

## Despliegue

### 1. Crear el bucket S3 para el estado

```bash
aws s3 mb s3://iue-bucket-ecs-893 --region us-east-1
```

### 2. Inicializar Terraform

```bash
terraform init
```

### 3. Revisar el plan

```bash
terraform plan
```

### 4. Desplegar

```bash
terraform apply -auto-approve
```

Esto creará:
1. Security Groups
2. EC2 MySQL con Docker instalado y contenedor MySQL corriendo
3. Construirá la imagen Docker de la app y la subirá a ECR
4. Cluster ECS con Launch Template y Auto Scaling Group
5. Task Definition con variables de entorno (incluyendo IP privada de MySQL)
6. ECS Service corriendo la app

### 5. Post-deploy: Crear la base de datos

Una vez que la instancia MySQL esté activa, conectarse y crear la BD:

```bash
# Obtener la IP pública
terraform output mysql_public_ip

# Conectarse vía SSH
ssh -i serverDocker.pem ec2-user@<IP_PUBLICA>

# Dentro de la instancia, conectarse a MySQL
docker exec -it some-mysql mysql -u root -p

# En MySQL:
CREATE DATABASE crud_db;
USE crud_db;
CREATE TABLE usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(100) NOT NULL
);
INSERT INTO usuarios (nombre, correo) VALUES ('Test', 'test@test.com');
SELECT * FROM usuarios;
EXIT;
```

### 6. Acceder a la aplicación

La app corre en el cluster ECS. Para obtener la URL:

```bash
# Obtener la IP pública de una instancia ECS
aws ec2 describe-instances --filters "Name=tag:Name,Values=ecs-iue-instance" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
```

Abrir en navegador: `http://<IP_ECS>:3000`

## Destruir todo

```bash
terraform destroy -auto-approve
```

Esto eliminará todos los recursos creados, **excepto**:
- El bucket S3 `iue-bucket-ecs-893` (debe eliminarse manualmente si se desea)
- El repositorio ECR `iue-repo` (debe eliminarse manualmente)
- El key pair `serverDocker`
- Los IAM roles (`ecsInstanceRole`, `ecsTaskExecutionRole`)

## Reconstruir desde cero (guía completa)

Si decides eliminar todo y rearmar la infraestructura en otro momento:

### Paso 1: Preparar el entorno local
```bash
# Parate en la carpeta del proyecto
cd C:\Users\Usuario\Desktop\terraform

# Verifica que Docker Desktop está corriendo
docker ps

# Verifica que AWS CLI está configurado
aws sts get-caller-identity

# Verifica que Terraform está instalado
terraform version
```

### Paso 2: Verificar recursos existentes en AWS
```bash
# Verificar que existe el key pair
aws ec2 describe-key-pairs --key-names serverDocker

# Verificar que existe la VPC
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=vpc-iue-vpc"

# Verificar que existe el repositorio ECR
aws ecr describe-repositories --repository-names iue-repo

# Verificar que existen los IAM roles
aws iam get-role --role-name ecsInstanceRole
aws iam get-role --role-name ecsTaskExecutionRole
```

### Paso 3: Crear el bucket S3 para el estado
```bash
aws s3 mb s3://iue-bucket-ecs-893 --region us-east-1
```

### Paso 4: Inicializar y desplegar
```bash
terraform init
terraform apply
```

### Paso 5: Post-deploy
```bash
# Ver outputs
terraform output

# Conectarse a MySQL y crear la BD (ver sección 5 arriba)
```

### Paso 6: Verificar que la app funciona
```bash
# Encontrar IP de instancia ECS
aws ec2 describe-instances --filters "Name=tag:Name,Values=ecs-iue-instance" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text

# Probar la API
curl http://<IP_ECS>:3000/usuarios
```

## Variables de Entorno en ECS

A diferencia del enfoque manual donde el `.env` se copiaba dentro de la imagen Docker, aquí las variables se pasan directamente en la **Task Definition**:

| Variable | Valor | Propósito |
|---|---|---|
| `DB_HOST` | IP privada de EC2 MySQL | Conexión interna VPC |
| `DB_USER` | root | Usuario MySQL |
| `DB_PASSWORD` | root | Contraseña MySQL |
| `DB_NAME` | crud_db | Nombre de la BD |
| `PORT` | 3000 | Puerto de la app Flask |

El `.env` local solo se usa para desarrollo. La imagen Docker **no** incluye el `.env`.

## Notas

- La IP de MySQL es **privada**: las instancias ECS se comunican internamente por la VPC
- Si la EC2 MySQL se destruye, la IP privada cambiará → toca actualizar la task definition
- El Auto Scaling Group mantiene 1 instancia ECS activa (puede escalar hasta 3)
- El Docker build se ejecuta localmente. Si los archivos `app.py`, `dockerfile`, `requirements.txt` o `index.html` cambian, Terraform detecta el cambio y reconstruye la imagen automáticamente en el próximo `apply`
