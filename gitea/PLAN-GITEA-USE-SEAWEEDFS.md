# Migration Plan: Forgejo Storage to SeaweedFS (S3-compatible)

This document outlines steps to configure Forgejo's object storage to use SeaweedFS S3-compatible object storage.

**⚠️ IMPORTANT:** This configuration depends on completing MinIO → SeaweedFS migration first. See `@PLAN-MIGRATE-MINIO-TO-SEAWEEDFS.md` for the general storage backend migration plan.

**Migration Sequence:**
1. **Phase 1:** Deploy SeaweedFS and migrate MinIO data (`@PLAN-MIGRATE-MINIO-TO-SEAWEEDFS.md`)
2. **Phase 2:** Configure Forgejo to use SeaweedFS (this document)

**Do NOT proceed with this document until MinIO is replaced with SeaweedFS.**

## Context

Forgejo version: **v13.x (Stable) or v11.x (LTS)**
Current storage: Local filesystem (volume: `forgejo_data`)
Current MinIO: Exists but will be migrated away (see `@PLAN-MIGRATE-MINIO-TO-SEAWEEDFS.md`)
Target storage: SeaweedFS S3 API (port 9000)

**Important Migration Dependencies:**

1. **Phase 1:** Deploy SeaweedFS and migrate from MinIO (see `@PLAN-MIGRATE-MINIO-TO-SEAWEEDFS.md`)
   - MinIO container is removed
   - SeaweedFS is running with all buckets created
   - Existing data migrated (or fresh start chosen)

2. **Phase 2:** Configure Forgejo to use SeaweedFS (this document)
   - Forgejo points to SeaweedFS for object storage
   - New Forgejo data stored in SeaweedFS

**Do NOT proceed with Forgejo configuration until MinIO → SeaweedFS migration is complete.**

Forgejo supports S3-compatible object storage for:
- **Attachments** (Issue and PR attachments)
- **LFS** (Git Large File Storage)
- **Avatars** (User and repository profile pictures)
- **Repository Avatars** (Repository profile pictures)
- **Repository Archives** (Generated ZIP/TAR.GZ downloads)
- **Packages** (Container, npm, Maven, etc.)
- **Actions Logs** (Forgejo Actions workflow logs)
- **Actions Artifacts** (Forgejo Actions build artifacts)

## 1. Prerequisites

### 1.1 Complete MinIO → SeaweedFS Migration

Ensure the general migration plan in `@PLAN-MIGRATE-MINIO-TO-SEAWEEDFS.md` is complete:

- [ ] SeaweedFS service is running in `docker-compose.yml`
- [ ] MinIO service has been removed
- [ ] SeaweedFS S3 API is accessible on port 9000
- [ ] Buckets are created (forgejo, drone-cache, k3d-registry)
- [ ] Data migration is complete (or fresh start chosen)

### 1.2 Verify SeaweedFS is Ready

Verify SeaweedFS is running:

```bash
cd gitea  # or forgejo/ depending on directory structure
docker-compose ps seaweedfs
```

Expected output: `seaweedfs` should be `Up` and listening on port 9000.

Verify the `forgejo` bucket exists:

```bash
docker-compose exec -T seaweedfs weed shell -master=seaweedfs:9333 -command "s3.bucket.list"
```

Expected output: Should show `forgejo` bucket in the list.

## 2. Forgejo Configuration Changes

Forgejo can be configured using either:
- **Environment variables** (recommended for Docker)
- **`app.ini`** configuration file

### 2.1 Environment Variables Approach (Recommended)

Update the `forgejo` service in `docker-compose.yml` with the following environment variables:

