# Migration Overview: Gitea/Drone to Forgejo/Forgejo Actions with SeaweedFS

**Last Updated:** 2026-01-07
**Status:** Planning Phase

---

## Executive Summary

This document outlines the migration from the current infrastructure to a consolidated, open-source, community-maintained stack:

| Component | Current | Target | Motivation |
|-----------|---------|--------|-------------|
| **VCS** | Gitea v1.25.2 | Forgejo v13.x/v11.x (LTS) | Licensing concerns, community governance |
| **CI/CD** | Drone CI v2.26.0 | Forgejo Actions | Drone not maintained by Harness; industry standard syntax |
| **Storage** | MinIO | SeaweedFS | Improved small-file performance, S3-compatible consolidation |

**Key Principles:**
1. **Phased migration** - Each component migrated sequentially to minimize risk
2. **Foundation first** - Storage layer migrated before CI/VCS changes
3. **Parallel operation** - Keep systems running during transition
4. **Rollback paths** - Documented rollback for each phase

---

## Architecture: Before & After

### Current Architecture (Gitea + Drone + MinIO)

```
┌───────────────────────────────────────────┐
│                   External Access         │
│  ┌──────────────┐  ┌──────────────┐       │
│  │ Gitea:3000   │  │ Drone:80     │       │
│  │ v1.25.2      │  │ v2.26.0      │       │
│  │              │  │              │       │
│  └──────┬───────┘  └───────┬──────┘       │
│         │                  │              │
│         │ git_data         │ ci_data      │
│         │                  │              │
│  ┌──────▼───────┐  ┌───────▼───────┐      │
│  │ MinIO:9000   │  │ Drone Runner  │      │
│  │ Cache/Storage│  │ Docker:1.8.4  │      │
│  │              │  │               │      │
│  └──────────────┘  └───────┬───────┘      │
│                            │              │
│                            │ docker.sock  │
└────────────────────────────▼──────────────┘
                             │
                      minio_data volume
```

### Target Architecture (Forgejo + Forgejo Actions + SeaweedFS)

```
┌──────────────────────────────────────┐
│           External Access            │
│  ┌────────────────────────────────┐  │
│  │    Forgejo:3000                │  │
│  │    v13.x / v11.x (LTS)         │  │
│  │                                │  │
│  │    ┌──────────────────────┐    │  │
│  │    │ Forgejo Actions      │    │  │
│  │    │ Built-in             │    │  │
│  │    └───────────┬──────────┘    │  │
│  │                │               │  │
│  │    ┌───────────▼──────────┐    │  │
│  │    │ Forgejo Runner       │    │  │
│  │    │ act_runner (fork)    │    │  │
│  │    └───────────┬──────────┘    │  │
│  └────────────────┼───────────────┘  │
│                   │                  │
│  ┌────────────────▼───────────────┐  │
│  │    SeaweedFS:9000              │  │
│  │    S3 Gateway                  │  │
│  │                                │  │
│  │    ┌──────────────────────┐    │  │
│  │    │ Master               │    │  │
│  │    ├──────────────────────┤    │  │
│  │    │ Filer                │    │  │
│  │    ├──────────────────────┤    │  │
│  │    │ Volume Server        │    │  │
│  │    └──────────────────────┘    │  │
│  └────────────────┬───────────────┘  │
└───────────────────┼──────────────────┘
                    │
          seaweedfs_data volume
```

**Differences:**
- **Single CI system**: Forgejo Actions built into Forgejo (no separate Drone server)
- **S3-compatible storage**: Both Forgejo and cache actions use SeaweedFS
- **Consolidated auth**: Single OAuth/token for code + CI + artifacts

---

## Migration Phases (High-Level)

### Phase 1: Storage Foundation (MinIO → SeaweedFS)

**Status:** ⏳ Pending
**Priority:** CRITICAL (Do First)
**Risk:** Low
**Duration:** 2-3 days
**Effort:** Low

**Objective:** Replace MinIO with SeaweedFS as S3-compatible storage backend.

**Why First:**
- Both Drone (transitional) and Forgejo (target) use S3-compatible storage
- Cache plugins work with SeaweedFS (requires `path_style: true`)
- Lowest risk migration; isolates storage layer from VCS/CI changes
- Existing MinIO data can be lost (cache/artifacts - acceptable)

