# Module deploy Transit
/* module "transit_hub" {
  source    = "terraform-aviatrix-modules/aws-transit/aviatrix"
  version   = "3.0.2"
  cidr      = "172.16.0.0/16"
  region    = var.hub_region
  account   = var.aws_account_name
  bgp_manual_spoke_advertise_cidrs = "0.0.0.0/0,172.16.0.0/12,192.168.0.0/16,10.230.0.0/16,10.240.0.0/24"
  enable_advertise_transit_cidr = true
  ha_gw                            = false
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

data "template_file" "db" {
  template = file("${path.module}/cloud-init/user-data-db.tpl")

  vars = {
    pod_id   = "pod${var.pod_id}"
    password = "${var.password}"
  }
}

resource "aws_security_group" "db" {
  name   = "db-sg"
  vpc_id = module.spoke_aws_1.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 22
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 3306
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "key" {
  key_name   = "${var.pod_id}-db"
  public_key = var.ssh_key
}

resource "aws_instance" "db" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t2.medium"
  key_name        = aws_key_pair.key.key_name
  subnet_id       = module.spoke_aws_1.vpc.subnets[0].subnet_id
  security_groups = [aws_security_group.db.id]
  user_data       = data.template_file.db.rendered
  tags = {
    Name = "db-pod${var.pod_id}-srv"
  }
  depends_on = [
    aviatrix_fqdn.egress, module.spoke_aws_1
  ]
}

resource "aws_route53_record" "db" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "db.${data.aws_route53_zone.main.name}"
  type    = "A"
  ttl     = "1"
  records = [aws_instance.db.private_ip]
}
####

# Module deploy AWS EC2
module "aws_srv1" {
  count = var.num_pods
  source = "git::https://github.com/fkhademi/terraform-aws-instance-module.git"

  name      = "cne-hub-client"
  region    = var.hub_region
  vpc_id    = module.transit_hub.vpc.vpc_id
  subnet_id = module.transit_hub.vpc.subnets[0].subnet_id
  ssh_key   = var.ssh_key
  public_ip = true
}

resource "aws_route53_record" "trans_gw" {
  provider = aws.dns
  zone_id  = data.aws_route53_zone.domain_name.zone_id
  name     = "onprem-gw.${data.aws_route53_zone.domain_name.name}"
  type     = "A"
  ttl      = "1"
  records  = [module.transit_hub.transit_gateway.eip]
}
 */