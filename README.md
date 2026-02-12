This guide provides step-by-step instructions for installing the Red Hat Golden Template path using the RHEcosystemAppEng/RHDH-templates repository.


---

## ✅ Prerequisites

Before getting started, ensure you have the following:

- **OpenShift CLI (oc)**: [Download and install](https://developers.redhat.com/learning/learn:openshift:download-and-install-red-hat-openshift-cli/resource/resources:download-and-install-oc) Openshift command-line interface
- **Platform Access**: Access to either [TAP](https://docs.redhat.com/en/documentation/red_hat_trusted_application_pipeline/1.0/html-single/installing_red_hat_trusted_application_pipeline/index) or a running RHDH instance. Helm Chart installation available [here](https://github.com/redhat-ai-dev/ai-rhdh-installer)
- **Hugging Face API Token**: A valid authentication token from [Hugging Face](https://huggingface.co/docs/hub/en/security-tokens)
- **Tavily API Key**: A valid API key from [Tavily](https://tavily.com/) for web search capabilities
- **Vault Scaffolder Plugin**: Must be installed before running templates (see setup below)

---

## 🔧 Vault Scaffolder Plugin Setup (Required)

> **⚠️ Important**: This setup must be completed before running any templates. The templates use `vault:add-secret` action to automatically create secrets in Vault.

### What is it?
The `rhdh-vault-setup.sh` script automates the installation of the Vault scaffolder plugin for Red Hat Developer Hub. This plugin enables templates to automatically create secrets in Vault during the scaffolding process using the `vault:add-secret` action.

#### Why do we need it?
The templates in this repository use the `vault:add-secret` action to store secrets in Vault. Without this plugin installed, the templates will **fail** because the action is not available. With the Vault scaffolder plugin enabled:
- Templates can **automatically create secrets** in Vault during component creation
- Users can input sensitive values (API keys, tokens) directly in the scaffolder form
- Secrets are securely stored in Vault without manual intervention
- Enables end-to-end automation of application deployment with secrets management

#### How to run it

1. **Prerequisites**:
   - OpenShift CLI (`oc`) installed and logged into your cluster
   - Vault deployed in the cluster
   - Access to your RHDH GitOps repository

2. **Run the setup script**:
   ```bash
   # Clone this repository
   git clone https://github.com/RHEcosystemAppEng/RHDH-templates.git
   cd RHDH-templates

   # Run the setup script
   ./scripts/rhdh-vault-setup.sh --gitops-repo <YOUR_GITOPS_REPO_URL>
   ```

3. **Options**:
   | Option                   | Description                        | Default     |
   | ------------------------ | ---------------------------------- | ----------- |
   | `--gitops-repo <url>`    | GitOps repository URL (required)   | -           |
   | `--vault-ns <ns>`        | Vault namespace                    | `vault`     |
   | `--backstage-ns <ns>`    | Backstage namespace                | `backstage` |
   | `--plugin-version <ver>` | Vault plugin version               | `0.1.14`    |
   | `--dry-run`              | Preview commands without executing | -           |

4. **What the script does**:
   - Creates `rhdh-vault-secrets` secret with Vault credentials
   - Updates the GitOps repository with plugin configuration
   - Triggers ArgoCD sync to deploy changes
   - Verifies plugin installation

5. **Available scaffolder actions after setup**:
   - `vault:add-secret` - Create a secret in Vault
   - `vault:get-secret` - Retrieve a secret from Vault
   - `vault:delete-secret` - Delete a secret from Vault

6. **Example template usage**:
   ```yaml
   - id: create-vault-secret
     name: Create Vault Secret
     action: vault:add-secret
     input:
       path: secrets/my-app
       key: api_key
       value: ${{ parameters.api_key }}
   ```

> **Reference**: Based on [dcurran90/rhdh vault plugin documentation](https://github.com/dcurran90/rhdh/blob/vaultPlugin/remote_testing/docs/rhtap_process.txt)

---

## 🚀 Step-by-Step Instructions

### 1. Login to Developer Hub
   * Sign in to Developer Hub via GitLab using your GitLab credentials

     <img src="images/dh-dashboard.jpg" alt="Create ai-ckstart secret" width="300">

---

### 2. Register AI Templates

1. **Navigate to Create**:
   - From the Developer Hub sidebar, click **"Create"**
 
      <img src="images/dh-create-view.jpg" alt="Create ai-ckstart secret" width="300">
2. **Register templates**:
   - Click **"Register Existing Component"**

3. **Import the template repository**:
   - Paste this URL into the input field:
     ```
     https://github.com/RHEcosystemAppEng/RHDH-templates/blob/main/showcase-templates.yaml
     ```
   - Click **"Analyze"**

      <img src="images/register-template.jpg" alt="Create ai-ckstart secret" width="300">

   - Click **"Import"** to complete registration
 
      <img src="images/import-template.jpg" alt="Create ai-ckstart secret" width="300">
---
### 3. Available Templates

Once registered, you'll see these AI-powered templates in the Catalog->Template page:

- **🤖 RAG Chatbot Kickstart** (`chatbot-rag-kickstart-template`)  
  Deploy a complete RAG (Retrieval Augmented Generation) architecture using LLaMA Stack, OpenShift AI, and PGVector. Includes document ingestion pipeline and vector database for intelligent question-answering.

- **🎯 AI Virtual Agent** (`ai-virtual-agent-kickstart-template`)  
  Create an intelligent virtual assistant powered by OpenShift AI and PGVector. Perfect for building conversational AI applications with advanced reasoning capabilities.

- **📊 AI Metrics Summarizer** (`ai-metric-summarizer-kickstart-template`)  
  Build a specialized chatbot that analyzes AI model performance metrics from Prometheus and generates human-readable summaries using LLaMA models. Ideal for AI observability and monitoring.

---
### 4. Launch a Template

Once you've registered the templates, follow these steps to deploy an AI application:

#### **Navigate to Self-Service Catalog**
- From the Developer Hub sidebar, click **"Create"**
- You'll see the available AI templates listed

#### **Choose Your Template**
Select one of the registered templates:
- **Chatbot-Rag Kickstart** - for RAG document-based Q&A systems
- **AI Virtual Agent** - for conversational AI assistants  
- **AI Metrics Summarizer** - for AI observability and monitoring

#### **Configure Template Parameters**
Fill in the guided form with your specifications:

**Application Information:**
- **Name**: Unique identifier for your component (e.g., `my-ai-chatbot`)
- **Description**: Brief description of your application

**Repository Details:**
- **Host Type**: Choose GitHub or GitLab
- **Repository Owner**: Your organization name
- **Repository Name**: Name for the source repository
- **Namespace**: Kubernetes namespace for deployment

**AI Model Configuration:**
- **Language Model**: Select from available LLaMA variants
- **Safety Model**: Optional LLaMA Guard for content filtering
- **GPU Tolerance**: Configure hardware requirements

#### **Review and Create**
- Review all configured parameters
- Click **"Review"** to validate your inputs
- Click **"Create"** to initiate the template deployment

#### **Automatic Deployment Process**
The template will automatically:
1. **Build** the software component with your specifications
2. **Publish** source and GitOps repositories to your chosen platform
3. **Register** the component in the Developer Hub catalog
4. **Deploy** via ArgoCD using GitOps workflows

#### **Access Your Application**
Once complete, use the provided links to:
- View source repository
- Monitor GitOps deployment  
- Access the component in the catalog
- Review ArgoCD applications

#### **Post-Deployment Steps:**
Once your application is deployed, you'll need to make the following changes in your GitOps repository:
1. Uncomment the Toolhive configuration to enable the service
2. Delete the chart.lock file to allow Helm to regenerate dependencies
3. Commit these changes to trigger the GitOps sync