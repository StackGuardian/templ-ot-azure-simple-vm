# Azure Virtual Machine (Linux)

Creates a single Linux VM (Ubuntu 24.04 LTS) in its own network. By default the VM has no public IP and is not reachable from the internet.

Use it when you need one VM for a test, a demo or a small tool.

## What gets created

- A resource group
- A virtual network with one subnet and a network security group
- The Linux VM with Trusted Launch and a managed identity
- Optional: a public IP

## Before you start

- A workflow with an Azure cloud connector for the target subscription
- Permissions to create resource groups, networks and VMs
- An SSH key pair. You paste the public key into the form
- Optional: the EncryptionAtHost feature registered in the subscription, if you want encryption at host

## Form fields

| Field | What it does | Default |
|---|---|---|
| SSH public key | **Required.** Your public SSH key, for example `ssh-ed25519 AAAA...`. Password login is disabled | none |
| Name prefix | Prefix for all resource names. 2 to 16 lowercase letters, digits or hyphens, starting with a letter | `demo` |
| Location | Azure region | Germany West Central |
| VM size | Size of the VM. All listed sizes support Trusted Launch | B2s v2 (2 vCPU, 8 GiB) |

**Advanced Settings** (tick "Show advanced settings" to change them):

| Field | What it does | Default |
|---|---|---|
| VNet cidr | IP range of the new network | `10.0.0.0/16` |
| Admin username | Name of the admin user on the VM | `azureuser` |
| Enable public ip | Gives the VM a public IP | off |
| Allowed ingress cidrs | IP ranges that may connect when the public IP is on | `0.0.0.0/0` (everyone) |
| Allowed ingress ports | TCP ports opened for those ranges | `22` |
| Encryption at host enabled | Also encrypts temp disk and caches on the host. Needs the subscription feature | off |
| Tags | Extra tags added to all resources | none |

**Important:** with the public IP switched on and the default ranges, SSH (port 22) is open to the whole internet. For anything beyond a short demo, enter your own IP range under Allowed ingress cidrs.

## After the run

The workflow outputs show:

- `vm_name`, `private_ip` and `resource_group_name`
- `public_ip` and `ssh_command`: only set when the public IP is on, for example `ssh azureuser@<public_ip>`

Without a public IP, connect through Azure Bastion (not part of this template) or from inside the network.

## Security defaults

- No public IP, no inbound rules and no outbound internet access unless you change it
- SSH key only, password login disabled
- Trusted Launch: Secure Boot and vTPM on. VM extensions disabled
- Disks encrypted at rest

## Cost and cleanup

The VM is billed per hour. A public IP is billed while it exists. Destroy the resources from the workflow when the demo is over.

## Limits

- Without a public IP the VM cannot reach the internet, so package updates need a NAT gateway or a public IP
- No Bastion host included
