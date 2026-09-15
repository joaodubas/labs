# Plan: migrate bootstrap tasks to mise file tasks

> Status: implemented on branch `jpd-feat-update-boostrap` (commits `04b8d09..abfac98`).
> Kept as the design record for the `mise/mise/tasks/` layout decision; see
> `docs/mise-bootstrap-migration.md` §11 for the as-built deviations.
>
> Context: follow-up to the comtrya→mise bootstrap migration. An earlier draft
> rejected file tasks on the assumption that they could not participate in the
> variant depends-merge mechanism; empirical tests on mise 2026.9.3 disproved
> that (see "Verified premises" below).

## Goal

Re-host all 34 inline TOML task bodies as mise file tasks under
`provision/mise/tasks/<namespace>/<task>`, keeping the TOML env-layering
mechanism (variant depends-stubs + `bootstrap` aggregators) intact, with a
provably identical task DAG before/after.

## Verified premises (mise 2026.9.3)

- File tasks support dependencies via `#MISE depends=[...]` frontmatter
  (multi-line form allowed).
- Colons in filenames become underscores, so namespaced tasks need
  subdirectories: `mise/tasks/config/mise` → task `config:mise`. Default
  discovery dirs include `mise/tasks/` (alongside the existing `mise.toml`).
- Depends-only TOML stubs in variant files (`mise.linux.toml`) DO merge onto
  same-named file tasks (`tasks info` shows both sources; stub's `depends`
  applies; the file script still runs). The OS-ordering merge mechanism is
  fully preserved.
- `{{ config_root }}` / Tera templating does NOT apply inside file task
  scripts — use `MISE_CONFIG_ROOT` / `MISE_PROJECT_ROOT` env vars instead.

## Decisions (with justification)

- **`bootstrap` aggregators stay in TOML (all three).** Pure `depends` config
  with no body; a file task version would be an empty script. The
  base-then-variant override via `-E` env layering stays untouched.
- **Variant depends-stubs stay in TOML; add two new ones.** Add
  `[tasks."shell:fish"]` stubs to *both* variants (today the full task lives
  in each variant; after migration the body unifies into one file).
- **`scripts/` is migrated and deleted — file tasks supersede it.** The 4
  scripts become the bodies of their file tasks (`git/allowed-signers`,
  `fish/env`, `neovim/kickstart`, `fonts/nerd`). Keeping `scripts/` as an
  exec-target adds double indirection; the old "keep tasks thin, logic in
  `scripts/`" convention inverts — the task file *is* the thin script.
  Document the convention change in the docs addendum.
- **`[vars]` is removed.** After migration no Tera remains anywhere.
  `ide_dir` becomes `ide_dir="$HOME/.local/share/ide"` inline in the ~7
  scripts that need it; the repo URL is hardcoded in `tasks/ide/clone`.
- **De-triplicating bootstrap lists via aggregate tasks: DONE** (branch
  `jpd-feat-update-boostrap`, deferred follow-up batch). It changes the DAG
  *shape* (new aggregate nodes: `user:config`, `linux:system`, `linux:apps`,
  `macos:system`), which is why it was kept out of the migration phases —
  the transitive leaf set before/after is identical (verified via
  `tasks deps` node-set diff).

## Plan

1. **Phase 0 — baseline snapshots (no repo changes).** From `provision/mise/`:
   save `mise -E linux tasks ls`, `mise -E macos tasks ls`,
   `mise -E linux tasks deps bootstrap`, `mise -E macos tasks deps bootstrap`
   output to files under `/tmp/`. These are the diff baselines for every
   later phase.
2. **Phase 0b — in-repo scratch check.** Throwaway `mise/tasks/scratch` file
   task (then delete) to confirm in this exact tree: subdir→colon naming,
   `#MISE depends=[...]` frontmatter applies, `echo "$MISE_CONFIG_ROOT"`
   resolves to `provision/mise/`, and exec-bit handling works through the
   vm.sh tar (still commit task files with the executable bit set).