```yaml
services:
  forgejo:
    image: "codeberg.org/forgejo/forgejo:13.0"  # or :11.0 for LTS
    # ... existing configuration ...
    environment:
      # ... existing environment variables ...
      # Storage configuration
      FORGEJO__storage__STORAGE_TYPE: minio
      FORGEJO__storage__MINIO_ENDPOINT: seaweedfs:9000
      FORGEJO__storage__MINIO_ACCESS_KEY_ID: forgejo_access_key
      FORGEJO__storage__MINIO_SECRET_ACCESS_KEY: forgejo_secret_key
      FORGEJO__storage__MINIO_BUCKET: forgejo
      FORGEJO__storage__MINIO_USE_SSL: "false"
      FORGEJO__storage__MINIO_BUCKET_LOOKUP: path
      FORGEJO__storage__SERVE_DIRECT: "true"
```

**Important:** Replace `forgejo_access_key` and `forgejo_secret_key` with actual values from SeaweedFS `s3_config.json` file.

**Note:** In Forgejo, use `FORGEJO__storage__MINIO_BUCKET_LOOKUP` (not `MINIO_BUCKET_LOOKUP_TYPE` as in Gitea). Valid options are:
- `auto` (default): Auto-detect bucket lookup type
- `dns`: Virtual Host style (for AWS S3 and compatible servers)
- `path`: Path style (for SeaweedFS and similar servers)

### 2.2 Alternative: app.ini Approach

If you prefer using a configuration file, create or modify `/data/forgejo/conf/app.ini` inside the Forgejo container.

Mount configuration file:
```yaml
volumes:
  - "forgejo_data:/data"
  - "./config/forgejo/app.ini:/data/forgejo/conf/app.ini:ro"
```

Content of `config/forgejo/app.ini`:
```ini
[storage]
STORAGE_TYPE = minio
MINIO_ENDPOINT = seaweedfs:9000
MINIO_ACCESS_KEY_ID = forgejo_access_key
MINIO_SECRET_ACCESS_KEY = forgejo_secret_key
MINIO_BUCKET = forgejo
MINIO_USE_SSL = false
MINIO_BUCKET_LOOKUP = path
SERVE_DIRECT = true
```

**Important:** Replace `gitea_access_key` and `gitea_secret_key` with the actual values from the SeaweedFS `s3_config.json` file.

### 2.2 Alternative: app.ini Approach

If you prefer using a configuration file, create or modify `/data/gitea/conf/app.ini` inside the Gitea container.

Mount the configuration file:
```yaml
volumes:
  - "git_data:/data"
  - "./config/gitea/app.ini:/data/gitea/conf/app.ini:ro"
```

Content of `config/gitea/app.ini`:
```ini
[storage]
STORAGE_TYPE = minio
MINIO_ENDPOINT = seaweedfs:9000
MINIO_ACCESS_KEY_ID = gitea_access_key
MINIO_SECRET_ACCESS_KEY = gitea_secret_key
MINIO_BUCKET = gitea
MINIO_USE_SSL = false
MINIO_BUCKET_LOOKUP_TYPE = path
SERVE_DIRECT = true
```

## 3. Configuration Option Reference

| Option | Value | Description |
|--------|-------|-------------|
| `STORAGE_TYPE` | `minio` | Use S3-compatible storage backend |
| `MINIO_ENDPOINT` | `seaweedfs:9000` | S3 API endpoint (host:port) |
| `MINIO_ACCESS_KEY_ID` | *from s3_config.json* | S3 access key for forgejo user |
| `MINIO_SECRET_ACCESS_KEY` | *from s3_config.json* | S3 secret key for forgejo user |
| `MINIO_BUCKET` | `forgejo` | Bucket name for Forgejo data |
| `MINIO_USE_SSL` | `false` | Use HTTPS (false for internal network) |
| `MINIO_BUCKET_LOOKUP` | `path` | URL style: `auto` (default), `dns` (virtual host), or `path` (path-based) |
| `MINIO_LOCATION` | `us-east-1` | S3 location to create bucket (default) |
| `MINIO_INSECURE_SKIP_VERIFY` | `false` | Skip SSL verification for self-signed certificates |
| `MINIO_CHECKSUM_ALGORITHM` | `default` | Checksum algorithm: `default` (for MinIO/SeaweedFS/AWS) or `md5` (for Cloudflare/Backblaze) |
| `SERVE_DIRECT` | `false` | Redirect to signed S3 URLs for efficient downloads |

