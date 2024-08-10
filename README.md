# packer-ubuntu-server-uefi
Templates for creating Ubuntu Server images with Packer + QEMU + Autoinstall (cloud-init)

Currently supported images:

| Name                | Version       |
|:--------------------|:-------------:|
| __Focal Fossa__     |     `20.04.6` |
| __Jammy Jellyfish__ |     `22.04.4` |
| __Noble Numbat__    |     `24.04`   |

An accompanying blogpost is available [here](https://shantanoo-desai.github.io/posts/technology/packer-ubuntu-qemu/).

## Usage

Use GNU-Make to perform validation / build images:

### Validation

To validate `cloud-init` and `ubuntu.pkr.hcl` template perform:

```shell
make validate
```

To simply validate `cloud-init` against all distros:

```shell
make validate-cloudinit
```

To validate `cloud-init` configuration of a specific distro (`focal`, `jammy`, `noble`):

```shell
make validate-cloudinit-<distroname>
```

To simply validate `ubuntu.pkr.hcl` template against all distros:

```shell
make validate-packer
```

### Build Images

To build Ubuntu 20.04 (Focal) image:

```shell
make build-focal
```

To build Ubuntu 22.04 (Jammy) image:

```shell
make build-jammy
```

To build Ubuntu 24.04 (Noble) image:

```shell
make build-noble
```

## UEFI BootLoader Sequence Determination

See the `late-commands` in the `user-data` file. This is determined by installing `efibootmgr` on the live
image and performing `sudo efibootmgr`. This lists what are the sequences and when should the image be booted.

> NOTE: there seems to be compatibility issue between Ubuntu 24.04 and older Ubuntu LTS version in terms of
> output from the `efibootmgr`, namely capitalization. Hence each Cloud-Init `user-data` now is in a
> separate directory under the `http` directory in the repo.