3. **Phase 1 — no-Tera OS tasks (16 files).** For each, create
   `provision/mise/tasks/<ns>/<name>`: `#!/usr/bin/env bash`,
   `#MISE description="..."` + `#MISE depends=[...]` frontmatter (copied
   verbatim from TOML), `set -euo pipefail`, body copied verbatim. In the
   *same commit*, delete the matching `[tasks."X"]` block from the variant
   TOML (a task defined in both places conflicts). Tasks: `linux/apt-base`,
   `linux/docker`, `linux/flatpak`, `linux/cuda-wsl`, `linux/qemu`,
   `apps/{wezterm,zenbrowser,ghostty,cursor,zed}`,
   `macos/{brew,formulae,casks,containers,stordcli}`, and unified
   `shell/fish`. Commit granularity: one per namespace.
4. **`shell/fish` unification** — the only body rewrite (not a copy). One
   file with `case "$(uname -s)"` branching to
   `sudo usermod --shell /usr/bin/fish "$(id -un)"` (Linux) /
   `sudo chsh -s /opt/homebrew/bin/fish "$(id -un)"` (Darwin). Add
   depends-only stubs to both variants: `mise.linux.toml` →
   `depends = ["linux:apt-base"]`, `mise.macos.toml` →
   `depends = ["macos:formulae"]`. Update each variant's header comment about
   the merge-stub section.
5. **Phase 2 — Tera-using tasks, substitution table:**
   - `{{ config_root }}` → `$MISE_CONFIG_ROOT` (`git:includes`,
     `fish:config`, `linux:cedilla`, and the 4 folded scripts)
   - `{{ xdg_config_home }}` → `config_home="${XDG_CONFIG_HOME:-$HOME/.config}"`
     at the top of each script that needs it
   - `{{ vars.ide_dir }}` → `ide_dir="$HOME/.local/share/ide"` inline;
     `{{ vars.ide_repo_url }}` → literal URL in `tasks/ide/clone`
   - `git:config`'s 11-element `run` array → one script with the 11
     `git config --global` lines in order
6. **Phase 2 task order (paired commits):** (a) `ide/clone` +
   `config/{mise,atuin,starship}` + `tools/cli`; (b)
   `git/{config,includes,allowed-signers}` — folding
   `scripts/git-allowed-signers.sh`; (c) `fish/{config,env}` — folding
   `scripts/fish-env.sh`; (d) `neovim/kickstart` — folding
   `scripts/neovim-kickstart.sh` (keep the error message referencing
   `ide:clone`); (e) `tmux/{config,tpm}` + `tmuxp/sessions`; (f) `fonts/nerd`
   (fold `scripts/nerd-fonts.sh`) + `linux/cedilla`.
7. **Phase 3 — TOML/`scripts/` cleanup.** Delete `provision/mise/scripts/`.
   Remove `[vars]` from `mise.toml`; update header comments. Final state:
   `mise.toml` = `min_version` + `[tasks.bootstrap]` + comments; variants =
   OS `bootstrap` overrides + depends stubs only.
8. **Phase 3b — docs.** Dated addendum in `docs/mise-bootstrap-migration.md`
   (don't rewrite historical sections; note `scripts/` convention is
   superseded). Check `provision/README.md` for `scripts/` references.
   `bootstrap.sh` needs no functional change — optionally tweak its header
   comment.
9. **Verification gate after every phase-commit:** re-run the Phase 0
   commands and diff. Names and dependency edges must be identical; the
   `tasks ls` *Source* column changes by design — compare name/edges, not
   Source. Also run `mise tasks validate` and
   `mise -E linux bootstrap --dry-run` / `-E macos` equivalent.
