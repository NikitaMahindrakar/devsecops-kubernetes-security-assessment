# Task 2 — Secure CI/CD Pipeline & Supply Chain

## Overview

Rebuilt the delivery path so security is **enforced by the pipeline**, not by good
intentions. Every image reaching the cluster has been scanned, signed, and attested —
and the pipeline hard-blocks on critical findings before deployment.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                     GitHub Actions Pipeline                          │
│                                                                      │
│  git push to main                                                    │
│       │                                                              │
│       ▼                                                              │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌────────────────┐  │
│  │  Gate 1  │   │  Gate 2  │   │  Gate 3  │   │     Deploy     │  │
│  │ Gitleaks │──▶│ Semgrep  │──▶│  Build   │──▶│  GitOps Update │  │
│  │ (secrets)│   │  (SAST)  │   │  +Trivy  │   │  (manifest)    │  │
│  │HARD BLOCK│   │HARD BLOCK│   │  +Cosign │   │                │  │
│  └──────────┘   └──────────┘   │  +Attest │   └───────┬────────┘  │
│                                 │HARD BLOCK│           │            │
│                                 └──────────┘           │            │
└──────────────────────────────────────────────────────  │  ─────────┘
                                                         │ git push
                                                         ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     ArgoCD (GitOps)                                  │
│                                                                      │
│  Watches git repo ──▶ Detects change ──▶ Syncs to cluster           │
│                                                                      │
│  Manual kubectl edit ──▶ Detected as OutOfSync ──▶ Auto-reverted    │
│                          (Drift Detection + Self-Heal)               │
└─────────────────────────────────────────────────────────────────────┘
```

## Step-by-Step Execution

### PHASE 1 — Setup GitHub (5 mins)

```
1. Go to your repo → Settings → General
   → Change to PUBLIC (required for GHCR free tier)

2. Your Profile → Settings → Packages
   → Enable "Improved container support"

3. Repo → Settings → Actions → General
   → "Allow all actions and reusable workflows" → Save
   → "Workflow permissions" → "Read and write permissions" → Save

4. Repo → Settings → Code security and analysis
   → Enable "Code scanning" → Save
```

### PHASE 2 — Push Pipeline (2 mins)

```powershell
# Copy task2 folder to your repo root
# Then push to GitHub

git add .github\workflows\secure-pipeline.yaml
git add .gitleaks.toml
git add .trivyignore
git commit -m "feat: add secure CI/CD pipeline with scan sign attest"
git push origin main
```

### PHASE 3 — Watch Pipeline (5-10 mins)

```
Open: https://github.com/YOUR_USERNAME/dodo-payments-assessment/actions

Jobs run in this order:
1. Gate 1 — Secrets Scan      (~30 seconds)
2. Gate 2 — SAST              (~2 minutes)
3. Gate 3 — Build Scan Sign   (~5 minutes)
4. Deploy — GitOps Update     (~1 minute)

All should show ✅ green checkmarks
```

### PHASE 4 — Install ArgoCD (5 mins)

```powershell
# Run the install script
.\task2\argocd\install-argocd.ps1

# In a SEPARATE terminal — keep running
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Apply ArgoCD app
kubectl apply -f task2\argocd\application.yaml

# Check it synced
kubectl get application -n argocd
# Expected: SYNC STATUS=Synced  HEALTH=Healthy
```

### PHASE 5 — Test Drift Detection (5 mins)

```powershell
# Run the automated test
.\task2\argocd\test-drift-detection.ps1

# OR manually:
kubectl set image deployment/ledger-api ledger-api=nginx:latest -n ledger
# Watch ArgoCD UI → OutOfSync → Syncing → Synced (auto reverts in ~3 mins)
kubectl get deployment ledger-api -n ledger -w
```

### PHASE 6 — Verify Image Signature (2 mins)

```powershell
# Install cosign from: https://github.com/sigstore/cosign/releases/latest
# cosign-windows-amd64.exe → rename to cosign.exe → add to PATH

# Run verification
.\task2\cosign\verify-image.ps1 -Username YOUR_USERNAME

# OR manually:
cosign verify `
  --certificate-identity-regexp="https://github.com/YOUR_USERNAME" `
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" `
  ghcr.io/YOUR_USERNAME/ledger-api:latest
