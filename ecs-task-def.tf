resource "aws_ecs_task_definition" "app" {
  family                   = "td-iue-ecr"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "128"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "crud-python"
      image     = "${data.aws_ecr_repository.app.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "DB_HOST",     value = aws_instance.mysql.private_ip },
        { name = "DB_USER",     value = "root" },
        { name = "DB_PASSWORD", value = var.db_password },
        { name = "DB_NAME",     value = var.db_name },
        { name = "PORT",        value = "3000" }
      ]
    }
  ])

  depends_on = [null_resource.docker_build_and_push]
}
