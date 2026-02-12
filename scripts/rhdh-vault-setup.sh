#!/bin/bash
#
# RHDH Vault Plugin Setup Script
# ==============================
#
# This script automates the setup of the Vault scaffolder plugin for RHDH.
# Based on: https://github.com/dcurran90/rhdh/blob/vaultPlugin/remote_testing/docs/rhtap_process.txt
#
# PREREQUISITES:
#   - OpenShift CLI (oc) installed and logged in
#   - Vault deployed in the cluster (namespace: vault)
#   - Git installed
#   - Access to the GitOps repository
#
# USAGE:
#   ./rhdh-vault-setup.sh [OPTIONS]
#
# OPTIONS:
#   --gitops-repo <url>     GitOps repository URL (auto-detected from ArgoCD if not provided)
#   --vault-ns <ns>         Vault namespace (default: vault)
#   --backstage-ns <ns>     Backstage namespace (default: backstage)
#   --plugin-version <ver>  Vault plugin version (default: 0.1.14)
#   --dry-run               Print commands without executing
#   --skip-git-push         Skip pushing changes to GitOps repo
#   -h, --help              Show this help message
#
# ============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
VAULT_NAMESPACE="${VAULT_NAMESPACE:-vault}"
BACKSTAGE_NAMESPACE="${BACKSTAGE_NAMESPACE:-backstage}"
PLUGIN_VERSION="${PLUGIN_VERSION:-0.1.14}"
PLUGIN_INTEGRITY="sha512-M+Xvv/bIL7UvAlD/YLqtG39RKNNNMPmLmMyrHN112gOfrTNXSROBGX0AVRsrOUSc6XinrOlJX1E0Z1DhxYnpDw=="
GITOPS_REPO=""
DRY_RUN=false
SKIP_GIT_PUSH=false
WORK_DIR=$(mktemp -d)

# =============================================================================
# Helper Functions
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}STEP $1: $2${NC}"
    echo -e "${GREEN}========================================${NC}"
}

show_help() {
    head -30 "$0" | grep -E "^#" | sed 's/^# //' | sed 's/^#//'
    exit 0
}

run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} $*"
    else
        eval "$@"
    fi
}

cleanup() {
    if [ -d "$WORK_DIR" ]; then
        log_info "Cleaning up temporary directory: $WORK_DIR"
        rm -rf "$WORK_DIR"
    fi
}

trap cleanup EXIT

# =============================================================================
# Parse Arguments
# =============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        --gitops-repo)
            GITOPS_REPO="$2"
            shift 2
            ;;
        --vault-ns)
            VAULT_NAMESPACE="$2"
            shift 2
            ;;
        --backstage-ns)
            BACKSTAGE_NAMESPACE="$2"
            shift 2
            ;;
        --plugin-version)
            PLUGIN_VERSION="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --skip-git-push)
            SKIP_GIT_PUSH=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# =============================================================================
# Step 1: Verify Prerequisites
# =============================================================================

log_step "1" "Verifying prerequisites"

# Check oc is installed
if ! command -v oc &> /dev/null; then
    log_error "OpenShift CLI (oc) is not installed"
    exit 1
fi

# Check logged in
if ! oc whoami &> /dev/null; then
    log_error "Not logged into OpenShift. Run 'oc login' first"
    exit 1
fi

# Check git is installed
if ! command -v git &> /dev/null; then
    log_error "Git is not installed"
    exit 1
fi

# Check Vault namespace exists
if ! oc get namespace "$VAULT_NAMESPACE" &> /dev/null; then
    log_error "Vault namespace '$VAULT_NAMESPACE' not found"
    exit 1
fi

# Check Backstage namespace exists
if ! oc get namespace "$BACKSTAGE_NAMESPACE" &> /dev/null; then
    log_error "Backstage namespace '$BACKSTAGE_NAMESPACE' not found"
    exit 1
fi

log_success "Prerequisites verified"

