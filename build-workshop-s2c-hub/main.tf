# Pseudo DC

module "build_hub" {
  source  = "terraform-aviatrix-modules/azure-transit/aviatrix"
  version = "3.0.1"

  name                             = "build-hub"
  cidr                             = var.hub_cidr
  region                           = var.hub_region
  account                          = var.azure_account_name
  instance_size                    = "Standard_B2s"
  ha_gw                            = false
  prefix                           = false
  suffix                           = false
  enable_advertise_transit_cidr    = true
  bgp_manual_spoke_advertise_cidrs = "172.16.0.0/12,192.168.0.0/16,10.230.0.0/16,10.240.0.0/24"
}

resource "aws_route53_record" "onprem-gw" {
  zone_id = data.aws_route53_zone.domain_name.zone_id
  name    = "onprem-gw.${data.aws_route53_zone.domain_name.name}"
  type    = "A"
  ttl     = "1"
  records = [module.build_hub.transit_gateway.eip]
}

data "azurerm_subnet" "client" {
  name                 = module.build_hub.vnet.subnets[0].name
  virtual_network_name = module.build_hub.vnet.name
  resource_group_name  = split(":", module.build_hub.vnet.vpc_id)[1]
}

#Transit workflow step 3
resource "aviatrix_transit_external_device_conn" "s2c" {
  count = var.num_pods

  vpc_id             = module.build_hub.vnet.vpc_id
  connection_name    = "pod${count.index + var.offset}"
  gw_name            = module.build_hub.transit_gateway.gw_name
  connection_type    = "bgp"
  bgp_local_as_num   = "65000"
  bgp_remote_as_num  = "650${format("%02d", count.index + var.offset)}"
  remote_gateway_ip  = data.dns_a_record_set.fqdn[count.index].addrs[0]
  pre_shared_key     = "mapleleafs"
  local_tunnel_cidr  = "169.254.${count.index + var.offset}.1/30"
  remote_tunnel_cidr = "169.254.${count.index + var.offset}.2/30"
}

module "azure_client" {
  count = var.num_pods

  source          = "git::https://github.com/fkhademi/terraform-azure-instance-build-module.git"
  name            = "client-pod${count.index + var.offset}"
  region          = var.hub_region
  rg              = split(":", module.build_hub.vnet.vpc_id)[1]
  vnet            = module.build_hub.vnet.name
  subnet          = data.azurerm_subnet.client.id
  ssh_key         = var.ssh_key
  cloud_init_data = data.template_cloudinit_config.config[count.index].rendered
  public_ip       = true
}

data "template_file" "cloudconfig" {
  count = var.num_pods

  template = file("${path.module}/cloud-init-client.tpl")
  vars = {
    username   = "pod${count.index + var.offset}"
    password   = var.client_password
    hostname   = "client.pod${count.index + var.offset}.${var.domain_name}"
    domainname = var.domain_name
    pod_id     = "pod${count.index + var.offset}"
  }
}

data "template_cloudinit_config" "config" {
  count         = var.num_pods
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.cloudconfig[count.index].rendered
  }
}

resource "aws_route53_record" "client" {
  count = var.num_pods

  zone_id = data.aws_route53_zone.pod_zone[count.index].zone_id
  name    = "client.${data.aws_route53_zone.pod_zone[count.index].name}"
  type    = "A"
  ttl     = "1"
  records = [module.azure_client[count.index].public_ip.ip_address]
}

resource "aws_route53_record" "client-priv" {
  count = var.num_pods

  zone_id = data.aws_route53_zone.pod_zone[count.index].zone_id
  name    = "client-int.${data.aws_route53_zone.pod_zone[count.index].name}"
  type    = "A"
  ttl     = "1"
  records = [module.azure_client[count.index].nic.private_ip_address]
}