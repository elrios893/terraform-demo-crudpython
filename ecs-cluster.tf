resource "aws_ecs_cluster" "main" {
  name = "cluster-iue"
}

resource "aws_launch_template" "ecs" {
  name_prefix   = "ecs-iue-"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = "t2.micro"
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ecs_instance.id]
    delete_on_termination       = true
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=cluster-iue >> /etc/ecs/ecs.config
  EOF
  )

  iam_instance_profile {
    name = data.aws_iam_instance_profile.ecs_instance.name
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ecs-iue-instance"
    }
  }
}

resource "aws_autoscaling_group" "ecs" {
  name_prefix         = "asg-ecs-iue-"
  vpc_zone_identifier = data.aws_subnets.public.ids
  min_size            = 1
  max_size            = 3
  desired_capacity    = 1

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }
}
