# ArgoCD Installation Script for Windows + Minikube

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Installing ArgoCD on Minikube" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1 - Create namespace
Write-Host "[1/6] Creating argocd namespace..." -ForegroundColor Yellow
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Step 2 - Install ArgoCD
Write-Host ""
Write-Host "[2/6] Installing ArgoCD (this may take a few minutes)..." -ForegroundColor Yellow

kubectl apply -n argocd -f "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"

# Step 3 - Wait for ArgoCD Server
Write-Host ""
Write-Host "[3/6] Waiting for ArgoCD server to become ready..." -ForegroundColor Yellow

kubectl wait `
    --for=condition=ready pod `
    -l app.kubernetes.io/name=argocd-server `
    -n argocd `
    --timeout=300s

# Step 4 - Get Admin Password
Write-Host ""
Write-Host "[4/6] Retrieving admin password..." -ForegroundColor Yellow

$encodedPass = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}"

$password = [System.Text.Encoding]::UTF8.GetString(
    [System.Convert]::FromBase64String($encodedPass)
)

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "ArgoCD Admin Password: $password" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green

# Step 5 - Show Pod Status
Write-Host ""
Write-Host "[5/6] ArgoCD Pods" -ForegroundColor Yellow

kubectl get pods -n argocd

# Step 6 - Next Steps
Write-Host ""
Write-Host "[6/6] Next Steps" -ForegroundColor Yellow
Write-Host ""

Write-Host "1. Run the following command in another PowerShell window:" -ForegroundColor Cyan
Write-Host "kubectl port-forward svc/argocd-server -n argocd 8080:443" -ForegroundColor White

Write-Host ""
Write-Host "2. Open your browser:" -ForegroundColor Cyan
Write-Host "https://localhost:8080" -ForegroundColor White

Write-Host ""
Write-Host "3. Login using:" -ForegroundColor Cyan
Write-Host "Username : admin" -ForegroundColor White
Write-Host "Password : $password" -ForegroundColor White

Write-Host ""
Write-Host "4. Deploy your ArgoCD application:" -ForegroundColor Cyan
Write-Host "kubectl apply -f task2\argocd\application.yaml" -ForegroundColor White

Write-Host ""
Write-Host "5. Check application status:" -ForegroundColor Cyan
Write-Host "kubectl get applications -n argocd" -ForegroundColor White

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "ArgoCD installation completed successfully!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green