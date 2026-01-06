**Assignment 1**

**Multi-Backend Image Upload Application on Kubernetes**

**Project Description**
Overview

This project demonstrates the deployment of a containerized microservices-based application on Azure Kubernetes Service (AKS).
The application consists of a frontend service, two backend services, and a PostgreSQL database, deployed using Kubernetes best practices such as:

Namespaces

Resource quotas

Secrets and ConfigMaps

StatefulSets with persistent storage

NetworkPolicies (zero-trust)

Horizontal Pod Autoscaling (HPA)

Azure LoadBalancer exposure




**Deployment Steps (AKS)**
1️⃣ Create Azure Container Registry (ACR)
az acr create --resource-group aks-rg-manvith --name manvithacr --sku Basic


Enable admin access (for local Docker push):

az acr update --name manvithacr --admin-enabled true


Login to ACR:

az acr login --name manvithacr

2️⃣ Build & Push Docker Images to ACR
🔹 Frontend
docker build -t manvithacr.azurecr.io/frontend:latest ./test/frontend
docker push manvithacr.azurecr.io/frontend:latest

🔹 Backend-A
docker build -t manvithacr.azurecr.io/backend-a:latest ./test/backend-a
docker push manvithacr.azurecr.io/backend-a:latest

🔹 Backend-B
docker build -t manvithacr.azurecr.io/backend-b:latest ./test/backend-b
docker push manvithacr.azurecr.io/backend-b:latest

3️⃣ Create AKS Cluster
az aks create \
  --resource-group aks-rg-manvith \
  --name manvith-aks \
  --location centralus \
  --node-count 2 \
  --enable-managed-identity \
  --attach-acr manvithacr \
  --generate-ssh-keys

4️⃣ Connect to AKS Cluster
az aks get-credentials --resource-group aks-rg-manvith --name manvith-aks


Verify nodes:

kubectl get nodes

5️⃣ Kubernetes Deployment Order

Apply Kubernetes manifests in the following order:

kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/resourcequota.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/pvc.yaml
kubectl apply -f k8s/postgres-statefulset.yaml
kubectl apply -f k8s/services.yaml
kubectl apply -f k8s/backend-a-deployment.yaml
kubectl apply -f k8s/backend-b-deployment.yaml
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/networkpolicy-*.yaml
kubectl apply -f k8s/hpa-*.yaml

6️⃣ Verify Deployment
kubectl get pods -n image-app
kubectl get svc -n image-app
kubectl get pvc -n image-app
kubectl get hpa -n image-app
kubectl get networkpolicy -n image-app

7️⃣ Access Application
kubectl get svc frontend -n image-app


**Yaml files**

***namespace.yaml***

This file creates the dedicated Kubernetes namespace image-app and adds helpful labels like project: multi-backend-microservices, environment: dev, and owner: manvith. By placing all application resources (Deployments, Services, HPAs, NetworkPolicies, StatefulSet, etc.) into this namespace, you isolate this project from other workloads on the cluster, making it easier to apply quotas, security policies, and environment-specific configurations without affecting anything else.

***frontend-deployment.yaml***

This Deployment defines the React frontend running behind Nginx in the image-app namespace. It runs 2 replicas of the frontend pod and uses labels (app: frontend) so Services and NetworkPolicies can target it. The pod spec (truncated with ... in the file) includes container configuration and HTTP-based liveness and readiness probes on path / and port 80, ensuring Kubernetes only routes traffic to healthy Nginx/React instances. This gives you a resilient, self-healing UI layer that can be safely rolled out and scaled.

***backend-a-deployment.yaml***

This Deployment manages the Backend-A Node.js microservice. It runs 2 replicas in the image-app namespace with the label app: backend-a, which is used by its Service and NetworkPolicies. The container section (truncated in the file) hosts the backend API on port 8080 and defines liveness and readiness probes on /health, so Kubernetes can detect unhealthy pods and remove them from service. This YAML essentially gives Backend-A a stable, scalable, and health-checked runtime on the cluster.

***backend-b-deployment.yaml***

This Deployment is the twin of Backend-A but for Backend-B, another Node.js microservice. It also runs 2 replicas, uses the label app: backend-b, and exposes port 8080 with HTTP liveness and readiness probes hitting /health. This ensures Backend-B can be rolled out independently, scaled horizontally, and kept healthy by Kubernetes, while still being discoverable by Services and controlled by NetworkPolicies.

***configmap.yaml***

