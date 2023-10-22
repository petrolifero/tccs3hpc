output "public_ip_addresses_workers" {
  description = "Endereços IP públicos das instâncias EC2"
  value       = aws_instance.cluster[*].public_ip
}

output "public_ip_addresses_manager" {
  description = "Endereços IP públicos da instância EC2 manager"
  value       = aws_instance.manager.public_ip
}



