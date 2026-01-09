# Infrastructure Migration: Gitea/Drone to Forgejo/SeaweedFS

**Overview:** Complete migration from current CI/CD stack to consolidated, open-source infrastructure.

---

## Quick Start

**What's changing:**
- **VCS:** Gitea v1.25.2 → Forgejo v13.x/v11.x (LTS)
- **CI/CD:** Drone CI v2.26.0 → Forgejo Actions (built-in)
- **Storage:** MinIO → SeaweedFS (S3-compatible)

**Why migrate:**
- Drone lack of maintenance by Harness
- Gitea licensing concerns (MIT under corporate control → GPLv3+ community-governed)
- Industry standard CI/CD (GitHub Actions syntax)
- Reduced maintenance surface (3 systems → 2 systems)
- Centralized management (code, pipelines, secrets, artifacts in one UI)

---

## Migration Phases (Summary)

### Phase 1: Storage Foundation (MinIO → SeaweedFS)
- **Duration:** 2-3 days
- **Risk:** 🟢 Low
- **Status:** ⏳ Pending
- **Link:** [Detailed Plan](./PLAN-MIGRATE-MINIO-TO-SEAWEEDFS.md)

**Objective:** Replace MinIO with SeaweedFS as S3-compatible storage backend.

**Key Deliverables:**
- Deploy SeaweedFS in `docker-compose.yml`
- Configure S3 identities (gitea, drone, forgejo, k3d)
- Update Drone cache (`drone-meltwater-cache`) to use SeaweedFS
- Configure Prometheus monitoring
- Decommission MinIO

---

### Phase 2: VCS Migration (Gitea → Forgejo)
- **Duration:** 1-2 weeks
- **Risk:** 🟡 Medium
- **Status:** ⏳ Pending
- **Link:** [Detailed Plan](./PLAN-MIGRATE-GITEA-TO-FORGEJO.md)

**Objective:** Migrate from Gitea v1.25.2 to Forgejo while maintaining data continuity.

**Key Deliverables:**
- Deploy Forgejo instance (port 3001 for parallel operation)
- Migrate repositories via Forgejo importer (Gitea API)
- Migrate users and SSH keys
- Reconfigure external authentication providers (OIDC, LDAP, etc.)
- Configure Forgejo to use SeaweedFS
- Switch DNS/load balancer to point to Forgejo
- Retire Gitea instance (1-2 week standby)

**Critical Constraint:**
- No direct upgrade path from Gitea 1.25.2 to Forgejo
- Database incompatibility (cannot restore SQL dump)
- Must use API-based "pull" migration

---

### Phase 3: CI/CD Migration (Drone → Forgejo Actions)
- **Duration:** 2-4 weeks
- **Risk:** 🔴 High
- **Status:** ⏳ Pending
- **Link:** [Detailed Plan](./PLAN-MIGRATE-DRONE-TO-FORGEJO-ACTIONS.md)

**Objective:** Migrate all Drone CI pipelines to Forgejo Actions (GitHub Actions syntax).

**Key Deliverables:**
- Deploy Forgejo Runners (alongside Drone runners initially)
- Migrate critical pipelines to `.forgejo/workflows/*.yml`
- Implement cache strategy (replace `drone-meltwater-cache`)
- Migrate secrets from Drone UI to Forgejo UI
- Cut over webhooks from Drone to Forgejo
- Retire Drone infrastructure (after 1-2 week verification)

**Major Challenge:**
- `drone-meltwater-cache` plugin has no direct equivalent in Forgejo Actions
- Must choose cache strategy: Runner-local (`actions/cache`), S3-compatible action, or manual script

---

## Migration Timeline

