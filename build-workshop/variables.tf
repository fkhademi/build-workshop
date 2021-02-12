#Aviatrix controller vars
variable "aviatrix_admin_account" { default = "admin" }
variable "aviatrix_admin_password" { default = "Password123" }
variable "aviatrix_controller_ip" { }

#Regions
variable "aws_region" { default = "eu-central-1" }
variable "azure_region" { default = "Germany West Central" }

#Contoller access accounts
variable "aws_account_name" { default = "AWS" }
variable "azure_account_name" { default = "Azure" }

#CSP Accounts
variable "aws_account_number" {
  type    = string
}
variable "aws_access_key" {
  type    = string
}
variable "aws_secret_key" {
  type    = string
}

variable "azure_subscription_id" { }
variable "azure_directory_id" { }
variable "azure_application_id" { }
variable "azure_application_key" { }

# Client Details
variable "ssh_key" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCnNDeCuEOgJjtFFzWa9fXyKj8mSdCnCVR+iOm40JYSO4/kKEOflq0VvtIcnezv1wa4Ghj3RqEcFd9857qAQfqsn5KgjwuoYG37eTthz9waKSbem6l8hilR4CncagBqMqje8EDuWFdyNPWmgM04nHJ+HRn0UoXzYikSbbQJ082XORREEpZA4Rt7ZHtIncqN5EMBPQ4lflDOR7l0pCTcGObHNPOuWje35ZQqcjryskUkgvEzx+kFxnJ5fG2cwvDkoq8JrCwXhZNmoYNvR6cAtzMo7S/v7THxCxYMgsSUWRzY1+Pi93EB/CIZp5le0gewblrzXpc8DmHd5NPi3ObPwPTh dennis@NUC"
}
variable "password" {
  default = "Password123"
}
variable "pod_id" {
  default = 50
  type    = string
}

variable "dns_zone" {
  type    = string
  default = "avxlab.cc"
}

#AWS Account used for S3 and DynamoDB
variable "s3_dd_aws_access_key" { }
variable "s3_dd_aws_secret_key" { }

#AWS Account used for route53 DNS
variable "dns_aws_access_key" { }
variable "dns_aws_secret_key" { }
