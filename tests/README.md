# Tests

Tests use the built-in OpenTofu test framework (`tofu test`, OpenTofu 1.9 or later).

| Level | Folder | What it does | Cost | When it runs |
|---|---|---|---|---|
| Unit | `tests/unit` | Plan only with mocked providers. Checks configuration and security settings. | None | Merge requests into `development` or `main`, and tags |
| Integration | `tests/integration` | Deploys real resources, checks them, destroys them. | Cloud cost while running | Tags, when cloud credentials are set (`integration-tests` job) |

## Run locally

```bash
tofu init
tofu test -test-directory=tests/unit
tofu test -test-directory=tests/integration   # needs cloud credentials
```

## Test cases

| ID | Level | Description | Status |
|---|---|---|---|
| U-01 | Unit | Default variables produce a valid plan with all default tags | done |
| U-02 | Unit | Invalid `name_prefix` is rejected | done |
| U-03 | Unit | Custom `tags` are merged with the default tags | done |
| U-04 | Unit | By default no public IP, NIC without public IP, no inbound NSG rules | done |
| U-05 | Unit | Password authentication is disabled | done |
| U-06 | Unit | Trusted Launch (Secure Boot and vTPM) is enabled | done |
| U-07 | Unit | VM has a system-assigned managed identity | done |
| U-08 | Unit | `enable_public_ip = true` without `allowed_ingress_cidrs` is rejected | done |
| U-09 | Unit | `allowed_ingress_cidrs` containing `0.0.0.0/0` is rejected | done |
| U-10 | Unit | With public IP enabled: Standard public IP, NSG allows only the given CIDRs and ports | done |
| U-11 | Unit | No flow logs without a Network Watcher | done |
| U-12 | Unit | With a Network Watcher: VNet flow logs target the VNet, storage enforces TLS 1.2 and blocks public access | done |
| U-13 | Unit | `allowed_ingress_cidrs` broader than `/8` (for example `128.0.0.0/1`) is rejected | done |
| I-01 | Integration | Default deployment has no public IP | done |
| I-02 | Integration | VM power state is `running` | done |
| I-03 | Integration | With `enable_public_ip = true`: public IP output is set | done |

Integration tests are written but have not run against a real cloud account yet.
