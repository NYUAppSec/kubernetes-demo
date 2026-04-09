# Kubernetes Demo

## Overview
This demo provides a hands-on introduction to Kubernetes by deploying a microservices application with a **frontend** and **backend**. It demonstrates the core concepts from the lecture: Pods, Deployments, Services (ClusterIP vs NodePort), scaling, rolling updates, and how microservices communicate inside a cluster.

### What You'll Learn
* How Kubernetes organizes containers into **Pods**
* How **Deployments** manage replicas and updates
* The difference between **ClusterIP** (internal) and **NodePort** (external) services
* How microservices discover and communicate with each other
* How to **scale** a service and observe load balancing
* How to perform a **rolling update** with zero downtime

## Architecture

```
                    ┌─────────────────────────────────────────┐
                    │            Kubernetes Cluster            │
                    │                                         │
  Browser ──────►  │  frontend-service (NodePort :30080)      │
                    │       │                                  │
                    │       ▼                                  │
                    │  ┌──────────┐     backend-service        │
                    │  │ frontend │────► (ClusterIP :5000)     │
                    │  │  (nginx) │         │                  │
                    │  └──────────┘         ▼                  │
                    │                 ┌──────────┐             │
                    │                 │ backend  │ ← Pod 1     │
                    │                 │ (python) │             │
                    │                 ├──────────┤             │
                    │                 │ backend  │ ← Pod 2     │
                    │                 │ (python) │             │
                    │                 └──────────┘             │
                    └─────────────────────────────────────────┘
```

- **Frontend** is exposed via **NodePort** so you can access it from your browser
- **Backend** uses **ClusterIP** so it is only reachable from inside the cluster
- The frontend's nginx reverse-proxies `/api/` requests to the backend service

## Prerequisites
* [minikube](https://minikube.sigs.k8s.io/docs/start/) installed
* [kubectl](https://kubernetes.io/docs/tasks/tools/) installed
* Docker installed (used by minikube)

## Project Structure
```
k8s-demo/
├── backend/
│   ├── Dockerfile          # Python API container
│   └── server.py           # Simple REST API
├── frontend/
│   ├── Dockerfile          # nginx container
│   ├── index.html          # Web UI
│   └── nginx.conf          # Reverse proxy config
├── k8s/
│   ├── backend-deployment.yaml
│   ├── backend-service.yaml     # ClusterIP
│   ├── frontend-deployment.yaml
│   └── frontend-service.yaml    # NodePort
├── setup.sh                # One-command setup
├── cleanup.sh              # Tear everything down
└── README.md
```

## Quick Start

Run the setup script to start minikube, build images, and deploy everything:
```bash
./setup.sh
```

Then open the app:
```bash
minikube service frontend-service
```

## Step-by-Step Instructions

### 1. Start Minikube
```bash
minikube start
```
This creates a single-node Kubernetes cluster on your machine. Minikube acts as both the **Main Node** (control plane) and a **Worker Node**.

### 2. Use Minikube's Docker Daemon
```bash
eval $(minikube docker-env)
```
This tells your terminal's Docker CLI to build images directly inside minikube, so Kubernetes can find them without a registry.

### 3. Build the Container Images
```bash
docker build -t k8s-demo-backend:latest ./backend
docker build -t k8s-demo-frontend:latest ./frontend
```

### 4. Deploy the Backend
```bash
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml
```

Let's look at what we created:
```bash
# See the Deployment (manages desired state)
kubectl get deployments

# See the individual Pods (smallest deployable units)
kubectl get pods -l app=backend

# See the ClusterIP service (internal networking)
kubectl get service backend-service
```

**Key concept:** The backend service has type `ClusterIP`. It gets an internal IP address that is only accessible from within the cluster. Other pods can reach it using the DNS name `backend-service`.

### 5. Deploy the Frontend
```bash
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml
```

```bash
# See the NodePort service (external access)
kubectl get service frontend-service
```

**Key concept:** The frontend service has type `NodePort`. It exposes port 30080 on the node's IP, making it accessible from outside the cluster (your browser).

### 6. Access the Application
```bash
minikube service frontend-service
```
This opens your browser to the frontend. You'll see the UI fetch data from the backend API, demonstrating microservice communication.

## Exercises

### Exercise 1: Explore Pods
```bash
# List all pods
kubectl get pods

# Get detailed info about a pod
kubectl describe pod <pod-name>

# View logs from a backend pod
kubectl logs <backend-pod-name>

# Open a shell inside a pod
kubectl exec -it <backend-pod-name> -- sh
```

### Exercise 2: Scale the Backend
```bash
# Scale from 2 to 5 replicas
kubectl scale deployment backend --replicas=5

# Watch the new pods come up
kubectl get pods -l app=backend -w
```
Now refresh the frontend page multiple times. Notice the **hostname** field changes as requests are load-balanced across different backend pods.

### Exercise 3: Rolling Update
Simulate deploying a new version of the backend:
```bash
# Update the version environment variable
kubectl set env deployment/backend APP_VERSION="2.0"

# Watch the rolling update happen
kubectl rollout status deployment/backend
```
Kubernetes replaces pods one at a time, ensuring zero downtime. Refresh the frontend to see the version change.

### Exercise 4: Rollback
```bash
# Undo the last update
kubectl rollout undo deployment/backend

# Verify it rolled back
kubectl rollout status deployment/backend
```

### Exercise 5: Observe Self-Healing
```bash
# Delete a backend pod (Kubernetes will recreate it)
kubectl delete pod <backend-pod-name>

# Watch it get replaced automatically
kubectl get pods -l app=backend -w
```

### Exercise 6: Inspect Services
```bash
# See all services and their types
kubectl get services

# Look at the endpoints (which pods back each service)
kubectl get endpoints
```

## Concept Mapping (Lecture to Demo)

| Lecture Concept | Where to See It |
|---|---|
| Pod | `kubectl get pods` - each line is a pod |
| Node | `kubectl get nodes` - minikube is the single node |
| Deployment | `kubectl get deployments` - manages pod replicas |
| ClusterIP Service | `backend-service` - internal only |
| NodePort Service | `frontend-service` - externally accessible |
| Scaling | Exercise 2 - `kubectl scale` |
| Rolling Update | Exercise 3 - `kubectl set env` |
| Self-Healing | Exercise 5 - delete a pod, watch it return |
| Microservices | Frontend + Backend as independent services |
| Probes | Backend has liveness + readiness probes |
| etcd | Stores all cluster state (managed by minikube) |

## Clean Up
```bash
# Remove all demo resources
./cleanup.sh

# Stop minikube entirely
minikube stop

# (Optional) Delete the minikube cluster
minikube delete
```

## Common Issues
* **ImagePullBackOff**: Make sure you ran `eval $(minikube docker-env)` before building images
* **Pods stuck in Pending**: Check `kubectl describe pod <name>` for events
* **Can't reach NodePort**: Try `minikube service frontend-service` instead of using the IP directly
* **Port 30080 in use**: Edit `nodePort` in `frontend-service.yaml` to another value (30000-32767)

## Next Steps
After this demo, explore:
* **Ingress controllers** for production-style routing
* **ConfigMaps and Secrets** for configuration management
* **Persistent Volumes** for stateful workloads
* **Namespaces** for multi-tenant isolation
* **Helm charts** for packaging applications
