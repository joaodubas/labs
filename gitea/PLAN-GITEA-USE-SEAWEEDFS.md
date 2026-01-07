# Migration Plan: Gitea Storage to SeaweedFS (S3-compatible)

This document outlines the steps to migrate Gitea's object storage from local filesystem to SeaweedFS S3-compatible object storage.

**⚠️ IMPORTANT:** This migration depends on completing the MinIO → SeaweedFS migration first. See `@PLAN.md` for the general storage backend migration plan.

**Migration Sequence:**
1. **Phase 1:** Deploy SeaweedFS and migrate MinIO data (`@PLAN.md`)
2. **Phase 2:** Configure Gitea to use SeaweedFS (this document)

**Do NOT proceed with this document until MinIO is replaced with SeaweedFS.**

## Context

Gitea version: **1.25.2**
Current storage: Local filesystem (volume: `git_data`)
Current MinIO: Exists but will be migrated away (see `@PLAN.md`)
Target storage: SeaweedFS S3 API (port 9000)

**Important Migration Dependencies:**

1. **Phase 1:** Deploy SeaweedFS and migrate from MinIO (see `@PLAN.md`)
   - MinIO container is removed
   - SeaweedFS is running with all buckets created
   - Existing data migrated (or fresh start chosen)

2. **Phase 2:** Configure Gitea to use SeaweedFS (this document)
   - Gitea points to SeaweedFS instead of MinIO
   - New Gitea data stored in SeaweedFS

**Do NOT proceed with Gitea configuration until MinIO → SeaweedFS migration is complete.**

Gitea supports S3-compatible object storage for:
- **LFS** (Git Large File Storage)
- **Attachments** (Issue and PR attachments)
- **Avatars** (User and repository profile pictures)
- **Packages** (Container, npm, Maven, etc.)
- **Actions** (CI/CD artifacts and logs)
- **Repo Archives** (Generated ZIP/TAR.GZ downloads)

## 1. Prerequisites

### 1.1 Complete MinIO → SeaweedFS Migration

Ensure the general migration plan in `@PLAN.md` is complete:

- [ ] SeaweedFS service is running in `docker-compose.yml`
- [ ] MinIO service has been removed
- [ ] SeaweedFS S3 API is accessible on port 9000
- [ ] Buckets are created (gitea, drone-cache, woodpecker-cache, k3d-registry)
- [ ] Data migration is complete (or fresh start chosen)

### 1.2 Verify SeaweedFS is Ready

Verify SeaweedFS is running:

```bash
cd gitea
docker-compose ps seaweedfs
```

Expected output: `seaweedfs` should be `Up` and listening on port 9000.

Verify the `gitea` bucket exists:

```bash
docker-compose exec -T seaweedfs weed shell -master=seaweedfs:9333 -command "s3.bucket.list"
```

Expected output: Should show `gitea` bucket in the list.

## 2. Gitea Configuration Changes

Gitea can be configured using either:
- **Environment variables** (recommended for Docker)
- **`app.ini`** configuration file

### 2.1 Environment Variables Approach (Recommended)

Update the `git` service in `gitea/docker-compose.yml` with the following environment variables:

