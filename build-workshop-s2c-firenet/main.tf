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
  version = "4.0.1"

  name          = "azure-transit"
  cidr          = "10.${var.pod_id}.0.0/20"
  region        = var.azure_region
  account       = aviatrix_account.azure.account_name
  instance_size = "Standard_B2s"
  ha_gw         = false
  prefix        = false
  suffix        = false
}

# FQDN for AVX Transit GW in Azure
resource "aws_route53_record" "gw" {
  zone_id = data.aws_route53_zone.parent_zone.zone_id
  name    = "pod${var.pod_id}-tgw.${data.aws_route53_zone.parent_zone.name}"
  type    = "A"
  ttl     = "1"
  records = [module.transit_azure.transit_gateway.eip]
}

#  WEB VNET
module "web_vnet" {
  source  = "terraform-aviatrix-modules/azure-spoke/aviatrix"
  version = "4.0.1"

  name          = "azure-web-node"
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
  version = "4.0.1"

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

#AWS TRANSIT FIRENET
module "firenet" {
  source  = "terraform-aviatrix-modules/aws-transit/aviatrix"
  version = "4.0.3"

  name                   = "aws-transit"
  cidr                   = "10.${var.pod_id}.48.0/23"
  region                 = var.aws_region
  account                = aviatrix_account.aws.account_name
  ha_gw                  = false
  prefix                 = false
  suffix                 = false
  enable_transit_firenet = true
  instance_size          = "c5.xlarge"
}

# Get the Transit GW LAN interface IP
data "aws_network_interface" "trans_gw" {
  filter {
    name   = "tag:Name"
    values = ["Aviatrix-eni@${module.firenet.transit_gateway.gw_name}_eth2"]
  }
  depends_on = [
    module.firenet
  ]
}

# Get the LAN subnet
data "aws_subnet_ids" "subnet" {
  vpc_id = module.firenet.vpc.vpc_id
  filter {
    name   = "tag:Name"
    values = ["*-dmz-firewall"]
  }
  depends_on = [
    module.firenet
  ]
}

# Deploy the Firewall
module "fw" {
  source = "git::https://github.com/fkhademi/terraform-aws-instance-module.git?ref=v1.5-firenet"

  name          = "fw-vm"
  region        = var.aws_region
  vpc_id        = module.firenet.vpc.vpc_id
  subnet_id     = module.firenet.vpc.public_subnets[0].subnet_id
  ssh_key       = var.ssh_key
  public_ip     = true
  instance_size = "t3.large"
  user_data     = data.template_file.cloudconfig.rendered
}

resource "aws_route53_record" "fw" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "fw.${data.aws_route53_zone.main.name}"
  type    = "A"
  ttl     = "1"
  records = [module.fw.vm.public_ip]
}

# Userdata for the firewall
data "template_file" "cloudconfig" {
  template = file("${path.module}/cloud-init/cloud-init-fw.tpl")
  vars = {
    hostname  = "fw.${data.aws_route53_zone.main.name}"
    gw_lan_ip = data.aws_network_interface.trans_gw.private_ip
  }
}

# Additional LAN interface for the FW
resource "aws_network_interface" "lan" {
  subnet_id         = element(tolist(data.aws_subnet_ids.subnet.ids), 0)
  security_groups   = [module.fw.sg.id]
  source_dest_check = false

  attachment {
    instance     = module.fw.vm.id
    device_index = 1
  }
}

# Associate FW with Firenet
resource "aviatrix_firewall_instance_association" "fw" {
  vpc_id               = module.firenet.vpc.vpc_id
  firenet_gw_name      = module.firenet.transit_gateway.gw_name
  instance_id          = module.fw.vm.id
  firewall_name        = "fw"
  lan_interface        = aws_network_interface.lan.id
  management_interface = null
  egress_interface     = module.fw.vm.primary_network_interface_id
  attached             = true
}

# Create Firenet
resource "aviatrix_firenet" "firenet" {
  vpc_id                               = module.firenet.vpc.vpc_id
  inspection_enabled                   = true
  egress_enabled                       = false
  keep_alive_via_lan_interface_enabled = true
  manage_firewall_instance_association = false
  depends_on                           = [aviatrix_firewall_instance_association.fw]
}


#AWS SPOKE
module "spoke_aws_1" {
  source  = "terraform-aviatrix-modules/aws-spoke/aviatrix"
  version = "4.0.3"

  name           = "aws-db-node"
  cidr           = "10.${var.pod_id}.64.0/20"
  region         = var.aws_region
  account        = aviatrix_account.aws.account_name
  instance_size  = "t3.micro"
  transit_gw     = ""
  ha_gw          = false
  prefix         = false
  suffix         = false
  attached       = false
  #single_ip_snat = true
}

# EGRESS POLICY
/* resource "aviatrix_fqdn" "egress" {
  fqdn_tag     = "Default-Egress-Policy"
  fqdn_enabled = true
  fqdn_mode    = "white"

  gw_filter_tag_list {
    gw_name = module.spoke_aws_1.spoke_gateway.gw_name
  }
}

resource "aviatrix_fqdn_tag_rule" "ubuntu" {
  fqdn_tag_name = aviatrix_fqdn.egress.fqdn_tag
  fqdn          = "*.ubuntu.com"
  protocol      = "tcp"
  port          = "80"
  action        = "Allow"
}

resource "aviatrix_fqdn_tag_rule" "github" {
  fqdn_tag_name = aviatrix_fqdn.egress.fqdn_tag
  fqdn          = "github.com"
  protocol      = "tcp"
  port          = "443"
  action        = "Allow"
}
 */