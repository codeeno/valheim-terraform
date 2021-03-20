output "server_elastic_ip" {
    value = aws_eip.ip.public_ip
}