#!/bin/bash

# CI/CD Secrets Setup Script for RAG Chatbot Template
# This script helps configure all necessary secrets for the CI/CD integration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
APP_NAME=""
NAMESPACE=""
GIT_PLATFORM=""
WEBHOOK_SECRET=""
GITOPS_WEBHOOK_URL=""

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}  RAG Chatbot CI/CD Secrets Setup${NC}"
    echo -e "${BLUE}  PRODUCTION/ENTERPRISE SETUP${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
    echo -e "${YELLOW}NOTE: For demo/quick setup, use ./demo-setup.sh instead${NC}"
    echo ""
}

print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if required tools are available
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    if ! command -v oc &> /dev/null; then
        print_error "OpenShift CLI (oc) is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v base64 &> /dev/null; then
        print_error "base64 command is not available"
        exit 1
    fi
    
    # Check if logged into OpenShift
    if ! oc whoami &> /dev/null; then
        print_error "Not logged into OpenShift. Please run 'oc login' first."
        exit 1
    fi
    
    print_info "Prerequisites check completed ✓"
    echo ""
}

# Collect configuration from user
collect_configuration() {
    print_step "Collecting configuration..."
    
    # Application name
    read -p "Enter your application name: " APP_NAME
    if [ -z "$APP_NAME" ]; then
        print_error "Application name cannot be empty"
        exit 1
    fi
    
    # Namespace
    read -p "Enter your application namespace: " NAMESPACE
    if [ -z "$NAMESPACE" ]; then
        print_error "Namespace cannot be empty"
        exit 1
    fi
    
    # Git platform
    echo "Select your Git platform:"
    echo "1) GitLab"
    echo "2) GitHub"
    read -p "Enter choice (1 or 2): " choice
    
    case $choice in
        1)
            GIT_PLATFORM="gitlab"
            ;;
        2)
            GIT_PLATFORM="github"
            ;;
        *)
            print_error "Invalid choice. Please select 1 or 2."
            exit 1
            ;;
    esac
    
    # Generate webhook secret
    WEBHOOK_SECRET=$(openssl rand -hex 20)
    print_info "Generated webhook secret: $WEBHOOK_SECRET"
    
    echo ""
}

# Create namespace if it doesn't exist
create_namespace() {
    print_step "Setting up namespaces..."
    
    BUILD_NAMESPACE="${NAMESPACE}-build"
    
    if ! oc get namespace "$NAMESPACE" &> /dev/null; then
        print_info "Creating namespace: $NAMESPACE"
        oc create namespace "$NAMESPACE"
    else
        print_info "Namespace $NAMESPACE already exists"
    fi
    
    if ! oc get namespace "$BUILD_NAMESPACE" &> /dev/null; then
        print_info "Creating build namespace: $BUILD_NAMESPACE"
        oc create namespace "$BUILD_NAMESPACE"
    else
        print_info "Build namespace $BUILD_NAMESPACE already exists"
    fi
    
    echo ""
}

# Create webhook secrets
create_webhook_secrets() {
    print_step "Creating webhook secrets..."
    
    BUILD_NAMESPACE="${NAMESPACE}-build"
    
    # Create GitLab webhook secret
    oc create secret generic gitlab-webhook-secret \
        --from-literal=secretToken="$WEBHOOK_SECRET" \
        -n "$BUILD_NAMESPACE" \
        --dry-run=client -o yaml | oc apply -f -
    
    # Create GitHub webhook secret  
    oc create secret generic github-webhook-secret \
        --from-literal=secretToken="$WEBHOOK_SECRET" \
        -n "$BUILD_NAMESPACE" \
        --dry-run=client -o yaml | oc apply -f -
    
    print_info "Webhook secrets created in namespace: $BUILD_NAMESPACE"
    echo ""
}

# Get webhook URL
get_webhook_url() {
    print_step "Getting webhook URL..."
    
    BUILD_NAMESPACE="${NAMESPACE}-build"
    
    # Wait for route to be created (may take a moment after ArgoCD deployment)
    print_info "Waiting for webhook route to be created..."
    
    for i in {1..30}; do
        if oc get route "${APP_NAME}-webhook-route" -n "$BUILD_NAMESPACE" &> /dev/null; then
            GITOPS_WEBHOOK_URL="https://$(oc get route ${APP_NAME}-webhook-route -n $BUILD_NAMESPACE -o jsonpath='{.spec.host}')"
            break
        fi
        
        if [ $i -eq 30 ]; then
            print_warning "Webhook route not found. You may need to run this script again after ArgoCD deploys the pipeline."
            GITOPS_WEBHOOK_URL="https://WEBHOOK_URL_WILL_BE_AVAILABLE_AFTER_DEPLOYMENT"
            break
        fi
        
        sleep 2
    done
    
    print_info "Webhook URL: $GITOPS_WEBHOOK_URL"
    echo ""
}

