# ── ArgoCD Installation Script for Windows + Minikube ────────────────────────
# Run this after Task 1 is complete and Minikube is running

Write-Host "================================================" -ForegroundColor Cyan
Write-Host " Installing ArgoCD on Minikube" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# ── Step 1: Create ArgoCD namespace ──────────────────────────────────────────
Write-Host "[1/6] Creating argocd namespace..." -ForegroundColor Yellow
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# ── Step 2: Install ArgoCD ────────────────────────────────────────────────────
Write-Host ""
Write-Host "[2/6] Installing ArgoCD (this takes 3-4 minutes)..." -ForegroundColor Yellow
kubectl apply -n argocd -f `
    https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# ── Step 3: Wait for ArgoCD server ───────────────────────────────────────────
Write-Host ""
Write-Host "[3/6] Waiting for ArgoCD server to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod `
    -l app.kubernetes.io/name=argocd-server `
    -n argocd `
    --timeout=300s

# ── Step 4: Get admin password ────────────────────────────────────────────────
Write-Host ""
Write-Host "[4/6] Getting admin password..." -ForegroundColor Yellow
$encodedPass = kubectl -n argocd get secret argocd-initial-admin-secret `
    -o jsonpath="{.data.password}" 2>&1
$password = [System.Text.Encoding]::UTF8.GetString(
    [System.Convert]::FromBase64String($encodedPass)
)
Write-Host ""
Write-Host "  ============================================" -ForegroundColor Green
Write-Host "  ArgoCD Admin Password: $password" -ForegroundColor Green
Write-Host "  ============================================" -ForegroundColor Green
Write-Host "  SAVE THIS PASSWORD — you need it to log in!" -ForegroundColor Yellow

# ── Step 5: Verify all pods running ──────────────────────────────────────────
Write-Host ""
Write-Host "[5/6] ArgoCD pods status:" -ForegroundColor Yellow
kubectl get pods -n argocd

# ── Step 6: Instructions ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "[6/6] Next steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  A) Port-forward ArgoCD UI (run in a SEPARATE terminal):" -ForegroundColor Cyan
Write-Host "     kubectl port-forward svc/argocd-server -n argocd 8080:443" -ForegroundColor White
Write-Host ""
Write-Host "  B) Open browser: https://localhost:8080" -ForegroundColor Cyan
Write-Host "     Username: admin" -ForegroundColor White
Write-Host "     Password: $password" -ForegroundColor White
Write-Host ""
Write-Host "  C) Apply ArgoCD application (edit YOUR_USERNAME first):" -ForegroundColor Cyan
Write-Host "     notepad task2\argocd\application.yaml" -ForegroundColor White
Write-Host "     kubectl apply -f task2\argocd\application.yaml" -ForegroundColor White
Write-Host ""
Write-Host "  D) Check sync status:" -ForegroundColor Cyan
Write-Host "     kubectl get application -n argocd" -ForegroundColor White
Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host " ArgoCD installation complete!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
