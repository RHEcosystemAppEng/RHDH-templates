# 🚀 RAG Chatbot Demo Setup

## ✅ Automated Configuration Complete!

Your RAG Chatbot CI/CD integration has been automatically configured for demo purposes.

### 📋 Configuration Summary

- **Application Name**: `skeleton`
- **Webhook URL**: ``
- **Webhook Secret**: `demo-webhook-secret-1754598618`

### 🔧 Quick Setup (2 minutes)

#### For GitHub:
1. Go to your repository **Settings > Webhooks**
2. Click **Add webhook**
3. **Payload URL**: ``
4. **Content type**: `application/json`
5. **Secret**: `demo-webhook-secret-1754598618`
6. **Which events**: Just the push event
7. Click **Add webhook**

#### For GitLab:
1. Go to your repository **Settings > Webhooks**
2. **URL**: ``
3. **Secret token**: `demo-webhook-secret-1754598618`
4. **Trigger**: Push events (checked)
5. **SSL verification**: Enable
6. Click **Add webhook**

### 🎯 Test Your Setup

1. **Make a change** to your Streamlit app:
   ```bash
   echo "# Demo update" >> README.md
   git add README.md
   git commit -m "Demo: test CI/CD pipeline"
   git push origin main
   ```

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

Every time you push code to the `main` branch:

1. **CI/CD Pipeline** builds a new container image
2. **Webhook** notifies OpenShift Tekton pipeline
3. **Tekton** updates the GitOps repository with new image tag
4. **ArgoCD** detects the change and deploys automatically
5. **Your app** updates with zero downtime!

---

**🎊 Happy Coding!** Your demo environment is ready to showcase automatic deployments!
