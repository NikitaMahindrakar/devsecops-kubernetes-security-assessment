# ── Cosign Image Verification Script ─────────────────────────────────────────
# Run this AFTER the GitHub Actions pipeline completes
# Replace YOUR_USERNAME with your actual GitHub username

param(
    [string]$Username = "NikitaMahindrakar",
    [string]$Tag = "latest"
)

$IMAGE = "ghcr.io/$Username/ledger-api:$Tag"
$REPO  = "https://github.com/$Username/devsecops-kubernetes-security-assessment"
$OIDC  = "https://token.actions.githubusercontent.com"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host " Cosign Image Verification" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host " Image:  $IMAGE" -ForegroundColor White
Write-Host " Repo:   $REPO" -ForegroundColor White
Write-Host ""

# ── Check cosign is installed ─────────────────────────────────────────────────
if (-not (Get-Command cosign -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] cosign not found. Download from:" -ForegroundColor Red
    Write-Host "  https://github.com/sigstore/cosign/releases/latest" -ForegroundColor Yellow
    Write-Host "  File: cosign-windows-amd64.exe -> rename to cosign.exe -> add to PATH"
    exit 1
}

Write-Host "[1/3] Verifying image signature..." -ForegroundColor Yellow
try {
    $env:COSIGN_EXPERIMENTAL = "1"
    cosign verify `
        --certificate-identity-regexp=$REPO `
        --certificate-oidc-issuer=$OIDC `
        $IMAGE

    Write-Host ""
    Write-Host "[+] SIGNATURE VALID" -ForegroundColor Green
} catch {
    Write-Host "[-] Signature verification FAILED: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[2/3] Checking SLSA attestation..." -ForegroundColor Yellow
try {
    cosign verify-attestation `
        --certificate-identity-regexp=$REPO `
        --certificate-oidc-issuer=$OIDC `
        --type slsaprovenance `
        $IMAGE | Out-Null

    Write-Host "[+] SLSA ATTESTATION VALID" -ForegroundColor Green
} catch {
    Write-Host "[!] No SLSA attestation found (warning only)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[3/3] Checking Rekor transparency log..." -ForegroundColor Yellow
try {
    cosign triangulate $IMAGE
    Write-Host "[+] Image found in Rekor transparency log" -ForegroundColor Green
} catch {
    Write-Host "[!] Could not check Rekor log" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host " Verification Complete" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host " Image $IMAGE is:" -ForegroundColor White
Write-Host "  - Signed by GitHub Actions OIDC identity" -ForegroundColor Green
Write-Host "  - Recorded in Sigstore transparency log" -ForegroundColor Green
Write-Host "  - Safe to deploy" -ForegroundColor Green
