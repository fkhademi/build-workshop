provider "aviatrix" {
  controller_ip           = var.aviatrix_controller_ip
  username                = var.aviatrix_admin_account
  password                = var.aviatrix_admin_password
  skip_version_validation = false
  version                 = ">=2.15.0"
}

provider "aws" {
  version    = "~> 2.0"
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

provider "aws" {
  alias      = "dns"
  version    = "~> 2.0"
  region     = var.aws_region
  access_key = var.dns_aws_access_key
  secret_key = var.dns_aws_secret_key
}

provider "aws" {
  alias      = "s3-dynamodb"
  version    = "~> 2.0"
  region     = var.aws_region
  access_key = var.s3_dd_aws_access_key
  secret_key = var.s3_dd_aws_secret_key
}

provider "azurerm" {
  version = "~> 2.0.0"
  features {}
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_application_id
  client_secret   = var.azure_application_key
  tenant_id       = var.azure_directory_id
}

provider "null" {}