```

---

## Gate Fail Policy

| Gate | Tool | Fail Mode | Condition |
|------|------|-----------|-----------|
| Secrets scan | Gitleaks | **HARD BLOCK** | Any secret detected in code |
| SAST | Semgrep | **HARD BLOCK** | CRITICAL severity finding |
| Dependency CVE | Trivy (fs) | **HARD BLOCK** | CRITICAL CVE with available fix |
| Image CVE | Trivy (image) | **HARD BLOCK** | CRITICAL CVE with available fix |
| Image signing | Cosign | **HARD BLOCK** | Pipeline fails if signing fails |
| SLSA attestation | Cosign attest | **WARN ONLY** | Logged, does not block deploy |

### Handling CVEs with No Fix Available

1. Run `trivy image --ignore-unfixed=false <image>` to confirm no fix exists
2. Open a GitHub issue to track it
3. Add to `.trivyignore` with format:
   ```
   CVE-2023-XXXXX  # Justification | Issue #N | Expires YYYY-MM-DD
   ```
4. Expiry is max 90 days — entry must be reviewed before expiry

---

## Security Controls Implemented

| Control | Tool | PCI DSS |
|---------|------|---------|
| Secret scanning | Gitleaks (custom rules) | Req 3.2 |
| Static analysis | Semgrep (OWASP Top 10) | Req 6.3 |
| Dependency CVEs | Trivy filesystem scan | Req 6.3 |
| Image CVEs | Trivy image scan | Req 6.3 |
| Supply chain integrity | Cosign keyless signing | Req 6.4 |
| Provenance | SLSA attestation | Req 6.4 |
| Audit trail | SARIF in Security tab | Req 10.2 |
| GitOps | ArgoCD with self-heal | Req 6.4 |
| Drift prevention | ArgoCD selfHeal: true | Req 11.5 |

---

## Design Decisions

**Why keyless Cosign over key-based signing?**
Keyless signing uses GitHub Actions OIDC tokens — no private key to manage, rotate,
or accidentally expose. The signature is cryptographically tied to the specific GitHub
workflow identity (`github.repository` + `github_sha`), making it provable that the
image was built by *this* pipeline, not a developer's local machine.

**Why ArgoCD over manual `kubectl apply`?**
ArgoCD makes git the single source of truth. `selfHeal: true` means any manual
`kubectl edit` is automatically detected and reverted. This prevents configuration
drift — a common PCI DSS audit finding (Req 11.5: detect unauthorized changes).

**Why GHCR over Docker Hub?**
GHCR is free, integrates with GitHub Actions via OIDC (no additional secrets needed),
supports image signing natively, and has no pull rate limits that would break CI.

**Why hard-block on CRITICAL but warn on SLSA attestation?**
CRITICAL CVEs represent known exploitable vulnerabilities that must be fixed before
shipping. Missing SLSA attestation is a supply-chain hygiene gap but not an immediate
exploit risk — warning allows gradual adoption while CRITICAL CVEs must be zero.

---

## What to Screenshot

| # | What | Where to Find It |
|---|------|-----------------|
| 1 | All 4 pipeline jobs GREEN | GitHub → Actions tab |
| 2 | SARIF findings | GitHub → Security → Code scanning |
| 3 | Image in GHCR with sha- tag | GitHub → Packages |
| 4 | ArgoCD UI — Synced + Healthy | https://localhost:8080 |
| 5 | Drift detected — OutOfSync | ArgoCD UI or `kubectl get application` |
| 6 | Self-healed — back to Synced | ArgoCD UI timeline |
| 7 | `cosign verify` output | Terminal output |

---

## What I Would Do With More Time

- Add **Sigstore policy-controller** to enforce signature verification at the
  Kubernetes admission level (cluster won't run unsigned images)
- Add **DAST scanning** (OWASP ZAP) against a staging environment
- Implement **canary releases** via ArgoCD Rollouts with automated analysis
- Add **branch protection rules** requiring all pipeline gates to pass before merge
- Integrate **Dependabot** for automatic dependency update PRs
- Add **container structure tests** to validate image contents post-build
