output "alb_dns_name" {
  value = aws_lb.nomad_lb.dns_name
  description = "The domain name of the load balancer"
} 

// URL that we've custom created and now should have the SSL certificate.
// get the sub domain, the root domain and the fully qualified domain name going
output "lb_url" {
  value = "SSL url for load balancer https://${aws_route53_record.domain.fqdn}"
}   