#!/usr/bin/env bash
# Clone kickstart.nvim pinned to a fixed commit, apply the ide repo patch and
# copy the custom plugins config from the local ide clone.
#
# Usage: neovim-kickstart.sh <ide_dir>
#
# Idempotent: existing clones are fetched and hard-reset to the pin before the
# patch is re-applied.
set -euo pipefail

PIN="626c660f54054953e630bef85fdf65e159c7516a"

ide_dir="${1:?ide repo clone directory required}"
if [ ! -d "$ide_dir/.git" ]; then
  echo "ide repo not cloned at $ide_dir (ide:clone must run first)" >&2
  exit 1
fi

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
nvim_dir="$config_home/nvim"

if [[ ! -d "$nvim_dir/.git" ]]; then
  git clone https://github.com/nvim-lua/kickstart.nvim.git "$nvim_dir"
fi
git -C "$nvim_dir" fetch --prune origin
git -C "$nvim_dir" restore '*'
git -C "$nvim_dir" reset --hard "$PIN"

git -C "$nvim_dir" apply "$ide_dir/patch/kickstart.nvim/updates.patch"

mkdir -p "$nvim_dir/lua/custom/plugins"
rm -f "$nvim_dir/lua/custom/plugins/init.lua"
cp "$ide_dir/config/nvim/lua/custom/plugins/init.lua" "$nvim_dir/lua/custom/plugins/init.lua"
