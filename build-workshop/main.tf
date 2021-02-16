#Controller accounts
resource "aviatrix_account" "aws" {
  account_name       = var.aws_account_name
  cloud_type         = 1
  aws_iam            = false
  aws_account_number = var.aws_account_number
  aws_access_key     = var.aws_access_key
  aws_secret_key     = var.aws_secret_key
}

resource "aviatrix_account" "azure" {
  account_name        = var.azure_account_name
  cloud_type          = 8
  arm_subscription_id = var.azure_subscription_id
  arm_directory_id    = var.azure_directory_id
  arm_application_id  = var.azure_application_id
  arm_application_key = var.azure_application_key
}

#Azure
module "transit_azure" {
  source  = "terraform-aviatrix-modules/azure-transit/aviatrix"
  version = "3.0.0"

  name            = "azure-transit"
  cidr            = "10.${var.pod_id}.0.0/20"
  region          = var.azure_region
  account         = aviatrix_account.azure.account_name
  instance_size   = "Standard_B2s"
  ha_gw           = false
  prefix          = false
  suffix          = false
}

module "client_vnet" {
  source  = "terraform-aviatrix-modules/azure-spoke/aviatrix"
  version = "3.0.0"

  name          = "azure-client-node"
  cidr          = "10.${var.pod_id}.16.0/20"
  region        = var.azure_region
  account       = aviatrix_account.azure.account_name
  transit_gw    = ""
  instance_size = "Standard_B2s"
  ha_gw         = false
  prefix        = false
  suffix        = false
  attached      = false
}

module "app_vnet" {
  source  = "terraform-aviatrix-modules/azure-spoke/aviatrix"
  version = "3.0.0"

  name          = "azure-app-node"
  cidr          = "10.${var.pod_id}.32.0/20"
  region        = var.azure_region
  account       = aviatrix_account.azure.account_name
  transit_gw    = ""
  instance_size = "Standard_B2s"
  ha_gw         = false
  prefix        = false
  suffix        = false
  attached      = false
}

#AWS
/* resource "aviatrix_vpc" "transit_aws" {
  cloud_type           = 1
  account_name         = aviatrix_account.aws.account_name
  region               = var.aws_region
  name                 = "aws-transit"
  cidr                 = "10.${var.pod_id}.48.0/20"
  aviatrix_transit_vpc = true
  aviatrix_firenet_vpc = false
}
 */
module "spoke_aws_1" {
  source  = "terraform-aviatrix-modules/aws-spoke/aviatrix"
  version = "3.0.0"

  name          = "aws-db-node"
  cidr          = "10.${var.pod_id}.64.0/20"
  region        = var.aws_region
  account       = aviatrix_account.aws.account_name
  instance_size = "t2.small"
  transit_gw    = ""
  ha_gw         = false
  prefix        = false
  suffix        = false
  attached      = false
}