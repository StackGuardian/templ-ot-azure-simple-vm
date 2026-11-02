# Integration tests: deploy real resources, check them, then destroy them.
# This costs money and needs cloud credentials.
# Run: tofu test -test-directory=tests/integration
# Test case catalog: tests/README.md

variables {
  name_prefix = "itest"
  # Throwaway test key, the private key was discarded.
  ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCx5BjE6HIv/f9JIjDM/6y459/JJ17pHQxFUaUoE9DXcKBS3AXuPUuv2Qfrlke/xImnSzfAIWAcUmjBhU1i523XrqOFYzqJM3CV4KbU8UJMiXDRx16qdAt8CacqMd4qOxjSXkkFTDElOMfh9TMChBI3VcshCuQevk9g6y54cpY+y+1ejU/hmfytubSKuXDZ2wfnqEZhQ8RBD9i6TPiQ1OcqUEUEt7WHvtlxx4c4WPkQdG+Sc/EvvglyqmIcye9FCQNDt0NUjMr2mMYyuAjj0pbpMcGoFACw98DN1Y6K3ZkahE65E2uo3b54RWifgGfgMCI2jhFs1KxM02aOLGpijddhkWjP8yRSchJvY5wVkJKzjZSlTaPA2kUiShprjZIEfW4OnNStk+UV0uDRHxTcm28EUuBEceL5qXnZt/f/fdyCJrLYrphd6OjD/oNOVMkTmE96DdzYuZCM9UNT1eyhwRIFsxks9VpCSh8dz02MBJAfRJNGd7VgSLQwiN1/WADaw9M= tofu-test-only"
  tags = {
    Purpose = "integration-test"
  }
}

# I-01
run "deploy_default" {
  command = apply

  assert {
    condition     = output.public_ip == null
    error_message = "The VM must not have a public IP by default."
  }
}

# I-02
run "vm_is_running" {
  module {
    source = "./tests/integration/vm-check"
  }

  variables {
    vm_name             = run.deploy_default.vm_name
    resource_group_name = run.deploy_default.resource_group_name
  }

  assert {
    condition     = output.power_state == "running"
    error_message = "The VM is not running."
  }
}

# I-03
run "deploy_with_public_ip" {
  command = apply

  variables {
    enable_public_ip      = true
    allowed_ingress_cidrs = ["203.0.113.0/24"]
  }

  assert {
    condition     = output.public_ip != null && can(cidrhost("${output.public_ip}/32", 0))
    error_message = "The public IP output is not set."
  }
}
