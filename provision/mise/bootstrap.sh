#!/usr/bin/env bash
# Entrypoint for the mise-based machine bootstrap (replaces `comtrya apply`).
#
#   1. Installs mise system-wide if missing:
#      - Linux: official apt repository when available, otherwise the static
#        binary at /usr/local/bin/mise (visible to every user).
#      - macOS: `brew install mise`.
#   2. Runs `mise -E <os> bootstrap` from this directory, layering
#      mise.linux.toml / mise.macos.toml over mise.toml.
#
# Idempotent: an existing mise is reused as-is, and `mise bootstrap` skips
# unchanged declarative state. Extra arguments are forwarded to
# `mise bootstrap` (e.g. --dry-run, --only, --skip).
#
# Prerequisites on the target machine:
#   - sudo access (system packages, login shell, docker group, ...)
#   - ~/.ssh/gitea.pub and ~/.ssh/github.pub for the git allowed_signers file
#     (git:allowed-signers warns and skips if they are absent)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install_mise_linux() {
  if command -v apt-get >/dev/null 2>&1 && command -v gpg >/dev/null 2>&1; then
    echo ">> installing mise via the official apt repository"
    sudo install -dm 755 /etc/apt/keyrings
    curl -fsSL https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg >/dev/null
    echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=$(dpkg --print-architecture)] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list >/dev/null
    sudo apt-get update
    sudo apt-get install -y mise
  else
    echo ">> installing mise static binary to /usr/local/bin (apt repo unavailable)"
    curl -fsSL https://mise.jdx.dev/install.sh | sudo env MISE_INSTALL_PATH=/usr/local/bin/mise sh
  fi
}

install_mise_macos() {
  local brew_bin
  brew_bin="$(command -v brew || true)"
  if [[ -z "$brew_bin" && -x /opt/homebrew/bin/brew ]]; then
    brew_bin=/opt/homebrew/bin/brew
  fi
  if [[ -z "$brew_bin" ]]; then
    echo "error: Homebrew not found; install it first (see the macos:brew task)" >&2
    exit 1
  fi
  echo ">> installing mise via Homebrew"
  "$brew_bin" install mise
}

if ! command -v mise >/dev/null 2>&1; then
  case "$(uname -s)" in
    Linux) install_mise_linux ;;
    Darwin) install_mise_macos ;;
    *)
      echo "error: unsupported OS: $(uname -s)" >&2
      exit 1
      ;;
  esac
else
  echo ">> mise already installed: $(mise --version)"
fi

case "$(uname -s)" in
  Linux) os_env="linux" ;;
  Darwin) os_env="macos" ;;
  *)
    echo "error: unsupported OS: $(uname -s)" >&2
    exit 1
    ;;
esac

cd "$SCRIPT_DIR"
for config_file in mise.toml "mise.${os_env}.toml"; do
  mise trust --quiet "$config_file" 2>/dev/null || true
done
exec mise --env "$os_env" bootstrap "$@"