**Deliverables:**
- [ ] SeaweedFS service running in `gitea/docker-compose.yml`
- [ ] MinIO service removed
- [ ] Buckets provisioned: `gitea`, `drone-cache`, `forgejo-cache`, `k3d-registry`
- [ ] Drone cache using SeaweedFS (`drone-meltwater-cache` updated)
- [ ] SeaweedFS monitoring configured (Prometheus targets added)

**📋 Detailed Plan:** See [PLAN-MIGRATE-MINIO-TO-SEAWEEDFS.md](./PLAN-MIGRATE-MINIO-TO-SEAWEEDFS.md)

**Rollback:** Stop SeaweedFS, restart MinIO, restore `minio_data` volume (if backed up)

---

### Phase 2: VCS Migration (Gitea → Forgejo)

**Status:** ⏳ Pending
**Priority:** HIGH
**Risk:** Medium
**Duration:** 1-2 weeks
**Effort:** Medium

**Objective:** Migrate from Gitea v1.25.2 to Forgejo while maintaining data continuity.

**Why Second:**
- Forgejo Actions require Forgejo server (not Gitea)
- Must run Forgejo in parallel to test Actions migration
- Cannot fully validate Forgejo Actions without Forgejo running

**Critical Constraint:**
- **No direct upgrade path** from Gitea 1.25.2 to Forgejo
- Database schemas incompatible beyond Gitea v1.22
- Must use API-based "pull" migration via Forgejo importer

**Deliverables:**
- [ ] Forgejo instance deployed (port 3001 for parallel operation)
- [ ] Repositories migrated via Forgejo importer (Gitea API)
- [ ] Users migrated (accounts created, SSH keys copied)
- [ ] External auth providers reconfigured (OIDC, etc.)
- [ ] Forgejo configured to use SeaweedFS
- [ ] DNS/load balancer updated to point to Forgejo
- [ ] Gitea instance retired (kept in standby during transition period)

**📋 Detailed Plan:** See [PLAN-MIGRATE-GITEA-TO-FORGEJO.md](./PLAN-MIGRATE-GITEA-TO-FORGEJO.md) *(To be created)*

**Rollback:** Point DNS back to Gitea, continue using Drone (still functional)

---

### Phase 3: CI/CD Migration (Drone → Forgejo Actions)

**Status:** ⏳ Pending
**Priority:** HIGH
**Risk:** High
**Duration:** 2-4 weeks
**Effort:** Very High

**Objective:** Migrate all Drone CI pipelines to Forgejo Actions (GitHub Actions syntax).

**Why Last:**
- Most complex and time-consuming phase
- Requires complete pipeline rewrite (`.drone.yml` → `.forgejo/workflows/*.yml`)
- Cannot fully test until Forgejo is live
- Keep Drone as fallback during transition period

**Key Challenge: `drone-meltwater-cache` Replacement**

Current setup uses `drone-meltwater-cache` plugin for S3 caching. **No direct equivalent in Forgejo Actions.**

**Cache Strategy Options:**

| Option | Description | Effort | Pros | Cons |
|---------|-------------|----------|-------|-------|
| **A. `actions/cache`** | Use built-in Forgejo cache action | Low | Industry standard; runner-local cache only | No cross-runner cache sharing |
| **B. S3 Cache Action** | Use community S3 cache action | Medium | Shared cache via SeaweedFS | Need to find SeaweedFS-compatible action |
| **C. Manual S3 Script** | Custom shell script with AWS CLI | Medium | Full control, explicit path-style | Higher maintenance, AWS CLI installation |
| **D. Fork as Action** | Containerize `drone-meltwater-cache` logic | High | Maintains exact behavior, single source | Development burden on you |

**Recommendation:** Start with **Option A** for simple pipelines. Use **Option C or D** for critical multi-runner scenarios.

**Deliverables:**
- [ ] Forgejo Runners deployed (alongside Drone runners initially)
- [ ] Critical pipelines migrated to `.forgejo/workflows/*.yml`
- [ ] Cache strategy implemented (choose Option A/B/C/D per pipeline)
- [ ] Secrets migrated to Forgejo UI
- [ ] Pipeline execution tested and verified
- [ ] DNS/registration switched to disable Drone, enable Forgejo Actions
- [ ] Drone instance retired

