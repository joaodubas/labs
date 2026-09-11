# Feasibility: migrating local provisioning from Comtrya to mise bootstrap

Status: implemented and verified — green + idempotent on the docker
playground, a full-system KVM VM (Ubuntu 26.04) and a real WSL distro
(Ubuntu 26.04, incl. cuda-wsl). Phase 5 cutover applied: comtrya trees
removed (recoverable from git history, last present at commit `02e4102`).
The macOS port is untested by decision (no spare machine); the macOS
comtrya manifests are likewise recoverable from git history. Phase 0 spike
findings recorded in §7.4.
Scope: the former `provision/comtrya/` (Linux) and `provision/comtrya-macos/`
(macOS) local provisioning, now `provision/mise/`.
`provision/ansible/` + `provision/terraform/` (remote DigitalOcean) are out
of scope.
References:
- https://github.com/comtrya/comtrya-dotfiles
- mise docs — bootstrap: https://mise.jdx.dev/bootstrap.html · CLI:
  https://mise.jdx.dev/cli/bootstrap.html · tasks:
  https://mise.jdx.dev/tasks/toml-tasks.html · environments:
  https://mise.jdx.dev/environments.html (full list with what each covers: §3.1)

## 1. Executive summary / verdict

**Feasible, and recommended — with a phased migration.** The migration is
lower-risk than it sounds because comtrya here is already used mostly as a
"YAML shell-runner": the majority of actions across both trees are
`command.run` wrapping installer scripts, `git config`, `fish set -Ux`, and
privileged setup commands. mise bootstrap tasks can host the exact same
commands, version-pinned global mise tools are a *strict improvement* for CLI tools
(replacing vendor `install.sh` for atuin/starship/zoxide — mise 2026.9.3 has
no `[bootstrap].tools` section, so the realized mechanism is a `tools:cli`
task running `mise use --global`; see §7.4), and a
single `mise.toml` (with OS variants) can unify the two duplicated trees —
finally delivering what `SPEC_PROVISION_MULTI_OS.md` proposed but never
implemented.

What is genuinely lost: comtrya's declarative `file.copy` / `file.download`
actions (they become `cp` / `curl` inside tasks) and `package.install` for apt
(becomes `apt-get` in a sudo task). Nothing in the current setup uses
symlinks, templating, or `when:` conditionals, so no comtrya feature that is
actually *exercised* has no mise-side equivalent.

**Gate before any migration:** mise bootstrap is a young feature. Phase 0 is a
verification spike of the specific capabilities flagged ⚠️ below (offline
planning; confirm against https://mise.jdx.dev/bootstrap.html and the mise
changelog for the pinned version).

## 2. Current state: how comtrya is used today

### 2.1 Inventory

**Linux (`provision/comtrya/`)**

| Manifest | What it does |
|---|---|
| `system-deps.yml` | apt `software-properties-common`, PPAs (fish-4, neovim-unstable), ~70 packages |
| `system-deps/docker.yml` | get.docker.com script, docker group, `docker-model-plugin` (privileged) |
| `system-deps/flatpack.yml` | apt flatpak + flathub remote (privileged) |
| `system-deps/wezterm.yml`, `zenbrowser.yml` | flatpak installs (depend on flatpak) |
| `system-deps/openssl.yml` | builds OpenSSL 1.1.1m from source into `~/.local/lib/ssl` (for Erlang) |
| `system-deps/nerd-fonts.yml` | git clone nerd-fonts; install JetBrainsMono + Go-Mono |
| `system-deps/cuda-wsl.yml` | NVIDIA CUDA 13.0 WSL repo + toolkit (privileged) |
| `cli/mise.yml` | mise via official `install.sh`; downloads mise config from gitea |
| `cli/{atuin,starship,zoxide}.yml` | vendor `install.sh` + config download from gitea |
| `cli/{cursor,zed}.yml` | vendor install scripts (GUI apps) |
| `cli/ghostty.yml` | `snap install --classic ghostty` |
| `user/fish.yml` | `usermod` default shell, copy `config.fish`, 10× `fish set -Ux`, `fish_add_path`, `abbr` |
| `user/git.yml` | 12× `git config --global`, builds `allowed_signers` from `~/.ssh/*.pub`, copies 3 includeIf files |
| `user/neovim.yml` | clone kickstart.nvim @ `3338d39`, apply remote patch, download plugins + mcphub config |
| `user/{tmux,tmuxp}.yml` | download tmux.conf, clone tpm, tmuxp session files |
| `user/cedilla.yml` | `.xsessionrc` append (bash), XCompose copy, `gsettings` ibus override |
| `system-deps/files/{gcloud,onepassword}/install.sh` | **dead code** — referenced by no manifest |

**macOS (`provision/comtrya-macos/`)** — brew-centric

