variable "db_identifier" { type = string }
variable "db_username" { type = string }
variable "db_password" { type = string }
variable "db_subnet_ids" { type = list(string) }
variable "vpc_security_group_ids" { type = list(string) }
variable "engine" { type = string default = "postgres" }
variable "instance_class" { type = string default = "db.t3.medium" }
variable "multi_az" { type = bool default = true }
variable "allocated_storage" { type = number default = 20 }

resource "aws_db_subnet_group" "db_subnet" {
  name       = "${var.db_identifier}-subnet"
  subnet_ids = var.db_subnet_ids
}

resource "aws_db_instance" "primary" {
  identifier = var.db_identifier
  engine = var.engine
  instance_class = var.instance_class
  name = "appdb"
  username = var.db_username
  password = var.db_password
  allocated_storage = var.allocated_storage
  multi_az = var.multi_az
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids = var.vpc_security_group_ids
  publicly_accessible = false
  tags = { Name = "${var.db_identifier}-primary" }
}

# Example read replica
variable "create_read_replica" { type = bool default = false }

resource "aws_db_instance" "replica" {
  count = var.create_read_replica ? 1 : 0
  identifier = "${var.db_identifier}-replica"
  replicate_source_db = aws_db_instance.primary.id
  instance_class = var.instance_class
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids = var.vpc_security_group_ids
}

output "primary_endpoint" { value = aws_db_instance.primary.endpoint }
output "primary_address" { value = aws_db_instance.primary.address }
output "replica_endpoint" { value = try(aws_db_instance.replica[0].endpoint, "") }

