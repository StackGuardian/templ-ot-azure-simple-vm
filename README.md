# Azure Simple VM

A single Linux VM. A public IP is optional and off by default.

OpenTofu demo template. Standalone, no dependency on other repos. Compatible with Terraform.

## Architecture

- Resource group
- VNet with one subnet (default outbound access disabled) and an NSG
- Linux VM (Ubuntu 24.04 LTS, Trusted Launch) with a NIC and a system-assigned managed identity
- Standard public IP (only when `enable_public_ip = true`)
- VNet flow logs to a storage account (only when `network_watcher` is set)

## Security

- SSH key only, password login disabled
- Trusted Launch: Secure Boot and vTPM enabled
- Managed disks encrypted at rest with platform-managed keys. Encryption at host is optional (`encryption_at_host_enabled`)
- VM extensions disabled
- Default: no public IP, no inbound NSG rules, no default outbound internet access
- Public IP only on opt-in. Inbound traffic limited to `allowed_ingress_cidrs` and `allowed_ingress_ports`; `0.0.0.0/0` is rejected
- VNet flow logs (optional). Network Watcher exists only once per region and subscription, so the template uses an existing one instead of creating it. The flow log storage account enforces TLS 1.2, blocks public blob access, denies network access except trusted Azure services and keeps deleted blobs for 7 days

Accepted checkov findings (documented inline in the code):

| Check | Reason |
|---|---|
| CKV_AZURE_119, CKV2_AZURE_39 | Public IP is opt-in and limited to allowed CIDRs |
| CKV_AZURE_59, CKV2_AZURE_33 | Flow log storage: firewall denies everything except trusted Azure services, private endpoint is out of scope |
| CKV_AZURE_206 | LRS is enough for demo flow logs |
| CKV_AZURE_33 | Queue service is not used |
| CKV2_AZURE_1 | Microsoft-managed keys, customer-managed keys are out of scope |
| CKV2_AZURE_40, CKV2_AZURE_41 | Provider needs shared key access, SAS tokens are not used |

## Usage

Sign in with `az login` and set `ARM_SUBSCRIPTION_ID` to the target subscription.

```bash
cp terraform.tfvars.example terraform.tfvars
tofu init
tofu plan
tofu apply
```

## Access

Without a public IP, connect through Azure Bastion (not part of this template) or from inside the VNet.
The VM has no default outbound internet access, so package updates need a NAT gateway or a public IP.

With `enable_public_ip = true`, SSH from an allowed CIDR:

```bash
ssh azureuser@<public_ip>
```


## Inputs

| Name | Description | Default |
|---|---|---|
| `name_prefix` | Prefix for all resource names | `"demo"` |
| `location` | Azure location | `"germanywestcentral"` |
| `tags` | Additional tags for all resources | `{}` |
| `ssh_public_key` | SSH public key for the admin user (required) | none |
| `vm_size` | VM size, must support Trusted Launch | `"Standard_B2s_v2"` |
| `vnet_cidr` | Address space of the VNet | `"10.0.0.0/16"` |
| `admin_username` | Admin user | `"azureuser"` |
| `enable_public_ip` | Attach a Standard public IP | `false` |
| `allowed_ingress_cidrs` | Allowed source CIDRs, required with a public IP, `/0` rejected | `[]` |
| `allowed_ingress_ports` | Opened TCP ports | `[22]` |
| `encryption_at_host_enabled` | Encryption at host (needs the subscription feature) | `false` |
| `network_watcher` | Existing Network Watcher (`name`, `resource_group_name`) for flow logs | `null` |
| `log_retention_days` | Flow log retention | `90` |

## Outputs

| Name | Description |
|---|---|
| `resource_group_name` | Name of the resource group |
| `vm_name` | Name of the VM |
| `vm_id` | ID of the VM |
| `private_ip` | Private IP |
| `public_ip` | Public IP, `null` if disabled |
| `ssh_command` | SSH command, `null` unless the public IP is enabled |

## Cost

The VM is billed hourly. A Standard public IP is billed while it exists. Flow logs bill storage and Network Watcher processing.

**Destroy after the demo:**

```bash
tofu destroy
```

## Tests

Unit tests run with mocked providers on every push and pull request. Integration tests deploy real
resources and run manually through the `integration` workflow. They need the repository variables `AZURE_CLIENT_ID`, `AZURE_TENANT_ID` and `AZURE_SUBSCRIPTION_ID` (app registration with a federated credential for GitHub OIDC).

```bash
tofu test -test-directory=tests/unit
```

Test cases: [tests/README.md](tests/README.md)

## Development

```bash
pre-commit install
pre-commit run --all-files
```
