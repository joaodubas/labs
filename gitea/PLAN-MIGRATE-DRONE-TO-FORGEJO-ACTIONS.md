# Migration Plan: Drone CI to Forgejo Actions

**Last Updated:** 2026-01-07
**Status:** Planning Phase
**Dependencies:**
- ✅ [PLAN-MIGRATE-MINIO-TO-SEAWEEDFS.md](./PLAN-MIGRATE-MINIO-TO-SEAWEEDFS.md) must be complete
- ✅ [PLAN-MIGRATE-GITEA-TO-FORGEJO.md](./PLAN-MIGRATE-GITEA-TO-FORGEJO.md) must be complete
- ⏳ [PLAN-GITEA-USE-SEAWEEDFS.md](./PLAN-GITEA-USE-SEAWEEDFS.md) for S3 cache configuration

---

## Context

### Current Setup (Drone CI)
- **Drone Server:** v2.26.0
- **Drone Runner:** Docker v1.8.4
- **Configuration:** `.drone.yml` files in each repository
- **Cache:** `drone-meltwater-cache` plugin with S3 backend (MinIO → SeaweedFS)
- **Secrets:** Managed in Drone UI
- **Triggers:** Gitea webhooks (push, pull_request, tag)

### Target Setup (Forgejo Actions)
- **Forgejo Server:** v13.x / v11.x (LTS)
- **Forgejo Runner:** `forgejo/forgejo-runner` (fork of `act_runner`)
- **Configuration:** `.forgejo/workflows/*.yml` files (GitHub Actions syntax)
- **Cache:** TBA (see Strategy section below)
- **Secrets:** Managed in Forgejo UI (organization/user secrets)
- **Triggers:** Forgejo webhooks (same events)

### Critical Constraint
- **Not a drop-in replacement**: Complete pipeline rewrite required
- **`drone-meltwater-cache` incompatible**: No direct equivalent in Forgejo Actions
- **Plugin ecosystem fragmentation**: Drone plugins → GitHub Actions (or custom actions)

---

## Migration Strategy: Parallel Runner Deployment

Deploy Forgejo runners alongside Drone runners during transition.

### Architecture During Migration

```
┌───────────────────────────────────────────┐
│            Forgejo Server                │
│  ┌──────────────────────────────┐   │
│  │ Forgejo Actions (Built-in)    │   │
│  └───────────┬──────────────┘   │
│                │                     │
│  ┌──────────────▼───────────────┐   │
│  │ ┌──────────┐ ┌──────────┐   │   │
│  │ │ Drone     │ │ Forgejo   │   │   │
│  │ │ Runner    │ │ Runner    │   │   │
│  │ │ Docker:1.8.4│ │ act_runner│   │   │
│  │ └───────────┘ └───────┬───┘   │
│  │                     │           │        │
│  └──────┬────────────┴───────────┘   │
│         │ docker.sock                │
└─────────┼───────────────────────────────┘
          │
  ┌───────▼───────────────────────────┐
  │ SeaweedFS:9000               │
  │ S3 API (Shared Cache Storage)     │
  └───────────────────────────────────┘
```

---

## Prerequisites

Before starting migration:

- [ ] **Forgejo deployed and verified** (Phase 2 complete)
- [ ] **SeaweedFS operational** (Phase 1 complete)
- [ ] **Drone pipeline inventory:** Document all `.drone.yml` files
- [ ] **Critical plugins identified:** List non-standard plugins used
- [ ] **Cache strategy decided:** Choose Option A/B/C/D (see below)
- [ ] **Secrets inventory:** Document all Drone secrets requiring migration
- [ ] **Testing environment:** Ability to run Forgejo Actions on test repos

---

## Pipeline Inventory Template

Before migration, catalog all Drone pipelines:

```markdown
| Repository | Pipeline File | Steps | Plugins Used | Criticality | Complexity |
|-----------|----------------|-------|-------------|---------------|-------------|
| repo1 | .drone.yml | [cache, docker, notify] | Critical | High |
| repo2 | .drone.yml | [build, deploy] | High | Medium |
| ... | ... | ... | ... | ... |
```

