# HPA Scaling Fix

A CPU-bound API stays at a fixed replica count during traffic spikes. Exactly three fault groups: missing CPU resource governance, HPA target mismatch, and an unsuitable HPA operating policy. Work in assessment order; faults can mask each other. Do not edit app code or scripts.

## Required operating contract

- Deployment/container `scaling-api` / `api`; loaded image `scaling-api:1.0.0`; port 5000; `/health` returns HTTP 200 with status `ok`; `/work` burns CPU for about 0.2 seconds per request.
- Requests: CPU **100m**, memory **64Mi**. Limits: CPU **500m**, memory **128Mi**. Set CPU request explicitly; a CPU limit alone may default the request and is not this contract.
- HPA `scaling-api` must target the existing Deployment; CPU utilization **50%**, minimum **1**, maximum **4** replicas. Preserve the Resource/Utilization metric.
- Do not manually scale to claim HPA recovery. Do not change `spec.replicas` after HPA takes control. Keep probes and memory settings.
- Scale-down can take 5–7 minutes with default stabilization. No exact peak replica count is required: show an increase above the quiet baseline, then a decrease after load stops.

## Instructor preparation (before timer)

Use a free local cluster, working metrics-server, kubectl and an editor. No credentials, registry login or cloud. Reserve enough capacity for four pods at the above budget.

```bash
docker build -t scaling-api:1.0.0 .
# kind load docker-image scaling-api:1.0.0 --name <cluster>
# or: minikube image load scaling-api:1.0.0
kubectl create namespace scaling-ca
kubectl -n scaling-ca apply -f k8s/
kubectl -n scaling-ca rollout status deploy/scaling-api
kubectl top nodes
```

Prepare tools, images and metrics before timer. Missing cluster metrics is an environment fault: report it, do not install add-ons during assessment.

## Command reference

```bash
kubectl -n scaling-ca get hpa,pods
kubectl -n scaling-ca describe hpa scaling-api
kubectl -n scaling-ca get deploy scaling-api -o yaml
kubectl -n scaling-ca apply -f k8s/deployment.yaml
kubectl -n scaling-ca apply -f k8s/hpa.yaml
kubectl -n scaling-ca top pods
bash scripts/load.sh scaling-ca
kubectl -n scaling-ca get hpa,pods -w
# Ctrl-C exits watch, not load. Load stops itself after 180 seconds.
kubectl -n scaling-ca delete pod scaling-load --ignore-not-found
bash scripts/request.sh scaling-ca http://scaling-api/health
```

A newly created HPA can briefly show `<unknown>` while metrics arrive; allow 60–120 seconds. Re-run load if needed after corrections. Edit only `k8s/deployment.yaml`, `k8s/hpa.yaml`, and your `repair-notes.md`. Use only assigned namespace. Commit repaired files and notes to your fork.
