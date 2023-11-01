output "public_ip_addresses" {
  description = "Endereços IP públicos das instâncias EC2"
  value       = aws_instance.cluster[*].public_ip
}

output "lustre_mount_name" {
  description = "Mount name do sistema lustre"
  value = aws_fsx_lustre_file_system.example.mount_name
}

output "lustre_dns_name" {
  description = "DNS name do sistema lustre"
  value = aws_fsx_lustre_file_system.example.dns_name
}