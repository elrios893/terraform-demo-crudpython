resource "aws_instance" "mysql" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t2.micro"
  subnet_id              = data.aws_subnets.public.ids[0]
  vpc_security_group_ids = [aws_security_group.mysql.id]
  key_name               = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y docker
    systemctl enable docker
    systemctl start docker
    usermod -a -G docker ec2-user

    # Descargar imagen MySQL explicitamente
    docker pull mysql

    # Ejecutar el contenedor MySQL
    docker run --name some-mysql \
      -e MYSQL_ROOT_PASSWORD=${var.db_password} \
      -d -p 3306:3306 mysql

    # Esperar a que MySQL este listo
    for i in $(seq 1 30); do
      if docker exec some-mysql mysql -u root -p${var.db_password} -e "SELECT 1" &>/dev/null; then
        break
      fi
      sleep 2
    done

    # Crear base de datos y tabla
    docker exec some-mysql mysql -u root -p${var.db_password} -e "CREATE DATABASE IF NOT EXISTS ${var.db_name};"
    docker exec some-mysql mysql -u root -p${var.db_password} -e "USE ${var.db_name}; CREATE TABLE IF NOT EXISTS usuarios (id INT AUTO_INCREMENT PRIMARY KEY, nombre VARCHAR(100) NOT NULL, correo VARCHAR(100) NOT NULL);"
    docker exec some-mysql mysql -u root -p${var.db_password} -e "INSERT IGNORE INTO ${var.db_name}.usuarios (nombre, correo) VALUES ('Test', 'test@test.com');"
  EOF

  tags = {
    Name = "mysql-server-iue"
  }
}
