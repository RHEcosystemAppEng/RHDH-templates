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

### 🎯 For Demo/Proof-of-Concept (Recommended)

Use the **automated demo setup** for the fastest experience:

```bash
./scripts/demo-setup.sh
```

**Demo Features:**
- ✅ **Zero manual secrets** - auto-generated webhook tokens
- ✅ **Platform defaults** - uses GitHub/GitLab built-in authentication  
- ✅ **2-minute setup** - just add webhook to repository
- ✅ **Instant gratification** - perfect for demos and testing

### 🏢 For Production/Enterprise

Use the **comprehensive production setup** for enterprise environments:

```bash
./scripts/setup-secrets.sh
```

**Production Features:**
- 🔒 **Manual secret control** - full security oversight
- 🎛️ **Custom registries** - configure any container registry
- 🔐 **SSH key support** - private repository access
- 📋 **Compliance ready** - meets enterprise security requirements

## Setup Process

### Demo Setup (2 minutes)
1. Run `./scripts/demo-setup.sh`
2. Follow the generated `DEMO-SETUP-INSTRUCTIONS.md`
3. Add webhook to your repository
4. Push code and watch automatic deployment!

### Production Setup (10 minutes)
1. Run `./scripts/setup-secrets.sh`
2. Follow detailed prompts for security configuration
3. Configure enterprise-specific requirements
4. Test and validate in staging environment

## Architecture

```
Developer → Source Repo → CI/CD → Container Registry → GitOps Repo → ArgoCD → OpenShift
    ↓           ↓          ↓            ↓              ↓          ↓         ↓
 Code Change → Build → Push Image → Update Config → Deploy → App Updated
```

## File Structure

```
├── scripts/
│   ├── demo-setup.sh              # 🎯 DEMO: Automated setup
│   └── setup-secrets.sh           # 🏢 PRODUCTION: Manual setup
├── .github/workflows/             # GitHub Actions
│   └── build-and-deploy.yml   
├── .gitlab-ci.yml                 # GitLab CI configuration
├── Dockerfile                     # Container build instructions
├── docs/
│   ├── ci-cd-integration.md       # Technical setup guide
│   └── secrets-management.md      # Comprehensive secrets guide
├── main.py                        # Your Streamlit application
└── requirements.txt               # Python dependencies
```

## Key Features

- 🔄 **Zero-Downtime Deployments**: Rolling updates via ArgoCD
- 🔍 **Automatic Rollbacks**: ArgoCD detects failed deployments
- 📊 **Build Monitoring**: Track builds in your Git platform
- 🔒 **Secure**: Uses platform-native authentication
- 🎯 **GitOps Best Practices**: Infrastructure as Code

## Which Setup Should I Use?

| Use Case        | Script             | Time   | Features                                   |
| --------------- | ------------------ | ------ | ------------------------------------------ |
| **Demo/PoC**    | `demo-setup.sh`    | 2 min  | Auto-generated secrets, platform defaults  |
| **Development** | `demo-setup.sh`    | 2 min  | Quick testing, rapid iteration             |
| **Staging**     | `setup-secrets.sh` | 10 min | Production-like environment                |
| **Production**  | `setup-secrets.sh` | 10 min | Full security control, enterprise features |

## Next Steps

1. **Choose your setup**: Demo for quick start, Production for enterprise
2. **Run the appropriate script**: Follow the prompts
3. **Configure webhook**: Add to your Git repository
4. **Test the pipeline**: Push a change and watch it deploy
5. **Monitor deployments**: Use ArgoCD UI to track application status

## Support

- 📖 **Demo Guide**: Run `./scripts/demo-setup.sh` for automated instructions
- 📖 **Production Guide**: [`docs/ci-cd-integration.md`](./docs/ci-cd-integration.md)
- 🔐 **Secrets Guide**: [`docs/secrets-management.md`](./docs/secrets-management.md)
- 🐛 **Issues**: Check troubleshooting section in the docs
- 💬 **Help**: Contact your platform team

---

**Happy Coding!** 🎉 Your changes will now automatically deploy to OpenShift. 