```yaml
services:
  git:
    image: "gitea/gitea:1.25.2"
    # ... existing configuration ...
    environment:
      # ... existing environment variables ...
      # Storage configuration
      GITEA__storage__STORAGE_TYPE: minio
      GITEA__storage__MINIO_ENDPOINT: seaweedfs:9000
      GITEA__storage__MINIO_ACCESS_KEY_ID: gitea_access_key
      GITEA__storage__MINIO_SECRET_ACCESS_KEY: gitea_secret_key
      GITEA__storage__MINIO_BUCKET: gitea
      GITEA__storage__MINIO_USE_SSL: "false"
      GITEA__storage__MINIO_BUCKET_LOOKUP_TYPE: path
      GITEA__storage__SERVE_DIRECT: "true"
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
| `MINIO_ACCESS_KEY_ID` | *from s3_config.json* | S3 access key for gitea user |
| `MINIO_SECRET_ACCESS_KEY` | *from s3_config.json* | S3 secret key for gitea user |
| `MINIO_BUCKET` | `gitea` | Bucket name for Gitea data |
| `MINIO_USE_SSL` | `false` | Use HTTPS (false for internal network) |
| `MINIO_BUCKET_LOOKUP_TYPE` | `path` | URL style: `path` (path-based) or `dns` (virtual host) |
| `SERVE_DIRECT` | `true` | Redirect to signed S3 URLs for efficient downloads |

**Why `path` lookup type?** SeaweedFS may not support DNS-based bucket lookup (virtual host style), so `path` style is more reliable.

## 4. Per-Feature Storage Configuration (Optional)

If you want different storage backends for different features, configure specific sections:

### Example: LFS on S3, Attachments Local

```yaml
environment:
  # Global storage (attachments, avatars, etc.) - keep local
  GITEA__storage__STORAGE_TYPE: local

  # LFS specifically on S3
  GITEA__lfs__STORAGE_TYPE: minio
  GITEA__lfs__MINIO_ENDPOINT: seaweedfs:9000
  GITEA__lfs__MINIO_ACCESS_KEY_ID: gitea_access_key
  GITEA__lfs__MINIO_SECRET_ACCESS_KEY: gitea_secret_key
  GITEA__lfs__MINIO_BUCKET: gitea-lfs
  GITEA__lfs__MINIO_USE_SSL: "false"
  GITEA__lfs__MINIO_BUCKET_LOOKUP_TYPE: path
  GITEA__lfs__SERVE_DIRECT: "true"
```

**Available sections:**
- `[storage]` - Global defaults
- `[attachment]` - Issue/PR attachments
- `[lfs]` - Git LFS objects
- `[avatar]` - User avatars
- `[repo-avatar]` - Repository avatars
- `[repo-archive]` - Repository archive downloads
- `[packages]` - Package registry
- `[actions]` - CI/CD artifacts

## 5. Migration Steps

### Step 1: Verify Prerequisites

**CRITICAL:** Ensure MinIO → SeaweedFS migration is complete (see `@PLAN.md`):

```bash
# 1. Check MinIO is gone
docker-compose ps | grep minio
# Expected: No output (minio service removed)

# 2. Check SeaweedFS is running
docker-compose ps seaweedfs
# Expected: seaweedfs service is "Up"

# 3. Verify gitea bucket exists
docker-compose exec -T seaweedfs weed shell -master=seaweedfs:9333 -command "s3.bucket.list"
# Expected: Should show "gitea" bucket
```

### Step 2: Backup Current Gitea Data

Before making changes, create a backup of the existing Gitea data:

```bash
cd gitea
docker-compose stop git
docker run --rm -v gitea_git_data:/data -v $(pwd):/backup alpine tar czf /backup/gitea-backup-$(date +%Y%m%d-%H%M%S).tar.gz -C /data .
```

### Step 3: Stop Gitea

```bash
docker-compose stop git
```

### Step 3: Apply Configuration Changes

Choose one approach:

**Option A: Environment Variables**
```bash
# Edit docker-compose.yml to add environment variables
# (see Section 2.1)
```

**Option B: app.ini File**
```bash
# Create config directory and file
mkdir -p config/gitea

# Create app.ini with content from Section 2.2
cat > config/gitea/app.ini << 'EOF'
[storage]
STORAGE_TYPE = minio
MINIO_ENDPOINT = seaweedfs:9000
MINIO_ACCESS_KEY_ID = gitea_access_key
MINIO_SECRET_ACCESS_KEY = gitea_secret_key
MINIO_BUCKET = gitea
MINIO_USE_SSL = false
MINIO_BUCKET_LOOKUP_TYPE = path
SERVE_DIRECT = true
EOF