```
Phase 1: Storage Foundation (MinIO → SeaweedFS)
└─ Week 1-2 (2-3 days total)
   ├─ Deploy SeaweedFS, configure buckets
   ├─ Update Drone cache to use SeaweedFS
   ├─ Test cache restore/rebuild
   ├─ Configure Prometheus monitoring
   └─ Decommission MinIO

Phase 2: VCS Migration (Gitea → Forgejo)
└─ Week 3-4 (1-2 weeks total)
   ├─ Deploy Forgejo instance (port 3001)
   ├─ Migrate repositories via API
   ├─ Migrate users and SSH keys
   ├─ Configure external auth providers
   ├─ Configure SeaweedFS storage
   ├─ Test functionality parallel to Gitea
   ├─ Switch DNS to Forgejo
   └─ Retire Gitea (1-2 week standby)

Phase 3: CI/CD Migration (Drone → Forgejo Actions)
└─ Week 6-10 (2-4 weeks total)
   ├─ Deploy Forgejo runners
   ├─ Migrate simple pipelines (low criticality)
   ├─ Implement cache strategy per pipeline
   ├─ Migrate complex pipelines (high criticality)
   ├─ Migrate secrets to Forgejo UI
   ├─ Test workflows extensively
   ├─ Cut over webhooks (Disable Drone, Enable Forgejo Actions)
   └─ Retire Drone infrastructure
```

**Total Estimated Duration:** 11 weeks
**Critical Path:** Phase 1 → Phase 2 → Phase 3 (sequential dependencies)

---

## Architecture Comparison

### Current Stack (3 Systems)
```
┌──────────────────────────────────────────────┐
│ Gitea v1.25.2 │ Drone v2.26.0 │ MinIO    │
│ Code VCS         │ CI/CD Server      │ S3 Storage │
│ (SQLite)         │ (SQLite)           │ Cache/Obj  │
└───────────┬───────┘ └───────┬───────┘ └────────┘
          │                    │
    git_data vol          ci_data vol       minio_data vol
```

### Target Stack (2 Systems)
```
┌──────────────────────────────────────────────┐
│         Forgejo v13.x/v11.x (LTS)         │
│    ┌────────────────────────────────┐   │
│    │    Forgejo Actions (Built-in)    │   │
│    │    Built-in CI/CD                │   │
│    └───────────┬──────────────────┘   │
│                  │                     │
│         ┌───────────────────────────────┐   │
│         │ SeaweedFS S3 API             │   │
│         │ Master │ Filer │ Volume     │   │
│         └───────────────────────────────┘   │
└───────────────────┬─────────────────────────┘
                  │
         seaweedfs_data volume
```

**Benefits:**
- **Single CI system** (Forgejo Actions built-in vs separate Drone server)
- **Industry standard** (GitHub Actions syntax)
- **S3-compatible storage** (SeaweedFS works with both Forgejo and cache actions)
- **Consolidated auth** (single UI for code + CI + secrets)

---

## Risk Summary

| Phase | Risk Level | Mitigation |
|--------|-------------|-------------|
| **Phase 1: Storage** | 🟢 Low | Documented plan, rollback exists, cache loss acceptable |
| **Phase 2: VCS** | 🟡 Medium | Parallel deployment (Gitea + Forgejo), gradual DNS switch, API-based migration |
| **Phase 3: CI/CD** | 🔴 High | Incremental pipeline migration, Drone as fallback, cache strategy testing |

---

## Quick Links to Detailed Plans

### Phase 1: Storage Migration
- **File:** [PLAN-MIGRATE-MINIO-TO-SEAWEEDFS.md](./PLAN-MIGRATE-MINIO-TO-SEAWEEDFS.md)
- **Scope:** MinIO → SeaweedFS replacement
- **Includes:** Docker Compose, bucket provisioning, S3 configuration, Prometheus setup

### Phase 2: VCS Migration
- **File:** [PLAN-MIGRATE-GITEA-TO-FORGEJO.md](./PLAN-MIGRATE-GITEA-TO-FORGEJO.md)
- **Scope:** Gitea → Forgejo migration via API
- **Includes:** Deployment, repository migration, user migration, DNS switching, rollback

### Phase 3: CI/CD Migration
- **File:** [PLAN-MIGRATE-DRONE-TO-FORGEJO-ACTIONS.md](./PLAN-MIGRATE-DRONE-TO-FORGEJO-ACTIONS.md)
- **Scope:** Drone → Forgejo Actions pipeline migration
- **Includes:** Runner deployment, cache strategy, pipeline conversion, plugin equivalents

