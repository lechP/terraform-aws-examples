output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.hello.public_ip
}

output "hello_url" {
  description = "URL to access the example page"
  value       = "http://${aws_instance.hello.public_ip}"
}

output "volume_id" {
  description = "ID of the attached EBS volume"
  value       = aws_ebs_volume.data.id
}
