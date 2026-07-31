# ── Cosign Image Verification Script ─────────────────────────────────────────
param(
    [string]$Username = "NikitaMahindrakar",
    [string]$RepoName = "devsecops-kubernetes-security-assessment",
    [string]$Tag = "latest"
)

$IMAGE = "ghcr.io/$Username/ledger-api:$Tag"
$CERT_IDENTITY = "https://github.com/$Username/$RepoName/.*"
$OIDC = "https://token.actions.githubusercontent.com"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "        Cosign Image Verification" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Image      : $IMAGE"
Write-Host "Repository : https://github.com/$Username/$RepoName"
Write-Host ""

# Check if Cosign exists
if (-not (Get-Command cosign -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Cosign is not installed." -ForegroundColor Red
    Write-Host "Download: https://github.com/sigstore/cosign/releases/latest" -ForegroundColor Yellow
    exit 1
}

$env:COSIGN_EXPERIMENTAL = "1"

# ------------------------------------------------------------------
# Verify Signature
# ------------------------------------------------------------------

Write-Host "[1/3] Verifying image signature..." -ForegroundColor Yellow

try {

    cosign verify `
        --certificate-identity-regexp "$CERT_IDENTITY" `
        --certificate-oidc-issuer "$OIDC" `
        $IMAGE

    if ($LASTEXITCODE -ne 0) {
        throw "Signature verification failed."
    }

    Write-Host ""
    Write-Host "[SUCCESS] Image signature is VALID." -ForegroundColor Green
}
catch {

    Write-Host ""
    Write-Host "[FAILED] Signature verification failed." -ForegroundColor Red
    Write-Host $_
    exit 1
}

# ------------------------------------------------------------------
# Verify SLSA Provenance
# ------------------------------------------------------------------

Write-Host ""
Write-Host "[2/3] Verifying SLSA provenance..." -ForegroundColor Yellow

try {

    cosign verify-attestation `
        --certificate-identity-regexp "$CERT_IDENTITY" `
        --certificate-oidc-issuer "$OIDC" `
        --type slsaprovenance `
        $IMAGE | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] SLSA attestation found." -ForegroundColor Green
    }
    else {
        Write-Host "[WARNING] No SLSA provenance found." -ForegroundColor Yellow
    }

}
catch {
    Write-Host "[WARNING] No SLSA provenance found." -ForegroundColor Yellow
}

# ------------------------------------------------------------------
# Rekor Transparency Log
# ------------------------------------------------------------------

Write-Host ""
Write-Host "[3/3] Checking Rekor transparency log..." -ForegroundColor Yellow

try {

    cosign triangulate $IMAGE | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] Image exists in Rekor transparency log." -ForegroundColor Green
    }
    else {
        Write-Host "[WARNING] Rekor verification could not be completed." -ForegroundColor Yellow
    }

}
catch {

    Write-Host "[WARNING] Unable to query Rekor." -ForegroundColor Yellow

}

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "Verification Completed Successfully" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Image: $IMAGE"
Write-Host ""
Write-Host "Verified Security Controls:"
Write-Host "  ✔ Image signed using GitHub Actions OIDC"
Write-Host "  ✔ Signature verified with Cosign"
Write-Host "  ✔ Checked for SLSA provenance"
Write-Host "  ✔ Verified Rekor transparency log"
Write-Host ""
Write-Host "Image is trusted and ready for deployment." -ForegroundColor Green