**Columns:**
- **Pipeline File:** Path to `.drone.yml`
- **Steps:** Brief description (e.g., "restore cache, build, test")
- **Plugins Used:** List all Drone plugin images (e.g., `meltwater/drone-cache`, `plugins/docker`)
- **Criticality:** Critical (blocking production), High (important), Medium (optional)
- **Complexity:** Simple (1-3 steps), Medium (4-6 steps), High (7+ steps, matrix, triggers)

---

## Cache Strategy

### The Challenge: `drone-meltwater-cache` Replacement

**Current Usage (Drone):**
```yaml
steps:
  - name: restore-cache
    image: meltwater/drone-cache
    settings:
      restore: true
      cache_key: "{{ .Commit.Branch }}-{{ checksum 'go.mod' }}"
      bucket: drone-cache
      endpoint: http://seaweedfs:9000
      path_style: true
      mount:
        - 'vendor'

  - name: build
    image: golang:1.22
    commands:
      - go build -v ./...

  - name: rebuild-cache
    image: meltwater/drone-cache
    settings:
      rebuild: true
      cache_key: "{{ .Commit.Branch }}-{{ checksum 'go.mod' }}"
      bucket: drone-cache
      endpoint: http://seaweedfs:9000
      path_style: true
      mount:
        - 'vendor'
```

**Problem:**
- `drone-meltwater-cache` is a Drone plugin (not a Forgejo Action)
- No direct equivalent in Forgejo Actions marketplace
- Different cache key template syntax (`{{ .Commit.Branch }}` vs `${{ github.ref }}`)

### Options

#### Option A: Built-in `actions/cache` (Runner-Local)

**Best for:** Simple pipelines, single runner scenarios

```yaml
# .forgejo/workflows/build.yml
name: Build
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'

      - name: Cache Go modules
        uses: actions/cache@v4
        with:
          path: |
            ~/.cache/go-build
            ~/go/pkg/mod
          key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
          restore-keys: |
            ${{ runner.os }}-go-

      - name: Build
        run: go build -v ./...
```

**Pros:**
- Native Forgejo Actions support
- Industry standard syntax
- Simple configuration
- No external dependencies

**Cons:**
- **Runner-local cache only** (not shared across runners)
- Multiple runners = multiple independent caches
- Not suitable for large multi-runner setups

**Migration Effort:** Low (1-2 hours per pipeline)

---

#### Option B: S3 Cache Action (Shared via SeaweedFS)

**Best for:** Multi-runner scenarios, shared cache required

**Challenge:** Need to find or fork S3 cache action compatible with SeaweedFS path-style access.

**Example (if compatible action exists):**

```yaml
# .forgejo/workflows/build.yml
name: Build
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Restore cache from S3
        uses: actions/cache-s3@v1  # Hypothetical action
        with:
          endpoint: ${{ secrets.SEAWEDFS_ENDPOINT }}
          access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          bucket: forgejo-cache
          path-style: true
          cache-key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
          restore-keys: |
            ${{ runner.os }}-go-

      - name: Build
        run: go build -v ./...

      - name: Save cache to S3
        uses: actions/cache-s3@v1
        with:
          endpoint: ${{ secrets.SEAWEDFS_ENDPOINT }}
          access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          bucket: forgejo-cache
          path-style: true
          cache-key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
          upload: true
```

**Pros:**
- Shared cache via SeaweedFS
- Consistent behavior with `drone-meltwater-cache`
- Works across multiple runners

**Cons:**
- **Action may not exist** or lack SeaweedFS support
- Need to fork/develop custom action
- Higher maintenance

**Migration Effort:** Medium (2-4 hours per pipeline + action development)

---

#### Option C: Manual S3 Cache Script

**Best for:** Immediate migration, full control over SeaweedFS compatibility