# Update docker-compose.yml to mount the file
# (see Section 2.2)
```

### Step 4: Verify SeaweedFS Bucket

**Note:** The `gitea` bucket should already exist from the MinIO → SeaweedFS migration (see `@PLAN.md`, section 3.1).

Verify bucket exists:

```bash
docker-compose exec -T seaweedfs weed shell -master=seaweedfs:9333 -command "s3.bucket.list"
```

If bucket does NOT exist, create it:

```bash
docker-compose exec -T seaweedfs weed shell -master=seaweedfs:9333 -command "s3.bucket.create -name=gitea"
```

### Step 5: Start Gitea

```bash
docker-compose up -d git
```

### Step 6: Verify Configuration

Check Gitea logs to ensure it connects to SeaweedFS successfully:

```bash
docker-compose logs -f git
```

Look for errors related to storage initialization.

### Step 7: Test Functionality

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

## 6. Data Migration Strategy

### Option A: Fresh Start (Recommended)

If existing data can be regenerated or is not critical:

1. **Stop Gitea**
2. **Configure SeaweedFS storage** (as above)
3. **Start Gitea**
4. **New data will be stored in SeaweedFS**
5. **Old local files remain accessible until overwritten**

### Option B: Migration (For Critical Data)

If you must preserve existing LFS objects or attachments:

1. **Install MinIO Client** (mc):
   ```bash
   docker run --rm -it --network git_cicd_net \
     quay.io/minio/mc:RELEASE.2025-02-21T16-00-46Z sh
   ```

2. **Configure local storage access** (before migration):
   ```bash
   # Assuming old data is in git_data volume
   mc alias set local http://git:3000/ --api S3v4
   ```

3. **Copy data to SeaweedFS**:
   ```bash
   mc mirror local/ seaweedfs
   ```

**Note:** This is complex and may require custom scripts depending on Gitea's internal file structure. For most setups, **Option A (Fresh Start)** is recommended as LFS files can be re-uploaded if needed.

## 7. Rollback Plan

If issues occur after migration:

### Immediate Rollback

1. **Stop Gitea**:
   ```bash
   docker-compose stop git
   ```

2. **Remove new configuration**:
   - If using environment variables: Remove the `GITEA__storage__*` entries from `docker-compose.yml`
   - If using `app.ini`: Remove the volume mount and file

3. **Restore backup** (if you made one):
   ```bash
   docker run --rm -v gitea_git_data:/data -v $(pwd):/backup alpine tar xzf /backup/gitea-backup-YYYYMMDD-HHMMSS.tar.gz -C /data
   ```

4. **Start Gitea**:
   ```bash
   docker-compose up -d git
   ```

### Note: Storage Backend Rollback

Rolling back Gitea configuration will return it to local filesystem storage. This does **not** restore MinIO - that's handled by the general migration plan in `@PLAN.md`.

If you need to completely revert to MinIO:
1. Roll back Gitea configuration (this section)
2. Roll back SeaweedFS deployment (see `@PLAN.md` rollback section)

### Verify Rollback

Check that:
- Gitea starts successfully
- Repositories are accessible
- Old attachments/avatars display correctly

## 8. Monitoring and Verification

### Check Storage Usage

Monitor SeaweedFS bucket usage:
```bash
docker-compose exec -T seaweedfs weed shell -master=seaweedfs:9333 -command "s3.bucket.stat -name=gitea"
```

### Check Gitea Logs

Monitor for storage-related errors:
```bash
docker-compose logs --tail 100 git | grep -i "storage\|minio\|s3"
```

### Verify Functionality Periodically

- New LFS uploads go to SeaweedFS
- New attachments display correctly
- Package registry works (if enabled)
- Actions artifacts upload/download correctly

## 9. Performance Considerations

### `SERVE_DIRECT = true`

When enabled, Gitea generates signed URLs that allow clients to download files directly from SeaweedFS, reducing load on the Gitea server.

### Network Latency

Ensure low latency between Gitea and SeaweedFS containers (same Docker network: `git_cicd_net`).

### Connection Pooling

Gitea's MinIO client handles connection pooling automatically. No additional tuning required for typical setups.

## 10. Troubleshooting

### Issue: Gitea fails to start with storage error

**Symptoms:** Container crashes, logs show "Endpoint does not follow ip address or domain name standards"

**Solutions:**
1. Verify `MINIO_ENDPOINT` is `host:port` format (not http://)
2. Check SeaweedFS is running: `docker-compose ps seaweedfs`
3. Verify network connectivity: `docker-compose exec git ping seaweedfs`

### Issue: Files not accessible after upload

**Symptoms:** Upload succeeds but downloads fail

**Solutions:**
1. Check bucket exists: `docker-compose exec seaweedfs weed shell -master=seaweedfs:9333 -command "s3.bucket.list"`
2. Verify credentials match `s3_config.json`
3. Check `SERVE_DIRECT` is set to `true` if using path-style buckets

### Issue: LFS uploads fail with "Access Denied"

**Symptoms:** Git LFS push returns 403 error

**Solutions:**
1. Verify `MINIO_ACCESS_KEY_ID` and `MINIO_SECRET_ACCESS_KEY` are correct
2. Check SeaweedFS `s3_config.json` grants `Read,Write` permissions to gitea user
3. Ensure bucket name matches configuration

## 11. Environment Variables Reference

Complete list for copy-paste to `docker-compose.yml`:

```yaml
environment:
  # Gitea S3/MinIO Storage Configuration
  GITEA__storage__STORAGE_TYPE: "minio"
  GITEA__storage__MINIO_ENDPOINT: "seaweedfs:9000"
  GITEA__storage__MINIO_ACCESS_KEY_ID: "${GITEA_S3_ACCESS_KEY_ID:-gitea_access_key}"
  GITEA__storage__MINIO_SECRET_ACCESS_KEY: "${GITEA_S3_SECRET_ACCESS_KEY:-gitea_secret_key}"
  GITEA__storage__MINIO_BUCKET: "${GITEA_S3_BUCKET:-gitea}"
  GITEA__storage__MINIO_USE_SSL: "false"
  GITEA__storage__MINIO_BUCKET_LOOKUP_TYPE: "path"
  GITEA__storage__SERVE_DIRECT: "true"
