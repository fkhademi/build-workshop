#Aviatrix controller vars
variable "aviatrix_admin_account" {
  description = "Aviatrix admin user"
  default     = "admin"
}
variable "aviatrix_admin_password" {
  description = "Aviatrix admin password"
}
variable "aviatrix_controller_ip" {
  description = "Aviatrix Controller IP/Hostname"
}
variable "aws_account_name" {
  description = "AWS Account name defined in AVX Controller"
  default     = "aws"
}

variable "azure_account_name" {
  description = "Azure Account name defined in AVX Controller"
  default     = "azure-sub-1"
}

# Azure stuff

variable "azure_subscription_id" {}
variable "azure_directory_id" {}
variable "azure_application_id" {}
variable "azure_application_key" {}


# AWS account for deploying EC2 Instance
variable "aws_access_key" {
  description = "AWS Access Key"
}
variable "aws_secret_key" {
  description = "AWS Secret Key"
}

# CNE details
variable "num_pods" {
  description = "Number of Pods deployed"
  default     = 2
}

variable "offset" {
  description = "Pod number to start on"
  default     = 2
}

variable "domain_name" {
  description = "Public Route53 Domain to update"
  default     = "avxlab.de"
}

variable "hub_cidr" {
  description = "CIDR range for central hub"
  default     = "172.16.0.0/16"
}

variable "hub_region" {
  description = "Region to deploy resources"
  default     = "eu-central-1"
}

variable "aws_region" {
  default = "eu-central-1"
}

variable "ssh_key" {
  description = "SSH public key for test Ubuntu VM"
}

variable "client_password" {
  description = "Password for the RDP client"
}