```yaml
# .forgejo/workflows/build.yml
name: Build
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: alpine:3.19
    env:
      SEAWEDFS_ENDPOINT: ${{ secrets.SEAWEDFS_ENDPOINT }}
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      CACHE_KEY: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
      BUCKET: forgejo-cache
    steps:
      - name: Install AWS CLI
        run: |
          apk add --no-cache py3-pip
          pip3 install --no-cache-dir /tmp/pip awscli

      - name: Restore cache from S3
        run: |
          # Check if cache exists
          if aws s3 ls "s3://${BUCKET}/${CACHE_KEY}" \
              --endpoint-url "${SEAWEDFS_ENDPOINT}" \
              --no-sign-request 2>/dev/null; then
            echo "Restoring cache..."
            aws s3 cp "s3://${BUCKET}/${CACHE_KEY}" /tmp/cache.tar.gz \
              --endpoint-url "${SEAWEDFS_ENDPOINT}" \
              --no-sign-request
            tar -xzf /tmp/cache.tar.gz -C ~/
          else
            echo "Cache miss"

      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'

      - name: Build
        run: go build -v ./...

      - name: Save cache to S3
        if: success()
        run: |
          tar -czf /tmp/cache.tar.gz -C ~/ go/
          aws s3 cp /tmp/cache.tar.gz "s3://${BUCKET}/${CACHE_KEY}" \
            --endpoint-url "${SEAWEDFS_ENDPOINT}" \
            --no-sign-request
```

**Pros:**
- Full control over SeaweedFS compatibility
- Explicit `path_style: true` support
- Works with any runner
- No dependency on external action

**Cons:**
- AWS CLI installation overhead (~30s)
- More complex to maintain
- Not reusable (script embedded in workflow)

**Migration Effort:** Medium (2-4 hours per pipeline)

---

#### Option D: Fork `drone-meltwater-cache` as Forgejo Action

**Best for:** Maintaining exact behavior, multi-repo consistency

**Implementation:**

1. **Fork repository:** Create `forgejo-actions/meltwater-cache`
2. **Containerize plugin as action:**

```yaml
# forgejo-actions/meltwater-cache/action.yml
name: 'Meltwater Cache for Forgejo'
description: 'Cache workspace files to/from S3-compatible storage'
inputs:
  action:
    description: 'restore or rebuild'
    required: true
  cache_key:
    description: 'Cache key template'
    required: true
  bucket:
    description: 'S3 bucket name'
    required: true
  endpoint:
    description: 'S3 endpoint URL'
    required: true
  path_style:
    description: 'Path style access'
    required: false
    default: 'false'
  mount:
    description: 'Directories to cache'
    required: true
runs:
  using: 'composite'
  steps:
    - name: Restore cache
      shell: bash
      if: inputs.action == 'restore'
      run: |
        # Call meltwater/drone-cache binary
        docker run --rm \
          -e DRONE_COMMIT_BRANCH="${{ github.ref }}" \
          -e DRONE_COMMIT_SHA="${{ github.sha }}" \
          -e PLUGIN_RESTORE=true \
          -e PLUGIN_CACHE_KEY="${{ inputs.cache_key }}" \
          -e PLUGIN_BUCKET="${{ inputs.bucket }}" \
          -e PLUGIN_ENDPOINT="${{ inputs.endpoint }}" \
          -e PLUGIN_PATH_STYLE="${{ inputs.path_style }}" \
          -e PLUGIN_MOUNT="${{ inputs.mount }}" \
          -v $(pwd):/workspace \
          meltwater/drone-cache:latest

    - name: Rebuild cache
      shell: bash
      if: inputs.action == 'rebuild'
      run: |
        # Call meltwater/drone-cache binary
        docker run --rm \
          -e DRONE_COMMIT_BRANCH="${{ github.ref }}" \
          -e DRONE_COMMIT_SHA="${{ github.sha }}" \
          -e PLUGIN_REBUILD=true \
          -e PLUGIN_CACHE_KEY="${{ inputs.cache_key }}" \
          -e PLUGIN_BUCKET="${{ inputs.bucket }}" \
          -e PLUGIN_ENDPOINT="${{ inputs.endpoint }}" \
          -e PLUGIN_PATH_STYLE="${{ inputs.path_style }}" \
          -e PLUGIN_MOUNT="${{ inputs.mount }}" \
          -v $(pwd):/workspace \
          meltwater/drone-cache:latest
```

