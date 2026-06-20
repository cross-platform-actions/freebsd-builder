# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.15.0] - 2026-06-20
### Added
- Add support for FreeBSD 15.1 ([#15](https://github.com/cross-platform-actions/freebsd-builder/issues/15), [action#153](https://github.com/cross-platform-actions/action/issues/113))

## [0.14.0] - 2026-04-28
### Added
- Add support for FreeBSD 14.4

### Changed
- Simplify SSH authentication. The previous solution created a secondary
    attached hard drive when the VM was created. A boot init script then
    mounted the secondary hard drive and installed a public SSH key from it.
    The new solution uses passwordless login.

## [0.13.1] - 2025-12-12
### Fixed
- Fix empty hostname ([action#113](https://github.com/cross-platform-actions/action/issues/113))
- Always use `sysrc` to edit `/etc/rc.conf`

## [0.13.0] - 2025-12-06
### Added
- Add support for FreeBSD 15.0 ([action#114](https://github.com/cross-platform-actions/action/issues/114))
- Add QEMU as a required Packer plugin

### Changed
- Increase timeout for downloading the ISO

### Fixed
- Fix building FreeBSD 13.0 ARM64

## [0.12.0] - 2025-06-21
### Added
- Add support for FreeBSD 14.3 ([#9](https://github.com/cross-platform-actions/freebsd-builder/pull/9), [action#106](https://github.com/cross-platform-actions/action/issues/106))

## [0.11.0] - 2025-03-14
### Added
- Add support for FreeBSD 13.5 ([action#99](https://github.com/cross-platform-actions/action/issues/99))

### Changed
- Improve checking if the upstream pkg site is available
- Use HTTPS whenever possible
- Update archive URL

## [0.10.0] - 2024-12-03
### Added
- Add support for FreeBSD 14.2

## [0.9.0] - 2024-09-17
### Added
- Add support for FreeBSD 13.4

## [0.8.0] - 2024-06-04
### Added
- Add support for FreeBSD 14.1 ([#6](https://github.com/cross-platform-actions/freebsd-builder/pull/6))

## [0.7.0] - 2024-03-05
### Added
- Add support for FreeBSD 13.3
- Enable hardware accelerated virtualization

## [0.6.0] - 2024-02-15
### Added
- Add support for FreeBSD 14.0 ([action#74](https://github.com/cross-platform-actions/action/issues/74))

### Changed
- Bump QEMU to 8.2 for FreeBSD 14.0 ARM64
- Use DVD image to bootstrap `pkg`
- Simplify network setup during installation
- Split provisioning script

### Fixed
- Fix #4: Ubuntu 22.10 is end of life ([#4](https://github.com/cross-platform-actions/freebsd-builder/issues/4))

### Removed
- Remove bad mirrors
- Remove unused environment variables

## [0.5.0] - 2023-07-17
### Added
- Add support for FreeBSD ARM64 ([action#55](https://github.com/cross-platform-actions/action/issues/55))

## [0.4.0] - 2023-04-28
### Added
- Add support for FreeBSD 13.2 ([#3](https://github.com/cross-platform-actions/freebsd-builder/pull/3))

## [0.3.0] - 2023-01-16
### Added
- Add support for FreeBSD 13.1
- Add support for FreeBSD 12.4
- Add mirror for old releases

### Changed
- Remove the need for a variable file with the OS version

## [0.2.1] - 2022-03-11
### Changed
- Send boot output to the serial console

## [0.2.0] - 2021-09-04
### Added
- Add support for FreeBSD 13.0

## [0.0.1] - 2021-05-28
### Added
- Initial release

[Unreleased]: https://github.com/cross-platform-actions/freebsd-builder/compare/v0.15.0...HEAD

[0.15.0]: https://github.com/cross-platform-actions/freebsd-builder/compare/v0.14.0...v0.15.0

[0.14.0]: https://github.com/cross-platform-actions/freebsd-builder/compare/v0.13.1...v0.14.0

[0.13.1]: https://github.com/cross-platform-actions/freebsd-builder/compare/v0.13.0...v0.13.1
[0.13.0]: https://github.com/cross-platform-actions/freebsd-builder/compare/v0.12.0...v0.13.0
[0.12.0]: https://github.com/cross-platform-actions/freebsd-builder/compare/v0.11.0...v0.12.0
[0.11.0]: https://github.com/cross-platform-actions/freebsd-builder/compare/v0.10.0...v0.11.0
[0.10.0]: https://github.com/cross-platform-actions/freebsd-builder/compare/v0.9.0...v0.10.0
[0.9.0]: https://github.com/cross-platform-actions/freebsd-builder/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/cross-platform-actions/freebsd-builder/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/cross-platform-actions/freebsd-builder/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/cross-platform-actions/freebsd-builder/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/cross-platform-actions/freebsd-builder/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/cross-platform-actions/freebsd-builder/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/cross-platform-actions/freebsd-builder/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/cross-platform-actions/freebsd-builder/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/cross-platform-actions/freebsd-builder/compare/v0.0.1...v0.2.0
[0.0.1]: https://github.com/cross-platform-actions/freebsd-builder/releases/tag/v0.0.1
