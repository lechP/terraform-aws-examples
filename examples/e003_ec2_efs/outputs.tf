output "efs_id" {
  description = "ID of the created EFS file system"
  value       = aws_efs_file_system.example_efs.id
}

output "efs_mount_targets" {
  description = "Number of EFS mount targets created"
  value       = aws_efs_file_system.example_efs.number_of_mount_targets
}
