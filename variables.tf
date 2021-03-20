#######################################
# VPC
#######################################

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  type    = string
  default = "10.0.0.0/24"
}

variable "availability_zone" {
  type    = string
  default = "eu-central-1a"
}

variable "vpc_subnet" {
  type    = string
  default = "10.0.0.0/24"
}

#######################################
# EC2
#######################################

variable "instance_type" {
  type = string
}

variable "key_name" {
  type    = string
  default = null
}

#######################################
# Scheduled startup/shutdown
#######################################

variable "enable_scheduled_shutdown" {
  type    = bool
  default = false
}

variable "shutdown_schedule_expression" {
  type    = string
  default = null
}

variable "enable_scheduled_startup" {
  type    = bool
  default = false
}

variable "startup_schedule_expression" {
  type    = string
  default = null
}

#######################################
# ECS
#######################################

variable "task_cpu" {
  type = number
}

variable "task_memory" {
  type = number
}

variable "container_image_tag" {
  type    = string
  default = "latest"
}

#######################################
# Server variables
#######################################

variable "server_name" {
  type = string
}

variable "server_world" {
  type = string
}

variable "server_password" {
  type = string
}

variable "server_public" {
  type    = number
  default = 1
}

variable "server_tz" {
  type    = string
  default = "Europe/Berlin"
}

variable "server_webhook_url" {
  type    = string
  default = null
}

variable "server_auto_update" {
  type    = number
  default = null
}

variable "server_auto_update_schedule" {
  type    = string
  default = null
}

variable "server_auto_backup" {
  type    = number
  default = null
}

variable "server_auto_backup_schedule" {
  type    = string
  default = null
}

variable "server_auto_backup_remove_old" {
  type    = number
  default = null
}

variable "server_auto_backup_days_to_live" {
  type    = number
  default = null
}

variable "server_auto_backup_on_update" {
  type    = number
  default = null
}

variable "server_auto_backup_on_shutdown" {
  type    = number
  default = null
}

variable "server_update_on_startup" {
  type    = number
  default = null
}