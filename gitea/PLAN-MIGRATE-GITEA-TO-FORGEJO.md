# Migration Plan: Gitea to Forgejo

**Last Updated:** 2026-01-07
**Status:** Planning Phase
**Dependencies:**
- ✅ [PLAN-MIGRATE-MINIO-TO-SEAWEEDFS.md](./PLAN-MIGRATE-MINIO-TO-SEAWEEDFS.md) must be complete
- ⏳ [PLAN-GITEA-USE-SEAWEEDFS.md](./PLAN-GITEA-USE-SEAWEEDFS.md) for storage configuration

---

## Context

### Current Setup
- **Gitea Version:** 1.25.2
- **Database:** SQLite3 (default configuration)
- **Storage:** Local filesystem (volume: `git_data`)
- **Port:** 3000
- **URL:** http://localhost:3000 (or configured domain)

### Target Setup
- **Forgejo Version:** v13.x (Stable) or v11.x (LTS)
- **Database:** PostgreSQL (recommended for production) or SQLite3
- **Storage:** SeaweedFS S3-compatible (via `PLAN-GITEA-USE-SEAWEEDFS.md`)
- **Port:** 3001 (for parallel deployment)
- **URL:** http://localhost:3001 (temporary), then http://localhost:3000 after DNS switch

### Critical Constraints
- **No direct upgrade path:** Gitea v1.25.2 is beyond v1.22 (last drop-in compatible version)
- **Database incompatibility:** Cannot restore Gitea 1.25.2 SQL dump into Forgejo
- **API-based migration only:** Must use Forgejo's built-in importer via Gitea API

---

## Migration Strategy: Parallel Deployment

Deploy Forgejo alongside existing Gitea instance during transition period.

### Architecture During Migration

```
┌──────────────────────────────────────┐
│         DNS / Load Balancer          │
│  ┌──────────────┐  ┌──────────────┐  │
│  │ Gitea:3000   │  │ Forgejo:3001 │  │
│  │ v1.25.2      │  │ v13.x        │  │
│  │ (Production) │  │ (Testing)    │  │
│  └───────┬──────┘  └────────┬─────┘  │
│          │                  │        │
│  ┌───────▼────────┐  ┌─── ──▼────┐   │
│  │ MinIO:9000     │  │ SeaweedFS │   │
│  │ (Still active) │  │ :9000     │   │
│  │                │  │           │   │
│  └────────────────┘  └───────────┘   │
└──────────────────────────────────────┘
```

**Note:** During Phase 1 storage migration, MinIO will be replaced by SeaweedFS.

---

## Prerequisites

Before starting migration:

- [ ] **SeaweedFS deployed and verified** (Phase 1 complete)
- [ ] **Gitea full backup created:**
  ```bash
  cd gitea
  docker-compose exec -T git gitea dump /backup/gitea-backup-$(date +%Y%m%d-%H%M%S).zip
  ```
- [ ] **Admin account on Gitea:** Required for API access
- [ ] **Forgejo instance ready:** Docker image pulled, environment variables prepared
- [ ] **Storage configuration documented:** SeaweedFS endpoint, bucket, credentials ready
- [ ] **Repository inventory:** List of all repos requiring migration

---

## Migration Steps

### Step 1: Deploy Forgejo Instance

**Objective:** Stand up Forgejo alongside Gitea for parallel operation.

```yaml
# Add to gitea/docker-compose.yml
forgejo:
  image: "codeberg.org/forgejo/forgejo:13.0"  # or :11.0 for LTS
  init: true
  hostname: forgejo
  environment:
    FORGEJO__server__ROOT_URL: http://forgejo:3000
    FORGEJO__server__HTTP_PORT: 3000
    FORGEJO__database__DB_TYPE: sqlite3  # or postgres
    FORGEJO__database__PATH: /data/forgejo.db
    FORGEJO__storage__STORAGE_TYPE: minio
    FORGEJO__storage__MINIO_ENDPOINT: seaweedfs:9000
    FORGEJO__storage__MINIO_BUCKET: gitea
    FORGEJO__storage__MINIO_BUCKET_LOOKUP_TYPE: path
    FORGEJO__storage__MINIO_USE_SSL: "false"
    FORGEJO__storage__MINIO_ACCESS_KEY_ID: gitea_access_key
    FORGEJO__storage__MINIO_SECRET_ACCESS_KEY: gitea_secret_key
    FORGEJO__storage__SERVE_DIRECT: "true"
  volumes:
    - "forgejo_data:/data"
  networks:
    - git_cicd_net
  ports:
    - "3001:3000"  # Different port for parallel operation
  restart: unless-stopped
```

