# FreeBSD Builder

This project builds the FreeBSD VM image for the
[cross-platform-actions/action](https://github.com/cross-platform-actions/action)
GitHub action. The image contains a standard FreeBSD installation without any
expectations of running X.

In addition to standard installation, the following packages are installed as
well:

* sudo
* bash
* curl

Except for the root user, there's one additional user, `runner`, which is the
user that will be running the commands in the GitHub action. This user is
allowed use `sudo` without a password.

## Architectures and Versions

The following architectures and versions are supported:

| Version | x86-64 | ARM64 |
|---------|--------|-------|
| 15.1    | ✓      | ✓     |
| 15.0    | ✓      | ✓     |
| 14.4    | ✓      | ✓     |
| 14.3    | ✓      | ✓     |
| 14.2    | ✓      | ✓     |
| 14.1    | ✓      | ✓     |
| 14.0    | ✓      | ✓     |
| 13.5    | ✓      | ✓     |
| 13.4    | ✓      | ✓     |
| 13.3    | ✓      | ✓     |
| 13.2    | ✓      | ✓     |
| 13.1    | ✓      | ✓     |
| 13.0    | ✓      | ✓     |
| 12.4    | ✓      | ✓     |
| 12.2    | ✓      | ✗     |

## Building Locally

### Prerequisite

* [Packer](https://www.packer.io) 1.9.1 or later
* [QEMU](https://qemu.org)

### Building

1. Clone the repository:
    ```
    git clone https://github.com/cross-platform-actions/freebsd-builder
    cd freebsd-builder
    ```

2. Run `build.sh` to build the image:
    ```
    ./build.sh <version> <architecture>
    ```
    Where `<version>` and `<architecture>` are the any of the versions or
    architectures available in the above table.

The above command will build the VM image and the resulting disk image will be
at the path: `output/freebsd-<version>-<architecture>.qcow2`.

## Contributing

### Changelog

The changelog is maintained in the [changelog.md](changelog.md) file, following
the [Keep a Changelog] format. The changelog is updated incrementally. That is,
for every new feature or bugfix, add an entry to the changelog. New entries are
added below the [Unreleased] section, with an appropriate sub header.

### Creating a Release

Make sure the [Unreleased] section of the changelog contains entries describing
the changes to be released, then run:

```
bin/release
```

The script will:

1. Determine the next version from the changelog's [Unreleased] section
    (`Removed`/`Breaking` → major, `Added`/`Changed`/`Deprecated` → minor,
    `Fixed` → patch). A version can also be passed explicitly as an argument.
1. Update the changelog: rename [Unreleased] to the new version with today's
    date, add a new empty [Unreleased] section, and update reference links.
1. Commit the changelog and create an annotated tag (e.g. `v2.1.0`).
1. Prompt before pushing `master` and the tag to origin.

Pass `--dry-run` to preview the changes without modifying anything.

After pushing:

1. The CI workflow creates a draft release from the pushed tag, using the
    newly added changelog section as the release notes.
1. Check the draft release at GitHub to make sure everything looks good, then
    publish it.

[Keep a Changelog]: https://keepachangelog.com/en/1.1.0/
[Unreleased]: https://github.com/cross-platform-action/freebsd-builder/blob/master/changelog.md#unreleased
