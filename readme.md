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
for every new feature or bugfix, add an entry to the changelog under the
[Unreleased] section using an appropriate sub header (`Added`, `Changed`,
`Deprecated`, `Removed`, `Fixed`, or `Security`).

Entries under these sub headers determine the semantic version bump when the
next release is cut with [relog].

### Creating a Release

Releases are cut with [relog], driven by the [Unreleased] section of
`changelog.md`. relog derives the next version from the sub headers under
[Unreleased]:

* `### Fixed` only → patch bump
* `### Added`, `### Changed`, `### Deprecated` → minor bump
* `### Removed` (or "Breaking" anywhere in the section) → major bump

To cut a release, from a clean `master` working tree, run:

```
relog
```

To preview the changes without modifying anything:

```
relog --dry-run
```

To override the auto-detected version:

```
relog X.Y.Z
```

relog rewrites the changelog, commits the result, creates an annotated `vX.Y.Z`
tag, and prompts before pushing. Pushing the `vX.Y.Z` tag triggers the GitHub
Actions workflow defined in
[`.github/workflows/build.yml`](.github/workflows/build.yml), which builds the
VM images and, in the "Create Release" step, creates a draft GitHub release
using the newly added changelog section as the release notes. Review the draft
release on GitHub and publish it.

[Keep a Changelog]: https://keepachangelog.com/en/1.1.0/
[relog]: https://github.com/jacob-carlborg/relog
[Unreleased]: https://github.com/cross-platform-action/freebsd-builder/blob/master/changelog.md#unreleased