**Why `path` lookup type?** SeaweedFS may not support DNS-based bucket lookup (virtual host style), so `path` style is more reliable.

## 4. Per-Feature Storage Configuration (Optional)

If you want different storage backends for different features, configure specific sections.

### Example: LFS on S3, Attachments Local

```yaml
environment:
  # Global storage (attachments, avatars, etc.) - keep local
  FORGEJO__storage__STORAGE_TYPE: local

  # LFS specifically on S3
  FORGEJO__lfs__STORAGE_TYPE: minio
  FORGEJO__lfs__MINIO_ENDPOINT: seaweedfs:9000
  FORGEJO__lfs__MINIO_ACCESS_KEY_ID: forgejo_access_key
  FORGEJO__lfs__MINIO_SECRET_ACCESS_KEY: forgejo_secret_key
  FORGEJO__lfs__MINIO_BUCKET: forgejo-lfs
  FORGEJO__lfs__MINIO_USE_SSL: "false"
  FORGEJO__lfs__MINIO_BUCKET_LOOKUP: path
  FORGEJO__lfs__SERVE_DIRECT: "true"
```

**Available sections:**
- `[storage]` - Global defaults for all subsystems
- `[attachment]` - Issue/PR attachments
- `[lfs]` - Git LFS objects
- `[avatar]` - User avatars
- `[repo-avatar]` - Repository avatars
- `[repo-archive]` - Repository archive downloads
- `[packages]` - Package registry
- `[storage.actions_log]` - Forgejo Actions logs
- `[storage.artifacts]` - Forgejo Actions artifacts

## 5. Migration Steps

### Step 1: Verify Prerequisites

**CRITICAL:** Ensure MinIO → SeaweedFS migration is complete (see `@PLAN-MIGRATE-MINIO-TO-SEAWEEDFS.md`):

```bash
# 1. Check MinIO is gone
docker-compose ps | grep minio
# Expected: No output (minio service removed)

# 2. Check SeaweedFS is running
docker-compose ps seaweedfs
# Expected: seaweedfs service is "Up"

# 3. Verify forgejo bucket exists
docker-compose exec -T seaweedfs weed shell -master=seaweedfs:9333 -command "s3.bucket.list"
# Expected: Should show "forgejo" bucket
```

### Step 2: Backup Current Forgejo Data

Before making changes, create a backup of existing Forgejo data:

```bash
cd gitea  # or forgejo/ depending on directory structure
docker-compose stop forgejo
docker run --rm -v forgejo_forgejo_data:/data -v $(pwd):/backup alpine tar czf /backup/forgejo-backup-$(date +%Y%m%d-%H%M%S).tar.gz -C /data .
```

### Step 3: Stop Forgejo

```bash
docker-compose stop forgejo
```

### Step 4: Apply Configuration Changes

Choose one approach:

**Option A: Environment Variables**
```bash
# Edit docker-compose.yml to add environment variables
# (see Section 2.1)
```

**Option B: app.ini File**
```bash
# Create config directory and file
mkdir -p config/forgejo

# Create app.ini with content from Section 2.2
cat > config/forgejo/app.ini << 'EOF'
[storage]
STORAGE_TYPE = minio
MINIO_ENDPOINT = seaweedfs:9000
MINIO_ACCESS_KEY_ID = forgejo_access_key
MINIO_SECRET_ACCESS_KEY = forgejo_secret_key
MINIO_BUCKET = forgejo
MINIO_USE_SSL = false
MINIO_BUCKET_LOOKUP = path
SERVE_DIRECT = true
EOF

# Update docker-compose.yml to mount file
# (see Section 2.2)
```

### Step 5: Verify SeaweedFS Bucket

**Note:** The `forgejo` bucket should already exist from the MinIO → SeaweedFS migration (see `@PLAN-MIGRATE-MINIO-TO-SEAWEEDFS.md`, section 3.1).

Verify bucket exists:

```bash
docker-compose exec -T seaweedfs weed shell -master=seaweedfs:9333 -command "s3.bucket.list"
```

