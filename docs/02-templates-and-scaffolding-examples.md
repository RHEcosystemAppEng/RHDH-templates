# Software Templates & Scaffolding Examples

## 🏗️ **Software Template Example**

### **Our Template**: `chatbot-rag-kickstart-template`

**What it provides:**
- Complete **RAG (Retrieval Augmented Generation)** chatbot template
- Pre-configured with **LLaMA Stack**, **OpenShift AI**, **PGVector** database
- Built-in **document ingestion pipeline**
- **Production-ready** architecture

**User only needs to specify:**
- ✅ Application name (`my-chatbot`)
- ✅ Repository details (GitHub/GitLab)
- ✅ LLM model choice (1B, 3B, 70B variants)
- ✅ Kubernetes namespace

---

## 🔧 **Scaffolding Example: What Gets Auto-Generated**

### **📁 Generated Repositories**
1. **Source Repository** (`chatbot-app`)
   - Python RAG application code
   - LLaMA Stack integration
   - Document processing logic

2. **GitOps Repository** (`chatbot-app-gitops`)
   - Kubernetes manifests
   - Helm charts
   - ArgoCD configurations

### **🗂️ Generated Files & Configurations**
```
chatbot-app/
├── src/                    # Python RAG application
├── requirements.txt        # Dependencies
├── Dockerfile             # Container image
└── README.md              # Setup instructions

chatbot-app-gitops/
├── helm/                  # Kubernetes deployments
├── argocd/               # GitOps manifests
├── catalog-info.yaml     # RHDH component registration
└── external-secrets.yaml # Secret management
```

### **⚡ Automated Actions**
- 🔄 **Repository Creation**: GitHub/GitLab repos with full code
- 📋 **Component Registration**: Auto-added to RHDH catalog
- 🚀 **ArgoCD Deployment**: GitOps pipeline activated
- 🔐 **Secret Management**: Hugging Face tokens configured
- 🏗️ **Infrastructure**: Minio, PGVector, model serving

---

## 🎯 **Developer Experience**

### **Before RHDH Templates:**
- **5+ days** of manual setup
- Research LLaMA integration
- Configure vector databases
- Set up GitOps pipelines
- Handle secret management

### **With RHDH Templates:**
- **5 minutes** to deployment
- Fill simple form
- Click "Create"
- ☕ Grab coffee while it deploys

**Result: From idea to production-ready AI chatbot in minutes!** 