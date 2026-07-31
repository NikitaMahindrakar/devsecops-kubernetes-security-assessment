# ArgoCD Drift Detection Test
# Verifies that ArgoCD detects and automatically fixes manual changes.

Write-Host "================================================" -ForegroundColor Cyan
Write-Host " ArgoCD Drift Detection Test" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1 - Show current image
Write-Host "[1/5] Checking current deployment image..." -ForegroundColor Yellow

$currentImage = kubectl get deployment ledger-api -n ledger `
    -o jsonpath="{.spec.template.spec.containers[0].image}"

Write-Host "Current Image : $currentImage" -ForegroundColor White

# Step 2 - Introduce Drift
Write-Host ""
Write-Host "[2/5] Changing image to nginx:latest..." -ForegroundColor Yellow

kubectl set image deployment/ledger-api `
    ledger-api=nginx:latest `
    -n ledger

Start-Sleep -Seconds 5

$driftImage = kubectl get deployment ledger-api -n ledger `
    -o jsonpath="{.spec.template.spec.containers[0].image}"

Write-Host "Image after change : $driftImage" -ForegroundColor Red

# Step 3 - Check ArgoCD Status
Write-Host ""
Write-Host "[3/5] Waiting for ArgoCD to detect drift..." -ForegroundColor Yellow

Start-Sleep -Seconds 15

$syncStatus = kubectl get applications.argoproj.io ledger-api `
    -n argocd `
    -o jsonpath="{.status.sync.status}"

$healthStatus = kubectl get applications.argoproj.io ledger-api `
    -n argocd `
    -o jsonpath="{.status.health.status}"

Write-Host "Sync Status   : $syncStatus"
Write-Host "Health Status : $healthStatus"

# Step 4 - Wait for Self Heal
Write-Host ""
Write-Host "[4/5] Waiting for self-heal..." -ForegroundColor Yellow

$timeout = 180
$elapsed = 0
$interval = 10
$healed = $false

while ($elapsed -lt $timeout) {

    $image = kubectl get deployment ledger-api -n ledger `
        -o jsonpath="{.spec.template.spec.containers[0].image}"

    $sync = kubectl get applications.argoproj.io ledger-api `
        -n argocd `
        -o jsonpath="{.status.sync.status}"

    Write-Host "[$elapsed sec] Image=$image | Sync=$sync"

    if (($image -ne "nginx:latest") -and ($sync -eq "Synced")) {
        $healed = $true
        break
    }

    Start-Sleep -Seconds $interval
    $elapsed += $interval
}

# Step 5 - Final Result
Write-Host ""
Write-Host "[5/5] Final Status" -ForegroundColor Yellow

$finalImage = kubectl get deployment ledger-api -n ledger `
    -o jsonpath="{.spec.template.spec.containers[0].image}"

$finalSync = kubectl get applications.argoproj.io ledger-api `
    -n argocd `
    -o jsonpath="{.status.sync.status}"

Write-Host ""
Write-Host "Final Image : $finalImage"
Write-Host "Sync Status : $finalSync"

Write-Host ""

if ($healed) {

    Write-Host "==============================================" -ForegroundColor Green
    Write-Host " Drift Detection Test PASSED" -ForegroundColor Green
    Write-Host " ArgoCD detected the manual change." -ForegroundColor Green
    Write-Host " ArgoCD automatically restored Git state." -ForegroundColor Green
    Write-Host " Git is the single source of truth." -ForegroundColor Green
    Write-Host "==============================================" -ForegroundColor Green

}
else {

    Write-Host "==============================================" -ForegroundColor Red
    Write-Host " Drift Detection Test FAILED or TIMED OUT" -ForegroundColor Red
    Write-Host " Check ArgoCD UI: https://localhost:8080" -ForegroundColor Yellow
    Write-Host " Verify Auto Sync and Self Heal are enabled." -ForegroundColor Yellow
    Write-Host "==============================================" -ForegroundColor Red

}