```

**Note:** Using environment variable defaults (`${VAR:-default}`) allows you to override via `.env` file if needed.

## 12. Summary Checklist

### Prerequisites (from `@PLAN.md`)
- [ ] MinIO → SeaweedFS migration complete
- [ ] MinIO service removed from docker-compose.yml
- [ ] SeaweedFS service running and healthy
- [ ] SeaweedFS S3 API accessible on port 9000
- [ ] SeaweedFS buckets created (gitea, drone-cache, etc.)

### Gitea Migration
- [ ] Gitea data backed up
- [ ] Gitea stopped
- [ ] Configuration applied (environment variables OR app.ini)
- [ ] SeaweedFS bucket `gitea` verified
- [ ] Gitea restarted successfully
- [ ] Gitea logs show no storage errors

### Verification
- [ ] LFS upload tested and working
- [ ] Attachment upload tested and working
- [ ] Avatar upload tested and working
- [ ] Packages registry tested (if enabled)
- [ ] Actions artifacts tested (if enabled)
- [ ] Old data accessible (fresh start) OR migrated (full migration)

### Safety
- [ ] Rollback plan documented
- [ ] Monitoring configured (Prometheus metrics)
- [ ] Backup stored securely

## References

- [Gitea Configuration Cheat Sheet - Storage](https://docs.gitea.com/administration/config-cheat-sheet)
- [Gitea MinIO Storage Module](https://github.com/go-gitea/gitea/blob/main/modules/storage/minio.go)
- [SeaweedFS S3 API Documentation](https://github.com/chrislusf/seaweedfs)
- [MinIO to SeaweedFS Migration Plan](./PLAN.md)