# =============================================================================
# Step 1b: Auto-detect GitOps Repository URL (if not provided)
# =============================================================================

if [ -z "$GITOPS_REPO" ]; then
    log_info "Auto-detecting GitOps repository URL from ArgoCD..."
    
    GITOPS_REPO=$(oc get application.argoproj.io backstage-gitops -n openshift-gitops \
        -o jsonpath='{.spec.source.repoURL}' 2>/dev/null) || {
        log_error "Failed to auto-detect GitOps repository URL"
        log_error "Could not find 'backstage-gitops' application in 'openshift-gitops' namespace"
        log_error "Please provide the GitOps repo URL manually: --gitops-repo <url>"
        exit 1
    }
    
    if [ -z "$GITOPS_REPO" ]; then
        log_error "GitOps repository URL is empty. Please provide it manually: --gitops-repo <url>"
        exit 1
    fi
    
    log_success "Found GitOps repository: $GITOPS_REPO"
fi

# =============================================================================
# Step 2: Get Vault Token
# =============================================================================

log_step "2" "Retrieving Vault token from cluster"

VAULT_TOKEN=$(oc get secret -n "$VAULT_NAMESPACE" vault-token -o jsonpath="{.data.token}" 2>/dev/null | base64 -d) || {
    log_error "Failed to retrieve Vault token. Ensure Vault is deployed in namespace '$VAULT_NAMESPACE'"
    exit 1
}

if [ -z "$VAULT_TOKEN" ]; then
    log_error "Vault token is empty"
    exit 1
fi

log_success "Vault token retrieved successfully"

# =============================================================================
# Step 3: Create rhdh-vault-secrets Secret
# =============================================================================

log_step "3" "Creating rhdh-vault-secrets secret"

VAULT_ADDR="http://vault.${VAULT_NAMESPACE}.svc.cluster.local:8200"

# Check if secret already exists
if oc get secret rhdh-vault-secrets -n "$BACKSTAGE_NAMESPACE" &> /dev/null; then
    log_warn "Secret 'rhdh-vault-secrets' already exists in namespace '$BACKSTAGE_NAMESPACE'"
    read -rp "Do you want to delete and recreate it? (y/N): " RECREATE
    if [[ "$RECREATE" =~ ^[Yy]$ ]]; then
        run_cmd "oc delete secret rhdh-vault-secrets -n $BACKSTAGE_NAMESPACE"
    else
        log_info "Skipping secret creation"
    fi
fi

if ! oc get secret rhdh-vault-secrets -n "$BACKSTAGE_NAMESPACE" &> /dev/null; then
    run_cmd "oc create secret generic rhdh-vault-secrets \
        --from-literal=VAULT_ADDR='$VAULT_ADDR' \
        --from-literal=VAULT_TOKEN='$VAULT_TOKEN' \
        -n $BACKSTAGE_NAMESPACE"
    log_success "Secret 'rhdh-vault-secrets' created"
else
    log_info "Secret 'rhdh-vault-secrets' already exists, skipping"
fi

# Verify secret
run_cmd "oc get secret rhdh-vault-secrets -n $BACKSTAGE_NAMESPACE -o yaml | head -10"

# =============================================================================
# Step 4: Clone GitOps Repository
# =============================================================================

log_step "4" "Cloning GitOps repository"

cd "$WORK_DIR"
run_cmd "git clone '$GITOPS_REPO' gitops-repo"
cd gitops-repo

log_success "GitOps repository cloned to $WORK_DIR/gitops-repo"

# =============================================================================
# Step 5: Update backstage-rhtap-values.yaml
# =============================================================================

log_step "5" "Updating backstage-rhtap-values.yaml"

VALUES_FILE="charts/backstage/backstage-rhtap-values.yaml"

if [ ! -f "$VALUES_FILE" ]; then
    log_error "Values file not found: $VALUES_FILE"
    exit 1
fi

