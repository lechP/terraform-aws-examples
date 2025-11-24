# ALB DNS
output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.load_balancer.dns_name
}
