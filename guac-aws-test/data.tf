data "dns_a_record_set" "fqdn" {
  count = var.num_pods

  host = "pod${count.index + var.offset}-tgw.${var.domain_name}"
}

data "aws_route53_zone" "domain_name" {
  name         = var.domain_name
  private_zone = false
}

data "aws_route53_zone" "pod_zone" {
  count = var.num_pods

  name         = "pod${count.index + var.offset}.${var.domain_name}"
  private_zone = false
}