**📋 Detailed Plan:** See [PLAN-MIGRATE-DRONE-TO-FORGEJO-ACTIONS.md](./PLAN-MIGRATE-DRONE-TO-FORGEJO-ACTIONS.md) *(To be created)*

**Rollback:** Re-enable Drone webhooks, continue using Drone (no data loss, but no rollback for rewritten pipelines)

---

## Risk Matrix

| Phase | Risk Level | Key Risks | Mitigation |
|--------|-------------|-------------|-------------|
| **Phase 1: Storage** | 🟢 Low | - SeaweedFS complexity (4 components vs MinIO's 1)<br>- S3 API incompatibilities | - Follow existing detailed plan<br>- Test with `drone-meltwater-cache` first<br>- Enable Prometheus monitoring |
| **Phase 2: VCS** | 🟡 Medium | - No direct upgrade path (Gitea 1.25.2)<br>- Database incompatibility<br>- API differences<br>- CI/CD integration break | - API-based migration (not DB dump)<br>- Parallel deployment (Gitea + Forgejo)<br>- Gradual DNS switch<br>- Keep Drone as fallback |
| **Phase 3: CI/CD** | 🔴 High | - Complete pipeline rewrite<br>- `drone-meltwater-cache` no equivalent<br>- Plugin ecosystem fragmentation<br>- Testing without production data | - Migrate critical pipelines first<br>- Keep Drone as fallback<br>- Implement cache strategy per pipeline<br>- Extensive testing before cut-over |
| **Overall** | 🟡 Medium | - Cumulative risk of multiple migrations<br>- Operational overhead during transition | - Phased approach isolates failures<br>- Parallel operation ensures continuity<br>- Documented rollback for each phase |

---

## Timeline

```
Week 1-2:  Phase 1 - Storage
├─ Day 1-2:   Deploy SeaweedFS, configure buckets
├─ Day 3-4:   Update Drone cache, test cache restore/rebuild
├─ Day 5-7:   Monitor, fix issues, verify stable operation
└─ Day 8-10:  Decommission MinIO

Week 3-4:  Phase 2 - VCS Migration
├─ Week 3:     Deploy Forgejo parallel, migrate critical repos
├─ Week 4:     Migrate remaining repos, configure auth, test
└─ Week 5:     DNS switch, Gitea retirement

Week 6-10: Phase 3 - CI/CD Migration
├─ Week 6-7:   Deploy Forgejo runners, migrate simple pipelines
├─ Week 8-9:   Migrate complex pipelines, implement cache strategy
├─ Week 10:      Testing, verification, Drone cut-over
└─ Week 11:      Cleanup, documentation, full retirement of old stack
```

**Total Estimated Duration:** 11 weeks

**Critical Path:** Phase 1 → Phase 2 → Phase 3 (sequential dependencies)

**Parallel Opportunities:**
- Week 3: Can start migrating simple pipelines to Forgejo Actions while testing Forgejo deployment
- Phase 3 testing can overlap with Phase 2 for low-risk pipelines

---

## Dependencies Between Phases

```
Phase 1 (SeaweedFS)
    ↓
    Must complete before Phase 2 (Forgejo S3 config)
    Must complete before Phase 3 (Cache strategy relies on SeaweedFS)

Phase 2 (Forgejo)
    ↓
    Must complete before Phase 3 (Forgejo Actions require Forgejo)
    Can start Phase 3 for simple pipelines during Phase 2 (parallel)

Phase 3 (Forgejo Actions)
    ↓
    Dependent on Phase 1 (S3 cache)
    Dependent on Phase 2 (Forgejo server)
```

---

## Pre-Migration Checklist

Before starting any phase:

- [ ] **Backup Strategy**: Automated backups configured for all data volumes
- [ ] **Rollback Plan**: Documented and tested for each phase
- [ ] **Monitoring**: Grafana/Prometheus dashboards ready for SeaweedFS
- [ ] **Documentation**: Existing `.drone.yml` pipelines cataloged
- [ ] **Stakeholders**: Team notified of planned downtime windows
- [ ] **Testing Environment**: Ability to test migrations without affecting production

---

## Post-Migration Verification

For each phase completion:

### Phase 1 (SeaweedFS)
- [ ] All services using SeaweedFS successfully
- [ ] Cache restore/rebuild working in Drone pipelines
- [ ] Prometheus metrics available and healthy
- [ ] No MinIO dependencies remaining in configuration

### Phase 2 (Forgejo)
- [ ] All repositories accessible on Forgejo
- [ ] SSH cloning works
- [ ] Git LFS objects accessible via SeaweedFS
- [ ] User accounts functional, external auth working
- [ ] Old Gitea instance in standby state

### Phase 3 (Forgejo Actions)
- [ ] All pipelines execute successfully
- [ ] Cache strategy working (S3 or runner-local)
- [ ] Build times comparable or improved vs Drone
- [ ] Artifacts and logs accessible in Forgejo UI
- [ ] Drone instance fully retired

---

## Detailed Plans

### Storage Migration
- **File:** [PLAN-MIGRATE-MINIO-TO-SEAWEEDFS.md](./PLAN-MIGRATE-MINIO-TO-SEAWEEDFS.md)
- **Scope:** MinIO → SeaweedFS replacement
- **Includes:** Docker Compose configuration, bucket provisioning, SeaweedFS S3 config, Prometheus setup

### Gitea to SeaweedFS Configuration
- **File:** [PLAN-GITEA-USE-SEAWEEDFS.md](./PLAN-GITEA-USE-SEAWEEDFS.md)
- **Scope:** Gitea S3 storage configuration
- **Includes:** Environment variables, bucket setup, LFS/attachment configuration, rollback procedures

### VCS Migration (To Be Created)
- **File:** [PLAN-MIGRATE-GITEA-TO-FORGEJO.md](./PLAN-MIGRATE-GITEA-TO-FORGEJO.md) *(planned)*
- **Scope:** Gitea → Forgejo migration via API
- **Will Include:** Deployment, repository migration, user migration, DNS switching, rollback

### CI/CD Migration (To Be Created)
- **File:** [PLAN-MIGRATE-DRONE-TO-FORGEJO-ACTIONS.md](./PLAN-MIGRATE-DRONE-TO-FORGEJO-ACTIONS.md) *(planned)*
- **Scope:** Drone → Forgejo Actions pipeline migration
- **Will Include:** Runner deployment, cache strategy, `.drone.yml` to `.forgejo/workflows/*.yml` conversion, plugin equivalents

---

## Decision Summary

### Why This Migration Path?

1. **Storage First** → Foundation layer benefits both transitional (Drone) and target (Forgejo)
2. **VCS Second** → Forgejo Actions require Forgejo; cannot test Actions without Forgejo
3. **CI Last** → Most complex rewrite; full testing only possible after VCS migration

### Why Not Woodpecker/Crow?

- **Not drop-in replacements**: Both require pipeline syntax changes, plugin replacements
- **`drone-meltwater-cache` incompatible**: Would need fork or replacement anyway
- **No strategic benefit**: Still separate CI system (same operational complexity as Drone)

### Why Forgejo Actions?

- **Industry standard**: GitHub Actions syntax widely known, community support
- **Reduced maintenance**: One system (Forgejo) instead of three (Gitea + Drone + MinIO)
- **Centralized management**: Code, pipelines, secrets, artifacts in single UI

---

## Next Steps

1. **Review this overview** with team and stakeholders
2. **Validate timeline** based on resource availability
3. **Execute Phase 1** (SeaweedFS deployment) - low risk, quick win
4. **Create detailed plans** for Phases 2 & 3 based on pipeline inventory
5. **Begin Phase 2** after Phase 1 verification

---

## Change Log

| Date | Change | Author |
|-------|---------|---------|
| 2026-01-07 | Initial migration overview created | Sisyphus |

---

## References

- [SeaweedFS Documentation](https://github.com/chrislusf/seaweedfs)
- [Forgejo Documentation](https://forgejo.org/docs/latest/)
- [Forgejo Actions](https://forgejo.org/docs/latest/user/actions/)
- [GitHub Actions Syntax](https://docs.github.com/en/actions)
- [drone-meltwater-cache](https://github.com/drone-plugins/drone-meltwater-cache)
