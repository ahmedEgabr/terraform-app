// use this data source to get the hosted zone details for domain. lookup
data "aws_route53_zone" "public" {
  name         = var.dns_hosted_zone
  private_zone = false
}

//  initiate a request to the the Amazon, a service
// certificate manager, to issue us an SSL certificate.
resource "aws_acm_certificate" "myapp" {
  domain_name       = aws_route53_record.domain.fqdn
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

// validation is going to be the process where we validate our certificate.
resource "aws_route53_record" "cert_validation" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.myapp.domain_validation_options)[0].resource_record_name
  records         = [ tolist(aws_acm_certificate.myapp.domain_validation_options)[0].resource_record_value ]
  type            = tolist(aws_acm_certificate.myapp.domain_validation_options)[0].resource_record_type
  zone_id  = data.aws_route53_zone.public.id
  ttl      = 60
}

// we're going to call it cert and this is going to allow the validation to
// take place and then we're going to continue.
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.myapp.arn
  validation_record_fqdns = [ aws_route53_record.cert_validation.fqdn ]
}

// we should get the SSL certificate from the Amazon certificate manager
//  and want to point that to our load balancer.
resource "aws_route53_record" "domain" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = "${var.dns_name}.${data.aws_route53_zone.public.name}"
  type    = "A"
  # we pointing at domain name which now has the SSL certificate to our load to our load balancer with alias
  alias {
    name                   = aws_lb.nomad_lb.dns_name
    zone_id                = aws_lb.nomad_lb.zone_id
    evaluate_target_health = false
  }
}