output "spoke1_private_ip" {
  value = azurerm_network_interface.spoke1-nic.private_ip_address
}

output "spoke1_public_ip" {
  value = azurerm_public_ip.spoke1-public-ip.ip_address
}


output "spoke2_private_ip" {
  value = azurerm_network_interface.spoke2-nic.private_ip_address
}

output "spoke2_public_ip" {
  value = azurerm_public_ip.spoke2-public-ip.ip_address
}
