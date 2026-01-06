#!/usr/bin/env bash
set -e
# NOTE: (jpd) Based on https://cloud.google.com/sdk/docs/install#deb 
echo "*** Install system dependencies for Google Cloud SDK ***"
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates gnupg curl
echo "*** Configure signature and repository for Google Cloud SDK ***"
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
echo "*** Install Google Cloud SDK ***"
sudo apt-get update && sudo apt-get install google-cloud-cli
