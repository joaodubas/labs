#!/usr/bin/env sh

# Wait for SeaweedFS Primary to be ready
until weed shell -master=seaweedfs:9333 -command "cluster.check" > /dev/null 2>&1; do
	echo "Waiting for SeaweedFS Primary..."
	sleep 2
done

# Create buckets
echo "Creating buckets..."
for bucket in forgejo k3d-registry; do
	echo "Create bucket $bucket"
	echo "s3.bucket.create -name=$bucket" | weed shell -master=seaweedfs:9333
done
echo "Buckets created successfully."
