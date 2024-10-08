# Copyright 2024 Shantanoo 'Shan' Desai <sdes.softdev@gmail.com>

#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at

#       http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#  limitations under the License.

packer {
  required_plugins {
    qemu = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

# Variables will be set via the command line defined under the `vars` directory
variable "ubuntu_distro" {
  type = string
}

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
    "ubuntu" = ""
  }
  ovmf_suffix = {
    "mangaro" = ""
    "ubuntu" = "_4M"
  }
}

source "qemu" "custom_image" {
  vm_name      = "${local.vm_name}"

  iso_url      = "https://releases.ubuntu.com/${var.ubuntu_version}/${var.ubuntu_iso_file}"
  iso_checksum = "file:https://releases.ubuntu.com/${var.ubuntu_version}/SHA256SUMS"

  # Location of Cloud-Init / Autoinstall Configuration files;
  # will be served via an HTTP Server from Packer
  http_directory = "http/${var.ubuntu_distro}"

  # Boot commands when loading the ISO file with OVMF.fd file (Tianocore) / GrubV2
  boot_command = [
    "<spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait>",
    "e<wait>",
    "<down><down><down><end>",
    " autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
    "<f10>"
  ]

  boot_wait = "5s"

  # QEMU specific configuration
  cpus             = 4
  memory           = 8*1024
  accelerator      = "kvm"
  disk_size        = "40G"
  disk_compression = true

  efi_firmware_code = "/usr/share/OVMF/${lookup(local.ovmf_prefix, var.host_distro, "")}OVMF_CODE${lookup(local.ovmf_suffix, var.host_distro, "_4M")}.fd"
  efi_firmware_vars = "/usr/share/OVMF/${lookup(local.ovmf_prefix, var.host_distro, "")}OVMF_VARS${lookup(local.ovmf_suffix, var.host_distro, "_4M")}.fd"
  efi_boot          = true

  # Final image will be available in `output/ubuntu-uefi-*/`
  output_directory = "${local.output_dir}"

  # SSH configuration so that Packer can log into the image
  ssh_password     = "packerubuntu"
  ssh_username     = "admin"
  ssh_timeout      = "20m"
  # Send the passowrd to the shutdown command
  shutdown_command = "echo 'packerubuntu' | sudo -S shutdown -P now"
  # NOTE: set this to true when using in CI Pipelines
  headless         = false
}

build {
  name    = "custom_build"
  sources = [ "source.qemu.custom_image" ]

  # Wait till Cloud-Init has finished setting up the image on first-boot
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for Cloud-Init...'; sleep 1; done"
    ]
  }

  # Generate a SHA256 checksum which can be used for further stages in the `output` directory
  post-processor "checksum" {
    checksum_types      = [ "sha256" ]
    output              = "${local.output_dir}/${local.vm_name}.{{.ChecksumType}}"
    keep_input_artifact = true
  }
}