| Manifest | What it does |
|---|---|
| `system-deps.yml` | Homebrew bootstrap script (sudo), shellenv → `.zprofile`, 20 formulae + 12 casks |
| `cli/mise.yml` | `brew install mise` + config download from gitea |
| `cli/container.yml` | brew podman/docker stacks + `podman-mac-helper install` (sudo) |
| `cli/stordcli.yml` | brew tap `stordco/tap` + stordcli (work-specific) |
| `user/fish.yml` | `chsh` → `/opt/homebrew/bin/fish`, same `set -Ux` pattern, mise shims path |
| `user/{git,neovim,tmux+tmuxp,atuin,starship,font}.yml` | same patterns as Linux; fonts via casks; `XDG_CONFIG_HOME`-based paths |

### 2.2 Architecture facts that drive the comparison

1. **Config source of truth is external.** atuin/mise/starship/tmux/tmuxp/
   neovim-plugin/mcphub configs are fetched at apply time over HTTP from
   `gitea.dubas.dev/joao.dubas/ide`. On macOS the 3 git-include files are
   fetched from a *pinned commit* of this repo on GitHub raw; on Linux they are
   copied from the local checkout — a known divergence.
2. **Two parallel trees, ~60% duplicated** (fish/git/neovim near-identical
   modulo paths). The two `SPEC_*.md` docs propose merging via `when:` /
   `os.family` conditionals — **never implemented**. Cross-platform is handled
   by fully separate directory trees today.
3. **mise is already installed by comtrya on both platforms**, `config.fish`
   sources `mise activate fish`, and `MISE_ENV_FILE=.env` is a fish universal
   var. The *runtime* tool list lives in the external ide repo's
   `config/mise/config.toml` — not in this repo.
4. **Action census across both trees:** `command.run` (workhorse), apt
   `package.install` (Linux only), `file.download`, `file.copy`, `file.remove`,
   `git.clone`, `directory.create`, `user.group`. **Not used anywhere:**
   `file.link` (symlinks), content templating, `when:`/OS conditionals.
5. **Invocation is manual** (`cd <tree> && comtrya apply`); testing is the
   docker playground (`ubuntu:24.04` + comtrya baked into the image); **no CI**
   touches provisioning.

## 3. What mise bootstrap offers

mise bootstrap is mise's machine-setup mode, aimed at replacing things like
Brewfiles/ansible-style bootstrappers. The website sketches it via a
`[bootstrap]` config table; the shipped CLI (2026.9.3) is a phased pipeline
instead — §3.1 documents the verified behavior and the mise doc references.
Config surface as originally assessed (findings resolved in §7.4 and §3.1):

| Capability | Description | Confidence |
|---|---|---|
| `[bootstrap] tools = [...]` | Declarative, version-pinnable tool installs from the mise registry/backends (aqua, ubi, asdf, cargo, npm, pipx, go, gem, vfox, spm, curl) — installed by `mise bootstrap` without needing shell activation | **refuted**: no `[bootstrap]` schema in 2026.9.3; the CLI is a phased pipeline (§3.1) — realized via the `tools:cli` task with `mise use --global` (§7.4) |
| `[bootstrap] env_files` | Load env files during bootstrap | high |
| `[bootstrap.tasks.<name>]` with `run` | Shell task definitions; `run` accepts string/array | high |
| Task `depends` | Task DAG (same semantics as core mise tasks) | high |
| Task `sudo` | Privileged execution with password prompt/handling | **refuted**: no task sudo field; `sudo` inline in commands (§7.4) |
| Idempotency/state | Completed bootstrap items tracked and skipped on re-run (unless `--force`); exact keying (name vs config hash) unverified | **partial**: declarative phases skip unchanged state; task-level idempotency is hand-guarded (§8) |
| Per-task OS filter (`os = "linux"` etc.) | OS-conditioned tasks | **refuted**: use `-E` env variants instead (§7.4) |
| Config variants `mise.linux.toml` / `mise.macos.toml` | OS-specific config files layered over the base `mise.toml` | **confirmed**, via the documented `-E/--env` flag (§3.1) |
| CLI: `mise bootstrap [--force] [task...]`, `--dry-run` | Flags per current docs | **settled**: flags differ from the docs page — `--from/--adopt/--only/--skip`, per-phase subcommands; see §3.1 |

Adjacent mise features that matter here: task `dir`/`env`, `run` from scripts,
`[vars]`, and the large tool registry (starship, atuin, zoxide, neovim, tmux,
… are all in the registry — ⚠️ VERIFY exact entries and backends).

**What mise bootstrap deliberately does NOT do:**

- No system package manager abstraction: apt + PPAs, Homebrew *casks*,
  flatpak, snap are not mise backends → they become (sudo) tasks running the
  same commands comtrya runs today.
- No declarative file actions: `file.copy` / `file.download` / `git.clone`
  become `cp` / `curl -fsSL ... -o` / `git clone` in tasks (or a tool install,
  where the download *is* a tool).
- No user/group management action → `usermod`/`chsh`/`groupadd` stay shell
  commands.