3. **Usage in workflow:**

```yaml
# .forgejo/workflows/build.yml
name: Build
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Restore cache
        uses: your-org/meltwater-cache-action@v1
        with:
          action: restore
          cache_key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
          bucket: forgejo-cache
          endpoint: http://seaweedfs:9000
          path_style: true
          mount: |
            ~/go/pkg/mod
            ~/.cache/go-build

      - name: Build
        run: go build -v ./...

      - name: Rebuild cache
        if: success()
        uses: your-org/meltwater-cache-action@v1
        with:
          action: rebuild
          cache_key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
          bucket: forgejo-cache
          endpoint: http://seaweedfs:9000
          path_style: true
          mount: |
            ~/go/pkg/mod
            ~/.cache/go-build
```

**Pros:**
- Maintains exact `drone-meltwater-cache` logic
- Single source for cache configuration
- Reusable across all repositories
- Community contribution potential

**Cons:**
- **Significant development effort** (estimate 1-2 weeks)
- Ongoing maintenance burden
- Requires Docker-in-Docker setup (security complexity)

**Migration Effort:** High (2-4 weeks initial + ongoing maintenance)

---

### Cache Strategy Recommendation

| Scenario | Recommended Option | Rationale |
|----------|--------------------|-----------|
| **Simple pipelines, single runner** | Option A (`actions/cache`) | Lowest effort, native support |
| **Critical multi-runner infrastructure** | Option D (Fork as action) | Consistent behavior, long-term maintainable |
| **Transition period, quick migration** | Option C (Manual script) | Immediate implementation, full control |
| **Low-risk, experimental** | Option B (S3 Action) | If compatible action exists |

**My recommendation:** Start with **Option A** for initial migration. Measure cache hit rates and build times. If shared cache is critical (multi-runner setup), invest in **Option D**.

---

## Migration Steps

### Step 1: Deploy Forgejo Runners

**Objective:** Stand up Forgejo runners alongside Drone runners.

```yaml
# Add to gitea/docker-compose.yml (now gitea/forgejo/docker-compose.yml after Phase 2)
forgejo-runner:
  image: "codeberg.org/forgejo/forgejo-runner:latest"
  hostname: forgejo-runner
  environment:
    FORGEJO_RUNNER_NAME: "forgejo-runner-1"
    FORGEJO_RUNNER_LABELS: "ubuntu-latest:docker"
    FORGEJO_RUNNER_CAPACITY: 2
    FORGEJO_INSTANCE_URL: "http://forgejo:3000"
    FORGEJO_RUNNER_REGISTRATION_TOKEN: ${{ secrets.FORGEJO_RUNNER_TOKEN }}
  volumes:
    - "/var/run/docker.sock:/var/run/docker.sock"
  networks:
    - git_cicd_net
  restart: unless-stopped
  depends_on:
    - forgejo
```

**Get Registration Token:**

1. **Login to Forgejo:** http://localhost:3001
2. **Navigate:** Site Administration → Actions → Runners
3. **Create Runner Token:** Click "New Runner" → Copy token

**Actions:**
```bash
cd gitea  # or forgejo/
docker-compose up -d forgejo-runner
docker-compose logs -f forgejo-runner
```

**Verification:**
- [ ] Runner appears in Forgejo UI (green checkmark)
- [ ] Runner accepts jobs
- [ ] Test workflow executes successfully

---

### Step 2: Migrate Secrets

**From Drone to Forgejo:**

1. **Inventory Drone secrets:**
   ```bash
   # Via Drone CLI
   drone org secrets list your-org --server http://drone:80
   ```

2. **Recreate in Forgejo:**
   - Navigate to Repository → Settings → Secrets and variables → New Secret
   - Or organization secrets for shared secrets

