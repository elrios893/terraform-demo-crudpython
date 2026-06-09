resource "aws_ecs_service" "app" {
  name            = "svc-iue"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "EC2"
}