### 3.1 How `mise bootstrap` actually works (verified against mise 2026.9.3)

The docs page presents bootstrap through a `[bootstrap]` config table
(`tools` / `env_files` / `tasks`). Phase 0 found that schema doesn't match
the shipped CLI: mise 2026.9.3 implements bootstrap as a **phased
machine-setup pipeline** with its own config keys, lifecycle hooks and — as
its final phase — a user-defined task named `bootstrap`. This section records
the verified behavior (`mise bootstrap --help`) and how this repo maps onto
it.

**The official pipeline** (phases run in order, each only when configured):

1. Linux accounts, then package-manager plugins
2. `pre-packages` hook, then packages via built-in managers
3. Privileged files/directories, system & user services, firewall, Compose
   projects
4. Git repositories, then dotfiles (each with pre/post hooks)
5. Shell activation, macOS defaults & LaunchAgents, Linux user units, user
   settings
6. `pre-tools` hook, versioned tools, `post-tools` hook
7. Package-plugin packages, `post-packages` hook, services requiring tools
8. **the `bootstrap` task, when defined**, then the final hook

**CLI surface** (authoritative source: `mise bootstrap --help`; docs mirror
the same reference):

- `-E, --env <ENV>` — loads `mise.<ENV>.toml` over the base config. This is
  the *documented* OS-variant mechanism this repo relies on for
  `mise.linux.toml` / `mise.macos.toml` (§7.4 finding 2).
- `--from <GIT_URL>`, `--adopt`, `--yes`, `--force-dotfiles` — bootstrap a
  machine directly from a dotfiles git repo, adopt existing state, force
  conflicting dotfile targets.
- `--only <phases>` / `--skip <phases>` — phase selection (e.g.
  `--skip tools,task`, `--only tools`).
- Per-phase subcommands with dry-run support: `status --missing`,
  `packages apply`, `repos status|apply --dry-run`, `dotfiles status`,
  `mise-shell-activate apply --dry-run`, `macos defaults|launchd-agents …`,
  `linux systemd-units …`, `user apply --dry-run`.
- `-C/--cd`, `-j/--jobs`, `--locked`, `-q/-v/--raw`.

**How this repo uses it** (`bootstrap.sh` ends with
`exec mise --env linux|macos bootstrap "$@"`):

- The entrypoint is the official command itself. No pipeline phases are
  configured, so they no-op; everything this repo needs lives in ordinary
  `[tasks.*]`, and the entry DAG is deliberately named `bootstrap` so the
  pipeline picks it up as phase 8. Extra CLI args (`--dry-run`, `--only`,
  `--skip`) are forwarded untouched.
- Task syntax (`run` as string or array, `description`, `depends` merging
  across variant files) — tasks docs:
  https://mise.jdx.dev/tasks/toml-tasks.html (system overview:
  https://mise.jdx.dev/tasks/).
- OS variants via `-E` — environments docs:
  https://mise.jdx.dev/environments.html.
- Tera templating in task strings (`{{ vars.x }}`, `{{ config_root }}`,
  `{{ xdg_config_home }}`) — https://mise.jdx.dev/templates.html.
- `mise use --global` (the `tools:cli` pins) —
  https://mise.jdx.dev/cli/use.html.
- `min_version = "2026.9.3"` guard — configuration docs:
  https://mise.jdx.dev/configuration.html.

**Deliberate scope line.** The hand-written tasks (apt via sudo, `git clone`,
`cp`, `usermod`) intentionally re-implement what native phases could do
declaratively (packages/repos/dotfiles/shell-activation). That was a parity
decision — migrate behavior 1:1 first — and doubles as the evolution path:
move `linux:apt-base` into a packages phase, `ide:clone` + kickstart into a
repos phase, `files/` copies into dotfiles, validating each with the
per-phase `status` / `apply --dry-run` subcommands in the playground before
committing.

**References:**

| Topic | URL |
|---|---|
| Bootstrap feature overview | https://mise.jdx.dev/bootstrap.html |
| Bootstrap CLI (flags, phases, subcommands) | https://mise.jdx.dev/cli/bootstrap.html |
| Tasks (system overview) | https://mise.jdx.dev/tasks/ |
| TOML task syntax (`run`, `depends`) | https://mise.jdx.dev/tasks/toml-tasks.html |
| Environments / `MISE_ENV` / `mise.<ENV>.toml` | https://mise.jdx.dev/environments.html |
| Configuration hierarchy, `min_version` | https://mise.jdx.dev/configuration.html |
| Templates (Tera: `vars`, `config_root`, …) | https://mise.jdx.dev/templates.html |
| `mise use` (tool pins) | https://mise.jdx.dev/cli/use.html |

## 4. Capability-by-capability comparison