3. **Secret mapping:**
   | Drone Secret | Forgejo Secret | Type |
   |-------------|---------------|------|
   | `aws_access_key` | `AWS_ACCESS_KEY_ID` | Repository |
   | `drone_secret` | `FORGEJO_RUNNER_TOKEN` | Organization |
   | `docker_password` | `REGISTRY_PASSWORD` | Repository |

**Verification:**
- [ ] All secrets accessible in Forgejo UI
- [ ] Secrets referenced in workflows work

---

### Step 3: Pipeline Conversion Framework

**Syntax Mapping: Drone → Forgejo Actions**

| Concept | Drone Syntax | Forgejo Actions Syntax |
|---------|-------------|--------------------|
| **Pipeline trigger** | `trigger: branch: main` | `on: [push: branches: [main]]` |
| **Job steps** | `pipeline:` → `steps:` | `jobs: build: steps:` |
| **Image** | `image: golang:1.22` | `runs-on: ubuntu-latest` + `actions/setup-go@v5` |
| **Commands** | `commands: [go build]` | `run: go build` |
| **Secrets** | `secrets: [api_key]` | `env: API_KEY: ${{ secrets.API_KEY }}` |
| **Environment** | `environment: ENV=value` | `env: ENV=value` |
| **Plugins** | `image: plugin/image` | `uses: actions/action@v1` |
| **Workspace** | Automatic (`/drone/src`) | Automatic (`/workspace`) |
| **Conditionals** | `when: branch: main` | `if: github.ref == 'refs/heads/main'` |
| **Cache key template** | `{{ .Commit.Branch }}-{{ checksum 'go.mod' }}` | `${{ runner.os }}-${{ hashFiles('**/go.sum') }}` |

---

### Step 4: Migrate Simple Pipelines (Iterative)

**Strategy:** Migrate low-risk pipelines first, validate, then move to critical.

**Example Conversion:**

**Original (`.drone.yml`):**
```yaml
kind: pipeline
name: default

trigger:
  branch: main

steps:
  - name: restore-cache
    image: meltwater/drone-cache
    settings:
      restore: true
      cache_key: "{{ .Commit.Branch }}-cache"
      bucket: drone-cache
      endpoint: http://seaweedfs:9000
      path_style: true
      mount:
        - 'vendor'

  - name: build
    image: golang:1.22
    commands:
      - go build -v ./...

  - name: rebuild-cache
    image: meltwater/drone-cache
    settings:
      rebuild: true
      cache_key: "{{ .Commit.Branch }}-cache"
      bucket: drone-cache
      endpoint: http://seaweedfs:9000
      path_style: true
      mount:
        - 'vendor'

  - name: notify
    image: plugins/slack
    settings:
      webhook: https://hooks.slack.com/services/...
      channel: builds
```

**Migrated (`.forgejo/workflows/build.yml` - Option A):**

```yaml
name: Build
on: [push: branches: [main]]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'

      - name: Cache Go modules
        uses: actions/cache@v4
        with:
          path: |
            ~/.cache/go-build
            ~/go/pkg/mod
          key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}

      - name: Build
        run: |
          go build -v ./...

      - name: Notify Slack
        if: always()
        uses: rtCamp/action-slack-notify@v2
        env:
          SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
          SLACK_CHANNEL: builds
          SLACK_ICON_EMOJI: ':white_check_mark:'
          SLACK_COLOR: ${{ job.status }}
```

**Testing:**
1. **Push to test branch:** `git push origin feature/forgejo-migration`
2. **Check Forgejo UI:** Workflow executed successfully
3. **Verify artifacts:** Build outputs accessible
4. **Compare build times:** Similar to Drone

---

### Step 5: Migrate Complex Pipelines (Advanced Features)

**Features to convert:**

#### Matrix Builds

**Drone:**
```yaml
pipeline:
  build:
    matrix:
      GO_VERSION: [1.20, 1.21, 1.22]
      OS: [alpine, debian]
    image: golang:${GO_VERSION}-${OS}
    commands:
      - go version
```

**Forgejo Actions:**
```yaml
strategy:
  matrix:
    go-version: ['1.20', '1.21', '1.22']
    os: ['alpine', 'debian']
runs-on: ubuntu-latest
container:
  image: golang:${{ matrix.go-version }}-${{ matrix.os }}
steps:
  - name: Check version
    run: go version
```