This file defines a ConfigMap called postgres-config in the image-app namespace. It stores non-sensitive database connection parameters like DB_HOST: postgres and DB_PORT: "5432". These values are intended to be injected into backend and database pods as environment variables or mounted files, so you can change connection details without rebuilding container images. It cleanly separates configuration from code and centralizes common DB settings used across services.

***secrets.yaml***

This YAML defines an opaque Kubernetes Secret named postgres-secret that holds base64-encoded PostgreSQL credentials: DB_USER, DB_PASSWORD, and DB_NAME. By putting these values into a Secret instead of a ConfigMap, you keep sensitive information out of the plain-text manifests and container images. Pods (like your backends and PostgreSQL StatefulSet) can then reference these keys as environment variables, giving you secure, centralized credential management.

***services.yaml***

This file defines all the core Service objects for your app in one place. It includes a ClusterIP Service for PostgreSQL (name: postgres, port 5432) so backends can reach the database using stable DNS (postgres.image-app.svc.cluster.local). It also defines Services for your application components (with selector: app: ...) and a NodePort Service for the frontend (type: NodePort, nodePort: 30080, port: 80, targetPort: 80). This allows external users (your browser) to reach the React/Nginx frontend via http://<node-ip>:30080, while keeping the backends and database internal behind ClusterIP endpoints.

***postgres-statefulset.yaml***

This StatefulSet deploys a single-instance PostgreSQL database in the image-app namespace with the label app: postgres. It uses serviceName: postgres so it can be reached via the corresponding Service. The pod template mounts a volume named postgres-storage backed by the postgres-pvc claim (from pvc.yaml), giving the database persistent storage across restarts. It also mounts a ConfigMap (postgres-config) via the postgres-init volume, which is used to inject an init.sql script. The included readiness and liveness probes (truncated in the file) ensure that only a healthy database is used by the application.

***pvc.yaml***

This defines a PersistentVolumeClaim named postgres-pvc in the image-app namespace, requesting 10Gi of storage with ReadWriteOnce access mode. The StatefulSet for PostgreSQL binds to this claim and mounts it into the pod so that database files are stored on persistent disk instead of ephemeral container storage. This is what allows PostgreSQL data to survive pod restarts, redeployments, and crashes, making the database truly stateful.

***hpa-frontend.yaml***

This file configures a HorizontalPodAutoscaler named frontend-hpa for the frontend Deployment. It targets the frontend Deployment and specifies a range of 2–5 replicas, automatically scaling the number of frontend pods based on CPU utilization. When average CPU usage across the frontend pods rises above 70%, Kubernetes will increase the replica count up to the maximum; if load drops, it scales back down, ensuring efficient resource usage while maintaining responsiveness.

***hpa-backend-a.yaml***

This HPA config (backend-a-hpa) targets the backend-a Deployment and also uses autoscaling in the 2–5 replica range. It monitors both CPU and memory utilization, aiming to keep each at about 70%. If Backend-A starts receiving more requests and CPU/memory usage rises, the HPA will scale the number of pods up; when traffic reduces, it scales down. This gives Backend-A elastic capacity based on real-time load, which is exactly what you’d expect in a production microservices environment.

***hpa-backend-b.yaml***

Similar to Backend-A, this HPA (backend-b-hpa) attaches to the backend-b Deployment with a 2–5 replica range and autoscaling based on both CPU and memory utilization (target 70%). This ensures Backend-B can handle spikes in traffic independently of Backend-A and the frontend, allowing each microservice to scale according to its own workload profile.

***networkpolicy-deny-all.yaml***

This NetworkPolicy (default-deny-all) is your baseline zero-trust rule. It applies to all pods in the image-app namespace (podSelector: {}) and sets both Ingress and Egress as policyTypes. With this applied, no pod can talk to any other pod or go out of the namespace by default—everything is blocked unless explicitly allowed by more specific NetworkPolicies. This is the core of your security posture; the other NetworkPolicy manifests then “poke holes” only where needed.

***networkpolicy-egress-allow.yaml***

This file groups several egress NetworkPolicies that selectively open outbound traffic from specific pods. From the visible parts, it includes a policy like allow-frontend-egress-backend-a which allows pods labeled app: frontend to send egress traffic to pods labeled app: backend-a on port 8080. Later in the file, another policy allows pods labeled app: backend-b to send egress traffic to pods labeled app: postgres on port 5432. Together with similar rules for Backend-A, this file defines exactly which pods are allowed to call which other pods, implementing strict, least-privilege egress controls.

***networkpolicy-ingress-allow.yaml***

