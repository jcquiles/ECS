
resource "aws_ecs_cluster" "foo" {
  name = "efs-example"
}

resource "aws_security_group" "allow_all_a" {
  name        = "security-group-fargate"
  description = "Allow all inbound traffic"
  vpc_id      = aws_vpc.foo.id

  ingress {
    protocol    = "6"
    from_port   = 80
    to_port     = 8000
    cidr_blocks = [aws_vpc.foo.cidr_block]
  }
}

resource "aws_ecs_service" "bar" {
  name             = "efs-example-service"
  cluster          = aws_ecs_cluster.foo.id
  task_definition  = aws_ecs_task_definition.efs-task.arn
  desired_count    = 2
  launch_type      = "FARGATE"
  platform_version = "1.4.0" //not specfying this version explictly will not currently work for mounting EFS to Fargate

  network_configuration {
    security_groups  = [aws_security_group.allow_all_a.id]
    subnets          = [aws_subnet.alpha.id]
    assign_public_ip = false
  }
}

resource "aws_ecs_task_definition" "efs-task" {
  family                   = "efs-example-task-fargate"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"

  container_definitions = <<DEFINITION
[
  {
      "memory": 128,
      "cpu": 10,
      "portMappings": [
          {
              "hostPort": 80,
              "containerPort": 80,
              "protocol": "tcp"
          }
      ],
      "essential": true,
      "mountPoints": [
          {
              "containerPath": "/usr/share/nginx/html",
              "sourceVolume": "efs-html"
          }
      ],
      "name": "nginx",
      "image": "nginx"
  }
]
DEFINITION

  volume {
    name      = "efs-html"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.foo.id
      root_directory = "/path/to/my/data"
    }
  }
}