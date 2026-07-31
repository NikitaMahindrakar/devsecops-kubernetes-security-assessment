# Dodo Payments – Security & DevOps Engineer Technical Assessment

## Overview

This repository contains my submission for the **Dodo Payments Security & DevOps Engineer Technical Assessment**.

The objective of this assessment was to secure a vulnerable Kubernetes-based microservice (**ledger-api**) by applying modern DevSecOps practices including workload hardening, secure CI/CD, GitOps, service mesh security, and security testing.

The entire project was implemented locally using **Minikube**, **GitHub Actions**, and open-source security tools without requiring any cloud infrastructure.

---


# Architecture

```
                         GitHub Repository
                                 │
                                 │
                    GitHub Actions CI/CD Pipeline
                                 │
       ┌─────────────────────────┼────────────────────────┐
       │                         │                        │
   Semgrep                  Gitleaks                 Trivy
       │                         │                        │
       └────────────── Security Gates ────────────────────┘
                                 │
                             Cosign Sign
                                 │
                                GHCR
                                 │
                           ArgoCD (GitOps)
                                 │
                           Kubernetes Cluster
                           (Minikube + Docker)
                                 │
             ┌───────────────────┴───────────────────┐
             │                                       │
        ledger-api                           neighbour-service
             │                                       │
             └──────── Istio Service Mesh ───────────┘
                     mTLS + AuthorizationPolicy
                             + NetworkPolicy
```

---

# Environment

- Windows 10
- Docker Desktop
- Minikube
- Kubernetes
- GitHub Actions
- ArgoCD
- Istio
- PowerShell

---

# Technologies Used

## Kubernetes

- Deployments
- Services
- ConfigMaps
- Secrets
- Ingress
- Service Accounts
- RBAC
- Network Policies

## DevSecOps

- GitHub Actions
- ArgoCD
- GHCR
- Cosign
- Kyverno

## Security Tools

- Semgrep
- Trivy
- Gitleaks
- Nuclei
- Burp Suite Community
- Subfinder
- Assetfinder
- Httpx

---

# Task Summary

## Task 1 – Deploy & Harden the Workload

Implemented production-grade Kubernetes security by:

- Deploying ledger-api and neighbour service
- ConfigMaps
- Secrets
- Ingress
- Dedicated Service Accounts
- Least-Privilege RBAC
- Security Context
- Read-only filesystem
- Non-root containers
- Dropped Linux capabilities
- RuntimeDefault seccomp
- Resource limits
- Liveness and readiness probes
- Kyverno admission policies
- Secure secret management

📄 Documentation

```
task1/README.md
```

---

## Task 2 – Secure CI/CD Pipeline & Supply Chain

Built a secure GitHub Actions pipeline implementing:

- Docker image build
- SAST (Semgrep)
- Secret scanning (Gitleaks)
- Dependency scanning (Trivy)
- Container image scanning
- Cosign image signing
- SLSA provenance
- GitOps deployment using ArgoCD
- Drift detection and self-healing

Pipeline Security Gates

| Tool | Purpose |
|------|---------|
| Gitleaks | Secret Detection |
| Semgrep | Static Analysis |
| Trivy | Dependency & Image Scan |
| Cosign | Image Signing |
| ArgoCD | GitOps Deployment |

📄 Documentation

```
task2/README.md
```

---

## Task 3 – Service Mesh & Zero Trust

Implemented Zero Trust networking using Istio.

Features

- Istio Service Mesh
- Sidecar Injection
- Mutual TLS (STRICT)
- SPIFFE Workload Identity
- AuthorizationPolicy
- Kubernetes NetworkPolicy
- Automatic Certificate Rotation
- Defense in Depth

📄 Documentation

```
task3/README.md
```

---

## Task 4 – Reconnaissance & Penetration Testing

Performed security assessment in two phases.

### Part A – Passive Reconnaissance

- Certificate Transparency
- DNS Enumeration
- Subfinder
- Assetfinder
- Httpx
- Technology Fingerprinting
- Attack Surface Mapping

### Part B – Authorized Penetration Testing

- Burp Suite Community
- Nuclei
- OWASP Top 10 Testing
- Vulnerability Reporting
- Risk Assessment
- Remediation Recommendations

📄 Documentation

```
task4/README.md
```

---

# Security Controls Implemented

| Area | Control |
|-------|----------|
| Container Security | Non-root containers |
| Filesystem | Read-only root filesystem |
| Linux Security | Drop all capabilities |
| Runtime Security | RuntimeDefault seccomp |
| Kubernetes | RBAC |
| Secrets | Kubernetes Secrets |
| Admission Control | Kyverno Policies |
| CI/CD | GitHub Actions |
| SAST | Semgrep |
| Secret Scanning | Gitleaks |
| Vulnerability Scanning | Trivy |
| Image Signing | Cosign |
| GitOps | ArgoCD |
| Service Mesh | Istio |
| Encryption | mTLS |
| Authorization | AuthorizationPolicy |
| Network Isolation | NetworkPolicy |

---

# Screenshots Included

The repository includes evidence for each task, including:

- Kubernetes deployments
- Kyverno policy enforcement
- GitHub Actions pipeline
- Trivy scan
- Semgrep scan
- Gitleaks scan
- Cosign verification
- ArgoCD synchronization
- Drift detection
- Istio installation
- mTLS verification
- AuthorizationPolicy enforcement
- NetworkPolicy
- Reconnaissance output
- Penetration testing results

---

# How to Run

Clone the repository.

```bash
git clone https://github.com/<YOUR_USERNAME>/devsecops-kubernetes-security-assessment.git
```

Start Minikube.

```powershell
minikube start --driver=docker
```

Deploy Task 1.

```powershell
kubectl apply -f task1/manifests/
```

Run the GitHub Actions pipeline by pushing changes to the `main` branch.

Install ArgoCD and Istio by following the instructions in:

- `task2/README.md`
- `task3/README.md`

Execute reconnaissance and penetration testing using the steps in:

- `task4/README.md`

---

# Key Learning Outcomes

This project demonstrates:

- Kubernetes Security Best Practices
- Secure CI/CD Pipelines
- DevSecOps Automation
- GitOps Workflows
- Software Supply Chain Security
- Zero Trust Networking
- Service Mesh Security
- Offensive Security Assessment
- Security Hardening for PCI DSS Environments

---

# References

- Kubernetes Documentation
- Istio Documentation
- ArgoCD Documentation
- Kyverno Documentation
- Cosign Documentation
- Semgrep Documentation
- Trivy Documentation
- OWASP Top 10
- Dodo Payments Technical Assessment

---

# Submission

This repository was created as part of the **Dodo Payments Security & DevOps Engineer Technical Assessment**.

Each task contains its own README with implementation details, commands, design decisions, and evidence demonstrating the completed work.