10. **End-to-end verification:** (a) fresh docker playground
    (`provision/docker-compose.yml` mounts `./mise:/opt/mise` wholesale —
    `tasks/` rides along): `cd /opt/mise && ./bootstrap.sh` twice; second run
    must be a no-op (also proves no extra `mise trust` needed — no new TOML
    files); (b) KVM VM via `provision/vm/vm.sh` — proves the tar includes
    `tasks/` with exec bits; (c) macOS: `MISE_ENV=macos` listing/dry-run on
    Linux; real run manually on hardware per existing strategy.

## Files to modify

- `provision/mise/mise.toml` — delete `[vars]` (L17–20) and all 14 shared
  task blocks (L29–162); keep `min_version`, `[tasks.bootstrap]` (L169–187),
  update header comments.
- `provision/mise/mise.linux.toml` — delete 13 full task blocks; keep 6
  depends stubs (L184–201) + `bootstrap` (L206–236); add
  `[tasks."shell:fish"] depends = ["linux:apt-base"]` stub.
- `provision/mise/mise.macos.toml` — delete 6 full task blocks; keep 6 stubs
  (L70–87) + `bootstrap` (L92–115); add
  `[tasks."shell:fish"] depends = ["macos:formulae"]` stub.
- `provision/mise/scripts/{git-allowed-signers,fish-env,neovim-kickstart,nerd-fonts}.sh`
  — delete (bodies folded into file tasks).
- `docs/mise-bootstrap-migration.md` — addendum section.
- `provision/README.md` — update any `scripts/` references.
- `provision/mise/bootstrap.sh` — comment-only tweak (optional).

## New files

All under `provision/mise/tasks/`, extension-less, executable,
`#!/usr/bin/env bash` + `#MISE` frontmatter + `set -euo pipefail`:

- Shared: `ide/clone`, `config/mise`, `config/atuin`, `config/starship`,
  `tools/cli`, `git/config`, `git/includes`, `git/allowed-signers`,
  `fish/config`, `fish/env`, `neovim/kickstart`, `tmux/config`, `tmux/tpm`,
  `tmuxp/sessions`
- Linux: `linux/{apt-base,docker,flatpak,cuda-wsl,qemu,cedilla}`,
  `apps/{wezterm,zenbrowser,ghostty,cursor,zed}`, `fonts/nerd`
- macOS: `macos/{brew,formulae,casks,containers,stordcli}`
- Cross-OS: `shell/fish` (uname-branched)

## Risks

- **`#MISE` vs `# MISE` formatter footgun:** if a formatter inserts a space,
  frontmatter silently becomes a comment → depends dropped → parallel apt
  chaos (the dpkg-lock serialization the comments depend on). Mitigate: use
  `#MISE` exactly, don't run shfmt/prettier over `tasks/`, rely on the
  per-commit `tasks deps` graph diff as the tripwire.
- **Duplicate definitions:** TOML block and file task coexisting in one
  commit conflicts. Every migration commit pairs the file addition with the
  TOML block deletion — this is the rollback unit (big-bang rejected: three
  environments, sudo-heavy, no macOS VM).
- **`MISE_CONFIG_ROOT` resolution** — assumed to be `provision/mise/`; the
  Phase 0b scratch check confirms before any real task depends on it.
- **`set -euo pipefail` tightening:** TOML multiline blocks didn't have it.
  Audited safe: all `$VAR` uses are already guarded (`${WSL_DISTRO_NAME:-}`,
  `${STORD_WORK:-0}`, `SHELL="${SHELL:-/bin/bash}"`); `grep -q` pipes sit
  inside `if` conditions so pipefail is consumed.
- **`shell:fish` unification** is the only semantic rewrite — extra attention
  in playground (linux) and macOS manual run.
- **bash shebang vs current sh execution** of `run` blocks — bodies are
  POSIX-clean, but verify in playground.
- **Version coupling:** stub-merge and frontmatter behavior verified on
  2026.9.3 only; the `min_version` pin guards this — re-verify on any future
  mise bump.
