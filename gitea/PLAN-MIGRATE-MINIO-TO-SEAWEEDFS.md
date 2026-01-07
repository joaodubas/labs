# Migration Plan: `MinIO` to `SeaweedFS`

This document outlines the steps to migrate the artifact and cache storage backend from `MinIO` to `SeaweedFS` within the `Gitea`/`Drone` CI environment.

## 1. Preparation

`SeaweedFS` uses a JSON configuration file to manage `S3` identities (users) and their permissions. We will create this file to provision users for `Gitea`, `Drone`, Woodpecker CI, and K3d.

### 1.1 Create Configuration Directory

Ensure a directory exists to store the `SeaweedFS` configuration.

```bash
mkdir -p gitea/config/seaweedfs
```

### 1.2 Create `s3_config.json`

Create the file `gitea/config/seaweedfs/s3_config.json` with the following content.

**Important:** Replace the `accessKey` and `secretKey` values with secure, random strings before deploying.

```json
{
  "identities": [
    {
      "name": "admin",
      "credentials": [
        { "accessKey": "admin_access_key", "secretKey": "admin_secret_key" }
      ],
      "actions": ["Admin", "Read", "Write"]
    },
    {
      "name": "gitea",
      "credentials": [
        { "accessKey": "gitea_access_key", "secretKey": "gitea_secret_key" }
      ],
      "actions": ["Read", "Write"],
      "resources": ["buckets/gitea*"]
    },
    {
      "name": "drone",
      "credentials": [
        { "accessKey": "drone_access_key", "secretKey": "drone_secret_key" }
      ],
      "actions": ["Read", "Write"],
      "resources": ["buckets/drone*"]
    },
    {
      "name": "woodpecker",
      "credentials": [
        { "accessKey": "woodpecker_access_key", "secretKey": "woodpecker_secret_key" }
      ],
      "actions": ["Read", "Write"],
      "resources": ["buckets/woodpecker*"]
    },
    {
      "name": "k3d",
      "credentials": [
        { "accessKey": "k3d_access_key", "secretKey": "k3d_secret_key" }
      ],
      "actions": ["Read", "Write"],
      "resources": ["buckets/k3d*"]
    }
  ]
}
```

## 2. Docker Compose Configuration

We will replace the existing `minio` and `mc` services with a single `seaweedfs` service running in "server" mode.

### 2.1 Update `@gitea/docker-compose.yml`

**Remove** the following services:

- `minio`
- `mc`

**Add** the `seaweedfs` service definition:

```yaml
  seaweedfs:
    image: "chrislusf/seaweedfs:3.59"
    hostname: seaweedfs
    restart: unless-stopped
    # Runs Master, Volume, Filer, and `S3` in one process
    # -volume.max=0 allows unlimited volumes (limited by disk space)
    command: 'server -dir=/data -s3 -s3.port=9000 -s3.config=/etc/seaweedfs/s3_config.json -s3.allowEmptyFolder=false -volume.max=0'
    volumes:
      # Reusing the existing volume name for convenience, but data format is incompatible
      - "minio_data:/data"
      - "./config/seaweedfs/s3_config.json:/etc/seaweedfs/s3_config.json:ro"
    ports:
      - "9000:9000"   # `S3` API
      - "8888:8888"   # Filer UI / API
      - "9333:9333"   # Master UI / API
      - "8080:8080"   # Volume Server UI / API (Metrics)
    networks:
      - git_cicd_net
```

## 3. Bucket Provisioning

To ensure all necessary buckets exist before applications start, we will add an initialization step.

### 3.1 Create `create_buckets.sh`

Create `gitea/config/seaweedfs/create_buckets.sh` with the following content:

```bash
#!/bin/sh

# Wait for SeaweedFS Master to be ready
until weed shell -master=seaweedfs:9333 -command "cluster.check" > /dev/null 2>&1; do
  echo "Waiting for SeaweedFS Master..."
  sleep 2
done

# Create buckets
echo "Creating buckets..."
# Syntax: s3.bucket.create -name=<bucket_name>
for bucket in gitea drone-cache woodpecker-cache k3d-registry; do
  echo "s3.bucket.create -name=$bucket" | weed shell -master=seaweedfs:9333
done

echo "Buckets created successfully."
```

