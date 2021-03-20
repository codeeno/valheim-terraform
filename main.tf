locals {
  ecs_cluster_name = "Valheim"
}

#######################################
# VPC
#######################################

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name           = "Valheim-VPC"
  cidr           = var.vpc_cidr
  azs            = [var.availability_zone]
  public_subnets = [var.subnet_cidr]

  enable_dns_hostnames = true
  enable_nat_gateway   = false
}

#######################################
# EFS
#######################################

resource "aws_efs_file_system" "valheim" {
  creation_token   = "valheim"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "true"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_efs_mount_target" "valheim" {
  file_system_id  = aws_efs_file_system.valheim.id
  subnet_id       = module.vpc.public_subnets[0]
  security_groups = [aws_security_group.efs.id]
}

resource "aws_security_group" "efs" {
  name   = "EFS"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "EFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#######################################
# EC2
#######################################


data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

resource "aws_instance" "valheim_server" {
  ami                    = data.aws_ssm_parameter.ecs_ami.value
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.valheim_server.id]
  iam_instance_profile   = aws_iam_instance_profile.ecs.name

  user_data = <<EOF
  #!/bin/bash
  echo "ECS_CLUSTER=${local.ecs_cluster_name}" >> /etc/ecs/ecs.config
  EOF

  tags = {
    Name   = "Valheim Server"
    tostop = var.enable_scheduled_shutdown || var.enable_scheduled_startup ? "true" : "false"
  }
}

resource "aws_eip" "ip" {
  instance = aws_instance.valheim_server.id
  vpc      = true
}

resource "aws_security_group" "valheim_server" {
  name        = "Valheim Server"
  description = "Allow SSH & Valheim server traffic"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Valheim"
    from_port   = 2456
    to_port     = 2458
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#######################################
# IAM Role for ECS Instances
#######################################

resource "aws_iam_instance_profile" "ecs" {
  name = "ecsInstanceRoleProfile"
  role = aws_iam_role.ecs_instance_role.name
}

resource "aws_iam_role" "ecs_instance_role" {
  name               = "ecsInstanceRole"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

#######################################
# Scheduled startup/shutdown
#######################################

module "stop_ec2_instance" {
  count                          = var.enable_scheduled_shutdown ? 1 : 0
  source                         = "diodonfrost/lambda-scheduler-stop-start/aws"
  name                           = "ec2_stop"
  cloudwatch_schedule_expression = "cron(${var.shutdown_schedule_expression})"
  schedule_action                = "stop"
  ec2_schedule                   = "true"
  scheduler_tag = {
    key   = "tostop"
    value = "true"
  }
}

module "start_ec2_instance" {
  count                          = var.enable_scheduled_startup ? 1 : 0
  source                         = "diodonfrost/lambda-scheduler-stop-start/aws"
  name                           = "ec2_start"
  cloudwatch_schedule_expression = "cron(${var.startup_schedule_expression})"
  schedule_action                = "start"
  ec2_schedule                   = "true"
  scheduler_tag = {
    key   = "tostop"
    value = "true"
  }
}

#######################################
# ECS
#######################################

resource "aws_ecs_cluster" "valheim_cluster" {
  name = local.ecs_cluster_name
}

resource "aws_ecs_service" "valheim_service" {
  name            = "valheim"
  cluster         = aws_ecs_cluster.valheim_cluster.id
  task_definition = aws_ecs_task_definition.valheim_task.arn
  desired_count   = 1
}

module "valheim_container_definitions" {
  source           = "cloudposse/ecs-container-definition/aws"
  version          = "0.53.0"
  container_name   = "valheim_server"
  container_image  = "mbround18/valheim:${var.container_image_tag}"
  essential        = true
  container_cpu    = var.task_cpu
  container_memory = var.task_memory

  map_environment = {
    NAME : var.server_name
    WORLD : var.server_world
    PASSWORD : var.server_password
    PUBLIC : var.server_public
    TZ : var.server_tz
    WEBHOOK_URL : var.server_webhook_url
    AUTO_UPDATE : var.server_auto_update
    AUTO_UPDATE_SCHEDULE : var.server_auto_update_schedule
    AUTO_BACKUP : var.server_auto_backup
    AUTO_BACKUP_SCHEDULE : var.server_auto_backup_schedule
    AUTO_BACKUP_REMOVE_OLD : var.server_auto_backup_remove_old
    AUTO_BACKUP_DAYS_TO_LIVE : var.server_auto_backup_days_to_live
    AUTO_BACKUP_ON_UPDATE : var.server_auto_backup_on_update
    UPDATE_ON_STARTUP : var.server_update_on_startup
    AUTO_BACKUP_ON_SHUTDOWN : var.server_auto_backup_on_shutdown
  }

  port_mappings = [
    {
      containerPort = 2456
      hostPort      = 2456
      protocol      = "udp"
    },
    {
      containerPort = 2457
      hostPort      = 2457
      protocol      = "udp"
    },
    {
      containerPort = 2458
      hostPort      = 2458
      protocol      = "udp"
    }
  ]

  mount_points = [
    {
      sourceVolume : "saves",
      containerPath : "/home/steam/.config/unity3d/IronGate/Valheim"
    },
    {
      sourceVolume : "server"
      containerPath : "/home/steam/valheim"
    },
    {
      sourceVolume : "backups"
      containerPath : "/home/steam/backups"
    }
  ]
}

resource "aws_ecs_task_definition" "valheim_task" {
  family                = "valheim_server"
  container_definitions = "[${module.valheim_container_definitions.json_map_encoded}]"

  volume {
    name = "saves"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.valheim.id
      root_directory = "/saves"
    }
  }

  volume {
    name = "server"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.valheim.id
      root_directory = "/server"
    }
  }

  volume {
    name = "backups"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.valheim.id
      root_directory = "/backups"
    }
  }
}