- **Docs drift:** six places in `docs/mise-bootstrap-migration.md` describe
  the `scripts/` pattern; the addendum (not a rewrite) keeps history honest.
- **`vm.sh` packaging:** tars `provision/mise` recursively so `tasks/` is
  included automatically, but the VM run is the proof.

## Phase 4 (optional, separable): task-configuration improvements

Checked against https://mise.jdx.dev/tasks/task-configuration.html and
verified empirically on the pinned mise 2026.9.3. These change runtime
*behavior* (skip semantics, I/O locking), so they are deliberately NOT part
of the file-task migration phases — apply them after, as their own commits,
each re-running the Phase 9/10 verification gates.

### Recommended

1. ~~**`sources`/`outputs` freshness on the pure file-copy tasks**~~ —
   **REJECTED after empirical testing** (mise 2026.9.3, post-migration):
   - `#MISE` frontmatter in file tasks does NOT expand `$VARS` or `~` in
     `sources`/`outputs` — the paths are stored literally unexpanded
     (verified: `tasks info` shows the raw `$HOME`/tilde string), so
     freshness never triggers.
   - Even with expansion, the copy tasks' sources live under
     `$HOME/.local/share/ide` — outside the project root — so freshness is
     impossible post-migration regardless.
   - `outputs = { auto = true }` without `sources` always runs (verified),
     so it buys nothing either.
   The pre-migration "confirm whether mise expands `~`/env vars" caveat
   above resolved to: it doesn't, and the idea dies with it.
2. **`interactive = true` on sudo-prompting tasks** (`linux:apt-base`,
   `linux:docker`, `shell:fish`, `macos:containers`) — **DONE**. Gives the
   task exclusive stdin/stdout (global lock) so a sudo password prompt isn't
   interleaved with parallel prefixed output. Verified accepted on 2026.9.3.
   Putting it on `apt-base` costs no parallelism — everything already
   serializes behind it.
3. **`usage` env-backed flag for `macos:stordcli`** — **DONE**:
   `flag "--work" env="STORD_WORK" help="work machine opt-in"`. Turns the
   magic env var into a documented CLI interface
   (`mise -E macos run macos:stordcli --work`); env var keeps working
   (verified both paths, plus `STORD_WORK=1`). Any truthy value opts in;
   only unset/empty/`0`/`false` skip. `--work` is parsed per-task, so under
   a full `bootstrap` run only `STORD_WORK` applies.

### Deferred (bundle with the bootstrap de-triplication follow-up) — DONE

4. **`wait_for` for apt-lock-only edges** — **DONE**: `linux:docker` doesn't
   need flatpak's *result*, only non-overlap (dpkg global lock).
   `#MISE wait_for=["linux:flatpak"]` expresses exactly that, so a standalone
   `mise run linux:docker` no longer drags flatpak in. Same for
   `linux:cuda-wsl` vs `linux:docker` and `linux:qemu` vs `linux:cuda-wsl`.
   Identical behavior under full `bootstrap` (everything is scheduled).
   Bundled with the aggregate-task follow-up since both are DAG-shape
   changes; transitive leaf set verified identical before/after.

### Rejected (checked, don't fit)

- `cache` (experimental remote cache) — overkill for provisioning.
- `deny_all`/`allow_*` sandboxing — bootstrap is all sudo + network +
  system-wide writes.
- `timeout` — CUDA (~GB) and brew downloads have unbounded variance;
  false kills mid-bootstrap are worse than hangs.
- `confirm` — fires inside unattended `bootstrap` runs too; the only
  tempting target (`ide:clone`'s `reset --hard`) isn't worth breaking
  automation for.
- `raw` — superseded by `interactive` for the sudo-prompt case.
- `task_config.shell`, `file =` property — superseded by the file-task
  migration (shebang per file).
- `alias` — task names already short.
- `depends_post`, structured `run = [{task=...}]` — no cleanup-chain or
  grouping need today.
