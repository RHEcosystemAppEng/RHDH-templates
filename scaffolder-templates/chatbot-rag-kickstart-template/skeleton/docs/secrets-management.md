# Secrets Management for RAG Chatbot CI/CD Integration

This document provides comprehensive guidance on managing secrets for the RAG Chatbot CI/CD integration across different platforms and scenarios.

## Overview

The CI/CD integration requires several types of secrets:

1. **Webhook Secrets** - For authenticating webhook calls from Git platforms
2. **Container Registry Credentials** - For pushing/pulling container images
3. **Git Repository Access** - For accessing private repositories (optional)
4. **GitOps Repository Updates** - For updating deployment configurations

## Quick Setup

### Automated Setup Script

Use the provided setup script for automated configuration:

```bash
# From your deployed source repository
./scripts/setup-secrets.sh
```

This script will:
- ✅ Create all required OpenShift secrets
- ✅ Generate secure webhook tokens
- ✅ Provide platform-specific configuration instructions
- ✅ Save configuration for later reference

## Manual Setup Instructions

### 1. Webhook Secrets (Required)

#### OpenShift/Tekton Side

Create webhook secrets in your build namespace:

```bash
# Generate a secure webhook secret
WEBHOOK_SECRET=$(openssl rand -hex 20)

# Create secrets in build namespace
oc create secret generic gitlab-webhook-secret \
  --from-literal=secretToken="$WEBHOOK_SECRET" \
  -n your-app-namespace-build

oc create secret generic github-webhook-secret \
  --from-literal=secretToken="$WEBHOOK_SECRET" \
  -n your-app-namespace-build
```

#### Git Platform Side

**For GitLab:**
1. Go to **Settings > Webhooks** in your source repository
2. Add webhook:
   - **URL**: `https://your-webhook-route-url`
   - **Secret Token**: Your generated webhook secret
   - **Trigger**: Push events
   - **SSL verification**: Enabled

**For GitHub:**
1. Go to **Settings > Webhooks** in your source repository
2. Add webhook:
   - **Payload URL**: `https://your-webhook-route-url`
   - **Content type**: `application/json`
   - **Secret**: Your generated webhook secret
   - **Events**: Just the push event

### 2. Container Registry Credentials

#### Option A: GitHub Container Registry (GHCR)

**Automatic (Recommended):**
- GitHub Actions automatically uses `GITHUB_TOKEN` for GHCR access
- No additional configuration needed for public repositories

**Custom Registry:**
Add these secrets to your GitHub repository:
```
CONTAINER_REGISTRY=your-registry.com
REGISTRY_USERNAME=your-username
REGISTRY_PASSWORD=your-token
```

#### Option B: GitLab Container Registry

**Automatic (Recommended):**
- GitLab CI automatically uses built-in `CI_REGISTRY_*` variables
- No additional configuration needed

**Custom Registry:**
Add these variables in GitLab CI/CD settings:
```
REGISTRY=your-registry.com
REGISTRY_USER=your-username
REGISTRY_PASSWORD=your-token
```

#### Option C: OpenShift Internal Registry

**For GitHub Actions:**
```bash
# Create a service account for registry access
oc create sa github-builder -n your-namespace

# Get the service account token
TOKEN=$(oc create token github-builder -n your-namespace)

# Add these secrets to GitHub:
CONTAINER_REGISTRY=image-registry.openshift-image-registry.svc:5000
REGISTRY_USERNAME=github-builder
REGISTRY_PASSWORD=$TOKEN
```

**For GitLab CI:**
```bash
# Create a service account for registry access
oc create sa gitlab-builder -n your-namespace

# Get the service account token
TOKEN=$(oc create token gitlab-builder -n your-namespace)

# Add these variables to GitLab:
REGISTRY=image-registry.openshift-image-registry.svc:5000
REGISTRY_USER=gitlab-builder
REGISTRY_PASSWORD=$TOKEN
```

### 3. Git Repository Access (Optional)

Only needed for private repositories or repositories requiring SSH access.

#### Create SSH Key Pair

```bash
# Generate SSH key pair
ssh-keygen -t ed25519 -C "ci-cd-pipeline" -f ci-cd-key

# Add public key to your Git platform
cat ci-cd-key.pub
```

#### Add to Git Platform

**GitHub:** Settings > Deploy keys > Add deploy key  
**GitLab:** Settings > Repository > Deploy Keys > Add key

#### Create OpenShift Secret

```bash
# Create git credentials secret
oc create secret generic git-credentials \
  --from-file=ssh-privatekey=ci-cd-key \
  --from-literal=known_hosts="$(ssh-keyscan github.com gitlab.com)" \
  --type=kubernetes.io/ssh-auth \
  -n your-app-namespace-build
```

### 4. GitOps Webhook Configuration

#### Get Webhook URL

```bash
# After ArgoCD deploys the pipeline, get the webhook URL
oc get route your-app-name-webhook-route -n your-app-namespace-build \
  -o jsonpath='{.spec.host}'
```

