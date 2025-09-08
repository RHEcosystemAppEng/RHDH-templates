# Template Starters

This directory contains **starter templates** that can be copied into your own template subdirectories as a foundation for creating new RHDH templates.

## 📁 **What's Included**

```
template-starters/
├── manifests/
│   ├── argocd/
│   │   ├── ${{values.name}}-argocd-appproj.yaml    # Basic AppProject
│   │   └── ${{values.name}}-argocd-app.yaml        # Basic Application
│   └── helm/
│       └── templates/
│           └── external-secret-huggingface.yaml    # HuggingFace secret
├── skeleton/
│   ├── .gitlab-ci.yml                              # GitLab CI/CD pipeline
│   ├── catalog-info.yaml                           # Backstage catalog entry
│   ├── mkdocs.yml                                  # Documentation config
│   └── docs/                                       # Documentation structure
│       ├── index.md                                # Main documentation
│       ├── onboard-openshift.md                    # OpenShift onboarding
│       └── application-migration/                  # Migration guides
│           ├── high-level-onboarding-process.png
│           ├── learning-path-for-developers.md
│           ├── migration-process-overview.md
│           └── migration-process-steps.md
└── README.md                                       # This file
```

## 🚀 **How to Use**

### Creating a New Template

1. **Create your template directory:**
   ```bash
   mkdir my-awesome-template
   cd my-awesome-template
   ```

2. **Copy the starter files:**
   ```bash
   cp -r ../template-starters/manifests .
   cp -r ../template-starters/skeleton .
   ```

3. **Customize for your needs:**
   - Edit `manifests/argocd/` files for your specific ArgoCD setup
   - Update `skeleton/catalog-info.yaml` with appropriate metadata and tags
   - Modify `skeleton/.gitlab-ci.yml` for your CI/CD needs
   - Customize documentation in `skeleton/docs/`
   - Add additional manifest files as needed

4. **Create your template.yaml** with steps like:
   ```yaml
   steps:
     - id: fetch-skeleton
       name: Fetch catalog-info from local Template
       action: fetch:template
       input:
         url: ./skeleton
         targetPath: ./tenant
         values:
           name: ${{ parameters.name }}
           description: ${{ parameters.description }}
           owner: ${{ parameters.owner }}
           repoURL: ${{ parameters.repoURL }}
           destination: ${{ parameters.destination }}
     
     - id: fetch-argocd
       name: Fetch Argo CD Resources
       action: fetch:template
       input:
         url: ./manifests/argocd
         targetPath: ./tenant-gitops/argocd
         values:
           name: ${{ parameters.name }}
           namespace: ${{ parameters.namespace }}
           repoURL: ${{ parameters.repoURL }}
           llm: ${{ parameters.llm }}
   ```

## 🔧 **Standard Variables**

The starter templates use these common variables:

| Variable             | Purpose                 | Example                              |
| -------------------- | ----------------------- | ------------------------------------ |
| `values.name`        | Application name        | `my-ai-app`                          |
| `values.description` | Application description | `My AI Application`                  |
| `values.owner`       | Application owner       | `team-ai`                            |
| `values.namespace`   | Target namespace        | `my-ai-app-prod`                     |
| `values.repoURL`     | Git repository URL      | `https://gitlab.com/myorg/my-ai-app` |
| `values.destination` | GitLab project slug     | `myorg/my-ai-app`                    |
| `values.llm`         | LLM model name          | `llama-3-2-3b-instruct`              |

## 📝 **Customization Examples**

### ArgoCD Application
```yaml
# Add custom Helm parameters
parameters:
  - name: myapp.feature.enabled
    value: "true"
  - name: myapp.replicas
    value: "3"
```

### Catalog Info
```yaml
# Add custom tags and annotations
tags:
  - python
  - machine-learning
  - recommendation
annotations:
  my-org.com/team: data-science
  my-org.com/cost-center: "12345"
```

### GitLab CI
```yaml
# Add custom stages
stages:
  - build
  - test
  - security
  - deploy
  - integration-test
```

## 💡 **Best Practices**

1. **Start Simple**: Copy the starters and get basic functionality working first
2. **Customize Gradually**: Add complexity only as needed
3. **Keep It Clean**: Avoid complex Jinja conditionals; prefer simple templates
4. **Document Changes**: Update your template's README with customizations
5. **Test Locally**: Verify your template works before committing
6. **Version Control**: Track your template changes in git

## 🔄 **Updating from Starters**

When the starter templates are updated, you can:

1. **Review changes** in the starter files
2. **Selectively apply** relevant updates to your templates
3. **Maintain your customizations** while adopting improvements

This approach gives you full control while benefiting from shared patterns! 🎉
