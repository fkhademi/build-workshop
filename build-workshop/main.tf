# Controller accounts
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

# AZURE TRANSIT
module "transit_azure" {
  source  = "terraform-aviatrix-modules/azure-transit/aviatrix"
  version = "3.0.0"

  name          = "azure-transit"
  cidr          = "10.${var.pod_id}.0.0/20"
  region        = var.azure_region
  account       = aviatrix_account.azure.account_name
  instance_size = "Standard_B2s"
  ha_gw         = false
  prefix        = false
  suffix        = false
}

# CLIENT / WEB VNET
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

# APP VNET
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

#AWS SPOKE
module "spoke_aws_1" {
  source  = "terraform-aviatrix-modules/aws-spoke/aviatrix"
  version = "3.0.0"

  name           = "aws-db-node"
  cidr           = "10.${var.pod_id}.64.0/20"
  region         = var.aws_region
  account        = aviatrix_account.aws.account_name
  instance_size  = "t2.small"
  transit_gw     = ""
  ha_gw          = false
  prefix         = false
  suffix         = false
  attached       = false
  single_ip_snat = true
}

# EGRESS POLICY
resource "aviatrix_fqdn" "egress" {
  fqdn_tag     = "Default-Egress-Policy"
  fqdn_enabled = true
  fqdn_mode    = "white"

  gw_filter_tag_list {
    gw_name        = module.spoke_aws_1.spoke_gateway.gw_name
  }

  domain_names {
    fqdn  = "*.ubuntu.com"
    proto = "tcp"
    port  = "80"
    action = "Allow"
  }

  domain_names {
    fqdn  = "github.com"
    proto = "tcp"
    port  = "443"
    action = "Allow"
  }
}
