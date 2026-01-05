terraform {
  required_version = ">= 1.3.0"
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = ">= 1.215.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.11.0"
    }
  }
}

variable "region" {
  description = "Aliyun region, e.g., cn-hongkong"
  type        = string
  default     = null
}

variable "instance_name" {
  description = "Name for the ECS instance"
  type        = string
  default     = "invoice-runner"
}

variable "instance_type" {
  description = "ECS instance type"
  type        = string
  default     = "ecs.c9i.large"
}

variable "image_id" {
  description = "Optional image ID. If unset, latest Ubuntu 22.04 x86_64 system image is selected."
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR for VPC"
  type        = string
  default     = "10.66.0.0/16"
}

variable "vswitch_cidr" {
  description = "CIDR for vSwitch"
  type        = string
  default     = "10.66.1.0/24"
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to access SSH (22). Strongly recommend setting to your IP range."
  type        = string
}

variable "ssh_public_key" {
  description = "Your SSH public key to inject into the instance"
  type        = string
}

variable "internet_max_bandwidth_out" {
  description = "Public internet bandwidth in Mbps to assign a public IP (0 disables public IP)."
  type        = number
  default     = 10
}

variable "system_disk_category" {
  description = "System disk category. For c9i in many regions, use cloud_essd."
  type        = string
  default     = "cloud_essd"
}

variable "system_disk_performance_level" {
  description = "ESSD performance level (PL0, PL1, PL2, PL3). Used when category is cloud_essd."
  type        = string
  default     = "PL1"
}

variable "system_disk_size" {
  description = "System disk size in GB"
  type        = number
  default     = 80
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {
    Project = "invoice-processing"
    Env     = "dev"
  }
}

variable "budget_usd" {
  description = "Approximate budget cap in USD. Used to compute auto-release time."
  type        = number
  default     = 100
}

variable "estimated_hourly_cost_usd" {
  description = "Estimated hourly cost for the selected instance in your region (conservative)."
  type        = number
  default     = 0.20
}

variable "auto_release_hours" {
  description = "Upper bound for auto-release hours. The effective hours will be min(this, floor(budget/estimate))."
  type        = number
  default     = 72
}