# Check if plugin is already configured
if grep -q "backstage-plugin-scaffolder-backend-module-vault-secret-add-module" "$VALUES_FILE"; then
    log_warn "Vault plugin already configured in values file"
    read -rp "Do you want to continue anyway? (y/N): " CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        log_info "Exiting without changes"
        exit 0
    fi
fi

# Backup original file
cp "$VALUES_FILE" "${VALUES_FILE}.backup"
log_info "Created backup: ${VALUES_FILE}.backup"

# 5a. Add dynamic plugin (after redhat-argocd plugin)
log_info "Adding Vault dynamic plugin..."

# Find the line with redhat-argocd and add vault plugin after it
if grep -q "backstage-community-plugin-redhat-argocd" "$VALUES_FILE"; then
    sed -i.tmp '/backstage-community-plugin-redhat-argocd/,/disabled: false/ {
        /disabled: false/a\
      # Vault scaffolder plugin for vault:add-secret action\
      - package: "@danielcurran90/backstage-plugin-scaffolder-backend-module-vault-secret-add-module@'"$PLUGIN_VERSION"'"\
        disabled: false\
        integrity: "'"$PLUGIN_INTEGRITY"'"
    }' "$VALUES_FILE"
    rm -f "${VALUES_FILE}.tmp"
    log_info "Added Vault plugin to dynamic plugins section"
else
    log_warn "Could not find redhat-argocd plugin marker. Please add plugin manually."
fi

# 5b. Add extraEnvVarsSecrets (after extraEnvVars section)
log_info "Adding extraEnvVarsSecrets..."

if ! grep -q "extraEnvVarsSecrets" "$VALUES_FILE"; then
    sed -i.tmp '/LOG_LEVEL/,/value: debug/ {
        /value: debug/a\
    # Load VAULT_ADDR and VAULT_TOKEN from rhdh-vault-secrets\
    extraEnvVarsSecrets:\
      - rhdh-vault-secrets
    }' "$VALUES_FILE"
    rm -f "${VALUES_FILE}.tmp"
    log_info "Added extraEnvVarsSecrets"
else
    log_info "extraEnvVarsSecrets already configured"
fi

# 5c. Add rhdhVault appConfig (after reading.allow section)
log_info "Adding rhdhVault appConfig..."

if ! grep -q "rhdhVault:" "$VALUES_FILE"; then
    sed -i.tmp '/reading:/,/- host:/ {
        /- host:/a\
\
      # Vault configuration for scaffolder vault:add-secret action\
      rhdhVault:\
        baseUrl: ${VAULT_ADDR}\
        token: ${VAULT_TOKEN}
    }' "$VALUES_FILE"
    rm -f "${VALUES_FILE}.tmp"
    log_info "Added rhdhVault appConfig"
else
    log_info "rhdhVault appConfig already configured"
fi

log_success "Values file updated"

# Show diff
log_info "Changes made to values file:"
diff "${VALUES_FILE}.backup" "$VALUES_FILE" || true

# =============================================================================
# Step 6: Commit and Push Changes
# =============================================================================

log_step "6" "Committing and pushing changes"

run_cmd "git add '$VALUES_FILE'"
run_cmd "git commit -m 'Add Vault scaffolder plugin for vault:add-secret action

- Add @danielcurran90/backstage-plugin-scaffolder-backend-module-vault-secret-add-module@$PLUGIN_VERSION
- Add extraEnvVarsSecrets to load VAULT_ADDR and VAULT_TOKEN from rhdh-vault-secrets
- Add rhdhVault appConfig with baseUrl and token'"

if [ "$SKIP_GIT_PUSH" = true ]; then
    log_warn "Skipping git push (--skip-git-push flag set)"
else
    run_cmd "git push origin main"
    log_success "Changes pushed to GitOps repository"
fi

# =============================================================================
# Step 7: Trigger ArgoCD Sync
# =============================================================================

log_step "7" "Triggering ArgoCD sync"

