# Azure Hub-Spoke Network Topology

This Terraform configuration creates a Hub-and-Spoke network topology in Azure with the following components:

## Architecture

- **Hub VNet**: `10.0.0.0/16` - Central network with DNS subnet
- **Spoke 1 VNet**: `10.1.0.0/16` - Isolated spoke network
- **Spoke 2 VNet**: `10.2.0.0/16` - Isolated spoke network
- **VNet Peering**: Hub-to-spoke connectivity (spokes cannot communicate directly)

## Resources Created

- 1 Resource Group
- 3 Virtual Networks (1 hub, 2 spokes)
- 4 Subnets
- 4 VNet Peering connections
- 2 Linux VMs (Ubuntu 22.04)
- 2 Public IPs
- 2 Network Interfaces

## Prerequisites

- Azure CLI installed and configured (`az login`)
- Terraform installed
- SSH key pair generated (`~/.ssh/id_rsa.pub`)

## Usage

1. Clone this repository
2. Login to Azure CLI: `az login`
3. Set your subscription: `az account set --subscription "your-subscription-id"`
4. Initialize Terraform:
   ```bash
   terraform init
   ```
4. Plan the deployment:
   ```bash
   terraform plan
   ```
5. Apply the configuration:
   ```bash
   terraform apply
   ```

## Outputs

- `spoke1_private_ip`: Private IP of Spoke 1 VM
- `spoke1_public_ip`: Public IP of Spoke 1 VM
- `spoke2_private_ip`: Private IP of Spoke 2 VM
- `spoke2_public_ip`: Public IP of Spoke 2 VM

## TODO

- [ ] Implement Private DNS for name resolution
- [ ] Add inter-spoke communication via hub routing
- [ ] Add Network Security Groups

## Clean Up

To destroy all resources:
```bash
terraform destroy
```
