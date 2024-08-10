# Copyright 2022 Shantanoo 'Shan' Desai <sdes.softdev@gmail.com>

#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at

#       http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#  limitations under the License.

# Variables will be set via the command line defined under the `vars` directory
variable "ubuntu_version" {
  type = string
}

variable "ubuntu_iso_file" {
  type = string
}

variable "vm_template_name" {
  type = string
  default = "ubuntu-uefi"
}

variable "host_distro" {
  type = string
  default = "ubuntu"
}

locals {
  vm_name = "${var.vm_template_name}-${var.ubuntu_version}"
  output_dir = "output/${local.vm_name}"
  ovmf_prefix = {
    "manjaro" = "x64/"
  }
  ovmf_suffix = {
    "ubuntu" = "_4M"
  }
}

source "qemu" "provision_source" {
  iso_url          = "${local.output_dir}/${local.vm_name}"
  iso_checksum     = "none"
  disk_image       = true
  disk_compression = true
  memory           = 8*1024
  cpus             = 4
  accelerator      = "kvm"
  disk_size        = "40G"
  qemuargs = [
    ["-bios", "/usr/share/OVMF/${lookup(local.ovmf_prefix, var.host_distro, "")}OVMF_CODE${lookup(local.ovmf_suffix, var.host_distro, "")}.fd"],
    ["-serial", "mon:stdio"],
    ["-device", "virtio-net,netdev=forward,id=net0"],
    ["-netdev", "user,hostfwd=tcp::{{ .SSHHostPort }}-:22,id=forward"],
  ]
  format          = "qcow2"

  shutdown_command = "echo 'ubuntu-uefi' | sudo shutdown -P now"
  shutdown_timeout = "15m"
  ssh_username     = "admin"
  ssh_password     = "packerubuntu"
  ssh_timeout      = "60m"
  headless         = true
}

build {
  name = "stage_provision_image"
  sources = [ "source.qemu.provision_source" ]
  provisioner "shell" {
    inline = [
      "cat /etc/os-release"
    ]
  }
}
