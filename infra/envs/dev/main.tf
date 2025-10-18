provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "../../modules/vpc"
  name = "demo-dev"
  vpc_cidr = var.vpc_cidr
  azs = var.azs
  public_subnets = var.public_subnets
  private_subnets = var.private_subnets
}

module "ecr" {
  source = "../../modules/ecr"
  name = var.ecr_name
}

module "rds" {
  source = "../../modules/rds"
  db_identifier = var.db_identifier
  db_username = var.db_username
  db_password = var.db_password
  db_subnet_ids = module.vpc.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  create_read_replica = var.create_read_replica
  instance_class = var.db_instance_class
}

resource "aws_security_group" "alb_sg" {
  name = "alb-sg"
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress { from_port=0 to_port=0 protocol="-1" cidr_blocks=["0.0.0.0/0"] }
}

resource "aws_security_group" "ecs_sg" {
  name = "ecs-sg"
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  egress { from_port=0 to_port=0 protocol="-1" cidr_blocks=["0.0.0.0/0"] }
}

resource "aws_security_group" "rds_sg" {
  name = "rds-sg"
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }
  egress { from_port=0 to_port=0 protocol="-1" cidr_blocks=["0.0.0.0/0"] }
}

module "ecs" {
  source = "../../modules/ecs"
  cluster_name = "demo-cluster"
  container_name = "go-api"
  image = "${module.ecr.repository_url}:latest"
  public_subnets = module.vpc.public_subnet_ids
  private_subnets = module.vpc.private_subnet_ids
  vpc_id = module.vpc.vpc_id
  alb_certificate_arn = var.alb_certificate_arn
  ecs_security_group_id = aws_security_group.ecs_sg.id
  desired_count = var.desired_count
  aws_region = var.aws_region
}