| Comtrya feature (as used today) | mise bootstrap equivalent | Verdict |
|---|---|---|
| `package.install` (apt, +PPAs) | sudo task: `add-apt-repository` + `apt-get install -y ...` | loss of declarativeness; same commands; apt idempotent |
| Homebrew formulae/casks (macOS) | task: `brew install` / `brew install --cask`; some formulae become mise `tools` instead | partial gain (formulae→tools), casks stay tasks |
| `command.run` vendor installers (mise/atuin/starship/zoxide/cursor/zed) | `[bootstrap] tools` for CLI tools in registry; tasks for GUI apps (cursor/zed) | **win**: version-pinned, hash-verified, no random install.sh |
| `command.run` (git config, `fish set -Ux`, gsettings, …) | task `run` (same commands) | parity |
| `privileged: true` (usermod, apt, docker, cuda, brew install) | task `sudo` param (⚠️ VERIFY) or `sudo` inside script | parity pending Phase 0 |
| `file.download` (remote configs from gitea) | `curl` in task; or move configs into repo (out of scope) | loss of declarativeness, same behavior |
| `file.copy` (config.fish, git includes, XCompose) | `cp` in task, sources kept in repo under `files/` | parity |
| `git.clone` (kickstart.nvim@pin, tpm, nerd-fonts) | `git clone` in task (same pins) | parity |
| `directory.create`, `user.group` | `mkdir -p`, `groupadd`/`usermod` in sudo task | parity |
| Manifest `depends:` DAG | task `depends` DAG | parity |
| Two parallel trees (Linux/macOS) | one `provision/mise/` with `mise.linux.toml`/`mise.macos.toml` variants (⚠️ VERIFY) or script-level OS guards | **win** — delivers the SPEC goal |
| `manifest_paths` discovery | explicit task names (`linux:apt`, `macos:casks`, …) | parity |
| `when:` / OS conditionals | not used today (SPEC only) — see above | n/a |
| Variables in `Comtrya.yaml` (gitea URLs) | `[vars]` in mise.toml (⚠️ VERIFY) or plain TOML strings | parity |
| Playground docker image with comtrya baked in | same image with mise baked in | parity |

## 5. Pros and cons

### Comtrya (status quo)

**Pros**
- Declarative file actions (`file.copy`/`file.download` with `chmod`) and apt
  `package.install` read clearly in manifests.
- Purpose-built for this job; manifest DAG and variable substitution.
- Already working, on both OSes, with a docker playground.

**Cons**
- Extra tool to install before it can provision anything (bootstrap-the-
  bootstrap: `curl get.comtrya.dev | bash` in the playground image) — mise is
  already a hard dependency of the machine anyway (installed *by* comtrya).
- Effectively a YAML shell-runner in this repo: ~70% of actions are
  `command.run`; the declarative value actually exercised is thin
  (file.copy/download + apt).
- Two duplicated trees; the cross-platform merge (SPEC docs) was designed but
  never implemented — comtrya's `when:`/`os.family` features sit unused.
- Project velocity/maintenance of comtrya is slow compared to mise
  (⚠️ VERIFY current release status).
- No CI validation path.

### mise bootstrap

**Pros**
- One fewer tool: mise is already installed on both platforms and already
  sourced in fish (`mise activate fish` exists) — bootstrap config composes
  with the existing setup instead of sitting next to it.
- `[bootstrap] tools` gives real, version-pinned, registry-backed tool
  installs — strictly better than curl-an-install.sh for
  mise/atuin/starship/zoxide (and friends).
- Unifies the two trees into one config with OS variants — retires ~60%
  duplication and realizes the SPEC docs' goal in a different way.
- Tasks keep the exact same shell commands, so migration risk per manifest is
  mechanical; complex logic already lives in `.sh` scripts (allowed_signers
  build, nerd-fonts) and that pattern extends naturally.
- Actively maintained, single config format (TOML) for tools+env+tasks.

**Cons**
- Bootstrap is a young/experimental feature: API churn risk, semantics
  (sudo, idempotency state, OS filters) need verification (Phase 0).
- Loses declarative file management: every `file.copy`/`file.download`
  becomes imperative `cp`/`curl` — slightly worse readability for those parts.
- No package-manager abstraction: apt/PPA/brew-casks/flatpak/snap stay raw
  commands (they mostly already are on macOS).
- TOML ergonomics for long multi-line scripts are worse than YAML manifests —
  mitigated by putting logic in `scripts/*.sh` and keeping tasks thin.
