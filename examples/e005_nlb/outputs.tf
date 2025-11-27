output "nlb_dns_name" {
  value = aws_lb.nlb.dns_name
}

output "instance_private_ips" {
  value = [for i in aws_instance.app : i.private_ip]
}
