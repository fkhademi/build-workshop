# DNS ZONES
data "aws_route53_zone" "parent_zone" {
  name         = var.dns_zone
  private_zone = false
}

data "aws_route53_zone" "main" {
  name         = "pod${var.pod_id}.${var.dns_zone}"
  private_zone = false
}

# VNET SUBNETS
data "azurerm_subnet" "web" {
  name                 = module.web_vnet.vnet.subnets[0].name
  virtual_network_name = module.web_vnet.vnet.name
  resource_group_name  = split(":", module.web_vnet.vnet.vpc_id)[1]
}

data "azurerm_subnet" "app" {
  name                 = module.app_vnet.vnet.subnets[0].name
  virtual_network_name = module.app_vnet.vnet.name
  resource_group_name  = split(":", module.app_vnet.vnet.vpc_id)[1]
}

# CLOUD INIT FOR WEB APP SERVERS
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
    content      = data.template_file.webapp.rendered
  }
}

##
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
    content      = data.template_file.app.rendered
  }
}

## USER DATA FOR DB
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["avxbuild-db-ami"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["594826232704"] # Frey
}

data "template_file" "db" {
  template = file("${path.module}/cloud-init/user-data-db.tpl")

  vars = {
    pod_id   = "pod${var.pod_id}"
    password = var.password
  }
}