This file contains the complementary ingress NetworkPolicies. From the snippets, one policy (allow-frontend-to-backend-a) allows ingress into pods labeled app: backend-a only from pods labeled app: frontend on the appropriate port. At the bottom of the file, another policy selects pods labeled app: frontend and allows ingress from an ipBlock with cidr: 0.0.0.0/0 on port 80, so your frontend can receive traffic from any external IP (for local/dev testing) while still being isolated from other internal pods. Overall, this file defines who is allowed to send traffic into each major component, matching your logical architecture.

***resourcequota.yaml***

This YAML defines a ResourceQuota named image-app-quota scoped to the image-app namespace. It caps total CPU requests at 2 cores, CPU limits at 4 cores, memory requests at 4Gi, memory limits at 8Gi, and limits the number of pods to 15 and PVCs to 3. This prevents any single app or misconfigured Deployment from consuming all cluster resources and enforces an upper bound that fits a dev/test environment. It’s a very “real-world” touch: you’re showing you know how to control multi-tenant usage in a namespace.






**Architecture diagram**

                  ┌─────────────────────────────┐
                  │        End User (Browser)    │
                  └──────────────┬──────────────┘
                                 │  HTTP Request
                                 ▼
                    ┌──────────────────────────┐
                    │   NodePort Service (30080)│
                    │   Exposes Frontend        │
                    └──────────────┬───────────┘
                                   ▼
                ┌──────────────────────────────────┐
                │   Frontend Deployment             │
                │   React App + Nginx Container     │
                │   (Multiple Replicas)             │
                └──────────────┬───────────────────┘
                               │
                ───────────────┼────────────────────────
                               │ Internal Routing via Nginx
                               ▼
           ┌─────────────────────────┐   ┌─────────────────────────┐
           │ Backend-A Service (CI)  │   │ Backend-B Service (CI)  │
           └──────────────┬─────────┘   └──────────────┬─────────┘
                          ▼                            ▼
              ┌──────────────────────┐     ┌──────────────────────┐
              │ Backend-A Deployment │     │ Backend-B Deployment │
              │ Node.js API Pods     │     │ Node.js API Pods     │
              └─────────────┬────────┘     └─────────────┬────────┘
                            │                              │
                            └───────────┬─────────────────┘
                                        ▼
                           ┌─────────────────────────────┐
                           │ PostgreSQL Headless Service │
                           │ (Stable DNS for DB Pods)    │
                           └──────────────┬──────────────┘
                                          ▼
                          ┌────────────────────────────────┐
                          │ PostgreSQL StatefulSet         │
                          │ Persistent Volume + PVC        │
                          │ Encrypted Data at Rest         │
                          └────────────────────────────────┘


     ✅ Network Policies Enforced:
     - Frontend → Backend-A & Backend-B allowed
     - Backend-A/B → PostgreSQL allowed
     - All other traffic blocked (Zero-Trust Model)





**Assignment 2: Static Code Analysis using SonarQube & Docker**

Project Description

In this assignment, I implemented static code quality analysis for a multi-tier microservices application using SonarQube and Sonar Scanner CLI running inside Docker containers. The goal was to identify code smells, bugs, security vulnerabilities, and maintainability issues across frontend and backend services before deployment, following industry-standard shift-left DevOps practices.

The application consists of:

Frontend service

Backend-A service

Backend-B service

Each service was analyzed as an independent SonarQube project, enabling granular quality tracking and governance.



**Key Implementation Steps**

1. SonarQube Setup

Ran SonarQube locally on port 9000

Created separate projects for frontend and backend services

Configured Quality Gates using default Sonar Way

2. Authentication & Security

Generated a global SonarQube user token

Used secure environment variables (SONAR_TOKEN) for authentication

Avoided hardcoding credentials in CLI commands

3. Dockerized Sonar Scanner Execution

Executed Sonar Scanner using Docker to ensure consistency across environments

Mounted source code directories into the scanner container

Passed project metadata dynamically using -Dsonar.* properties

4. Multi-Service Analysis

Analyzed each microservice independently:

image-app (frontend)

image-app-backend-a

image-app-backend-b

Uploaded analysis reports to SonarQube dashboard

5. Quality & Security Validation

Reviewed metrics including:

Bugs

Code smells

Security hotspots

Maintainability ratings

Verified Quality Gate status for each service


(Commands Used)

1️⃣ Run SonarQube Server (Docker – Local)
docker run -d --name sonarqube -p 9000:9000 sonarqube:9.9-community