### Forgejo S3 Configuration
- **File:** [PLAN-GITEA-USE-SEAWEEDFS.md](./PLAN-GITEA-USE-SEAWEEDFS.md)
- **Scope:** Forgejo S3 storage configuration for SeaweedFS
- **Includes:** Environment variables, bucket setup, LFS/attachment configuration

---

## Decision Rationale

### Why This Order?

1. **Storage First (Phase 1):**
   - Foundation layer benefits both transitional (Drone) and target (Forgejo)
   - Both Drone and Forgejo use S3-compatible storage
   - `drone-meltwater-cache` works with SeaweedFS (requires `path_style: true`)
   - Lowest risk migration; isolates storage layer from VCS/CI changes

2. **VCS Second (Phase 2):**
   - Forgejo Actions require Forgejo server (not Gitea)
   - Cannot fully test Forgejo Actions without Forgejo running
   - Must run Forgejo in parallel to Gitea during transition

3. **CI/CD Last (Phase 3):**
   - Most complex and time-consuming phase
   - Requires complete pipeline rewrite (`.drone.yml` → `.forgejo/workflows/*.yml`)
   - Can't fully test until Forgejo is live
   - Keep Drone as fallback during transition period

### Why Not Woodpecker/Crow CI?

Based on compatibility analysis:
- **Not drop-in replacements**: Both require pipeline syntax changes, plugin replacements
- **`drone-meltwater-cache` incompatible**: Would need fork or replacement anyway
- **No strategic benefit**: Still separate CI system (same operational complexity as Drone)

**Conclusion:** Migrating to Forgejo Actions provides:
- Industry standard tooling (GitHub Actions syntax)
- Reduced maintenance surface (1 system vs 3)
- Centralized management (code + CI + secrets in one UI)

---

## Pre-Migration Checklist

Before starting any phase:

- [ ] **Backup Strategy:** Automated backups configured for all data volumes
- [ ] **Rollback Plans:** Documented and tested for each phase
- [ ] **Monitoring:** Grafana/Prometheus dashboards ready for SeaweedFS
- [ ] **Pipeline Inventory:** Existing `.drone.yml` files cataloged
- [ ] **Stakeholder Notification:** Team informed of planned downtime windows
- [ ] **Testing Environment:** Ability to test migrations without affecting production

---

## Next Steps

1. **Review all plans** with team and stakeholders
2. **Validate timeline** based on resource availability
3. **Execute Phase 1** (SeaweedFS deployment) - low risk, quick win
4. **Begin Phase 2** after Phase 1 verification (Forgejo deployment)
5. **Start Phase 3** after Phase 2 completion (Forgejo Actions migration)

---

## Change Log

| Date | Change | Author |
|-------|---------|---------|
| 2026-01-07 | Initial migration overview and detailed plans created | Sisyphus |

---

## References

### External Documentation
- [SeaweedFS Documentation](https://github.com/chrislusf/seaweedfs)
- [Forgejo Documentation](https://forgejo.org/docs/latest/)
- [Forgejo Actions](https://forgejo.org/docs/latest/user/actions/)
- [GitHub Actions Syntax](https://docs.github.com/en/actions)

### Existing Plans in Repository
- [PLAN-MIGRATE-MINIO-TO-SEAWEEDFS.md](./PLAN-MIGRATE-MINIO-TO-SEAWEEDFS.md) - MinIO to SeaweedFS
- [PLAN-MIGRATE-GITEA-TO-FORGEJO.md](./PLAN-MIGRATE-GITEA-TO-FORGEJO.md) - Gitea to Forgejo
- [PLAN-MIGRATE-DRONE-TO-FORGEJO-ACTIONS.md](./PLAN-MIGRATE-DRONE-TO-FORGEJO-ACTIONS.md) - Drone to Forgejo Actions
- [PLAN-GITEA-USE-SEAWEEDFS.md](./PLAN-GITEA-USE-SEAWEEDFS.md) - Forgejo S3 configuration

### Key Plugins & Tools
- [drone-meltwater-cache](https://github.com/drone-plugins/drone-meltwater-cache) - Current Drone cache plugin
- [actions/cache](https://github.com/actions/cache) - Runner-local cache (Option A)
- [Forgejo Runner](https://codeberg.org/forgejo/runner) - Forgejo Actions runner
