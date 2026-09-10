#!/usr/bin/env bash
# Clone ryanoasis/nerd-fonts and install JetBrainsMono + Go-Mono.
# Idempotent: an existing clone is reused; install.sh skips installed fonts.
set -euo pipefail

fonts_dir="$HOME/.local/src/nerd-fonts"

if [[ ! -d "$fonts_dir/.git" ]]; then
  mkdir -p "$HOME/.local/src"
  git clone https://github.com/ryanoasis/nerd-fonts.git "$fonts_dir"
fi

(
  cd "$fonts_dir"
  ./install.sh JetBrainsMono
  ./install.sh Go-Mono
)