If bucket does NOT exist, create it:

```bash
docker-compose exec -T seaweedfs weed shell -master=seaweedfs:9333 -command "s3.bucket.create -name=forgejo"
```

### Step 6: Start Forgejo

```bash
docker-compose up -d forgejo
```

### Step 7: Verify Configuration

Check Forgejo logs to ensure it connects to SeaweedFS successfully:

```bash
docker-compose logs -f forgejo
```

Look for errors related to storage initialization.

### Step 8: Test Functionality

Perform functional tests:

1. **LFS Upload Test**:
   ```bash
   # In a repository, create a large file and push
   echo "Large file content" > largefile.txt
   git lfs track "*.txt"
   git add .gitattributes largefile.txt
   git commit -m "Test LFS"
   git push
   ```

2. **Attachment Upload Test**:
   - Create an issue
   - Upload an image/file attachment
   - Verify it downloads correctly

3. **Avatar Test**:
   - Upload a user avatar
   - Verify it displays correctly

4. **Actions Artifacts Test** (Forgejo-specific):
   - Create a `.forgejo/workflows/test.yml` workflow
   - Configure workflow to upload artifacts
   - Verify artifacts are stored in SeaweedFS

5. **Actions Logs Test** (Forgejo-specific):
   - Run a workflow that generates logs
   - Verify logs are accessible in the UI

## 6. Data Migration Strategy

### Option A: Fresh Start (Recommended)

If existing data can be regenerated or is not critical:

1. **Stop Forgejo**
2. **Configure SeaweedFS storage** (as above)
3. **Start Forgejo**
4. **New data will be stored in SeaweedFS**
5. **Old local files remain accessible until overwritten**

### Option B: Migration (For Critical Data)

If you must preserve existing LFS objects, attachments, or Actions data:

**Note:** Forgejo's storage layout differs from Gitea's. Direct migration requires understanding the directory structure in `forgejo_data` volume.

1. **Install MinIO Client** (mc) and AWS CLI:
   ```bash
   docker run --rm -it --network git_cicd_net \
     quay.io/minio/mc:RELEASE.2025-02-21T16-00-46Z sh
   docker run --rm -it --network git_cicd_net \
     amazon/aws-cli:latest sh
   ```

2. **Configure local storage access** (before migration):
   ```bash
   # Assuming old Forgejo data is in forgejo_data volume
   docker run --rm -v forgejo_forgejo_data:/data alpine sh -c '
     mc alias set local http://localhost:3000/ --api S3v4
   '

   # Configure SeaweedFS as target
   mc alias set seaweedfs http://seaweedfs:9000 \
     --access-key forgejo_access_key \
     --secret-key forgejo_secret_key
   ```

3. **Copy specific directories to SeaweedFS**:
   ```bash
   # Copy LFS data
   mc mirror local/lfs/ seaweedfs/forgejo/lfs/

   # Copy attachments
   mc mirror local/attachments/ seaweedfs/forgejo/attachments/

   # Copy avatars
   mc mirror local/avatars/ seaweedfs/forgejo/avatars/

   # Copy repo avatars
   mc mirror local/repo-avatars/ seaweedfs/forgejo/repo-avatars/

   # Copy actions artifacts (if existing)
   mc mirror local/actions_artifacts/ seaweedfs/forgejo/actions_artifacts/

   # Copy actions logs (if existing)
   mc mirror local/actions_log/ seaweedfs/forgejo/actions_log/
   ```

**Important:** Forgejo uses specific subdirectories within the bucket for each subsystem:
- `attachments/` for issue/PR attachments
- `lfs/` for Git LFS objects
- `avatars/` for user avatars
- `repo-avatars/` for repository avatars
- `repo-archive/` for repository archive downloads
- `packages/` for package registry
- `actions_log/` for Forgejo Actions logs
- `actions_artifacts/` for Forgejo Actions build artifacts

