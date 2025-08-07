# Templates vs Scaffolding: Understanding the Difference

## 🤔 **What's the Difference?**

### **Software Template** = **The Blueprint/Recipe** 📋
- **What it is**: Static files in our repository (`template.yaml` + skeleton)
- **Where it lives**: `/scaffolder-templates/chatbot-rag-kickstart-template/`
- **What it contains**: Instructions, parameters, skeleton code
- **Think of it as**: 📜 **A blueprint or specification**

### **Scaffolding** = **The Process + Result** ⚡
- **What it is**: The ACT of using the template + what gets generated
- **When it happens**: When user clicks "Create" in RHDH
- **What it produces**: Working application repositories and code
- **Think of it as**: ⚡ **Using the blueprint to build something real**

---



## 🏗️ **Our AI Template Examples**

### **📋 Template: What's in Our Repository**

**File Structure:**
```
/scaffolder-templates/chatbot-rag-kickstart-template/
├── template.yaml           # 📜 The blueprint/specification
├── skeleton/              # 🏗️ Basic structure 
├── manifests/             # ⚙️ Configuration templates
└── README.md              # 📚 Instructions
```

**template.yaml defines:**
- 🔧 **Parameters**: Name, owner, LLM model
- 📋 **Steps**: Fetch code, publish repos, deploy
- 🎯 **Outputs**: Links to generated repositories

---

## ⚡ **Scaffolding: What Happens When You Use It**

### **🔄 The Process (When User Clicks "Create")**

1. **User fills form** → `name: "my-chatbot"`, `model: "llama-3-2-3b"`
2. **RHDH reads template.yaml** → Follows the blueprint
3. **Code generation happens** → Creates actual files
4. **Repositories created** → GitHub/GitLab repos appear
5. **Deployment starts** → ArgoCD deploys to Kubernetes

### **📁 The Result: Generated Repositories**

**Source Repository** (`my-chatbot`):
```
my-chatbot/
├── src/app.py              # 🐍 Working Python code
├── requirements.txt        # 📦 Dependencies
├── Dockerfile             # 🐳 Container setup
└── README.md              # 📚 Setup guide
```

**GitOps Repository** (`my-chatbot-gitops`):
```
my-chatbot-gitops/
├── helm/                  # ☸️ Kubernetes manifests
├── argocd/               # 🚀 Deployment configs
└── catalog-info.yaml     # 📋 RHDH registration
```

---

## 🎯 **Key Differences Summary**

| **Aspect**      | **Template**                     | **Scaffolding**                    |
| --------------- | -------------------------------- | ---------------------------------- |
| **When**        | Created once by template authors | Happens each time user creates app |
| **Where**       | Lives in our GitHub repository   | Creates new repositories           |
| **What**        | Static blueprint/instructions    | Dynamic generation + working code  |
| **Purpose**     | Defines HOW to create            | Actually CREATES the application   |
| **Reusability** | Used by many developers          | Results are specific to one user   |

---

## 🚀 **From Template to Working App**

**Template** (Static) → **Scaffolding Process** (Dynamic) → **Generated Application** (Working)

1. 📜 **Template exists** in our repo
2. 👤 **User selects** template in RHDH  
3. ⚡ **Scaffolding runs** (follows template instructions)
4. 🎉 **Working AI app** appears in 6 minutes!

**Template = The blueprint | Scaffolding = Using the blueprint to build something real** 