# template.yaml Architecture: Engineering Perspective

## Overview

The `template.yaml` file is essentially a declarative specification for code generation workflows. It's built on Backstage's scaffolder system and follows a standard pattern: define inputs, execute steps, produce outputs.

Let's break down each section and understand why we structured it this way.

---

## File Structure

```yaml
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata: {...}
spec:
  owner: rhdh
  type: service
  parameters: [...]
  steps: [...]
  output: {...}
```

## API Declaration

```yaml
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
```

This follows Kubernetes resource patterns. The API version tells Backstage which schema to validate against and which features are available. We're using `v1beta3` because it's the current stable release with the features we need (conditional parameters, complex step orchestration).

## Metadata Section

```yaml
metadata:
  name: chatbot-rag-kickstart-template
  title: "Deploy RAG Reference Architecture using LLaMA Stack, OpenShift AI, and PGVector via GitOps"
  description: "..."
  tags: [chatbot, rag, vllm, llama, pgvector, openshift-ai, gitops, python]
  annotations:
    backstage.io/techdocs-ref: dir:.
```

**Key Engineering Decisions:**

- **name**: Must be unique across the Backstage instance. We use kebab-case for DNS compatibility since this becomes part of URLs and resource identifiers.

- **tags**: These drive the filtering and search in the UI. We include both technology stack identifiers (`llama`, `pgvector`) and pattern descriptors (`rag`, `gitops`).

- **annotations**: The `backstage.io/techdocs-ref` tells Backstage where to find documentation. Using `dir:.` means docs are co-located with the template.

## Spec Section

```yaml
spec:
  owner: rhdh
  type: service
```

- **owner**: Links to a Backstage entity (user or group). This establishes ownership for lifecycle management and access control.
- **type**: Affects how the generated component appears in catalogs and what lifecycle hooks apply.

## Parameters: Form Schema Definition

This is where we define the user interface and validation logic:

```yaml
parameters:
  - title: "Application Information"
    required: [name, owner]
    properties:
      name:
        title: Name
        type: string
        description: "Unique identifier for the component"
        default: chatbot-app
        ui:autofocus: true
```

**Schema Architecture:**

The parameters section uses JSON Schema with UI extensions. Each parameter block becomes a form step in the UI.

**Input Validation Strategy:**
- `required` arrays enforce mandatory fields at submission
- `type` provides client-side validation
- `enum` restricts choices to prevent invalid configurations
- `maxLength` prevents resource naming conflicts in Kubernetes

**Dynamic Form Logic:**
```yaml
dependencies:
  hostType:
    oneOf:
      - required: [githubServer]
        properties:
          hostType:
            const: GitHub
```

This implements conditional field visibility. When `hostType` equals "GitHub", the form dynamically shows the `githubServer` field. This keeps the UI clean while supporting multiple deployment targets.

**UI Optimization:**
- `ui:autofocus`: Improves form UX by setting initial cursor position
- `ui:help`: Provides contextual guidance for complex fields
- `ui:field`: Allows custom React components for specialized inputs

## Steps: Workflow Execution Engine

The steps array defines the scaffolding workflow. Each step is atomic and can reference outputs from previous steps.

```yaml
steps:
  - id: fetch-all-rag-kickstart
    name: "Fetch RAG-kickstart"
    action: fetch:plain
    input:
      url: https://github.com/rh-ai-kickstart/RAG
      targetPath: ./tenant
      copyWithoutTemplating: ["**/*.jinja"]
```

**Step Types and Use Cases:**

### Code Retrieval: `fetch:plain`
```yaml
action: fetch:plain
input:
  url: https://github.com/rh-ai-kickstart/RAG
  targetPath: ./tenant
  copyWithoutTemplating: ["**/*.jinja"]
```

Downloads external repositories without template processing. We use this for base application code that doesn't need customization. The `copyWithoutTemplating` prevents the scaffolder from trying to process template files that should remain as-is.

### Template Processing: `fetch:template`
```yaml
action: fetch:template
input:
  url: ./skeleton
  values:
    name: ${{ parameters.name }}
    owner: ${{ parameters.owner }}
```

Processes template files with variable substitution using Nunjucks templating. User parameters get injected into template placeholders. This generates customized configuration files, manifests, and code.

### File System Operations: `fs:delete`
```yaml
action: fs:delete
input:
  files:
    - ./tenant/.github
    - ./tenant/.ansible-lint
```

Cleanup step to remove files that don't belong in the generated project. Essential for removing upstream CI/CD configurations that don't apply to user projects.

### Repository Management: `publish:github`
```yaml
action: publish:github
input:
  repoUrl: ${{ parameters.githubServer }}?owner=${{ parameters.repoOwner }}&repo=${{ parameters.repoName }}
  sourcePath: ./tenant
  repoVisibility: "public"
  defaultBranch: "main"
```

Creates Git repositories using provider APIs. This step handles OAuth authentication, repository creation, and initial code push. The `sourcePath` determines which directory gets pushed to the repo.

### Component Registration: `catalog:register`
```yaml
action: catalog:register
input:
  repoContentsUrl: ${{ steps['publish-github'].output.repoContentsUrl }}
  catalogInfoPath: "/catalog-info.yaml"
```

Registers the generated component in Backstage's service catalog. Note the step output reference - this creates a dependency chain ensuring repositories exist before registration.

### GitOps Integration: `argocd:create-resources`
```yaml
action: argocd:create-resources
input:
  appName: ${{ parameters.name }}-bootstrap
  argoInstance: ${{ parameters.argoInstance }}
  namespace: janus-argocd
  repoUrl: https://github.com/owner/repo-gitops.git
  path: "argocd/"
```

Creates ArgoCD Application resources for continuous deployment. This connects the template output to our deployment pipeline, enabling automated infrastructure provisioning.

## Output Linking

```yaml
output:
  links:
    - title: "Source Repository"
      url: ${{ steps['publish-github'].output.remoteUrl }}
    - title: "Open Component in Catalog"
      icon: catalog
      entityRef: ${{ steps['register'].output.entityRef }}
```

Provides navigation links to generated resources. The step output references create dynamic URLs based on actual created resources.

## Engineering Considerations

**Error Handling**: Each step can fail independently. We use conditional execution (`if:` clauses) to handle different deployment scenarios without breaking the workflow.

**Idempotency**: Steps should be idempotent where possible. Repository creation steps check for existing repos before attempting creation.

**Security**: Template execution runs in a sandboxed environment. File system access is restricted to the working directory.

**Performance**: We fetch external resources in parallel where possible and cache template repositories to reduce latency.

**Maintainability**: The separation between parameters, steps, and outputs makes it easy to modify the workflow without affecting the user interface.

## Template as Infrastructure as Code

This template essentially codifies our AI application deployment patterns. It captures institutional knowledge about how to properly configure LLaMA Stack, integrate with OpenShift AI, and set up GitOps workflows.

The declarative nature means we can version control our deployment patterns, test changes, and ensure consistency across teams. 