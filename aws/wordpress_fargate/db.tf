resource "random_string" "snapshot_suffix" {
  length  = 8
  special = false
}

resource "aws_rds_cluster" "this" {
  cluster_identifier      = "${var.prefix}-${var.environment}"
  engine                  = "aurora"
  engine_mode             = "serverless"
  vpc_security_group_ids  = [aws_security_group.db.id]
  db_subnet_group_name    = aws_db_subnet_group.this.name
  engine_version          = var.db_engine_version
  availability_zones      = data.aws_availability_zones.this.names
  database_name           = "wordpress"
  master_username         = var.db_master_username
  master_password         = var.db_master_password
  backup_retention_period = var.db_backup_retention_days
  preferred_backup_window = var.db_backup_window
  scaling_configuration {
    auto_pause               = var.db_auto_pause
    seconds_until_auto_pause = var.db_seconds_until_auto_pause
    max_capacity             = var.db_max_capacity
    min_capacity             = var.db_min_capacity
  }
  final_snapshot_identifier = "${var.prefix}-${var.environment}-${random_string.snapshot_suffix.result}"
  tags = merge(var.tags, {
    yor_trace = "9124922b-6951-47f4-92e2-5251fbdead8d"
  })
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.prefix}-${var.environment}"
  subnet_ids = module.vpc.private_subnets
  tags = merge(var.tags, {
    yor_trace = "7a36a644-be98-4bfe-ab53-bf59ff5c8fe4"
  })
}

resource "aws_security_group" "db" {
  vpc_id = module.vpc.vpc_id
  name   = "${var.prefix}-db-${var.environment}"
  ingress {
    protocol  = "tcp"
    from_port = 3306
    to_port   = 3306
    self      = true
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
  tags = merge(var.tags, {
    yor_trace = "1f707fb5-dc10-49b3-9881-0eb8d7ba1003"
  })
}

resource "aws_ssm_parameter" "db_master_user" {
  name  = "/${var.prefix}/${var.environment}/db_master_user"
  type  = "SecureString"
  value = var.db_master_username
  tags = merge(var.tags, {
    yor_trace = "1e060394-780f-4dfa-8cb1-b2f4df04c55c"
  })
}

resource "aws_ssm_parameter" "db_master_password" {
  name  = "/${var.prefix}/${var.environment}/db_master_password"
  type  = "SecureString"
  value = var.db_master_password
  tags = merge(var.tags, {
    yor_trace = "77d80e7c-fa8d-49b4-b888-e64bf05081a5"
  })
}