**Actions:**
```bash
cd gitea
docker-compose up -d forgejo
docker-compose logs -f forgejo
```

**Verification:**
- [ ] Forgejo accessible at http://localhost:3001
- [ ] Create admin account
- [ ] Verify SeaweedFS connectivity (check Forgejo logs)
- [ ] Check `gitea` bucket accessible in SeaweedFS

---

### Step 2: Configure Gitea API Access

Generate admin token on Gitea for repository migration:

```bash
# Via Gitea UI:
# 1. Login to http://localhost:3000
# 2. Go to Settings → Applications → Generate Token
# 3. Token name: "Forgejo Migration"
# 4. Scopes: read (organization), write (user), admin (repo)
```

**Save credentials securely:**
```bash
# Export to environment (or use secrets management)
export GITEA_ADMIN_TOKEN="your_gitea_token_here"
export GITEA_URL="http://git:3000"
```

---

### Step 3: Migrate Repositories

#### **Method 1: Via Forgejo UI (Manual, for small number of repos)**

1. **Login to Forgejo** (http://localhost:3001)
2. **Navigate:** User Menu → Create → Migrate Repository
3. **Fill migration form:**
   - **Source:** Gitea
   - **Clone Address:** `http://git:3000`
   - **Username:** `your_gitea_username`
   - **Password:** `your_gitea_password` (or use token)
   - **Repository:** `orgname/reponame` (for specific repo)
   - Or use **"Clone all repositories"** for bulk migration

4. **Configure Migration Options:**
   - [x] Issues
   - [x] Pull Requests
   - [x] Labels
   - [x] Milestones
   - [x] LFS objects
   - [ ] Wiki (optional)
   - [ ] Releases (optional)

#### **Method 2: Via API (Automated, for large number of repos)**

Use Forgejo's migration API with Gitea source:

```bash
#!/bin/bash
# migrate-repos.sh

GITEA_TOKEN="your_gitea_token"
FORGEJO_TOKEN="your_forgejo_token"
GITEA_URL="http://git:3000"
FORGEJO_URL="http://forgejo:3000"

# Get list of repositories from Gitea
repos=$(curl -sH "Authorization: token $GITEA_TOKEN" \
  "$GITEA_URL/api/v1/user/repos" | \
  jq -r '.[].full_name')

# Migrate each repository to Forgejo
for repo in $repos; do
  echo "Migrating $repo..."

  curl -X POST \
    -H "Authorization: token $FORGEJO_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"clone_addr\": \"$GITEA_URL\",
      \"clone_addr\": \"$repo\",
      \"service\": \"gitea\",
      \"auth_username\": \"$GITEA_USERNAME\",
      \"auth_password\": \"$GITEA_PASSWORD\",
      \"mirror\": false,
      \"private\": true,
      \"issues\": true,
      \"pull_requests\": true,
      \"labels\": true,
      \"lfs\": true
    }" \
    "$FORGEJO_URL/api/v1/repos/migrate"

  echo "Migration initiated for $repo"
done
```

**Verification:**
- [ ] All repositories visible in Forgejo UI
- [ ] Issues/PRs migrated with history
- [ ] Git LFS objects accessible
- [ ] Labels and milestones preserved

---

### Step 4: Migrate Users

**For each user:**

1. **Create account** in Forgejo UI (or bulk create via API)
2. **Copy SSH keys** from Gitea to Forgejo:
   - Gitea: Settings → SSH Keys → Copy
   - Forgejo: Settings → SSH/GPG Keys → Add
3. **Copy personal access tokens** (if any)
4. **Notify users** of migration, provide new login URL

**Bulk user migration script (if needed):**

```bash
#!/bin/bash
# migrate-users.sh

# Get users from Gitea
curl -sH "Authorization: token $GITEA_ADMIN_TOKEN" \
  "$GITEA_URL/api/v1/admin/users" | \
  jq -r '.[] | "\(.login) \(.email)"' | \
  while read -r login email; do
    # Create user in Forgejo via admin API
    curl -X POST \
      -H "Authorization: token $FORGEJO_ADMIN_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{
        \"username\": \"$login\",
        \"email\": \"$email\",
        \"password\": \"temporary_password\",
        \"must_change_password\": true
      }" \
      "$FORGEJO_URL/api/v1/admin/users"

    echo "Created user: $login"
done
```

**Verification:**
- [ ] All users can login to Forgejo
- [ ] SSH keys functional
- [ ] User email addresses match

---

### Step 5: Reconfigure External Auth

**For each external authentication provider (OIDC, LDAP, etc.):**

1. **Get current config from Gitea:**
   ```bash
   docker-compose exec -T git cat /data/gitea/conf/app.ini | grep -A 20 "\[openid-connect\]"
   ```

2. **Configure in Forgejo:**
   - Via UI: Site Administration → Authentication → Add Source
   - Or via environment variables:
     ```yaml
     environment:
       FORGEJO__oauth2__ENABLED: "true"
       FORGEJO__openid-connect__NAME: "your_provider"
       FORGEJO__openid-connect__OPENID_CONNECT__CLIENT_ID: "client_id"
       FORGEJO__openid-connect__OPENID_CONNECT__CLIENT_SECRET: "client_secret"
       FORGEJO__openid-connect__OPENID_CONNECT__ENABLE_AUTO_REGISTRATION: "true"
     ```

**Verification:**
- [ ] Users can login via external provider
- [ ] Existing users linked to external accounts

---

### Step 6: Migrate Webhooks

For each repository:

1. **Get webhooks from Gitea:**
   ```bash
   curl -sH "Authorization: token $GITEA_TOKEN" \
     "$GITEA_URL/api/v1/repos/{owner}/{repo}/hooks"
   ```

2. **Recreate in Forgejo:**
   - Via UI: Repository → Settings → Webhooks → Add Webhook
   - Or via API:
     ```bash
     curl -X POST \
       -H "Authorization: token $FORGEJO_TOKEN" \
       -H "Content-Type: application/json" \
       -d "{
         \"type\": \"gitea\",
         \"config\": {
           \"url\": \"https://external.service/webhook\",
           \"content_type\": \"json\",
           \"secret\": \"webhook_secret\"
         },
         \"events\": [\"push\", \"pull_request\"]
       }" \
       "$FORGEJO_URL/api/v1/repos/{owner}/{repo}/hooks"
     ```

**Verification:**
- [ ] Webhooks fire on push/PR events
- [ ] External services receive notifications

---

### Step 7: DNS / Load Balancer Switch

**When ready to cut over:**

1. **Update DNS:**
   ```bash
   # If using DNS
   # Change A record from Gitea server IP to Forgejo server IP
   # Or update load balancer backend
   ```

2. **Update Drone configuration** (if still using Drone during transition):
   ```yaml
   # In gitea/docker-compose.yml
   ci:
     environment:
       DRONE_GITEA_SERVER: "http://forgejo:3000"  # Updated
   ```

3. **Verify traffic:**
   ```bash
   # Test DNS resolution
   curl http://your-domain.com/
   # Should return Forgejo UI
   ```

**Verification:**
- [ ] DNS propagates (check multiple resolvers)
- [ ] All Git operations (clone, push) work via new domain
- [ ] Drone connects to Forgejo (if not yet migrated)

---

### Step 8: Retire Gitea

**Only after full verification (1-2 weeks of stable operation):**

```bash
# Stop Gitea instance
cd gitea
docker-compose stop git

# Keep in standby for rollback period
# docker-compose rm git  # Only after full confirmation

# Optional: Backup final state before removal
docker run --rm -v gitea_git_data:/data \
  alpine tar czf /backup/gitea-final-backup.tar.gz -C /data .
```

**Verification:**
- [ ] Forgejo fully functional
- [ ] No critical issues reported by users
- [ ] Monitoring stable
- [ ] Stakeholders approve retirement

---

## Data Validation Checklist

After migration, verify for each repository:

| Data Type | Source | Verification Method |
|-----------|---------|-------------------|
| **Git History** | Gitea `git log` | Clone from Forgejo, verify commit SHAs match |
| **Branches** | Gitea `git branch -a` | Compare branch list in Forgejo UI |
| **Tags** | Gitea `git tag` | Verify tags in Forgejo UI |
| **LFS Objects** | Gitea `git lfs ls-files` | Clone LFS repo, verify download works |
| **Issues** | Gitea Issues count | Match issue count in Forgejo UI |
| **Pull Requests** | Gitea PRs count | Match PR count in Forgejo UI |
| **Labels** | Gitea label list | Verify label names and colors |
| **Wiki Pages** | Gitea wiki content | Render and verify in Forgejo |
| **Releases** | Gitea releases | Verify release attachments and checksums |

---

## Rollback Plan

### Immediate Rollback (DNS switch back)

If critical issues discovered within 24 hours:

1. **Revert DNS** to point to Gitea
2. **Update Drone config** (if applicable) back to `http://git:3000`
3. **Verify operations** continue with Gitea stack

### Full Rollback (redeploy from backup)

If complete recovery required:

1. **Stop Forgejo:**
   ```bash
   docker-compose stop forgejo
   ```

2. **Restore Gitea from backup:**
   ```bash
   # Stop Gitea if still running
   docker-compose stop git

   # Restore data
   docker run --rm -v gitea_git_data:/data \
     -v $(pwd):/backup alpine \
     tar xzf /backup/gitea-backup-YYYYMMDD-HHMMSS.tar.gz -C /data

   # Restart Gitea
   docker-compose up -d git
   ```

3. **Update DNS** back to Gitea IP

4. **Verify data integrity:**
   - Repositories accessible
   - Users can login
   - Git operations work

---

## Post-Migration Tasks

- [ ] **Monitor Forgejo logs** for errors
- [ ] **Verify SeaweedFS usage:** Cache objects stored correctly
- [ ] **Update documentation** with new URLs, credentials
- [ ] **Notify team** of migration completion
- [ ] **Archive Gitea instance** (after 30-day standby period)
- [ ] **Clean up `git_data` volume** (if no longer needed)

---

## Troubleshooting

### Issue: Migration fails with "repository not found"

**Cause:** Repository visibility mismatch or API token permissions

**Solutions:**
1. Verify token has `admin:repo` scope
2. Check repository is public or token user has access
3. Use exact full name: `owner/repository`

### Issue: LFS objects not migrated

**Cause:** LFS stored in object storage (MinIO), not in Git repository

**Solutions:**
1. Ensure Gitea LFS pointing to SeaweedFS (Phase 2 of storage migration)
2. Use `git lfs migrate` or manual sync:
   ```bash
   # Copy LFS data from Gitea's MinIO/SeaweedFS bucket
   # Update LFS pointer in Forgejo repository
   ```

### Issue: Users cannot login with external auth

**Cause:** Client ID/secret mismatch or provider URL not configured

**Solutions:**
1. Verify Forgejo OIDC config matches Gitea
2. Check callback URL in provider dashboard
3. Enable debug logs: `FORGEJO__log__LEVEL=debug`

### Issue: Drone connects to wrong Gitea instance

**Cause:** DNS still pointing to Forgejo during transition

**Solutions:**
1. Use internal Docker network hostname: `http://git:3000` or `http://forgejo:3000`
2. Or use direct IP addresses in `docker-compose.yml`
3. Do not use external DNS during parallel operation

---

## Estimated Timeline

| Week | Task | Effort |
|-------|--------|----------|
| **Week 1** | Deploy Forgejo, migrate critical repos | 3 days |
| **Week 2** | Migrate remaining repos, users, webhooks | 3 days |
| **Week 3** | Configure external auth, parallel testing | 2 days |
| **Week 4** | DNS switch, monitoring, issue resolution | 2 days |

**Total:** 2-3 weeks (excluding testing/verification period)

---

## References

- [Forgejo Migration Documentation](https://forgejo.org/docs/latest/user/migration/)
- [Forgejo API Documentation](https://codeberg.org/api/swagger#/default/repo_migrate)
- [Gitea API Documentation](https://docs.gitea.com/api-v1/)
- [SeaweedFS Gitea Configuration](./PLAN-GITEA-USE-SEAWEEDFS.md)

---

## Change Log

| Date | Change | Author |
|-------|---------|---------|
| 2026-01-07 | Initial plan created | Sisyphus |
