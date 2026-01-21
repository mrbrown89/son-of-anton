packer {
  required_plugins {
    parallels = {
      source  = "github.com/Parallels/parallels"
      version = ">= 1.2.0"
    }
  }
}

packer {
  required_plugins {
    ansible = {
      version = "~> 1"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

# -------- Variables (top-level only) --------
variable "username" {
  type    = string
  default = "mattb"
}

variable "local_user" {
  type    = string
  default = "debian"
}

variable "local_pass" {
  type    = string
  default = "debian"
}

variable "vm_name" {
  type    = string
  default = "zfs"
}

# -------- Source --------
source "parallels-pvm" "debianzfs" {
  source_path            = "/Users/${var.username}/Parallels/GoldenImages/debian13-base.pvm"
  vm_name                = var.vm_name
  output_directory       = "/Users/${var.username}/Parallels/${var.vm_name}.pvm"
  parallels_tools_flavor = "lin"

  communicator = "ssh"
  ssh_username = var.local_user
  ssh_password = var.local_pass
  ssh_timeout  = "30m"

  # Configure hardware resources (CPU/RAM only)
  prlctl = [
    ["set", "{{.Name}}", "--memsize", "6144"],
    ["set", "{{.Name}}", "--cpus",    "2"]
  ]

  # These belong to the source block, not inside prlctl
  shutdown_command = "sudo -n shutdown -h now"
  shutdown_timeout = "10m"
}


# -------- Build --------
build {
  name    = "debian-clone"
  sources = ["source.parallels-pvm.debianzfs"]

  #Make sudo passwordless so all later steps use sudo -n
  provisioner "shell" {
    inline = [
      "set -euxo pipefail",
      "echo '${var.local_user} ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/99-${var.local_user}",
      "sudo chmod 440 /etc/sudoers.d/99-${var.local_user}"
    ]
  }
  
  # Disable IPv6 on the VM
  provisioner "shell" {
  inline = [
    "echo 'Fully disabling IPv6 at the kernel level...'",

    # Disable IPv6 immediately
    "sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1",
    "sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1",

    # Persistently disable at boot via sysctl
    "echo 'net.ipv6.conf.all.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.conf",
    "echo 'net.ipv6.conf.default.disable_ipv6 = 1' | sudo tee -a /etc/sysctl.conf",

    # Ensure kernel module is disabled at boot
    "echo 'blacklist ipv6' | sudo tee /etc/modprobe.d/disable-ipv6.conf",

    # Disable the kernel command line IPv6 option
    "sudo sed -i 's/^GRUB_CMDLINE_LINUX=\"/GRUB_CMDLINE_LINUX=\"ipv6.disable=1 /' /etc/default/grub || true",
    "sudo update-grub || true"
  ]
}

  # Son of Anton Ansible playbooks
  # Update and Upgrade the VM
  provisioner "ansible" {
    playbook_file   = "ansible/update-upgrade.yml"
    user            = "debian"
}

  # Clone Anton Repo
  provisioner "ansible" {
    playbook_file   = "ansible/son-of-anton.yml"
    user            = "debian"
}

  #Post-processor
  post-processor "shell-local" {
    inline = [
      "echo 'Registering VM with Parallels...'",
      "BASE='/Users/${var.username}/Parallels/${var.vm_name}.pvm'",
      "INNER=\"$BASE/$(basename \"$BASE\")\"",
      "if prlctl list -a | grep -Fq '${var.vm_name}'; then echo 'Already registered'; exit 0; fi",
      "(prlctl register \"$BASE\" || prlctl register \"$INNER\") || { echo 'WARN: register failed for both paths'; exit 0; }",
      "(prlctl set ${var.vm_name} --device-set net0 --type shared || prlctl set ${var.vm_name} --device-add net --type shared) || true",
      "prlctl list -a | grep -F '${var.vm_name}' || true",
      "echo \"Registered VM: ${var.vm_name} → $(prlctl list -a | awk '/${var.vm_name}/ {print $4}')\""
    ]
  }
}
