variable "cluster_name" { type = string }
variable "container_name" { type = string }
variable "container_port" { type = number default = 8080 }
variable "task_cpu" { type = number default = 512 }
variable "task_memory" { type = number default = 1024 }
variable "image" { type = string } # ECR image url:tag
variable "public_subnets" { type = list(string) }
variable "private_subnets" { type = list(string) }
variable "alb_certificate_arn" { type = string default = "" }
variable "vpc_id" { type = string }

resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_name
}

resource "aws_iam_role" "task_exec_role" {
  name = "${var.cluster_name}-task-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}
data "aws_iam_policy_document" "ecs_task_assume" {
  statement { actions = ["sts:AssumeRole"] principals { type = "Service" identifiers = ["ecs-tasks.amazonaws.com"] } }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role = aws_iam_role.task_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_lb" "alb" {
  name = "${var.cluster_name}-alb"
  internal = false
  load_balancer_type = "application"
  subnets = var.public_subnets
}

resource "aws_lb_target_group" "tg" {
  name = "${var.cluster_name}-tg"
  port = var.container_port
  protocol = "HTTP"
  vpc_id = var.vpc_id
  target_type = "ip"
  health_check {
    path = "/health"
    interval = 30
    matcher = "200-399"
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port = 443
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = var.alb_certificate_arn
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_ecs_task_definition" "task" {
  family = "${var.cluster_name}-task"
  cpu = tostring(var.task_cpu)
  memory = tostring(var.task_memory)
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn = aws_iam_role.task_exec_role.arn
  container_definitions = jsonencode([
    {
      name = var.container_name
      image = var.image
      portMappings = [{ containerPort = var.container_port, protocol = "tcp" }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = "/ecs/${var.cluster_name}"
          awslogs-region = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
      environment = []
    }
  ])
}

resource "aws_ecs_service" "service" {
  name = "${var.cluster_name}-service"
  cluster = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  network_configuration {
    subnets = var.private_subnets
    assign_public_ip = false
    security_groups = [var.ecs_security_group_id]
  }
  desired_count = var.desired_count
  launch_type = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.https]
}