Ensure the script is executable:
```bash
chmod +x gitea/config/seaweedfs/create_buckets.sh
```

### 3.2 Add Initialization Service

Add the `init-seaweedfs` service to `@gitea/docker-compose.yml`. This service uses the `weed shell` command to communicate directly with the Master server.

```yaml
  init-seaweedfs:
    image: "chrislusf/seaweedfs:3.59"
    depends_on:
      - seaweedfs
    volumes:
      - ./config/seaweedfs/create_buckets.sh:/usr/local/bin/create_buckets.sh
    entrypoint: ["/bin/sh", "/usr/local/bin/create_buckets.sh"]
    networks:
      - git_cicd_net
```

## 4. Data Migration Strategy

`SeaweedFS` uses a different on-disk format than `MinIO`. The existing data in `minio_data` will not be readable by `SeaweedFS`.

### Option A: Fresh Start (Recommended for Caches)

If the data consists primarily of CI caches and build artifacts that can be regenerated:

1. Stop the current services: `docker-compose down`
2. Remove the existing volume to clear old `MinIO` data: `docker volume rm gitea_minio_data` (Check exact name with `docker volume ls`)
3. Start the new setup: `docker-compose up -d`

### Option B: Migration via Rclone

If you must preserve existing artifacts:

1. Keep the old `MinIO` container running (temporarily mapped to a different port, e.g., 9001).
2. Start the new `SeaweedFS` container on port 9000.
3. Use `rclone` to copy data from `MinIO` to `SeaweedFS`.

```bash
rclone sync minio:bucket-name s3:bucket-name \
  --s3-endpoint=http://seaweedfs:9000 \
  --s3-access-key-id=admin_access_key \
  --s3-secret-access-key=admin_secret_key
```

## 5. Client Configuration Updates

Update the services to use the new credentials and endpoint.

### 4.1 `Gitea`

Update `app.ini` or the relevant environment variables in `docker-compose.yml`:

- `STORAGE_TYPE`: `minio` (`Gitea` uses the `MinIO` client library for generic `S3`)
- `MINIO_ENDPOINT`: `seaweedfs:9000`
- `MINIO_ACCESS_KEY_ID`: `gitea_access_key`
- `MINIO_SECRET_ACCESS_KEY`: `gitea_secret_key`
- `MINIO_USE_SSL`: `false`
- **Important:** Ensure the "Path Style" option is enabled in `Gitea`'s storage settings if configuring via UI.

### 4.2 `Drone` CI

Update your drone secrets or `.drone.yml` configuration:

- **Secrets:** Update `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` with the values for the `drone` user defined in `s3_config.json`.
- **Pipeline:** In your `.drone.yml` `S3` steps (e.g., `plugins/s3`), ensure you set `path_style: true`.

```yaml
steps:
  - name: cache
    image: plugins/s3
    settings:
      bucket: drone-cache
      endpoint: http://seaweedfs:9000
      path_style: true # Required for `SeaweedFS`
      # ...
```

## 6. Metrics Configuration

`SeaweedFS` components expose Prometheus-compatible metrics on the `/metrics` endpoint. To monitor the health and performance of your storage backend, configure your Prometheus server to scrape these targets.

### 5.1 Scrape Targets

Add the following jobs to your `prometheus.yml` configuration:

```yaml
scrape_configs:
  - job_name: 'seaweedfs-master'
    static_configs:
      - targets: ['seaweedfs:9333']

  - job_name: 'seaweedfs-filer'
    static_configs:
      - targets: ['seaweedfs:8888']

  - job_name: 'seaweedfs-volume'
    static_configs:
      - targets: ['seaweedfs:8080']
```

> **Note:** Ensure that the port `8080` (Volume Server) is exposed in the `docker-compose.yml` if you are scraping from an external Prometheus instance (as added in section 2.1).