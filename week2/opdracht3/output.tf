output "webserver_ips" {
  value = [for i in esxi_guest.webserver : i.ip_address]
}

output "databaseserver_ip" {
  value = esxi_guest.databaseserver.ip_address
}

resource "local_file" "vm_ips_file" {
  filename = "vm_ips.txt"
  content = <<EOT
Databaseserver: ${esxi_guest.databaseserver.ip_address}
Webservers:
%{ for ip in esxi_guest.webserver[*].ip_address ~}
- ${ip}
%{ endfor }
EOT
}