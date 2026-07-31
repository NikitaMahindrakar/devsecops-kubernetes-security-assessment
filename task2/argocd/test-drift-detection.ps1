# ── ArgoCD Drift Detection Test ───────────────────────────────────────────────
# Proves ArgoCD detects + self-heals manual kubectl edits
# Run AFTER ArgoCD is installed and application.yaml is applied

Write-Host "================================================" -ForegroundColor Cyan
Write-Host " ArgoCD Drift Detection Test" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# ── Step 1: Show current image ─────────────────────────────────────────────
Write-Host "[1/5] Current image in deployment:" -ForegroundColor Yellow
$currentImage = kubectl get deployment ledger-api -n ledger `
    -o jsonpath='{.spec.template.spec.containers[0].image}' 2>&1
Write-Host "  Current: $currentImage" -ForegroundColor White

# ── Step 2: Introduce drift ────────────────────────────────────────────────
Write-Host ""
Write-Host "[2/5] Introducing drift — changing image to nginx:latest..." -ForegroundColor Yellow
kubectl set image deployment/ledger-api `
    ledger-api=nginx:latest `
    -n ledger

Start-Sleep -Seconds 3

$driftedImage = kubectl get deployment ledger-api -n ledger `
    -o jsonpath='{.spec.template.spec.containers[0].image}' 2>&1
Write-Host "  Drifted to: $driftedImage" -ForegroundColor Red
Write-Host "  [!] DRIFT INTRODUCED — image changed from git state" -ForegroundColor Red

# ── Step 3: Show ArgoCD detected drift ────────────────────────────────────
Write-Host ""
Write-Host "[3/5] ArgoCD status (should show OutOfSync soon):" -ForegroundColor Yellow
Write-Host "  Checking sync status..." -ForegroundColor White
Start-Sleep -Seconds 10

$syncStatus = kubectl get application ledger-api -n argocd `
    -o jsonpath='{.status.sync.status}' 2>&1
$healthStatus = kubectl get application ledger-api -n argocd `
    -o jsonpath='{.status.health.status}' 2>&1
Write-Host "  Sync Status: $syncStatus" -ForegroundColor $(
    if ($syncStatus -eq "OutOfSync") { "Red" } else { "Yellow" }
)
Write-Host "  Health Status: $healthStatus" -ForegroundColor White

# ── Step 4: Watch self-heal ────────────────────────────────────────────────
Write-Host ""
Write-Host "[4/5] Watching ArgoCD self-heal (up to 3 minutes)..." -ForegroundColor Yellow
Write-Host "  ALSO OPEN: https://localhost:8080 to see ArgoCD UI" -ForegroundColor Cyan
Write-Host ""

$maxWait  = 180  # 3 minutes
$interval = 10   # check every 10 seconds
$elapsed  = 0
$healed   = $false

while ($elapsed -lt $maxWait) {
    $image = kubectl get deployment ledger-api -n ledger `
        -o jsonpath='{.spec.template.spec.containers[0].image}' 2>&1
    $sync = kubectl get application ledger-api -n argocd `
        -o jsonpath='{.status.sync.status}' 2>&1

    Write-Host "  [${elapsed}s] Image: $image | Sync: $sync" -ForegroundColor White

    if ($image -notmatch "nginx:latest" -and $sync -eq "Synced") {
        Write-Host ""
        Write-Host "  [+] SELF-HEALED! Image reverted back to: $image" -ForegroundColor Green
        $healed = $true
        break
    }

    Start-Sleep -Seconds $interval
    $elapsed += $interval
}

# ── Step 5: Final result ───────────────────────────────────────────────────
Write-Host ""
Write-Host "[5/5] Final state:" -ForegroundColor Yellow
$finalImage = kubectl get deployment ledger-api -n ledger `
    -o jsonpath='{.spec.template.spec.containers[0].image}' 2>&1
$finalSync = kubectl get application ledger-api -n argocd `
    -o jsonpath='{.status.sync.status}' 2>&1

Write-Host "  Final Image:  $finalImage" -ForegroundColor White
Write-Host "  Sync Status:  $finalSync" -ForegroundColor White

Write-Host ""
Write-Host "================================================" -ForegroundColor $(
    if ($healed) { "Green" } else { "Red" }
)
if ($healed) {
    Write-Host " DRIFT DETECTION: PASSED" -ForegroundColor Green
    Write-Host " ArgoCD detected and reverted the manual change" -ForegroundColor Green
    Write-Host " Git is the single source of truth — proven!" -ForegroundColor Green
} else {
    Write-Host " DRIFT DETECTION: TIMEOUT" -ForegroundColor Red
    Write-Host " ArgoCD may need more time or check ArgoCD UI" -ForegroundColor Yellow
    Write-Host " Open: https://localhost:8080 and check sync status" -ForegroundColor Yellow
}
Write-Host "================================================" -ForegroundColor $(
    if ($healed) { "Green" } else { "Red" }
)
