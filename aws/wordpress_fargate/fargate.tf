# Ref - https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
resource "aws_iam_role" "task_execution_role" {
  name = "${var.prefix}-task-execution-role-${var.environment}"
  tags = merge(var.tags, {
    yor_trace = "4f18c9b6-1b1e-4496-abae-7f1faf1aa632"
  })

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ecs-tasks.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "task_execution_policy" {
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "ssm:GetParameters",
        "kms:Decrypt"
      ],
      "Resource": "*"
    }
  ]
  }
EOF
  tags = {
    yor_trace = "e7862122-c1a9-418d-810c-bfec3db4a244"
  }
}

resource "aws_iam_role_policy_attachment" "task_execution_policy_attach" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.task_execution_policy.arn
}


resource "aws_iam_role" "task_role" {
  name = "${var.prefix}-task-role-${var.environment}"
  tags = merge(var.tags, {
    yor_trace = "c374902e-333b-4581-882b-c4b5984f3d63"
  })

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ecs-tasks.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "task_policy" {
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite"
      ],
      "Resource": "*"
    }
  ]
  }
EOF
  tags = {
    yor_trace = "b6cc665e-1bf1-48db-84c3-4d630c6189a6"
  }
}

resource "aws_iam_role_policy_attachment" "task_policy_attach" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.task_policy.arn
}


resource "aws_ecs_cluster" "this" {
  name = "${var.prefix}-${var.environment}"
  tags = {
    yor_trace = "40e427de-1110-4899-b27b-d48d0efe7d49"
  }
}

resource "aws_security_group" "wordpress" {
  name        = "${var.prefix}-wordpress-${var.environment}"
  description = "Fargate wordpress"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id, aws_security_group.efs.id]
  }

  tags = merge(var.tags, {
    yor_trace = "5c7bcf00-3b2b-47de-b24d-03e929de3e38"
  })
}

resource "aws_ecs_service" "this" {
  name             = "${var.prefix}-${var.environment}"
  cluster          = aws_ecs_cluster.this.id
  task_definition  = aws_ecs_task_definition.this.arn
  desired_count    = var.desired_count
  launch_type      = "FARGATE"
  platform_version = "1.4.0" // required for mounting efs
  network_configuration {
    security_groups = [aws_security_group.alb.id, aws_security_group.db.id, aws_security_group.efs.id]
    subnets         = module.vpc.private_subnets
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.id
    container_name   = "wordpress"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    yor_trace = "363236fe-05c2-4c45-8dc8-84e0cbf2c696"
  }
}


resource "aws_ecs_task_definition" "this" {
  family                   = "${var.prefix}-${var.environment}"
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  container_definitions    = <<CONTAINER_DEFINITION
[
  {
    "secrets": [
      {
        "name": "WORDPRESS_DB_USER", 
        "valueFROM": "${aws_ssm_parameter.db_master_user.arn}"
      },
      {
        "name": "WORDPRESS_DB_PASSWORD", 
        "valueFROM": "${aws_ssm_parameter.db_master_password.arn}"
      }
    ],
    "environment": [
      {
        "name": "WORDPRESS_DB_HOST",
        "value": "${aws_rds_cluster.this.endpoint}"
      },
      {
        "name": "WORDPRESS_DB_NAME",
        "value": "wordpress"
      }
    ],
    "essential": true,
    "image": "wordpress",        
    "name": "wordpress",
    "portMappings": [
      {
        "containerPort": 80
      }
    ],
    "mountPoints": [
      {
        "containerPath": "/var/www/html",
        "sourceVolume": "efs"
      }
    ],
    "logConfiguration": {
      "logDriver":"awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.wordpress.name}",
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-stream-prefix": "app"
      }
    }
  }
]
CONTAINER_DEFINITION

  volume {
    name = "efs"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.this.id
    }
  }
  tags = {
    yor_trace = "861c32cd-48f4-4253-8306-ae70c4199b96"
  }
}

resource "aws_cloudwatch_log_group" "wordpress" {
  name = "/${var.prefix}/${var.environment}/fg-task"
  tags = merge(var.tags, {
    yor_trace = "ac671563-2c72-49b2-a6f8-3eda653aa929"
  })
  retention_in_days = var.log_retention_in_days
}

resource "aws_lb_target_group" "this" {
  name        = "${var.prefix}-${var.environment}"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id
  health_check {
    path    = "/"
    matcher = "200,302"
  }

  tags = {
    yor_trace = "6da4927f-e2fc-4584-996a-0f1a13973046"
  }
}

resource "aws_lb_listener_rule" "wordpress" {
  listener_arn = module.alb.https_listener_arns[0]
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  condition {
    host_header {
      values = [var.site_domain, var.public_alb_domain]
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_high" {
  alarm_name          = "${var.prefix}-high-CPU-utilization-ecs-${var.environment}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.task_cpu_high_threshold

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.this.name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_up.arn]
  tags = {
    yor_trace = "8578b15e-5c1d-4270-8133-63b138dda1a1"
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_low" {
  alarm_name          = "${var.prefix}-low-CPU-utilization-ecs-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.task_cpu_low_threshold

  dimensions = {
    ClusterName = aws_ecs_cluster.this.name
    ServiceName = aws_ecs_service.this.name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_down.arn]
  tags = {
    yor_trace = "9d2cadbb-f74f-4d65-a202-b6b5e7d9c196"
  }
}


resource "aws_appautoscaling_target" "this" {
  max_capacity       = var.max_task
  min_capacity       = var.min_task
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "scale_up" {
  name               = "${var.prefix}-ecs-scale-up-${var.environment}"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  service_namespace  = aws_appautoscaling_target.this.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.scaling_up_cooldown
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = var.scaling_up_adjustment
    }
  }
}

resource "aws_appautoscaling_policy" "scale_down" {
  name               = "${var.prefix}-ecs-scale-down-${var.environment}"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  service_namespace  = aws_appautoscaling_target.this.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.scaling_down_cooldown
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = var.scaling_down_adjustment
    }
  }
}

resource "aws_route53_record" "wordpress" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.public_alb_domain
  type    = "A"

  alias {
    name                   = module.alb.this_lb_dns_name
    zone_id                = module.alb.this_lb_zone_id
    evaluate_target_health = true
  }
}
