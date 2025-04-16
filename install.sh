#!/bin/zsh
# make sure you have a clean kubernetes cluster

# Install ingress-nginx
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace

# Install kube-prometheus-stack
helm upgrade --install prometheus kube-prometheus-stack \
    --repo https://prometheus-community.github.io/helm-charts \
    --namespace prometheus --create-namespace \
    --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
    --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false

# Upgrade nginx ingress controller to use prometheus metrics
helm upgrade ingress-nginx ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx \
    --namespace ingress-nginx \
    --set controller.metrics.enabled=true \
    --set controller.metrics.serviceMonitor.enabled=true \
    --set controller.metrics.serviceMonitor.additionalLabels.release="prometheus"

# To verify the helm values
helm get values ingress-nginx --namespace ingress-nginx
helm get values prometheus --namespace prometheus

# Install Argo Rollouts
kubectl create namespace argo-rollouts || echo "Namespace argo-rollouts already exists!"
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# Install Argo Rollouts manifests
kubectl apply -f ./manifests/rollout.yaml -f ./manifests/service.yaml -f ./manifests/ingress.yaml -f ./manifests/latency.yaml -f ./manifests/success-rate.yaml