# Display Git platform specific instructions
display_git_instructions() {
    print_step "Git platform configuration instructions..."
    
    echo -e "${YELLOW}=== ${GIT_PLATFORM^^} CONFIGURATION ===${NC}"
    echo ""
    
    if [ "$GIT_PLATFORM" = "gitlab" ]; then
        echo "1. Go to your GitLab source repository"
        echo "2. Navigate to Settings > Webhooks"
        echo "3. Add a new webhook with:"
        echo "   - URL: $GITOPS_WEBHOOK_URL"
        echo "   - Secret Token: $WEBHOOK_SECRET"
        echo "   - Trigger: Push events"
        echo "   - SSL verification: Enable"
        echo ""
        echo "4. In GitLab CI/CD Variables (Settings > CI/CD > Variables):"
        echo "   - Add variable: GITOPS_WEBHOOK_URL = $GITOPS_WEBHOOK_URL"
        
    elif [ "$GIT_PLATFORM" = "github" ]; then
        echo "1. Go to your GitHub source repository"
        echo "2. Navigate to Settings > Webhooks"
        echo "3. Add webhook:"
        echo "   - Payload URL: $GITOPS_WEBHOOK_URL"
        echo "   - Content type: application/json"
        echo "   - Secret: $WEBHOOK_SECRET"
        echo "   - Events: Just the push event"
        echo ""
        echo "4. In GitHub Secrets (Settings > Secrets and variables > Actions):"
        echo "   - Add secret: GITOPS_WEBHOOK_URL = $GITOPS_WEBHOOK_URL"
    fi
    
    echo ""
}

# Create git credentials (optional)
setup_git_credentials() {
    print_step "Git credentials setup (optional)..."
    
    read -p "Do you need to set up Git SSH credentials for private repositories? (y/N): " setup_git
    
    if [[ $setup_git =~ ^[Yy]$ ]]; then
        read -p "Enter path to SSH private key file: " ssh_key_path
        
        if [ ! -f "$ssh_key_path" ]; then
            print_error "SSH key file not found: $ssh_key_path"
            return
        fi
        
        BUILD_NAMESPACE="${NAMESPACE}-build"
        
        # Create git credentials secret
        oc create secret generic git-credentials \
            --from-file=ssh-privatekey="$ssh_key_path" \
            --from-literal=known_hosts="$(ssh-keyscan github.com gitlab.com)" \
            --type=kubernetes.io/ssh-auth \
            -n "$BUILD_NAMESPACE" \
            --dry-run=client -o yaml | oc apply -f -
        
        print_info "Git credentials secret created"
    else
        print_info "Skipping Git credentials setup"
    fi
    
    echo ""
}

# Save configuration to file
save_configuration() {
    print_step "Saving configuration..."
    
    CONFIG_FILE="ci-cd-config.env"
    
    cat > "$CONFIG_FILE" << EOF
# RAG Chatbot CI/CD Configuration
# Generated on $(date)

APP_NAME="$APP_NAME"
NAMESPACE="$NAMESPACE"
BUILD_NAMESPACE="${NAMESPACE}-build"
GIT_PLATFORM="$GIT_PLATFORM"
WEBHOOK_SECRET="$WEBHOOK_SECRET"
GITOPS_WEBHOOK_URL="$GITOPS_WEBHOOK_URL"

# Git platform instructions saved in: git-platform-setup.md
EOF

    # Create markdown file with instructions
    cat > "git-platform-setup.md" << EOF
# Git Platform Setup Instructions

## Configuration Summary
- **Application**: $APP_NAME
- **Platform**: ${GIT_PLATFORM^^}
- **Webhook URL**: \`$GITOPS_WEBHOOK_URL\`
- **Webhook Secret**: \`$WEBHOOK_SECRET\`

$(display_git_instructions | sed 's/\x1b\[[0-9;]*m//g')

## Verification
After configuring the webhook:
1. Make a change to your application code
2. Commit and push to the main branch
3. Check the pipeline execution in your Git platform
4. Verify deployment in ArgoCD

## Troubleshooting
- Check webhook deliveries in your Git platform settings
- View pipeline logs: \`oc logs -l app.kubernetes.io/name=$APP_NAME -n ${NAMESPACE}-build\`
- Check ArgoCD application status in the OpenShift console
EOF

    print_info "Configuration saved to: $CONFIG_FILE"
    print_info "Setup instructions saved to: git-platform-setup.md"
    echo ""
}

# Main execution
main() {
    print_header
    check_prerequisites
    collect_configuration
    create_namespace
    create_webhook_secrets
    get_webhook_url
    setup_git_credentials
    display_git_instructions
    save_configuration
    
    echo -e "${GREEN}================================================${NC}"
    echo -e "${GREEN}  Setup completed successfully! ✓${NC}"
    echo -e "${GREEN}================================================${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Follow the instructions in: git-platform-setup.md"
    echo "2. Test the CI/CD pipeline by making a code change"
    echo "3. Monitor the deployment in ArgoCD"
    echo ""
    echo -e "${BLUE}Configuration files created:${NC}"
    echo "- ci-cd-config.env (environment variables)"
    echo "- git-platform-setup.md (setup instructions)"
}

# Run main function
main "$@" 