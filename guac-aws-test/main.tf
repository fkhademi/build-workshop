# Transit Hub site for BUILD
module "build_hub" {
  source  = "terraform-aviatrix-modules/aws-transit/aviatrix"
  version = "3.0.1"

  name                             = "build-hub"
  cidr                             = var.hub_cidr
  region                           = var.hub_region
  account                          = var.aws_account_name
  instance_size                    = "t3.medium"
  ha_gw                            = false
  prefix                           = false
  suffix                           = false
  enable_advertise_transit_cidr    = true
  bgp_manual_spoke_advertise_cidrs = "172.16.0.0/12,192.168.0.0/16,10.230.0.0/16,10.240.0.0/24"
}

# Route53 entry for the fake Data Center GW
resource "aws_route53_record" "onprem-gw" {
  zone_id = data.aws_route53_zone.domain_name.zone_id
  name    = "onprem-gw.${data.aws_route53_zone.domain_name.name}"
  type    = "A"
  ttl     = "1"
  records = [module.build_hub.transit_gateway.eip]
}

#Create a S2C for each POD
resource "aviatrix_transit_external_device_conn" "s2c" {
  count = var.num_pods

  vpc_id             = module.build_hub.vpc.vpc_id
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

# Create a Guacamole client for each pod
module "aws_client" {
  count = var.num_pods

  source    = "git::https://github.com/fkhademi/terraform-aws-instance-module.git?ref=v1.3"
  name      = "client-pod${count.index + var.offset}"
  region    = var.hub_region
  vpc_id    = module.build_hub.vpc.vpc_id
  subnet_id = module.build_hub.vpc.public_subnets[0].subnet_id
  ssh_key   = var.ssh_key
  user_data = data.template_file.cloudconfig[count.index].rendered
  public_ip = true
  instance_size = "t3.small"
}

# User-Data for Guacamole
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

# Public DNS record for each Guacamole client
resource "aws_route53_record" "client" {
  count = var.num_pods

  zone_id = data.aws_route53_zone.pod_zone[count.index].zone_id
  name    = "client.${data.aws_route53_zone.pod_zone[count.index].name}"
  type    = "A"
  ttl     = "1"
  records = [module.aws_client[count.index].vm.public_ip]
}

# Internal DNS record for each client
resource "aws_route53_record" "client-priv" {
  count = var.num_pods

  zone_id = data.aws_route53_zone.pod_zone[count.index].zone_id
  name    = "client-int.${data.aws_route53_zone.pod_zone[count.index].name}"
  type    = "A"
  ttl     = "1"
  records = [module.aws_client[count.index].vm.private_ip]
}
