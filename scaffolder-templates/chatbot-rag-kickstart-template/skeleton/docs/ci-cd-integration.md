# CI/CD Integration for RAG Chatbot

This document explains how the CI/CD integration works for the RAG Chatbot application, enabling automatic builds and deployments when you make changes to your Streamlit dashboard or other application code.

## Architecture Overview

The CI/CD integration follows a GitOps pattern with the following components:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Source Repo    │    │  GitOps Repo    │    │  OpenShift      │
│                 │    │                 │    │  Cluster        │
│ • Application   │───▶│ • Helm Charts   │───▶│ • Running App   │
│   Code          │    │ • ArgoCD Apps   │    │ • ArgoCD        │
│ • Streamlit     │    │ • Build Pipeline│    │ • Tekton        │
│ • CI/CD Configs │    │ • Manifests     │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       ▲
         │                       │
         └───────────────────────┘
           Webhook Triggers
```

## How It Works

### 1. Source Code Changes
When you modify your Streamlit dashboard or any application code:

1. **Push to Source Repository**: Commit and push changes to the main branch
2. **CI Pipeline Triggered**: GitHub Actions or GitLab CI automatically starts
3. **Container Build**: New container image is built with your changes
4. **Image Push**: Image is pushed to the container registry
5. **Webhook Call**: CI pipeline calls the GitOps webhook

### 2. GitOps Update Process
The webhook triggers a Tekton pipeline that:

1. **Clones GitOps Repo**: Fetches the current deployment configuration
2. **Updates Image Tag**: Updates the Helm values with the new image tag
3. **Commits Changes**: Commits the update back to the GitOps repository
4. **ArgoCD Detection**: ArgoCD detects the GitOps repo change
5. **Automatic Deployment**: ArgoCD deploys the new version to OpenShift

## Setting Up the Integration

### Prerequisites
- OpenShift cluster with:
  - OpenShift Pipelines (Tekton) operator installed
  - ArgoCD/OpenShift GitOps operator installed
- Source repository with appropriate permissions
- GitOps repository accessible by the cluster

### Step 1: Configure Webhook Secret
Create a webhook secret in your GitOps namespace:

```bash
oc create secret generic gitlab-webhook-secret \
  --from-literal=secretToken=YOUR_WEBHOOK_SECRET \
  -n your-app-namespace-build
```

### Step 2: Get Webhook URL
After deployment, get the webhook URL:

```bash
oc get route your-app-name-webhook-route -n your-app-namespace-build -o jsonpath='{.spec.host}'
```

### Step 3: Configure Source Repository

#### For GitLab:
1. Go to your source repository settings
2. Navigate to **Webhooks**
3. Add a new webhook:
   - URL: `https://YOUR_WEBHOOK_URL`
   - Secret Token: `YOUR_WEBHOOK_SECRET`
   - Trigger: Push events
   - SSL verification: Enable

#### For GitHub:
1. Go to repository **Settings** → **Webhooks**
2. Add webhook:
   - Payload URL: `https://YOUR_WEBHOOK_URL`
   - Content type: `application/json`
   - Secret: `YOUR_WEBHOOK_SECRET`
   - Events: Just the push event

### Step 4: Set CI/CD Variables

#### GitLab Variables:
- `GITOPS_WEBHOOK_URL`: The webhook URL from Step 2

#### GitHub Secrets:
- `GITOPS_WEBHOOK_URL`: The webhook URL from Step 2

## Making Changes to Your Streamlit Dashboard

Once the integration is set up, making changes is simple:

1. **Edit Your Code**: Modify files in the source repository
   ```bash
   # Example: Update your Streamlit app
   vi main.py
   git add .
   git commit -m "Update dashboard UI"
   git push origin main
   ```

2. **Monitor the Build**: Watch the CI/CD pipeline in your Git platform
   - GitLab: Go to **CI/CD** → **Pipelines**
   - GitHub: Go to **Actions** tab

3. **Track Deployment**: Monitor ArgoCD for deployment status
   - OpenShift Console → **GitOps** → **Applications**
   - Or use ArgoCD UI directly

4. **Verify Changes**: Check your running application
   ```bash
   oc get route your-app-name-rag-ui -n your-namespace
   ```

## Troubleshooting

### Build Pipeline Not Triggering
- Check webhook configuration in source repository
- Verify webhook secret matches in OpenShift
- Check EventListener pod logs:
  ```bash
  oc logs -l eventlistener=your-app-name-event-listener -n your-namespace-build
  ```

### Build Failing
- Check PipelineRun logs:
  ```bash
  oc get pipelinerun -n your-namespace-build
  oc logs pipelinerun/your-pipeline-run-name -n your-namespace-build
  ```

### ArgoCD Not Deploying
- Check ArgoCD application status:
  ```bash
  oc get application your-app-name-rag-ui -n janus-argocd
  ```
- Verify GitOps repository has been updated with new image tag

### Image Pull Errors
- Ensure image registry credentials are configured
- Check if image exists in the registry
- Verify image pull secrets in the application namespace

## Advanced Configuration

### Custom Build Parameters
You can customize the build pipeline by modifying the Helm values in your GitOps repository:

```yaml
# In helm/build-pipeline/values.yaml
pipeline:
  image:
    registry: "your-custom-registry.com"
  buildConfig:
    strategy: "Buildpacks"  # Alternative to Docker
  triggers:
    enabled: false  # Disable automatic triggers
```

### Multi-Environment Deployments
Set up different branches for different environments:
- `main` → Production
- `develop` → Staging
- `feature/*` → Development

### Custom Tekton Tasks
Add custom tasks to the pipeline for:
- Security scanning
- Code quality checks
- Integration tests
- Deployment notifications

## Best Practices

1. **Use Feature Branches**: Develop on feature branches and use pull/merge requests
2. **Tag Releases**: Use semantic versioning for production releases
3. **Monitor Resources**: Watch build namespace resource usage
4. **Backup GitOps**: Ensure GitOps repository is backed up
5. **Security Scanning**: Add security scanning to your pipeline
6. **Resource Limits**: Set appropriate resource limits for build pods

## Support

For issues with the CI/CD integration:
1. Check the troubleshooting section above
2. Review ArgoCD and Tekton documentation
3. Check OpenShift cluster events and logs
4. Consult your platform team for cluster-specific configurations 