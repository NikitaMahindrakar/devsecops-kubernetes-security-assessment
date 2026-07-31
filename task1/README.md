<img width="1366" height="768" alt="Screenshot 2026-07-29 155545" src="https://github.com/user-attachments/assets/6d15b4f4-7786-44fd-a6f1-abffdd12965e" /># Task 1 – Deploy & Secure the Workload

## Overview

In this task, I deployed the **ledger-api** application on a local Kubernetes cluster (Minikube) and improved its security to make it closer to a production-ready application.

The original application had several security issues:

* Secrets stored in plain text
* Container running as the root user
* No security restrictions
* Using the default ServiceAccount
* No admission policies to stop insecure deployments

After hardening, the application includes:

* Encrypted secrets using **Sealed Secrets**
* Non-root containers
* Read-only root filesystem
* All Linux capabilities removed
* Least-privilege ServiceAccount and RBAC
* Kyverno policies to block insecure deployments
* Pod Security Standards enabled for the namespace

---

# Steps

## 1. Start Minikube

```powershell
minikube start --driver=docker
```

Check the cluster:

```powershell
kubectl get nodes
```

---

## 2. Build the Application Image

```powershell
minikube docker-env --shell powershell | Invoke-Expression

docker build -t ledger-api:v1.0.0 .
```
<img width="1366" height="768" alt="Screenshot 2026-07-29 144728" src="https://github.com/user-attachments/assets/de4e96e9-abfa-465d-9691-ffa02878ecca" />

---

## 3. Create Encrypted Secrets

Instead of storing passwords in Git, I used **Sealed Secrets**.

```powershell
kubectl create secret generic ledger-api-secrets \
--from-literal=DB_PASSWORD=****** \
--dry-run=client -o yaml | kubeseal > sealed-secret.yaml
```
<img width="1366" height="768" alt="Screenshot 2026-07-29 152302" src="https://github.com/user-attachments/assets/45655739-52eb-47f3-aa9d-dda93fd0f654" />


This allows the encrypted secret to be safely committed to Git.

---

## 4. Deploy the Application

Apply all Kubernetes manifests.

```powershell
kubectl apply -f manifests/
```

Verify:

```powershell
kubectl get all -n ledger
```
<img width="1366" height="768" alt="Screenshot 2026-07-29 155519" src="https://github.com/user-attachments/assets/0f5a143a-7200-44f1-8cea-469e891f5952" />

---

## 5. Install Kyverno Policies

Apply the security policies.

```powershell
kubectl apply -f kyverno/
```

These policies block:

* Containers running as root
* Images using the **latest** tag
* Other insecure deployments

---

## 6. Test the Policies

Deploy an insecure application.

```powershell
kubectl apply -f test/insecure-deployment.yaml
```

Expected result:

<img width="1366" height="768" alt="Screenshot 2026-07-29 155545" src="https://github.com/user-attachments/assets/dba049c6-13b8-4337-b558-271e5fd726b9" />

<img width="1366" height="768" alt="Screenshot 2026-07-29 160223" src="https://github.com/user-attachments/assets/5a55ee36-d788-4a90-9ffb-0fba79d87fa3" />



Deploy the secure version.

```powershell
kubectl apply -f test/secure-deployment.yaml
```

Expected result:

<img width="1366" height="768" alt="Screenshot 2026-07-29 160419" src="https://github.com/user-attachments/assets/286960b6-659e-438b-8edf-875a3bcfc926" />


---

# Security Improvements

| Security Control             | Status |
| ---------------------------- | ------ |
| Run as non-root              | ✅      |
| Read-only filesystem         | ✅      |
| Drop all Linux capabilities  | ✅      |
| Disable privilege escalation | ✅      |
| Resource limits              | ✅      |
| Health probes                | ✅      |
| Dedicated ServiceAccount     | ✅      |
| RBAC                         | ✅      |
| Sealed Secrets               | ✅      |
| Kyverno policies             | ✅      |
| Pod Security Standards       | ✅      |

---

# Why I Chose These Tools

* **Sealed Secrets** – Keeps secrets encrypted in Git.
* **Kyverno** – Easy-to-read Kubernetes security policies written in YAML.
* **Dedicated ServiceAccount** – Gives the application only the permissions it needs.
* **Non-root Containers** – Reduces the impact if the container is compromised.

---

# Future Improvements

If I had more time, I would also add:

* Network Policies for pod-to-pod communication
* HashiCorp Vault with External Secrets
* Falco for runtime security monitoring
* Pod Disruption Budgets for high availability
* Automatic secret rotation

---

# Result

The original insecure application was successfully transformed into a much more secure Kubernetes deployment by applying container hardening, encrypted secret management, RBAC, and admission policies that prevent insecure workloads from running.