2️⃣ Access SonarQube UI
http://localhost:9000


(Default login: admin / admin, then generate token)

3️⃣ Run Sonar Scanner for Frontend
docker run --rm -e SONAR_HOST_URL=http://host.docker.internal:9000 -e SONAR_TOKEN=<SONAR_TOKEN> -v ${PWD}/test/frontend:/usr/src sonarsource/sonar-scanner-cli --% -Dsonar.projectKey=image-app-frontend -Dsonar.projectName=manvith-sonar-frontend -Dsonar.sources=.

4️⃣ Run Sonar Scanner for Backend-A
docker run --rm -e SONAR_HOST_URL=http://host.docker.internal:9000 -e SONAR_TOKEN=<SONAR_TOKEN> -v ${PWD}/test/backend-a:/usr/src sonarsource/sonar-scanner-cli --% -Dsonar.projectKey=image-app-backend-a -Dsonar.projectName=manvith-sonar-backend-a -Dsonar.sources=.

5️⃣ Run Sonar Scanner for Backend-B
docker run --rm -e SONAR_HOST_URL=http://host.docker.internal:9000 -e SONAR_TOKEN=<SONAR_TOKEN> -v ${PWD}/test/backend-b:/usr/src sonarsource/sonar-scanner-cli --% -Dsonar.projectKey=image-app-backend-b -Dsonar.projectName=manvith-sonar-backend-b -Dsonar.sources=.

6️⃣ Verify Results in SonarQube Dashboard
http://localhost:9000/projects




**Assignment 3 — Monitoring with Prometheus & Grafana (AKS)**
Objective

The objective of Assignment 3 is to implement end-to-end monitoring and observability for a microservices-based application deployed on Azure Kubernetes Service (AKS). This includes collecting real-time CPU and memory metrics, visualizing application performance, and validating Horizontal Pod Autoscaler (HPA) behavior under load.

Monitoring Architecture

The monitoring stack is built using Kubernetes-native tools:

Metrics Server – Provides real-time resource metrics required for HPA

Prometheus – Collects and stores cluster, node, and pod-level metrics

Grafana – Visualizes metrics using dashboards

kube-prometheus-stack (Helm) – Simplifies deployment and management

Prometheus automatically scrapes metrics from:

kubelets

cAdvisor

Kubernetes API server

Nodes

Pods

Namespaces

Implementation Summary

Metrics Server was installed to enable CPU and memory metrics for pods and nodes.

Helm was used to deploy the kube-prometheus-stack, which includes:

Prometheus

Grafana

Alertmanager

Grafana was accessed via port forwarding, and dashboards were used to monitor:

Pod CPU usage

Pod memory usage

Node utilization

Namespace-level metrics

HPA metrics were validated by observing live resource usage and replica scaling behavior.

Key Validations Performed

Verified real-time metrics using:

kubectl top pods

kubectl top nodes

Confirmed Prometheus scraping cluster metrics

Accessed Grafana dashboards to visualize:

CPU & memory usage

Deployment replica counts

Validated that HPA could react to metric changes

Outcome

Achieved full observability of the AKS cluster and application workloads

Enabled proactive monitoring of performance and resource utilization

Confirmed Kubernetes auto-scaling readiness

Implemented a production-grade monitoring stack using industry-standard tools


(Commands Used)

1️⃣ Install Metrics Server (Required for HPA)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

2️⃣ Verify Metrics Server
kubectl top nodes

kubectl top pods -n image-app

3️⃣ Install Helm (Manual – Windows)
Invoke-WebRequest https://get.helm.sh/helm-v3.14.4-windows-amd64.zip -OutFile helm.zip

tar -xf helm.zip

mkdir $env:USERPROFILE\bin; Move-Item windows-amd64\helm.exe $env:USERPROFILE\bin

$env:PATH += ";$env:USERPROFILE\bin"

helm version

4️⃣ Add Prometheus Helm Repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

helm repo update

5️⃣ Install Prometheus + Grafana Stack
helm install monitoring prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace

6️⃣ Verify Monitoring Pods
kubectl get pods -n monitoring

7️⃣ Get Grafana Admin Password (PowerShell)
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String((kubectl get secret monitoring-grafana -n monitoring -o jsonpath="{.data.admin-password}")))

8️⃣ Access Grafana
kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring

http://localhost:3000

9️⃣ Verify HPA & Metrics
kubectl get hpa -n image-app

kubectl top pods -n image-app

kubectl top nodes