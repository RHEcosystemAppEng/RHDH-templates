# Deployment Architecture: How Templates Become Running Systems

## Architecture Overview

When someone clicks "Create" on our AI templates, we're not just generating code - we're provisioning a complete AI application stack. Here's how the deployment flow works and what infrastructure gets created.

## High-Level Deployment Flow

```
Template Execution → Repository Creation → GitOps Sync → Infrastructure Provisioning → Application Deployment
```

The template generates two key repositories:
- **Source repo**: Contains the application code
- **GitOps repo**: Contains all Kubernetes manifests and Helm charts

ArgoCD watches the GitOps repo and automatically deploys changes to the cluster.

## GitOps Architecture

### Repository Strategy

We use a two-repository pattern:

**Source Repository** (`my-chatbot`):
```
my-chatbot/
├── src/                    # Python application code
├── requirements.txt        # Dependencies
├── Dockerfile             # Container build definition
└── .github/workflows/     # CI pipeline (optional)
```

**GitOps Repository** (`my-chatbot-gitops`):
```
my-chatbot-gitops/
├── helm/
│   ├── values.yaml        # Environment-specific config
│   └── templates/
│       ├── deployment.yaml    # K8s Deployment
│       ├── service.yaml       # K8s Service
│       ├── ingress.yaml       # External access
│       └── configmap.yaml     # App configuration
├── argocd/
│   ├── application.yaml       # ArgoCD Application
│   └── appproject.yaml        # ArgoCD Project
└── external-secrets.yaml     # Secret management
```

### ArgoCD Integration

The template creates ArgoCD resources that establish continuous deployment:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-chatbot-bootstrap
spec:
  source:
    repoURL: https://github.com/user/my-chatbot-gitops.git
    path: helm/
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: my-chatbot-ns
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

This creates a feedback loop: any changes to the GitOps repo automatically trigger redeployment.

## AI Application Stack Deployment

### Core Infrastructure Components

**LLaMA Model Serving**:
```yaml
apiVersion: serving.kserve.io/v1beta1
kind: InferenceService
metadata:
  name: llama-model-server
spec:
  predictor:
    model:
      modelFormat:
        name: vllm
      storageUri: s3://models/llama-3-2-3b-instruct
  resources:
    limits:
      nvidia.com/gpu: 1
      memory: 16Gi
```

**PGVector Database**:
```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: pgvector-cluster
spec:
  instances: 3
  postgresql:
    parameters:
      shared_preload_libraries: vector
      max_connections: "200"
  storage:
    size: 100Gi
    storageClass: fast-ssd
```

**Document Storage (Minio)**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: minio
spec:
  template:
    spec:
      containers:
      - name: minio
        image: minio/minio:latest
        env:
        - name: MINIO_ACCESS_KEY
          valueFrom:
            secretKeyRef:
              name: minio-credentials
              key: access-key
```

### Application Layer

**RAG Application Deployment**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: chatbot-app
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: app
        image: registry.io/user/my-chatbot:latest
        env:
        - name: PGVECTOR_HOST
          value: pgvector-cluster-rw.default.svc.cluster.local
        - name: LLAMA_ENDPOINT
          value: http://llama-model-server.default.svc.cluster.local:8080
        - name: MINIO_ENDPOINT
          value: http://minio.default.svc.cluster.local:9000
        resources:
          requests:
            memory: 2Gi
            cpu: 1000m
          limits:
            memory: 4Gi
            cpu: 2000m
```

## Network Architecture

### Service Mesh Integration

We deploy with Istio for traffic management and security:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: chatbot-routing
spec:
  hosts:
  - chatbot.example.com
  http:
  - match:
    - uri:
        prefix: /api/
    route:
    - destination:
        host: chatbot-app
        port:
          number: 8080
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: chatbot-frontend
        port:
          number: 3000
```

### Internal Communication

Services communicate over the cluster network:
- **App → PGVector**: Database queries for vector similarity search
- **App → LLaMA**: HTTP requests to model inference endpoint
- **App → Minio**: S3 API calls for document storage
- **Frontend → App**: REST API calls

### External Access

Ingress controllers expose services externally:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: chatbot-ingress
spec:
  tls:
  - hosts:
    - chatbot.example.com
    secretName: chatbot-tls
  rules:
  - host: chatbot.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: chatbot-app
            port:
              number: 8080
```

## Storage Architecture

### Persistent Storage Strategy

**Database Storage**: 
- PGVector uses persistent volumes for database files
- Configured with replication for high availability
- Automatic backups to S3-compatible storage

**Document Storage**:
- Minio provides S3-compatible object storage
- Documents uploaded by users stored here
- Vector embeddings stored in PGVector reference these documents

**Model Storage**:
- LLaMA models loaded from shared storage or container images
- GPU memory allocated for model inference
- Model weights cached locally on nodes with GPUs

## Secret Management

### External Secrets Operator

Instead of hardcoding secrets, we use External Secrets Operator with Vault:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: huggingface-secret
spec:
  secretStoreRef:
    name: vault-secret-store
    kind: SecretStore
  target:
    name: huggingface-token
    creationPolicy: Owner
  data:
  - secretKey: HF_TOKEN
    remoteRef:
      key: secret/ai-kickstart
      property: hf-token
```

This integrates with our Vault instance to securely manage API tokens and database credentials.

## Monitoring and Observability

### Prometheus Integration

The template includes monitoring configurations:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: chatbot-metrics
spec:
  selector:
    matchLabels:
      app: chatbot-app
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

**Key Metrics Collected**:
- Request latency and throughput
- Model inference time
- Vector search performance
- Database connection pool stats
- GPU utilization

### Logging Strategy

Centralized logging with Fluentd:
- Application logs → Fluentd → ElasticSearch → Kibana
- Structured JSON logging for better parsing
- Log correlation across distributed components

## Deployment Considerations

### Resource Management

**GPU Scheduling**: We use node selectors and tolerations to ensure model workloads land on GPU nodes:
```yaml
nodeSelector:
  nvidia.com/gpu.present: "true"
tolerations:
- key: nvidia.com/gpu
  operator: Exists
  effect: NoSchedule
```

**Memory Management**: LLaMA models require significant memory. We configure resource requests/limits to prevent OOM kills and ensure proper scheduling.

**Storage Performance**: Vector similarity search is I/O intensive. We use fast SSD storage classes for PGVector.

### Scaling Strategy

**Horizontal Pod Autoscaling**:
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: chatbot-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: chatbot-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

**Model Serving Scaling**: LLaMA inference endpoints can be scaled based on request queue depth and GPU utilization.

## Security Architecture

### Network Policies

We implement network segmentation:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: chatbot-network-policy
spec:
  podSelector:
    matchLabels:
      app: chatbot-app
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
```

### RBAC Configuration

Service accounts with minimal required permissions:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: chatbot-app-role
rules:
- apiGroups: [""]
  resources: ["secrets", "configmaps"]
  verbs: ["get", "list"]
```

## Infrastructure as Code Benefits

This deployment architecture provides several engineering advantages:

**Reproducibility**: Every deployment follows the same pattern, reducing environment-specific issues.

**Version Control**: All infrastructure is code-managed, enabling rollbacks and change tracking.

**Testing**: We can spin up identical environments for testing and development.

**Compliance**: Network policies, RBAC, and secret management are consistently applied.

**Scalability**: HPA and resource management ensure applications can handle varying loads.

The template encapsulates all this complexity, allowing developers to focus on their AI application logic rather than infrastructure concerns. 