**Note:** This is complex and may require custom scripts depending on Forgejo's internal file structure. For most setups, **Option A (Fresh Start)** is recommended as LFS files can be re-uploaded if needed.

## 7. Rollback Plan

If issues occur after migration:

### Immediate Rollback

1. **Stop Forgejo**:
   ```bash
   docker-compose stop forgejo
   ```

2. **Remove new configuration**:
   - If using environment variables: Remove `FORGEJO__storage__*` entries from `docker-compose.yml`
   - If using `app.ini`: Remove volume mount and file

3. **Restore backup** (if you made one):
   ```bash
   docker run --rm -v forgejo_forgejo_data:/data -v $(pwd):/backup alpine tar xzf /backup/forgejo-backup-YYYYMMDD-HHMMSS.tar.gz -C /data
   ```

4. **Start Forgejo**:
   ```bash
   docker-compose up -d forgejo
   ```

### Note: Storage Backend Rollback

Rolling back Forgejo configuration will return it to local filesystem storage. This does **not** restore MinIO - that's handled by general migration plan in `@PLAN-MIGRATE-MINIO-TO-SEAWEEDFS.md`.

If you need to completely revert to MinIO:
1. Roll back Forgejo configuration (this section)
2. Roll back SeaweedFS deployment (see `@PLAN-MIGRATE-MINIO-TO-SEAWEEDFS.md` rollback section)

### Verify Rollback

Check that:
- Forgejo starts successfully
- Repositories are accessible
- Old attachments/avatars display correctly

## 8. Monitoring and Verification

### Check Storage Usage

Monitor SeaweedFS bucket usage:
```bash
docker-compose exec -T seaweedfs weed shell -master=seaweedfs:9333 -command "s3.bucket.stat -name=forgejo"
```

### Check Forgejo Logs

Monitor for storage-related errors:
```bash
docker-compose logs --tail 100 forgejo | grep -i "storage\|minio\|s3"
```

### Verify Functionality Periodically

- New LFS uploads go to SeaweedFS
- New attachments display correctly
- Package registry works (if enabled)
- Actions logs and artifacts upload/download correctly

## 9. Performance Considerations

### `SERVE_DIRECT = false` (Recommended)

When enabled, Forgejo generates signed URLs that allow clients to download files directly from SeaweedFS, reducing load on the Forgejo server. However, for SeaweedFS, this may require proper DNS/SSL setup. Default is `false`.

**Note:** For SeaweedFS with path-style access, you may need to set `SERVE_DIRECT = true` if you have reverse proxy handling signed URL redirects, or `false` if files should be proxied through Forgejo.

### Network Latency

Ensure low latency between Forgejo and SeaweedFS containers (same Docker network: `git_cicd_net`).

### Connection Pooling

Forgejo's MinIO client handles connection pooling automatically. No additional tuning required for typical setups.

## 10. Troubleshooting

### Issue: Forgejo fails to start with storage error

**Symptoms:** Container crashes, logs show "Endpoint does not follow ip address or domain name standards"

