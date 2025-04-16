# Argo Rollouts Demo

A local demo environment for [Argo Rollouts](https://argoproj.github.io/argo-rollouts/) featuring Nginx Ingress Controller and Prometheus monitoring.

## Overview

This project provides a complete development environment to demonstrate progressive delivery capabilities using Argo Rollouts, with:

- Local Kubernetes environment
- Nginx Ingress Controller for traffic management
- Prometheus for metrics collection and analysis
- Example applications showcasing various deployment strategies

## Prerequisites

- Kubernetes cluster (minikube, kind, or k3d)
- kubectl
- Helm
- [Argo Rollouts kubectl plugin](https://argoproj.github.io/argo-rollouts/installation/#kubectl-plugin-installation)

## Installation

1. **Start your local Kubernetes cluster**

```bash
# Example with kind
kind create cluster --name argo-rollouts-demo

# OR with minikube
minikube start --cpus 4 --memory 8192
```

3. **Install Nginx Ingress Controller**

```bash
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```

4. **Install Prometheus**

```bash
# Install kube-prometheus-stack
helm upgrade --install prometheus kube-prometheus-stack \
    --repo https://prometheus-community.github.io/helm-charts \
    --namespace prometheus --create-namespace \
    --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
    --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false

# Upgrade nginx ingress controller to use prometheus metrics
helm upgrade ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --set controller.metrics.enabled=true \
    --set controller.metrics.serviceMonitor.enabled=true \
    --set controller.metrics.serviceMonitor.additionalLabels.release="prometheus"

# To verify the helm values
helm get values ingress-nginx --namespace ingress-nginx
helm get values prometheus --namespace prometheus
```

2. **Install Argo Rollouts**

```bash
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# Also install the kubectl plugin
https://argoproj.github.io/argo-rollouts/installation/#kubectl-plugin-installation
```

5. **Deploy demo applications**

```bash
kubectl apply -f ./manifests/rollout.yaml -f ./manifests/service.yaml -f ./manifests/ingress.yaml -f ./manifests/latency.yaml -f ./manifests/success-rate.yaml
```

## Usage

### Accessing the Demo Applications

1. **Get the Ingress IP/hostname**

```bash
export INGRESS_HOST=$(kubectl get svc -n ingress-nginx nginx-ingress-ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
# If using minikube, you might need:
# minikube tunnel (in a separate terminal)
```

2. **Access the demo applications**

```bash
# Example application
kubectl get ingress rollouts-demo -o jsonpath='{.spec.rules[0].host}' # rollouts-demo.example.com
kubectl get ingress rollouts-demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}' # 198.19.249.2
echo '198.19.249.2 rollouts-demo.example.com' >> /etc/hosts # Add to /etc/hosts for local testing
# Then open http://rollouts-demo.example.com in your browser
```

3. **Access Argo Rollouts Dashboard**

```bash
kubectl argo rollouts dashboard
# then open http://localhost:3100/rollouts
```

4. **Access Grafana**

forward grafana service to localhost then access it.
default authentication is **admin:prom-operator**
You can import the dashboard for nginx with this url: https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/grafana/dashboards/nginx.json

### Triggering a Rollout

```bash
# Update the application image to trigger a rollout
kubectl argo rollouts set image rollouts-demo rollouts-demo=argoproj/rollouts-demo:blue

# Watch the rollout progress
kubectl argo rollouts get rollout rollouts-demo --watch
```

### Promoting a Rollout

```bash
# After verification, promote the rollout
kubectl argo rollouts promote rollouts-demo
```

## Demo Scenarios

1. **Canary Deployment**: Gradually shifts traffic from the stable version to the new version
2. **Blue/Green Deployment**: Deploys new version alongside old version, then switches traffic
3. **Analysis with Prometheus**: Uses metrics to automatically validate deployments

## Project Structure

```
.
├── README.md
├── manifests/                  # Kubernetes manifests
└── install.sh                    # Helper scripts
```

## Troubleshooting

- **Issue**: Ingress controller not responding
  **Solution**: Check if the ingress controller is running with `kubectl get pods -n ingress-nginx`

- **Issue**: Metrics not showing in Prometheus
  **Solution**: Verify ServiceMonitor resources are correctly configured

## Resources

- [Argo Rollouts Documentation](https://argoproj.github.io/argo-rollouts/)
- [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Prometheus Documentation](https://prometheus.io/docs/introduction/overview/)
