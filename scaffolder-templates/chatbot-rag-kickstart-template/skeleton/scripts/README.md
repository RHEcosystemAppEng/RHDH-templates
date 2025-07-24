# Setup Scripts

This directory contains setup scripts for configuring the CI/CD integration.

## Scripts Overview

### 🎯 `demo-setup.sh` - Demo/PoC Setup (Recommended for testing)

**Use for:**
- Demonstrations and proof-of-concepts
- Development environments
- Quick testing and validation
- Learning and experimentation

**Features:**
- ✅ Fully automated secret generation
- ✅ Uses platform authentication defaults (GitHub/GitLab)
- ✅ 2-minute setup time
- ✅ Zero manual secret management
- ✅ Perfect for demos and development

**Usage:**
```bash
./demo-setup.sh
```

### 🏢 `setup-secrets.sh` - Production/Enterprise Setup

**Use for:**
- Production environments
- Enterprise deployments
- Staging environments requiring production-like security
- Environments with specific compliance requirements

**Features:**
- 🔒 Manual control over all secrets
- 🎛️ Support for custom container registries
- 🔐 SSH key configuration for private repositories
- 📋 Comprehensive security options
- 🏢 Enterprise compliance features

**Usage:**
```bash
./setup-secrets.sh
```

## Quick Decision Guide

| Question                                      | Answer | Recommended Script |
| --------------------------------------------- | ------ | ------------------ |
| Is this for a demo?                           | Yes    | `demo-setup.sh`    |
| Do you need manual secret control?            | No     | `demo-setup.sh`    |
| Is this a production environment?             | Yes    | `setup-secrets.sh` |
| Do you have enterprise security requirements? | Yes    | `setup-secrets.sh` |
| Do you want the fastest setup?                | Yes    | `demo-setup.sh`    |
| Do you need custom registry authentication?   | Yes    | `setup-secrets.sh` |

## What Each Script Does

### Demo Setup Process
1. Auto-generates secure webhook secrets
2. Configures platform authentication defaults
3. Creates simple setup instructions
4. Generates webhook configuration
5. Ready in 2 minutes!

### Production Setup Process
1. Collects security requirements
2. Configures custom secrets manually
3. Sets up SSH keys if needed
4. Configures custom registries
5. Creates comprehensive configuration
6. Provides detailed security guidance

## Files Created

### Demo Setup
- `DEMO-SETUP-INSTRUCTIONS.md` - Simple webhook setup guide

### Production Setup
- `ci-cd-config.env` - Environment configuration
- `git-platform-setup.md` - Detailed setup instructions
- OpenShift secrets and configurations

## Need Help?

- **Demo issues**: Check `DEMO-SETUP-INSTRUCTIONS.md`
- **Production issues**: See `docs/secrets-management.md`
- **General guidance**: See `docs/ci-cd-integration.md`

---

**Recommendation**: Start with `demo-setup.sh` for testing, then use `setup-secrets.sh` for production deployment. 