# Refresh backstage-gitops app
if oc get application.argoproj.io backstage-gitops -n openshift-gitops &> /dev/null; then
    run_cmd "oc patch application.argoproj.io backstage-gitops -n openshift-gitops --type merge -p '{\"metadata\":{\"annotations\":{\"argocd.argoproj.io/refresh\":\"hard\"}}}'"
    log_info "Triggered refresh on backstage-gitops"
fi

# Refresh backstage app
if oc get application.argoproj.io backstage -n openshift-gitops &> /dev/null; then
    run_cmd "oc patch application.argoproj.io backstage -n openshift-gitops --type merge -p '{\"metadata\":{\"annotations\":{\"argocd.argoproj.io/refresh\":\"hard\"}}}'"
    log_info "Triggered refresh on backstage"
fi

log_success "ArgoCD refresh triggered"

# =============================================================================
# Step 8: Wait for Deployment Rollout
# =============================================================================

log_step "8" "Waiting for deployment rollout"

log_info "Waiting 30 seconds for ArgoCD to sync..."
sleep 30

log_info "Waiting for backstage-developer-hub deployment to roll out..."
run_cmd "oc rollout status deployment/backstage-developer-hub -n $BACKSTAGE_NAMESPACE --timeout=300s" || {
    log_warn "Rollout timed out or failed. Check deployment status manually."
}

log_success "Deployment rollout complete"

# =============================================================================
# Step 9: Verify Plugin Installation
# =============================================================================

log_step "9" "Verifying plugin installation"

# Wait a bit for pod to start
sleep 10

# Get the new pod name
POD_NAME=$(oc get pods -n "$BACKSTAGE_NAMESPACE" -l app.kubernetes.io/name=developer-hub --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -n "$POD_NAME" ]; then
    log_info "Checking init container logs for plugin installation..."
    
    INSTALL_LOG=$(oc logs "$POD_NAME" -n "$BACKSTAGE_NAMESPACE" -c install-dynamic-plugins 2>&1 | grep -i "vault-secret-add-module" || echo "")
    
    if echo "$INSTALL_LOG" | grep -q "Successfully installed"; then
        log_success "Vault plugin installed successfully!"
        echo "$INSTALL_LOG"
    else
        log_warn "Could not verify plugin installation. Check logs manually:"
        echo "  oc logs $POD_NAME -n $BACKSTAGE_NAMESPACE -c install-dynamic-plugins | grep vault"
    fi
    
    log_info "Checking backend logs for plugin loading..."
    BACKEND_LOG=$(oc logs "$POD_NAME" -n "$BACKSTAGE_NAMESPACE" -c backstage-backend 2>&1 | grep -i "loaded dynamic backend plugin.*vault" || echo "")
    
    if [ -n "$BACKEND_LOG" ]; then
        log_success "Vault plugin loaded in backend!"
        echo "$BACKEND_LOG"
    fi
else
    log_warn "Could not find running backstage pod. Check deployment status manually."
fi

# =============================================================================
# Summary
# =============================================================================

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}       SETUP COMPLETE!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "Vault Plugin Version: $PLUGIN_VERSION"
echo "Vault Address:        $VAULT_ADDR"
echo "Backstage Namespace:  $BACKSTAGE_NAMESPACE"
echo ""
echo "Available scaffolder actions:"
echo "  - vault:add-secret"
echo "  - vault:get-secret"
echo "  - vault:delete-secret"
echo ""
echo "Next steps:"
echo "  1. Access Developer Hub and create a new component using the scaffolder"
echo "  2. Use vault:add-secret action in your templates"
echo ""
echo "Example template step:"
echo '  - id: create-vault-secret'
echo '    name: Create Vault Secret'
echo '    action: vault:add-secret'
echo '    input:'
echo '      path: secrets/my-app'
echo '      key: my-key'
echo '      value: ${{ parameters.my_value }}'
echo ""
