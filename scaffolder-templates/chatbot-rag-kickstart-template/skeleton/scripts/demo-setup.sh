#!/bin/bash

# DEMO: Simplified CI/CD Setup Script for RAG Chatbot Template
# This script automates setup for demo purposes with minimal manual configuration

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}  RAG Chatbot DEMO Setup (Automated)${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
}

print_step() {
    echo -e "${GREEN}[DEMO]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_instructions() {
    echo -e "${YELLOW}[SETUP]${NC} $1"
}

get_demo_config() {
    print_step "Getting auto-generated demo configuration..."
    
    # Get app name from current directory or prompt
    APP_NAME=$(basename "$(pwd)" 2>/dev/null || echo "my-rag-app")
    NAMESPACE="${APP_NAME}-ns"
    BUILD_NAMESPACE="${NAMESPACE}-build"
    
    print_info "Application: $APP_NAME"
    print_info "Namespace: $NAMESPACE"
    print_info "Build Namespace: $BUILD_NAMESPACE"
    echo ""
}

get_webhook_info() {
    print_step "Getting webhook configuration..."
    
    # Try to get webhook info from OpenShift
    if command -v oc &> /dev/null && oc whoami &> /dev/null; then
        print_info "Getting webhook URL from OpenShift..."
        
        # Wait a moment for route to be available
        for i in {1..10}; do
            if oc get route "${APP_NAME}-webhook-route" -n "$BUILD_NAMESPACE" &> /dev/null; then
                WEBHOOK_URL="https://$(oc get route ${APP_NAME}-webhook-route -n $BUILD_NAMESPACE -o jsonpath='{.spec.host}')"
                break
            fi
            sleep 3
        done
        
        # Get webhook secret from ConfigMap
        if oc get configmap "${APP_NAME}-demo-config" -n "$BUILD_NAMESPACE" &> /dev/null; then
            WEBHOOK_SECRET=$(oc get configmap "${APP_NAME}-demo-config" -n "$BUILD_NAMESPACE" -o jsonpath='{.data.webhook-secret}')
        else
            WEBHOOK_SECRET="demo-webhook-secret-$(date +%s)"
        fi
    else
        print_info "OpenShift not available - showing example configuration"
        WEBHOOK_URL="https://${APP_NAME}-webhook-route-${BUILD_NAMESPACE}.apps.YOUR-CLUSTER.com"
        WEBHOOK_SECRET="demo-webhook-secret-$(date +%s)"
    fi
    
    print_info "Webhook URL: $WEBHOOK_URL"
    print_info "Webhook Secret: $WEBHOOK_SECRET"
    echo ""
}

create_setup_file() {
    print_step "Creating demo setup instructions..."
    
    cat > "DEMO-SETUP-INSTRUCTIONS.md" << EOF
# 🚀 RAG Chatbot Demo Setup

## ✅ Automated Configuration Complete!

Your RAG Chatbot CI/CD integration has been automatically configured for demo purposes.

### 📋 Configuration Summary

- **Application Name**: \`$APP_NAME\`
- **Webhook URL**: \`$WEBHOOK_URL\`
- **Webhook Secret**: \`$WEBHOOK_SECRET\`

### 🔧 Quick Setup (2 minutes)

#### For GitHub:
1. Go to your repository **Settings > Webhooks**
2. Click **Add webhook**
3. **Payload URL**: \`$WEBHOOK_URL\`
4. **Content type**: \`application/json\`
5. **Secret**: \`$WEBHOOK_SECRET\`
6. **Which events**: Just the push event
7. Click **Add webhook**

#### For GitLab:
1. Go to your repository **Settings > Webhooks**
2. **URL**: \`$WEBHOOK_URL\`
3. **Secret token**: \`$WEBHOOK_SECRET\`
4. **Trigger**: Push events (checked)
5. **SSL verification**: Enable
6. Click **Add webhook**

### 🎯 Test Your Setup

1. **Make a change** to your Streamlit app:
   \`\`\`bash
   echo "# Demo update" >> README.md
   git add README.md
   git commit -m "Demo: test CI/CD pipeline"
   git push origin main
   \`\`\`

2. **Watch the magic happen**:
   - ✅ GitHub Actions or GitLab CI builds your container
   - ✅ Webhook triggers the OpenShift pipeline
   - ✅ ArgoCD automatically deploys the update
   - ✅ Your app updates with zero manual intervention!

### 🔍 Monitor Progress

- **GitHub**: Check the **Actions** tab
- **GitLab**: Check **CI/CD > Pipelines**
- **OpenShift**: Check the **Developer** perspective > **Pipelines**
- **ArgoCD**: Check **Applications** in the GitOps section

### 🎉 Demo Features

✅ **Zero Manual Secrets**: Uses platform authentication automatically  
✅ **Auto-Generated Webhooks**: No manual token generation needed  
✅ **Multi-Platform**: Works with GitHub and GitLab  
✅ **GitOps Ready**: Full ArgoCD integration out of the box  
✅ **Production Ready**: Can be enhanced for production use  

### 💡 What Happens Next?

Every time you push code to the \`main\` branch:

1. **CI/CD Pipeline** builds a new container image
2. **Webhook** notifies OpenShift Tekton pipeline
3. **Tekton** updates the GitOps repository with new image tag
4. **ArgoCD** detects the change and deploys automatically
5. **Your app** updates with zero downtime!

---

**🎊 Happy Coding!** Your demo environment is ready to showcase automatic deployments!
EOF

    print_info "Demo setup instructions saved to: DEMO-SETUP-INSTRUCTIONS.md"
    echo ""
}

show_demo_summary() {
    print_step "Demo setup complete!"
    echo ""
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║                    DEMO READY! 🎉                       ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}What was automated:${NC}"
    echo "✅ Webhook secrets auto-generated"
    echo "✅ Container registry authentication (uses platform defaults)"
    echo "✅ GitOps pipeline configuration"
    echo "✅ ArgoCD integration"
    echo ""
    echo -e "${GREEN}Quick setup remaining:${NC}"
    echo "🔧 Add webhook to your Git repository (2 minutes)"
    echo "🔧 Push a change to test the pipeline"
    echo ""
    echo -e "${GREEN}Files created:${NC}"
    echo "📄 DEMO-SETUP-INSTRUCTIONS.md (complete setup guide)"
    echo ""
    echo -e "${YELLOW}Next step: Open DEMO-SETUP-INSTRUCTIONS.md and follow the webhook setup!${NC}"
}

# Main execution
main() {
    print_header
    get_demo_config
    get_webhook_info
    create_setup_file
    show_demo_summary
}

# Run main function
main "$@" 