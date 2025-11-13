# Output public IP of the created instance
output "public_ip" {
  value       = aws_instance.hello.public_ip
  description = "Public IP of the hello EC2 instance"
}

output "hello_url" {
  value       = "http://${aws_instance.hello.public_ip}"
  description = "Open this in your browser"
}