**Solutions:**
1. Verify `MINIO_ENDPOINT` is `host:port` format (not http://)
2. Check SeaweedFS is running: `docker-compose ps seaweedfs`
3. Verify network connectivity: `docker-compose exec forgejo ping seaweedfs`

### Issue: Files not accessible after upload

**Symptoms:** Upload succeeds but downloads fail

**Solutions:**
1. Check bucket exists: `docker-compose exec seaweedfs weed shell -master=seaweedfs:9333 -command "s3.bucket.list"`
2. Verify credentials match `s3_config.json`
3. Check `MINIO_BUCKET_LOOKUP` is set to `path` for SeaweedFS
4. Verify `SERVE_DIRECT` setting matches your network configuration

### Issue: LFS uploads fail with "Access Denied"

**Symptoms:** Git LFS push returns 403 error

**Solutions:**
1. Verify `MINIO_ACCESS_KEY_ID` and `MINIO_SECRET_ACCESS_KEY` are correct
2. Check SeaweedFS `s3_config.json` grants `Read,Write` permissions to forgejo user
3. Ensure bucket name matches configuration

### Issue: Actions artifacts not stored in SeaweedFS

**Symptoms:** Workflows complete but artifacts not downloadable

**Solutions:**
1. Verify `[storage.artifacts]` section configuration in `app.ini`
2. Check Forgejo Actions is enabled in Forgejo UI (Site Administration → Actions)
3. Review workflow syntax for artifact upload steps
4. Check SeaweedFS bucket for `actions_artifacts/` directory

## 11. Environment Variables Reference

Complete list for copy-paste to `docker-compose.yml`:

```yaml
environment:
  # Forgejo S3/MinIO Storage Configuration
  FORGEJO__storage__STORAGE_TYPE: "minio"
  FORGEJO__storage__MINIO_ENDPOINT: "seaweedfs:9000"
  FORGEJO__storage__MINIO_ACCESS_KEY_ID: "${FORGEJO_S3_ACCESS_KEY_ID:-forgejo_access_key}"
  FORGEJO__storage__MINIO_SECRET_ACCESS_KEY: "${FORGEJO_S3_SECRET_ACCESS_KEY:-forgejo_secret_key}"
  FORGEJO__storage__MINIO_BUCKET: "${FORGEJO_S3_BUCKET:-forgejo}"
  FORGEJO__storage__MINIO_USE_SSL: "false"
  FORGEJO__storage__MINIO_BUCKET_LOOKUP: "path"
  FORGEJO__storage__MINIO_LOCATION: "us-east-1"
  FORGEJO__storage__SERVE_DIRECT: "false"
```

**Note:** Using environment variable defaults (`${VAR:-default}`) allows you to override via `.env` file if needed.

## 12. Summary Checklist

### Prerequisites (from `@PLAN-MIGRATE-MINIO-TO-SEAWEEDFS.md`)
- [ ] MinIO → SeaweedFS migration complete
- [ ] MinIO service removed from docker-compose.yml
- [ ] SeaweedFS service running and healthy
- [ ] SeaweedFS S3 API accessible on port 9000
- [ ] SeaweedFS buckets created (forgejo, drone-cache, etc.)

### Forgejo Migration
- [ ] Forgejo data backed up
- [ ] Forgejo stopped
- [ ] Configuration applied (environment variables OR app.ini)
- [ ] SeaweedFS bucket `forgejo` verified
- [ ] Forgejo restarted successfully
- [ ] Forgejo logs show no storage errors

### Verification
- [ ] LFS upload tested and working
- [ ] Attachment upload tested and working
- [ ] Avatar upload tested and working
- [ ] Packages registry tested (if enabled)
- [ ] Actions logs tested and working
- [ ] Actions artifacts tested and working
- [ ] Old data accessible (fresh start) OR migrated (full migration)

### Safety
- [ ] Rollback plan documented
- [ ] Monitoring configured (Prometheus metrics)
- [ ] Backup stored securely

## References

- [Forgejo Storage Settings Documentation](https://forgejo.org/docs/next/admin/setup/storage/)
- [Forgejo Configuration Cheat Sheet](https://forgejo.org/docs/next/admin/config-cheat-sheet/)
- [Forgejo MinIO/S3 Storage](https://codeberg.org/forgejo/forgejo/src/branch/forgejo/modules/storage/minio.go)
- [SeaweedFS S3 API Documentation](https://github.com/chrislusf/seaweedfs)
 - [MinIO to SeaweedFS Migration Plan](./PLAN-MIGRATE-MINIO-TO-SEAWEEDFS.md)
 - [Forgejo Gitea Migration Plan](./PLAN-MIGRATE-GITEA-TO-FORGEJO.md)
 - [Drone to Forgejo Actions Migration Plan](./PLAN-MIGRATE-DRONE-TO-FORGEJO-ACTIONS.md)

---

## Change Log

| Date | Change | Author |
|-------|---------|---------|
| 2026-01-07 | Initial migration overview and detailed plans created | Sisyphus |
| 2026-01-09 | Updated for Forgejo (from Gitea) | Sisyphus |