- Idempotency is now *your* responsibility for shell side effects that aren't
  naturally idempotent (e.g. `.xsessionrc` append — a trap that already exists
  in comtrya form, but comtrya's `file.copy`-based steps were overwrite-safe).

### Option C (for completeness): keep comtrya, implement the SPEC merge

Would fix duplication without tool churn, but keeps the extra tool, keeps
curl-installers, and requires adopting comtrya's `when:`/`os.family` feature
that has gone unused for a year. Recommended only if Phase 0 kills the mise
bootstrap path.

## 6. Feasibility verdict

**Migrate — phased, keeping comtrya in place until parity is proven.**

Rationale: (a) comtrya usage is already imperative under the hood, so the
migration is a re-hosting, not a redesign; (b) mise bootstrap's tool section
and OS-variant config are genuine improvements the comtrya setup can't get;
(c) mise is the one tool guaranteed to exist on every machine this repo
targets (it's installed by the current provisioning itself); (d) the main
uncertainty is mise bootstrap maturity, contained by Phase 0 and by keeping
comtrya as fallback until the parity checklist is green.

## 7. Migration plan

### 7.1 Target layout

```
provision/mise/
  bootstrap.sh            # entrypoint: installs mise if missing, then `mise bootstrap`
  mise.toml               # shared tasks (ide clone, git, fish, neovim, tmux, tmuxp, config copies)
  mise.linux.toml         # OS-specific tasks/vars  (⚠️ VERIFY variant support)
  mise.macos.toml
  scripts/                # thin, idempotent shell scripts for multi-step logic
    git-allowed-signers.sh
    neovim-kickstart.sh
    nerd-fonts.sh
    fish-env.sh           # the 10× set -Ux + fish_add_path + abbr
  files/                  # copied (not linked) at bootstrap time, same as today
    fish/config.fish
    git/{personal_gitea,personal_github,work}
    cedilla/XCompose
```

Notes:
- **Bootstrap-the-bootstrap**: mise cannot install itself. Keep a 2-command
  entrypoint (`bootstrap.sh`): `curl ... mise.jdx.dev/install.sh` (Linux) /
  `brew install mise` (macOS), then `cd provision/mise && mise bootstrap`.
  This replaces comtrya's own install step in the playground image.
- **Config home**: the `[bootstrap]` section lives in *this repo*
  (`provision/mise/`) and is applied by running `mise bootstrap` from that
  directory. The external ide-repo `config/mise/config.toml` continues to be
  the *runtime* config (tools/env for development) and is installed by
  copying from a single local clone of the ide repo (`ide:clone` task — an
  improvement over comtrya's per-file raw HTTP fetches). Bootstrap config
  (one-time machine setup) and runtime config (daily tools) stay cleanly
  separated.
- **Design rule: fish (and anything needed pre-PATH) stays a system package**
  (apt/brew), never a mise tool — a login shell behind mise shims is a
  brickable foot-gun.
- **macOS git includes**: stop fetching the 3 include files from the pinned
  GitHub-raw URL; use the local `files/git/*` like Linux. Fixes the existing
  divergence for free.

### 7.2 File-by-file mapping

**Linux (`provision/comtrya/` → `provision/mise/`)**

| Comtrya manifest | mise bootstrap target |
|---|---|
| `Comtrya.yaml` | `[vars]` (gitea URLs) in `mise.toml` |
| `system-deps.yml` | task `linux:apt-base` (sudo): PPAs + apt-get install |
| `system-deps/docker.yml` | task `linux:docker` (sudo): get.docker.com, groupadd/usermod, docker-model-plugin |
| `system-deps/flatpack.yml` | task `linux:flatpak` (sudo) |
| `system-deps/wezterm.yml` | task `apps:wezterm` (flatpak, depends `linux:flatpak`) |
| `system-deps/zenbrowser.yml` | task `apps:zenbrowser` (flatpak, depends `linux:flatpak`) |
| `system-deps/openssl.yml` | **dropped** — OpenSSL 1.1.1m build no longer needed (decided, §10) |
| `system-deps/nerd-fonts.yml` | task `fonts:nerd` → `scripts/nerd-fonts.sh` |
| `system-deps/cuda-wsl.yml` | task `linux:cuda-wsl` (sudo, guarded by `$WSL_DISTRO_NAME`) |
| `cli/mise.yml` | entrypoint (`bootstrap.sh` installs mise) + task `config:mise` (copy from the local ide clone) |
| `cli/atuin.yml` | global mise tool via task `tools:cli` (pinned, `mise use --global`; see §7.4) + task `config:atuin` (copy from the ide clone); drop `ATUIN_BIN` uvar/PATH entry |
| `cli/starship.yml` | global mise tool via task `tools:cli` + task `config:starship` |
| `cli/zoxide.yml` | global mise tool via task `tools:cli` |
| `cli/cursor.yml` / `cli/zed.yml` | tasks `apps:cursor` / `apps:zed` (vendor scripts — GUI apps, not in registry) |
| `cli/ghostty.yml` | task `apps:ghostty` (`snap install --classic`) |
| `user/fish.yml` | tasks `shell:fish` (sudo usermod), `fish:config` (cp), `fish:env` (script), `fish:abbr` |
| `user/git.yml` | tasks `git:config` (12× git config --global), `git:includes` (cp from files/), `git:allowed-signers` (script) |
| `user/neovim.yml` | task `neovim:kickstart` → `scripts/neovim-kickstart.sh` (pin updated to `626c660` — the old `3338d39` predates the ide repo patch and breaks it; patch + custom plugins from the ide clone). mcphub config **dropped** — `config/mcphub/servers.json` no longer exists in the ide repo |
| `user/tmux.yml` | tasks `tmux:config` (copy from ide clone), `tmux:tpm` (clone) |
| `user/tmuxp.yml` | task `tmuxp:sessions` (copy from ide clone) |
| `user/cedilla.yml` | task `linux:cedilla` (idempotent append — see Risks) |
| `user/files/*` | `provision/mise/files/*` (git includes + XCompose unchanged; `fish/config.fish` is a *unified* variant merging the Linux/macOS originals — behavior preserved per OS, documented in-file) |
| `system-deps/files/openssl/install.sh` | **dropped** along with the task (decided, §10) |
| `system-deps/files/{gcloud,onepassword}/install.sh` | **dropped** (dead code) |

**macOS (`provision/comtrya-macos/` → same `provision/mise/` tree)**

| Comtrya manifest | mise bootstrap target |
|---|---|
| `system-deps.yml` | tasks `macos:brew` (install script, sudo), `macos:formulae` (drops atuin/starship/zoxide — now global mise tools), `macos:casks` |
| `cli/mise.yml` | entrypoint (`brew install mise`) + shared task `config:mise` |
| `cli/container.yml` | task `macos:containers` (brew + sudo `podman-mac-helper`) |
| `cli/stordcli.yml` | task `macos:stordcli` (tap + install) — **opt-in**: script exits early unless `STORD_WORK=1` (decided, §10) |
| `user/fish.yml` | shared `shell:fish`/`fish:config`/`fish:env` tasks; chsh path from OS-variant vars |
| `user/{git,neovim,tmux+tmuxp,atuin,starship}.yml` | shared tasks already defined for Linux (paths via `$HOME/.config`) |
| `user/font.yml` | merged into `macos:casks` |
| git includes from pinned GitHub raw | use local `files/git/*` (fixes divergence) |

**Shared-tool opportunity (both OSes):** atuin, starship, zoxide become
pinned *global* mise tools installed by the shared `tools:cli` task (§7.4
finding 3–4), removing the Linux-vs-macOS split for them entirely — including
their removal from the macOS brew formulae. neovim/tmux/tmuxp stay system
packages by decision (§10), so they remain in the apt/brew tasks.

### 7.3 Phases (each a separate conventional commit; comtrya untouched until Phase 5)

1. **Phase 0 — Spike (decision gate).** Verify, against mise docs/changelog for
   the pinned mise version: `sudo` task param, idempotency/state semantics,
   per-task OS filters vs `mise.linux.toml`/`mise.macos.toml` variants, CLI
   flags (`--force`/`--dry-run`), `[vars]` support, registry entries
   (atuin, starship, zoxide). Prototype a 2-task
   `mise.toml` in the playground container. Update this doc with findings.
   **Exit criteria:** sudo + idempotency semantics confirmed; unification
   option (variants vs guards) chosen; mise version pinned.
2. **Phase 1 — Scaffold.** `provision/mise/{bootstrap.sh,mise.toml,mise.*.toml,scripts/,files/}`
   with entrypoint + `ide:clone`/`config:*` copy tasks only. Run side-by-side with
   comtrya on a real Linux box.
3. **Phase 2 — Tools.** Move CLI tools to pinned global mise tools (atuin,
   starship, zoxide — via the `tools:cli` task, §7.4); adjust `fish:env` to
   drop the now-obsolete `ATUIN_BIN` uvar/PATH.
4. **Phase 3 — User-level tasks.** Port git, fish, neovim, tmux/tmuxp,
   cedilla as shared tasks + scripts; macOS git includes switch to local
   files.
5. **Phase 4 — System-level tasks + unification.** Port sudo tasks (apt/PPA,
   docker, flatpak, fonts, cuda-wsl; brew/formulae/casks/containers/stordcli);
   wire OS variants; drop dead-code scripts during the port.
6. **Phase 5 — Cutover.** Parity checklist green (see §9) → update
   `provision/Dockerfile.playground` (drop comtrya, keep mise) +
   `provision/docker-compose.yml` mount (`./mise:/opt/mise`) +
   `provision/README.md` → delete `provision/comtrya/` and
   `provision/comtrya-macos/` → mark the two SPEC docs as superseded by this
   document (or delete them).

### 7.4 Phase 0 findings (verified against mise 2026.9.3)

The spike (playground container + local binary) settled the ⚠️ markers from
§3 as follows:

1. **No task-level `sudo` field.** Privileged operations use `sudo` inline in
   task commands (the playground user is passwordless; real machines prompt).
2. **No automatic OS-variant config loading.** `mise.linux.toml` /
   `mise.macos.toml` are *not* picked up automatically; `bootstrap.sh`
   layers the variant over the base via `mise --env linux|macos bootstrap`.
3. **No `[bootstrap]` config section** (no `[bootstrap].tools`, no
   `env_files`, no `[bootstrap.tasks]`). The `mise bootstrap` subcommand
   exists and, in its final phase, runs the task named `bootstrap` from the
   loaded config — so the DAG lives in ordinary `[tasks]` and the entry task
   is deliberately named `bootstrap`. Everywhere §7.2 originally said
   "`[bootstrap] tools`", the realized mechanism is the `tools:cli` task.
   (The full CLI behavior — phases, flags, subcommands — is documented in
   §3.1.)
4. **Project `[tools]` are directory-scoped.** A `[tools]` table in
   `provision/mise/mise.toml` would put tools on PATH only inside that
   directory tree; daily shells see the runtime global config copied from
   the local ide clone (which provides zoxide but not atuin/starship). Hence
   `tools:cli` runs `mise use --global atuin@… starship@… zoxide@…`, ordered
   *after* `config:mise` because that task rewrites the global config file on
   every run — the pins are re-added afterwards. Versions are pinned and must
   satisfy the runtime config's `minimum_release_age = "7d"` setting.
5. **Variant task redefinition merges fields.** Re-declaring a task in
   `mise.<os>.toml` with only `depends` adds dependencies without clobbering
   the base `run` — used to order shared tasks after `linux:apt-base` /
   `macos:formulae`.
6. **`[vars]` compose.** Vars may reference other vars via Tera
   (`{{ vars.x }}`). Superseded during implementation: per-URL vars built
   from `gitea_ide_raw` were replaced by a single `ide:clone` task (clone of
   the ide repo into `~/.local/share/ide`) + `ide_dir` var; config tasks copy
   from the clone (atomic per-commit consistency instead of 9 independent
   raw HTTP fetches).

## 8. Risks and mitigations

| Risk | Mitigation |
|---|---|
| mise bootstrap immaturity / API churn | Phase 0 gate; pin mise version; comtrya remains functional fallback until Phase 5 |
| Unverified capabilities (sudo, idempotency, OS variants) | explicit Phase 0 checklist; fallback per item (sudo-in-script, idempotent scripts, OS guards in scripts) |
| Shell-task idempotency traps (`.xsessionrc` append, `.zprofile` brew shellenv append) | write append-once guards (`grep -qF … || echo …`); both traps exist in current comtrya manifests too — fix during port |
| fish universal vars / `chsh` need correct user + fish present | task `depends` ordering (system fish before `shell:fish`/`fish:env`); run bootstrap as the target user |
| Long scripts in TOML | keep tasks thin; logic in `scripts/*.sh` (pattern already proven by openssl) |
| GUI apps (cursor, zed, wezterm, zen, ghostty) not in mise registry | stay vendor-script/flatpak/snap/cask tasks — no regression vs today |
| WSL CUDA task running on non-WSL machines | guard with `$WSL_DISTRO_NAME` (as SPEC docs intended) |
| gitea.dubas.dev / vendor install.sh availability | unchanged dependency either way; note as future work to vendor configs into the repo |
| SSH keys missing on a fresh machine (`git:allowed-signers` needs `~/.ssh/{gitea,github}.pub`) | script warns and skips (exit 0) instead of aborting the DAG; re-run bootstrap after creating the keys; prerequisite also documented in `bootstrap.sh` |
| Playground/CI sudo interactivity | container runs as root (no prompt); macOS runners have passwordless sudo; if task-level `sudo` prompts awkwardly, `sudo` inside scripts |

## 9. Verification strategy

1. **Parity checklist** — table of every comtrya action (§2.1) → its mise
   target → verification command (`which`/`--version`, `git config --global -l`,
   `fish -c 'set -U'`, file existence, `docker info`, `flatpak list`). Must be
   green on Linux before Phase 5; macOS items verified manually.
2. **Idempotency test** — run `mise bootstrap` twice in the playground
   container; second run must be a no-op (per verified state semantics) and
   `diff` of `$HOME` must be stable (procedure in §9.1).
3. **Playground** — the docker playground is the primary test vehicle for the
   Linux side at every phase; concrete procedure and known limitations in
   §9.1.
4. **macOS** — manual run per phase on the real machine (no VM automation
   today); checklist per phase 3+.
5. **Optional CI** — GitHub Actions matrix (ubuntu container + macos runner)
   running `mise bootstrap` on ephemeral environments; catches regressions
   before they reach the real machines.
6. **Rollback** — comtrya trees are deleted only in Phase 5, one commit;
   `git revert` of any phase commit restores comtrya-era state.

### 9.1 Playground test procedure

**Current setup** (`provision/Dockerfile.playground` +
`provision/docker-compose.yml`): `ubuntu:24.04` image with a `playground`
user (docker + sudo groups, NOPASSWD sudoers entry) and comtrya baked in at
build time (`curl -fsSL https://get.comtrya.dev | bash`). Manifests are
bind-mounted at runtime (`./comtrya:/opt/comtrya`) and applied manually by
exec'ing into the container. Only the Linux tree is mounted; macOS is tested
on the real machine.

**Changes the migration requires (phases 0–4):**

- `provision/Dockerfile.playground`: add mise *next to* comtrya so both run
  side by side. Install it system-wide (static binary to `/usr/local/bin` or
  the mise apt repository) rather than running `install.sh` as root — the
  root-scoped default (`/root/.local/...`) is invisible to the `playground`
  user the container runs as. Drop comtrya from the image at Phase 5.
- `provision/docker-compose.yml`: add the new tree to the `playground`
  service mounts, mirroring the existing one: `./mise:/opt/mise`.

**Per-phase playground role:**

| Phase | Playground role |
|---|---|
| 0 | Verify the ⚠️ markers: `sudo` task param, idempotency/state semantics, OS-variant configs; prototype the 2-task `mise.toml` |
| 1 | Scaffold smoke test: entrypoint + `ide:clone`/`config:*` tasks |
| 2–4 | Run `mise bootstrap` after each ported task group; check the affected surface |
| 5 | Rebuild image with mise only; final full run + idempotency test |

**A/B parity baseline** (the strong version of the checklist in this
section): from the same base image, run container A with comtrya
(`comtrya apply`) and container B with mise (`mise bootstrap`), then diff
captured state:

```bash
# inside each container, after provisioning — capture to a file
fish -c 'set -U'
git config --global -l
dpkg --get-selections
ls -laR ~/.config ~/.local/bin 2>/dev/null
```

Every diff between containers must map to a known, intentional change (e.g.
the `ATUIN_BIN` uvar dropped in Phase 2).

**Idempotency check:** run `mise bootstrap` twice in one container; the
second run must be a no-op (per Phase 0-verified state semantics) and a
before/after `diff -r` of `$HOME` must be stable.

**Known container limitations** (true for comtrya today as well — boundaries
of what the playground can prove, not migration regressions):

- **No systemd** → flatpak, snap, and docker-daemon tasks don't fully
  validate in the container; smoke-test only, verify on the real machine.
- **NOPASSWD sudo** hides mise's real sudo/password-prompt behavior — the
  Phase 0 `sudo`-task verification is only partial here; re-confirm on the
  real machine in Phase 1.
- **No macOS coverage** — phases ≥ 3 need a manual run on the real Mac.
- **WSL CUDA task** is guarded out by `$WSL_DISTRO_NAME`, as intended.
- **Network dependency** — the `ide:clone` task fetches `gitea.dubas.dev`
  over git at apply time, so the container needs egress (unchanged from
  comtrya today; now a single clone instead of per-file raw HTTP fetches).

## 10. Decisions and open questions

### Resolved (pre-implementation)

1. **OpenSSL 1.1.1m source build — dropped.** It existed to support an older
   Erlang version that is no longer in use. `system-deps/openssl.yml` and
   `system-deps/files/openssl/install.sh` are not migrated.
2. **Gitea config dependency — kept, via one `git clone`.** The ide repo
   remains the single source of truth (no vendoring). During implementation
   the per-file raw HTTP fetches were replaced by an `ide:clone` task that
   clones/updates `gitea.dubas.dev/joao.dubas/ide` into `~/.local/share/ide`
   and copies configs from it — atomic per-commit consistency, fewer network
   round-trips (asymmetric improvement over comtrya). Side findings: the
   mcphub servers config no longer exists in the ide repo (task dropped);
   possible future direction — moving `provision/` into the ide repo — is
   undecided and out of scope here.
3. **neovim/tmux/tmuxp — system packages.** Stay in the apt (Linux) and brew
   (macOS) tasks; only atuin/starship/zoxide move to mise tools — realized as
   pinned *global* tools via the `tools:cli` task, because mise 2026.9.3 has
   no `[bootstrap].tools` and project `[tools]` are directory-scoped (§7.4).
4. **`stordcli` — opt-in, work machines only.** Ported as an env-var-guarded
   task (`STORD_WORK=1`): the script exits early when unset, so default
   `mise bootstrap` runs skip it.
5. **macOS — no pre-testing, full removal.** No spare machine was available,
   so the macOS port (brew tasks, shared user tasks) is verified by review
   only. `provision/comtrya-macos/` was removed at cutover together with the
   Linux tree; both are recoverable from git history (last present at
   commit `02e4102`). The two SPEC docs
   (`SPEC_PROVISION_MULTI_OS.md`, `CROSS_PLATFORM_SPECIFICATION.md`) lived
   inside `provision/comtrya/` and are superseded by this document.

### Open (resolved by Phase 0 unless noted)

1. Per-task OS filters vs `mise.linux.toml`/`mise.macos.toml` variants.
2. `MISE_ENV_FILE=.env` uvar + `env_files` interplay — confirm bootstrap
   `env_files` doesn't conflict with the runtime `.env` pattern.
3. Does mise have (or plan) a brew backend? Informational only — would
   simplify `macos:formulae` marginally; casks remain tasks regardless.
