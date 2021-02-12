data "aws_route53_zone" "main" {
  name         = "pod${var.pod_id}.${var.dns_zone}"
  private_zone = false
}

data "azurerm_subnet" "client" {
  name                 = module.client_vnet.vnet.subnets[0].name
  virtual_network_name = module.client_vnet.vnet.name
  resource_group_name  = split(":", module.client_vnet.vnet.vpc_id)[1]
}
data "azurerm_subnet" "app" {
  name                 = module.app_vnet.vnet.subnets[0].name
  virtual_network_name = module.app_vnet.vnet.name
  resource_group_name  = split(":", module.app_vnet.vnet.vpc_id)[1]
}

module "azure_client" {
  source = "git::https://github.com/fkhademi/terraform-azure-instance-build-module.git"

  name            = "client-pod${var.pod_id}"
  region          = var.azure_region
  rg              = split(":", module.client_vnet.vnet.vpc_id)[1]
  vnet            = module.client_vnet.vnet.name
  subnet          = data.azurerm_subnet.client.id
  ssh_key         = var.ssh_key
  cloud_init_data = data.template_cloudinit_config.config.rendered
  public_ip       = true
}

data "template_file" "cloudconfig" {
  template = file("${path.module}/cloud-init/cloud-init-client.tpl")
  vars = {
    username   = "pod${var.pod_id}"
    password   = "${var.password}"
    hostname   = "client.pod${var.pod_id}.${var.dns_zone}"
    domainname = var.dns_zone
    pod_id     = "pod${var.pod_id}"
  }
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = "${data.template_file.cloudconfig.rendered}"
  }
}

resource "aws_route53_record" "client" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "client.${data.aws_route53_zone.main.name}"
  type    = "A"
  ttl     = "1"
  records = [module.azure_client.public_ip.ip_address]
}

module "web" {
  source = "git::https://github.com/fkhademi/terraform-azure-instance-build-module.git"

  name            = "web-pod${var.pod_id}"
  region          = var.azure_region
  rg              = split(":", module.client_vnet.vnet.vpc_id)[1]
  vnet            = module.client_vnet.vnet.name
  subnet          = data.azurerm_subnet.client.id
  ssh_key         = var.ssh_key
  cloud_init_data = data.template_cloudinit_config.webapp.rendered
  public_ip       = false
}
data "template_file" "webapp" {
  template = file("${path.module}/cloud-init/cloud-init-webapp.tpl")
  vars = {
    domainname = var.dns_zone
    hostname   = "client.pod${var.pod_id}.${var.dns_zone}"
    pod_id     = "pod${var.pod_id}"
    type       = "web"
    accesskey  = "na"
    secretkey  = "na"
    db_ip      = aws_instance.db.private_ip
  }
}
data "template_cloudinit_config" "webapp" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = "${data.template_file.webapp.rendered}"
  }
}
resource "aws_route53_record" "web" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "web.${data.aws_route53_zone.main.name}"
  type    = "A"
  ttl     = "1"
  records = [module.web.nic.private_ip_address]
}
module "app" {
  source = "git::https://github.com/fkhademi/terraform-azure-instance-build-module.git"

  name            = "app-pod${var.pod_id}"
  region          = var.azure_region
  rg              = split(":", module.app_vnet.vnet.vpc_id)[1]
  vnet            = module.app_vnet.vnet.name
  subnet          = data.azurerm_subnet.app.id
  ssh_key         = var.ssh_key
  cloud_init_data = data.template_cloudinit_config.app.rendered
  public_ip       = false
}
data "template_file" "app" {
  template = file("${path.module}/cloud-init/cloud-init-webapp.tpl")
  vars = {
    domainname = var.dns_zone
    hostname   = "client.pod${var.pod_id}.${var.dns_zone}"
    pod_id     = "pod${var.pod_id}"
    type       = "app"
    accesskey  = var.s3_dd_aws_access_key
    secretkey  = var.s3_dd_aws_secret_key
    db_ip      = aws_instance.db.private_ip
  }
}
data "template_cloudinit_config" "app" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = "${data.template_file.app.rendered}"
  }
}
resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "app.${data.aws_route53_zone.main.name}"
  type    = "A"
  ttl     = "1"
  records = [module.app.nic.private_ip_address]
}
# AWS Client
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
    pod_id     = "pod${var.pod_id}"
    password   = "${var.password}"
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
}
resource "aws_route53_record" "db" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "db.${data.aws_route53_zone.main.name}"
  type    = "A"
  ttl     = "1"
  records = [aws_instance.db.private_ip]
}