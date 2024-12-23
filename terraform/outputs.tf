output "public_ip_addresses" {
  description = "Endereços IP públicos das instâncias EC2"
  value       = aws_instance.cluster[*].public_ip
}

output "private_dns" {
  description = "DNS privados das instâncias EC2"
  value       = aws_instance.cluster[*].private_dns
}

output "information_on_instances" {
  description = "combinar dns privado e endereço ip publico"
  value = zipmap(aws_instance.cluster[*].public_ip,aws_instance.cluster[*].private_dns)
}

output "lustre_mount_name" {
  description = "Mount name do sistema lustre"
  value       = var.isFSX? aws_fsx_lustre_file_system.example[0].mount_name: null
}

output "lustre_dns_name" {
  description = "DNS name do sistema lustre"
  value       = var.isFSX? aws_fsx_lustre_file_system.example[0].dns_name : null
}

output "s3_endpoint" {
  description = "S3 endpoint to use on io500"
  value       = var.isS3? aws_s3_bucket.use_on_tests[0].bucket : null
}
