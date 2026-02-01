# OpenShift Deployment Guide for Blu-Reserve

## Prerequisites

1. OpenShift CLI (`oc`) installed
2. Access to OpenShift cluster
3. Container images built and pushed to registry
4. Appropriate permissions to create resources

## Deployment Steps

### Step 1: Login to OpenShift
```bash
oc login https://api.your-cluster.com:6443 --token=<your-token>
