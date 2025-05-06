# 🧩 Using RHEcosystemAppEng/RHDH-templates as Golden Templates in Red Hat Developer Hub

This guide walks you through using [RHEcosystemAppEng/RHDH-templates](https://github.com/RHEcosystemAppEng/RHDH-templates) as **golden templates** inside your own instance of [Red Hat Developer Hub (RHDH)](https://redhat-developer-hub-openshift-gitops.apps.gpu.osdu.opdev.io/).

---

## ✅ Prerequisites

- Access to a running RHDH instance  
  👉 [https://redhat-developer-hub-openshift-gitops.apps.gpu.osdu.opdev.io](https://redhat-developer-hub-openshift-gitops.apps.gpu.osdu.opdev.io)
- Access to GitHub and permission to use the `RHEcosystemAppEng/RHDH-templates` repository
- Requires a secret to be defined that provides the [Hugging Face Token](https://huggingface.co/)
  - Manually create a Kubernetes Secret or create a secret using a secure secret solution such as Vault
    ````
    export HF_TOKEN=<hf token>

    kubectl create secret generic huggingface-secret -n <The namespace where the application will be deployed> --from-literal=HF_TOKEN=$HF_TOKEN
    ````
---

## 🚀 Step-by-Step Instructions

### 1. Open the Developer Hub

Visit your RHDH instance: https://redhat-developer-hub-openshift-gitops.apps.gpu.osdu.opdev.io


---

### 2. Go to the Catalog Import Page

- From the sidebar, click **"Catalog"**
- Then click **"Register Existing Component"** (or **"Import"**)

---

### 3. Register the Golden Template Repository

Paste this URL into the import input field:

https://github.com/RHEcosystemAppEng/RHDH-templates/blob/main/catalog-info.yaml



> 📝 This file registers all golden templates defined in the repository.

Click **"Analyze"** and then **"Import"** to complete registration.

---

### 4. Use a Template from the Create Page

- Click **"Create"** in the sidebar
- You’ll now see new golden templates like:

  - RAG Chatbot Blueprint

Click a template to launch the guided form.

---

### 5. Fill in the Form and Create a New Component

- Provide the required inputs (name, repo, owner, etc.)
- Click **"Create"**
- Once complete, follow the output links to:
  - View the source repository
  - See the component in the catalog
  - Review Argo CD

