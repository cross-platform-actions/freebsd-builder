# AGENTS.md - Coding Agent Instructions for freebsd-builder

## Project Overview

This is a **Packer + QEMU infrastructure project** that builds FreeBSD VM disk images
(qcow2) for the [cross-platform-actions/action](https://github.com/cross-platform-actions/action)
GitHub Action. The codebase consists of shell scripts, HashiCorp Configuration Language
(HCL) files, and CI YAML. There is no application-level code (no TypeScript, JavaScript,
Python, etc.).

**Supported architectures:** `x86-64`, `arm64`
**Supported FreeBSD versions:** 12.2, 12.4, 13.0–13.5, 14.0–14.4, 15.0

## Build Commands

### Build an image

```bash
./build.sh <version> <architecture>
# Examples:
./build.sh 14.4 arm64
./build.sh 15.0 x86-64
```

This runs `packer init .` then `packer build` with layered variable files:
1. `var_files/common.pkrvars.hcl` (shared: memory, CPUs, disk, user config)
2. `var_files/<architecture>.pkrvars.hcl` (arch-specific: QEMU binary, CPU type, firmware)
3. `var_files/<version>/<architecture>.pkrvars.hcl` (version-specific: ISO checksum)

Output: compressed qcow2 image in `output/`.

### Validate Packer template

```bash
packer validate -var-file=var_files/common.pkrvars.hcl \
  -var-file=var_files/x86-64.pkrvars.hcl \
  -var-file=var_files/14.4/x86-64.pkrvars.hcl \
  freebsd.pkr.hcl
```

### Format HCL files

```bash
packer fmt freebsd.pkr.hcl
packer fmt var_files/
```

## Testing

There is **no unit test framework**. Testing is integration-only via GitHub Actions CI.

The CI pipeline (`.github/workflows/build.yml`):
1. Builds the image with Packer
2. Serves it via a local HTTP server
3. Boots it using `cross-platform-actions/action@master`
4. Runs shell assertions inside the VM verifying OS name, version, architecture,
   working directory, hostname, and file synchronization

**There is no way to run the full test suite locally.** You can only build an image
and manually boot it with QEMU.

CI matrix: 13 versions x 2 architectures = ~25 jobs.

## Linting

No linting tools are configured. There is no shellcheck, no editorconfig, no
pre-commit hooks. Maintain consistency manually by following the patterns below.

## Code Style Guidelines

### Shell Scripts

#### Shebang and Strict Mode
- Provisioning scripts (run inside the VM): `#!/bin/sh` with `set -exu`
- Build entrypoint: `#!/usr/bin/env sh` with `set -eux`
- Always enable strict mode: `set -exu` or `set -eux`

#### Naming Conventions
- **Functions:** `snake_case` (e.g., `configure_boot_flags`, `install_extra_packages`)
- **Environment/exported variables:** `UPPER_SNAKE_CASE` (e.g., `OS_VERSION`, `ABI_VERSION`)
- **Local variables:** `lower_snake_case`, declared with `local` keyword
  ```sh
  local rc_dir="/etc/rc.d"
  local device_version="$1"
  ```

#### Variable Quoting
Always double-quote variable expansions:
```sh
echo "$OS_VERSION"
if [ -e "$device" ]; then
```

#### Error Handling
- Rely on `set -e` for automatic exit on error
- Use explicit checks with error messages to stderr for critical failures:
  ```sh
  if [ ! -e /dev/vtbd0 ] && [ ! -e /dev/ada0 ]; then
    echo "ERROR: There is no disk available for installation" >&2
    exit 1
  fi
  ```
- Suppress expected failures with `|| :` (e.g., `dd if=/dev/zero of=/EMPTY bs=1M || :`)

#### Script Structure
Organize scripts as function definitions at the top, followed by sequential calls at the bottom:
```sh
#!/bin/sh
set -exu

configure_thing() {
  # ...
}

install_packages() {
  # ...
}

# Main execution
configure_thing
install_packages
```

#### Heredocs
Use heredocs for multi-line file content:
```sh
cat <<EOF >> /boot/loader.conf
autoboot_delay="-1"
beastie_disable="YES"
EOF
```

### HCL (Packer) Style

- **Variable naming:** `snake_case` (e.g., `os_version`, `image_architecture`)
- **Every variable** should have `type`, `description`, and `default` where appropriate
- **String interpolation:** `${var.name}` and `${local.name}`
- **Comments:** `//` for single-line comments
- **File organization:** Variables at top, locals next, source block, then build block

### YAML (GitHub Actions)

- Standard GitHub Actions conventions
- Use matrix strategy for version/architecture combinations
- Multi-line shell commands use `|` block scalar

## Project Architecture

### Configuration Layering

```
var_files/
├── common.pkrvars.hcl          # Shared: memory, CPUs, disk size, user
├── arm64.pkrvars.hcl           # Arch: QEMU binary, CPU type, firmware
├── x86-64.pkrvars.hcl          # Arch: QEMU binary, CPU type
└── <version>/
    ├── arm64.pkrvars.hcl       # Version+arch: ISO checksum only
    └── x86-64.pkrvars.hcl      # Version+arch: ISO checksum only
```

### Provisioning Pipeline (runs inside the VM)

1. `resources/installerconfig` - FreeBSD bsdinstall automation (partitioning, network, SSH)
2. `resources/provision.sh` - Main setup (user creation, boot config, packages, sudo)
3. `resources/custom.sh` - Empty customization hook for downstream images
4. `resources/cleanup.sh` - Minimize disk (clear caches, zero free space)

### Release Process

- Tags matching `v*` trigger draft GitHub Releases with qcow2 artifacts
- One artifact per version/architecture combination

## Adding a New FreeBSD Version

1. Create `var_files/<version>/arm64.pkrvars.hcl` with the ISO checksum
2. Create `var_files/<version>/x86-64.pkrvars.hcl` with the ISO checksum
3. Add the version to the CI matrix in `.github/workflows/build.yml`
4. Verify the ISO URL pattern still works (defined in `freebsd.pkr.hcl` locals)

## Common Pitfalls

- ISO download can be slow; `PACKER_GETTER_READ_TIMEOUT=60m` is set in `build.sh`
- arm64 builds require EFI firmware (path configured in `var_files/arm64.pkrvars.hcl`)
- arm64 var file overrides memory to 3072MB (from common's 4096MB)
- Version-specific var files contain **only** the checksum; all other config is inherited
- The `installerconfig` script auto-detects the disk device (`vtbd0` or `ada0`)