#### Configure in CI/CD Platform

**GitHub Secrets:**
```
GITOPS_WEBHOOK_URL=https://your-webhook-url
```

**GitLab Variables:**
```
GITOPS_WEBHOOK_URL=https://your-webhook-url
```

## Security Best Practices

### 1. Secret Rotation

**Webhook Secrets:**
```bash
# Generate new webhook secret
NEW_SECRET=$(openssl rand -hex 20)

# Update OpenShift secrets
oc patch secret gitlab-webhook-secret -n your-build-namespace \
  -p '{"data":{"secretToken":"'$(echo -n "$NEW_SECRET" | base64)'"}}'

# Update webhook configuration in Git platform
```

**Registry Tokens:**
- Use time-limited tokens when possible
- Rotate tokens regularly (quarterly recommended)
- Use service accounts with minimal required permissions

### 2. Permission Management

**OpenShift RBAC:**
```yaml
# Minimal permissions for CI/CD service accounts
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ci-cd-role
rules:
- apiGroups: [""]
  resources: ["secrets", "configmaps"]
  verbs: ["get", "list"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "patch"]
```

**Git Platform Access:**
- Use deploy keys instead of personal access tokens
- Limit scope to specific repositories
- Use read-only access where possible

### 3. Secret Storage

**DO:**
- ✅ Use platform-native secret management (GitHub Secrets, GitLab Variables, OpenShift Secrets)
- ✅ Enable secret scanning in your repositories
- ✅ Use environment-specific secrets
- ✅ Document secret purposes and rotation schedules

**DON'T:**
- ❌ Store secrets in code or configuration files
- ❌ Share secrets across environments unnecessarily
- ❌ Use long-lived personal access tokens
- ❌ Log secret values in CI/CD outputs

## Troubleshooting

### Common Issues

#### 1. Webhook Authentication Failures

**Symptoms:**
- Webhook deliveries fail with 401/403 errors
- Pipeline not triggering on code push

**Solutions:**
```bash
# Check webhook secret matches
oc get secret gitlab-webhook-secret -n your-build-namespace -o yaml

# Verify webhook configuration in Git platform
# Check webhook delivery logs in Git platform
```

#### 2. Registry Authentication Failures

**Symptoms:**
- Image push/pull failures
- "authentication required" errors

**Solutions:**
```bash
# For OpenShift internal registry
oc policy add-role-to-user system:image-builder your-service-account

# For external registries
# Verify credentials are correct
# Check token expiration
# Ensure registry URL is correct
```

#### 3. Git Access Failures

**Symptoms:**
- Repository clone failures
- SSH key authentication errors

**Solutions:**
```bash
# Test SSH key
ssh -T git@github.com

# Check known_hosts
oc get secret git-credentials -n your-build-namespace -o yaml | \
  base64 -d

# Verify deploy key is added to repository
```

### Debugging Commands

```bash
# Check pipeline logs
oc logs -l tekton.dev/pipeline=rag-build-pipeline -n your-build-namespace

# Check webhook event listener
oc logs -l eventlistener=your-app-event-listener -n your-build-namespace

# Check ArgoCD application status
oc get application your-app-rag-ui -n janus-argocd -o yaml

# Test webhook manually
curl -X POST "https://your-webhook-url" \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: push" \
  -d '{"repository":{"clone_url":"your-repo-url"},"after":"test-sha"}'
```

## Platform-Specific Configurations

### GitHub Enterprise

```bash
# For GitHub Enterprise instances
GITHUB_SERVER=github-enterprise.company.com

# Update GitHub Actions workflow
REGISTRY=$GITHUB_SERVER/your-org/your-repo
```

### GitLab Self-Hosted

```bash
# For self-hosted GitLab instances
GITLAB_SERVER=gitlab.company.com

# Update GitLab CI configuration
REGISTRY=$CI_REGISTRY  # Automatically configured by GitLab
```

### OpenShift with External Registry

```yaml
# For using external registry with OpenShift
apiVersion: v1
kind: Secret
metadata:
  name: external-registry-secret
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: <base64-encoded-docker-config>
```

## Migration and Backup

### Backup Current Configuration

```bash
# Export all secrets
oc get secrets -n your-build-namespace -o yaml > secrets-backup.yaml

# Export configuration
kubectl get cm ci-cd-config -n your-build-namespace -o yaml > config-backup.yaml
```

### Migration Between Environments

```bash
# Export from source environment
oc get secret webhook-secrets -n source-namespace -o yaml | \
  sed 's/namespace: source-namespace/namespace: target-namespace/' | \
  oc apply -f -
```

## Support and Resources

- **Setup Script**: Use `./scripts/setup-secrets.sh` for automated configuration
- **Documentation**: See `ci-cd-integration.md` for complete setup instructions
- **Troubleshooting**: Check OpenShift events and ArgoCD application status
- **Security**: Follow your organization's security policies for secret management

---

**Important**: Always follow your organization's security policies and compliance requirements when managing secrets and credentials. 