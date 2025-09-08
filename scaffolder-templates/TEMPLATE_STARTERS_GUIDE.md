# Template Starters Guide

This repository uses a **template starter** approach for best-practice and flexibility when creating RHDH templates.

## 🎯 **The Template Starter Approach**

We provide **starter templates** that you copy and customize for each specific template.

## 📁 **Repository Structure**

```
scaffolder-templates/
├── template-starters/                    # 👈 Copy these to create new templates
│   ├── manifests/
│   │   ├── argocd/                      # ArgoCD resources
│   │   └── helm/templates/              # Helm templates
│   ├── skeleton/                        # Application skeleton
│   │   ├── .gitlab-ci.yml              # CI/CD pipeline
│   │   ├── catalog-info.yaml           # Backstage catalog
│   │   ├── mkdocs.yml                  # Documentation config
│   │   └── docs/                       # Documentation files
│   └── README.md                       # Detailed usage instructions
├── existing-template-1/                 # Existing templates use local files
│   ├── manifests/                      # 👈 Copied from template-starters
│   ├── skeleton/                       # 👈 Copied from template-starters
│   └── template.yaml
├── existing-template-2/
└── TEMPLATE_STARTERS_GUIDE.md          # 👈 This file
```

## 🚀 **Quick Start**

### Creating a New Template

```bash
# 1. Create your template directory
mkdir my-new-ai-template
cd my-new-ai-template

# 2. Copy starter files
cp -r ../template-starters/manifests .
cp -r ../template-starters/skeleton .

# 3. Customize the files for your needs
# Edit manifests/argocd/ files
# Update skeleton/catalog-info.yaml
# Modify skeleton/.gitlab-ci.yml
# Customize skeleton/docs/

# 4. Create your template.yaml
# Reference local paths: ./skeleton, ./manifests/argocd
```

### Template.yaml Example

```yaml
steps:
  - id: fetch-skeleton
    name: Fetch catalog-info from local Template
    action: fetch:template
    input:
      url: ./skeleton                    # 👈 Local path
      targetPath: ./tenant
      values:
        name: ${{ parameters.name }}
        description: ${{ parameters.description }}
        # ... other values

  - id: fetch-argocd
    name: Fetch Argo CD Resources
    action: fetch:template
    input:
      url: ./manifests/argocd           # 👈 Local path
      targetPath: ./tenant-gitops/argocd
      values:
        name: ${{ parameters.name }}
        namespace: ${{ parameters.namespace }}
        # ... other values
```

## 🔧 **Standard Variables**

All starter templates use consistent variable names:

- `values.name` - Application name
- `values.description` - Application description  
- `values.owner` - Application owner
- `values.namespace` - Target namespace
- `values.repoURL` - Git repository URL
- `values.destination` - GitLab project slug
- `values.llm` - LLM model name (for AI apps)

## 📋 **What's Included in Starters**

### Manifests
- **AppProject**: Basic ArgoCD project setup
- **Application**: Basic ArgoCD application with common patterns
- **External Secret**: HuggingFace token integration

### Skeleton
- **GitLab CI**: TechDocs build pipeline with S3 publishing
- **Catalog Info**: Backstage component definition
- **Documentation**: Complete docs structure with migration guides
- **MkDocs Config**: Documentation site configuration

## 🔄 **Maintenance**

### Updating Existing Templates
When starter templates improve, you can:
1. Review changes in `template-starters/`
2. Selectively apply relevant updates to your templates
3. Keep your customizations while adopting improvements

### Adding New Patterns
To add new common patterns:
1. Add them to `template-starters/`
2. Document in the README
3. Existing templates can adopt them optionally

## 💡 **Best Practices**

1. **Always start with template-starters** when creating new templates
2. **Customize gradually** - start simple, add complexity as needed
3. **Keep templates self-contained** - avoid external dependencies
4. **Document your customizations** in each template's README
5. **Test templates locally** before committing

## 🎉 **Result**

This approach gives you:
- **Reusable starting points** with common patterns implemented
- **Full flexibility** to customize each template independently
- **Clean, maintainable code** without complex conditionals
- **Easy onboarding** for new developers
- **Scalable architecture** that grows with your needs

Happy templating! 🚀
