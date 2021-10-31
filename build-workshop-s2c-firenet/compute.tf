module "web" {
  source = "git::https://github.com/fkhademi/terraform-azure-instance-build-module.git"

  name            = "web-pod${var.pod_id}"
  region          = var.azure_region
  rg              = split(":", module.web_vnet.vnet.vpc_id)[1]
  vnet            = module.web_vnet.vnet.name
  subnet          = data.azurerm_subnet.web.id
  ssh_key         = var.ssh_key
  cloud_init_data = data.template_cloudinit_config.webapp.rendered
  public_ip       = false
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

resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "app.${data.aws_route53_zone.main.name}"
  type    = "A"
  ttl     = "1"
  records = [module.app.nic.private_ip_address]
}

# AWS Client
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
  instance_type   = "t3.small"
  key_name        = aws_key_pair.key.key_name
  subnet_id       = module.spoke_aws_1.vpc.subnets[0].subnet_id
  security_groups = [aws_security_group.db.id]
  user_data       = "" #data.template_file.db.rendered
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