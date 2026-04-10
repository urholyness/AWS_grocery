variable "aws_region" {
  description = "The AWS region to deploy the resources in."
  type        = string
  default     = "eu-north-1"
}

variable "project_name" {
  description = "The name of the project."
  type        = string
  default     = "terraform-grocerymate"
}

variable "db_username" {
  description = "The username for the RDS database."
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "The password for the RDS database."
  type        = string
  sensitive   = true
}

variable "aws_profile" {
  description = "The AWS CLI profile to use."
  type        = string
  default     = "AdministratorAccess-941781854407"
}

variable "alert_email" {
  description = "Email address to receive CloudWatch alarm notifications."
  type        = string
}
