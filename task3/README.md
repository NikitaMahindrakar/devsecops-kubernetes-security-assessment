# Task 3 – Service Mesh & Zero Trust (Istio)

## Objective

The goal of this task is to secure communication between Kubernetes workloads using **Istio Service Mesh**.

This implementation demonstrates:

- Mutual TLS (mTLS) encryption
- Identity-based authorization
- Zero Trust networking
- Kubernetes Network Policies
- Defense-in-depth security

---

# Architecture

```
                 +-----------------------+
                 |     Istio Ingress     |
                 +----------+------------+
                            |
                            |
                 +----------v-----------+
                 |      ledger-api      |
                 |  Service Account     |
                 +----------+-----------+
                            |
                mTLS (STRICT)
                            |
                 +----------v-----------+
                 |   neighbour-service  |
                 |  Service Account     |
                 +----------------------+

            Kubernetes NetworkPolicy
          (Default Deny + Explicit Allow)
```

---

# Prerequisites

- Windows 10/11
- Docker Desktop
- Minikube
- kubectl
- Istioctl

---

# Step 1 — Increase Minikube Resources

Istio requires additional CPU and memory.

```powershell
minikube stop

minikube start ^
  --driver=docker ^
  --memory=8192 ^
  --cpus=4
```

Verify:

```powershell
kubectl get nodes
```

---

# Step 2 — Install Istio

Download:

https://github.com/istio/istio/releases

Extract and add **istioctl.exe** to PATH.

Verify installation:

```powershell
istioctl version
```

Install Istio:

```powershell
istioctl install --set profile=demo -y
```
<img width="965" height="498" alt="Screenshot 2026-07-30 144545" src="https://github.com/user-attachments/assets/458b0b30-bd33-4e04-9105-3945ad7448ef" />

Verify:

```powershell
kubectl get pods -n istio-system
```

Wait until every pod is Running.

---

# Step 3 — Enable Automatic Sidecar Injection

Enable injection on the application namespace.

```powershell
kubectl label namespace ledger istio-injection=enabled
```

Restart deployments.

```powershell
kubectl rollout restart deployment ledger-api -n ledger
kubectl rollout restart deployment neighbour-service -n ledger
```

Verify sidecars.

```powershell
kubectl get pods -n ledger
```
<img width="1366" height="768" alt="Screenshot 2026-07-30 143344" src="https://github.com/user-attachments/assets/621e1ede-8810-4193-af23-1ec4589cc9f8" />

Expected:

```
ledger-api-xxxxx            2/2 Running
neighbour-service-xxxxx     2/2 Running
```

The second container is the Envoy sidecar.

---

# Step 4 — Apply Peer Authentication

Apply STRICT mTLS.

```powershell
kubectl apply -f task3/manifests/peer-auth.yaml
```
<img width="1366" height="768" alt="Screenshot 2026-07-30 144708" src="https://github.com/user-attachments/assets/5112ccfe-a935-43f1-bf76-f2dc41147e6d" />

Verify:

```powershell
kubectl get peerauthentication -n ledger
```

Check TLS status:

```powershell
istioctl authn tls-check ledger-api.ledger.svc.cluster.local
```

Expected:

```
TLS mode: STRICT
```

This proves all traffic between workloads is encrypted.

---

# Step 5 — Apply Authorization Policy

Apply the default deny policy.

```powershell
kubectl apply -f task3/manifests/authz-policy.yaml
```

Verify:

```powershell
kubectl get authorizationpolicy -n ledger
```

Only workloads using the approved ServiceAccount are allowed to access the application.

Requests from unauthorized workloads are denied.

---

# Testing

## Verify Sidecar Injection

```powershell
kubectl get pods -n ledger
```

Expected:

```
2/2 Running
```

---

## Verify mTLS

```powershell
istioctl authn tls-check ledger-api.ledger.svc.cluster.local
```

Expected:

```
STRICT
```

---

## Verify Authorization

Deploy a temporary pod.

```powershell
kubectl run test \
--image=curlimages/curl \
-it \
--rm \
--restart=Never \
-n ledger \
-- sh
```

Attempt to call:

```
http://ledger-api
```

Expected:

```
403 Forbidden
```

An unauthorized workload is denied.

---

## Verify Authorized Workload

Call the service from the approved neighbour service.

Expected:

```
200 OK
```

---

# Workload Identity

Istio authenticates workloads using **SPIFFE identities**.

Example identity:

```
spiffe://cluster.local/ns/ledger/sa/ledger-api-sa
```

Authorization decisions are based on workload identity rather than IP addresses.

---

# Certificate Management

Istio automatically issues certificates to every workload.

Certificate lifecycle:

1. Workload starts
2. Envoy requests certificate from Istiod
3. Istiod signs certificate
4. Certificate is automatically rotated before expiry

Trust Root:

```
Istio Root CA
```

No manual certificate management is required.

---

# Defense in Depth

## Istio AuthorizationPolicy

Protects:

- Service-to-service communication
- Identity-based access
- Mutual TLS authentication

---

## Kubernetes NetworkPolicy

Protects:

- Pod networking
- Namespace isolation
- East-West traffic

Even if Istio is bypassed, NetworkPolicy still blocks unauthorized traffic.

---

# Security Controls Implemented

- Istio Service Mesh
- STRICT Mutual TLS
- SPIFFE Workload Identity
- AuthorizationPolicy
- Kubernetes NetworkPolicy
- Automatic Certificate Rotation
- Zero Trust Architecture

---

# Evidence

Include the following screenshots:

- Istio installation
- istioctl version
- Pods with sidecars (2/2 Ready)
- PeerAuthentication
- AuthorizationPolicy
- NetworkPolicy
- TLS Check
- Unauthorized request (403)
- Authorized request (200)

---

# Outcome

Successfully implemented a Zero Trust architecture using Istio Service Mesh.

Features achieved:

- Mutual TLS encryption
- Identity-based authorization
- Automatic workload certificates
- Default deny access
- Defense-in-depth with Kubernetes Network Policies

This implementation secures communication between services and aligns with the security requirements for PCI DSS scoped workloads.