#### Conditional Execution

**Drone:**
```yaml
steps:
  - name: deploy
    image: plugins/docker
    settings:
      repo: myrepo
      when:
        branch: main
        event: push
```

**Forgejo Actions:**
```yaml
steps:
  - name: deploy
    uses: actions/docker-build-push@v2
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    with:
      registry: ghcr.io
      image: myrepo
```

#### Parallel Jobs

**Drone:**
```yaml
pipeline:
  test-suite:
    parallel: true
    image: golang:1.22
    commands:
      - go test ./...
```

**Forgejo Actions:**
```yaml
jobs:
  test-unit:
    runs-on: ubuntu-latest
    steps:
      - run: go test ./...

  test-integration:
    runs-on: ubuntu-latest
    steps:
      - run: go test ./integration/...
```

---

### Step 6: Cut-over (Disable Drone, Enable Forgejo Actions)

**When all pipelines migrated and tested:**

1. **Update Forgejo repository webhooks:**
   - Via UI: Repository → Settings → Webhooks
   - Verify Forgejo Actions trigger on push/PR

2. **Disable Drone webhooks:**
   ```bash
   # Via Drone CLI
   drone repo info your-org/repo --server http://drone:80
   # Then delete webhooks via UI or API
   ```

3. **Stop Drone runners:**
   ```bash
   cd gitea
   docker-compose stop worker
   ```

4. **Monitor Forgejo Actions:**
   - Check first 10 builds execute successfully
   - Verify cache hit rates acceptable
   - Monitor runner resource usage

5. **Retire Drone server (after 1-2 week verification):**
   ```bash
   docker-compose stop ci
   ```

---

## Plugin Equivalents Reference

| Drone Plugin | Forgejo Actions Equivalent | Notes |
|-------------|-------------------------|-------|
| `meltwater/drone-cache` | `actions/cache` or custom | See Cache Strategy section |
| `plugins/docker` | `actions/docker-build-push@v2` | `docker login` required |
| `plugins/docker` (push) | `actions/push-image@v1` | Alternative to docker-build-push |
| `plugins/gcr` | `actions/docker-build-push@v2` + GCR config | |
| `plugins/ecr` | `actions/docker-build-push@v2` + ECR config | |
| `plugins/slack` | `rtCamp/action-slack-notify@v2` | |
| `plugins/email` | `dawidd6/action-send-mail@v3` | |
| `plugins/telegram` | `Appleboy/telegram-action@master` | |
| `plugins/discord` | `appleboy/discord-action@master` | |
| `plugins/git` | `actions/checkout@v4` | Built-in |
| `drillster/drone-s3` | Custom action or `actions/cache-s3` | |
| `plugins/kubernetes` | `actions/k8s-set-context@v1` | |
| `plugins/ssh` | Custom SSH step or `appleboy/ssh-action@master` | |

---

## Data Verification Checklist

For each migrated pipeline:

| Verification | Method |
|------------|--------|
| **Build executes** | Check Forgejo Actions UI for green checkmark |
| **Artifacts produced** | Verify in Forgejo UI → Repository → Actions → Artifacts |
| **Cache works** | Check build logs for "Cache hit/miss" |
| **Build times** | Compare to Drone historical times |
| **Notifications sent** | Verify Slack/email received |
| **Deploys successful** | Verify application updated |

---

## Rollback Plan

### Immediate Rollback (Back to Drone)

If critical pipeline failures within 24 hours:

1. **Re-enable Drone webhooks:**
   ```bash
   drone repo add --server http://drone:80 your-org/repo
   ```

2. **Restart Drone runners:**
   ```bash
   docker-compose start worker
   ```

3. **Verify Drone pipelines** execute successfully

**Note:** Cannot rollback Forgejo Actions pipelines (already rewritten). Must fix issues or continue using Drone.

### Full Rollback (Complete Reversion)

Only if Forgejo migration deemed unsuccessful:

1. **Disable Forgejo Actions:** Disable all `.forgejo/workflows/*.yml`
2. **Continue using Drone:** Keep Drone as primary CI
3. **Archive Forgejo workflow branches:** Delete or push to archive branch

---

## Estimated Timeline

| Week | Task | Effort |
|-------|--------|----------|
| **Week 6-7** | Deploy runners, migrate secrets, simple pipelines | 10 days |
| **Week 8-9** | Migrate complex pipelines, implement cache strategy | 10 days |
| **Week 10** | Testing, cut-over, monitoring | 5 days |

**Total:** 3-4 weeks

**Critical Path:** Runner deployment → Secret migration → Pipeline conversion (by criticality) → Testing → Cut-over

---

## Troubleshooting

### Issue: Runner not accepting jobs

**Cause:** Registration token invalid, runner offline, or labels mismatch

**Solutions:**
1. Verify token in Forgejo UI (not expired)
2. Check runner logs: `docker logs forgejo-runner`
3. Verify `FORGEJO_RUNNER_LABELS` match workflow `runs-on` specification

### Issue: Cache not working (Option A - `actions/cache`)

**Cause:** Path mismatch or cache key not matching

**Solutions:**
1. Verify `path:` in `actions/cache` matches actual directory
2. Check `hashFiles()` pattern matches file location
3. Enable debug logging: `run: | set -x; go build`

### Issue: S3 cache fails (Option C - Manual script)

**Cause:** Incorrect `path_style`, credentials, or bucket permissions

**Solutions:**
1. Verify `--endpoint-url` matches SeaweedFS (no trailing slash)
2. Check bucket permissions in `s3_config.json`
3. Test S3 connection manually:
   ```bash
   aws s3 ls s3://forgejo-cache \
     --endpoint-url "http://seaweedfs:9000" \
     --no-sign-request
   ```

### Issue: Workflow not triggering

**Cause:** Webhook misconfiguration or YAML syntax error

**Solutions:**
1. Check webhook in Forgejo UI → Repository → Settings → Webhooks
2. Verify YAML syntax:
   ```bash
   # Use Forgejo's linter (if available)
   # Or use GitHub Actions syntax checker
   curl -X POST https://lint.github.com/github/validate \
     -d "$(cat .forgejo/workflows/*.yml)"
   ```
3. Check `on:` trigger conditions match actual events

---

## Post-Migration Tasks

- [ ] **Monitor runner health:** CPU, memory, disk usage
- [ ] **Monitor workflow success rate:** Target >95%
- [ ] **Clean up Drone configuration:** Remove `.drone.yml` files after verification
- [ ] **Archive old pipelines:** Move to `.drone.archive/` for reference
- [ ] **Update documentation:** Migration guide, team onboarding
- [ ] **Retire Drone infrastructure:** After 4-week verification period

---

## Best Practices

### 1. Migrate Incrementally
- Start with low-risk, simple pipelines
- Validate thoroughly before moving to critical paths
- Keep Drone operational during transition

### 2. Use Parallel Execution
- Migrate multiple pipelines in parallel phases
- Test non-production branches
- Don't block other migrations on single pipeline issues

### 3. Document Everything
- Maintain mapping: Drone step → Forgejo step
- Track issues and resolutions
- Update this migration plan with learnings

### 4. Monitor Closely
- First week: Check every build
- Second week: Daily review
- Third week: Weekly review until stable

### 5. Communicate with Team
- Notify before webhook changes
- Share testing instructions
- Provide feedback channels

---

## References

- [Forgejo Actions Documentation](https://forgejo.org/docs/latest/user/actions/)
- [GitHub Actions Syntax](https://docs.github.com/en/actions)
- [actions/cache](https://github.com/actions/cache)
- [GitHub Marketplace](https://github.com/marketplace?type=actions)
- [Forgejo Actions Examples](https://codeberg.org/forgejo-examples/forgejo-examples)

---

## Change Log

| Date | Change | Author |
|-------|---------|---------|
| 2026-01-07 | Initial plan created | Sisyphus |
