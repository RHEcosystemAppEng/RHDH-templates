# RAG Chatbot CI/CD Integration

This repository has been enhanced with a complete CI/CD integration that automatically builds and deploys your application when you make changes to the source code.

## What's Included

### 🔄 Automatic Build Pipeline
- **GitHub Actions** (`.github/workflows/build-and-deploy.yml`)
- **GitLab CI** (`.gitlab-ci.yml`) 
- **Dockerfile** for containerizing your application

### 🚀 GitOps Integration
- **Tekton Pipeline** for building container images
- **Webhook Triggers** for automatic deployment
- **ArgoCD Integration** for GitOps-based deployment

## Quick Start

### 1. Initial Setup
After deploying the template, you'll have two repositories:
- **Source Repository** (this repo): Contains your application code
- **GitOps Repository**: Contains deployment configurations

### 2. Configure Webhooks
Follow the detailed steps in [`docs/ci-cd-integration.md`](./docs/ci-cd-integration.md) to:
- Set up webhook secrets
- Configure repository webhooks
- Connect CI/CD variables

### 3. Start Developing
Once configured, simply:
```bash
# Make changes to your Streamlit dashboard
vi main.py

# Commit and push
git add .
git commit -m "Update dashboard UI"
git push origin main
```

The CI/CD pipeline will automatically:
1. ✅ Build a new container image
2. ✅ Push it to the registry
3. ✅ Update the GitOps repository
4. ✅ Trigger ArgoCD to deploy the new version

## Architecture

```
Developer → Source Repo → CI/CD → Container Registry → GitOps Repo → ArgoCD → OpenShift
    ↓           ↓          ↓            ↓              ↓          ↓         ↓
 Code Change → Build → Push Image → Update Config → Deploy → App Updated
```

## File Structure

```
├── .github/workflows/          # GitHub Actions
│   └── build-and-deploy.yml   
├── .gitlab-ci.yml             # GitLab CI configuration
├── Dockerfile                 # Container build instructions
├── docs/
│   └── ci-cd-integration.md   # Detailed setup guide
├── main.py                    # Your Streamlit application
└── requirements.txt           # Python dependencies
```

## Key Features

- 🔄 **Zero-Downtime Deployments**: Rolling updates via ArgoCD
- 🔍 **Automatic Rollbacks**: ArgoCD detects failed deployments
- 📊 **Build Monitoring**: Track builds in your Git platform
- 🔒 **Secure**: Uses platform-native authentication
- 🎯 **GitOps Best Practices**: Infrastructure as Code

## Next Steps

1. **Read the Documentation**: See [`docs/ci-cd-integration.md`](./docs/ci-cd-integration.md) for complete setup instructions
2. **Customize Your App**: Modify `main.py` and other application files
3. **Add Dependencies**: Update `requirements.txt` as needed
4. **Monitor Deployments**: Use ArgoCD UI to track application status

## Support

- 📖 **Documentation**: [`docs/ci-cd-integration.md`](./docs/ci-cd-integration.md)
- 🐛 **Issues**: Check troubleshooting section in the docs
- 💬 **Help**: Contact your platform team

---

**Happy Coding!** 🎉 Your changes will now automatically deploy to OpenShift. 