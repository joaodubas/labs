# macOS Provisioning with Comtrya

This directory contains `comtrya` manifests specifically designed for provisioning macOS systems.

It automates the installation and configuration of:

*   **System Dependencies:** Essential tools and applications via Homebrew.
*   **CLI Tools:** Such as `mise`.
*   **User Configuration:** Primarily for the `fish` shell.

## Usage

To apply these configurations, navigate to the main `comtrya` directory and run `comtrya apply`. Ensure your system's OS family is detected as "Darwin" for these manifests to be applied.

```bash
cd /opt/personal/labs/provision/comtrya-macos
comtrya apply
```

## Improvements

This is not a finished project and there are some improvements that must be made:

* [x] Add `fish` configuration file
* [x] Copy `configuration` from `ide` repo
* [x] Copy `neovim` configuration from `ide` repo
* [x] Copy `git` configuration from `comtrya` folder
* [ ] Add `1password` configuration through `brew`
* [ ] Check `docker desktop` instead for `podman desktop`
