# Task 4 – Reconnaissance & Penetration Testing

## Objective

The objective of this task is to demonstrate both defensive and offensive security skills by:

- Performing passive reconnaissance (OSINT) against the public domain **dodopayments.tech**.
- Conducting an authorized penetration test against the designated vulnerable application running locally.
- Producing professional security findings with remediation recommendations.

> **Important**
>
> Passive reconnaissance was performed only against publicly available information.
>
> Active penetration testing was performed **only** against the authorized local vulnerable application as specified in the assessment.

---

# Tools Used

| Tool | Purpose |
|-------|----------|
| Subfinder | Subdomain enumeration |
| Assetfinder | Additional subdomain discovery |
| crt.sh | Certificate Transparency logs |
| httpx | Live host discovery & technology fingerprinting |
| WhatWeb *(optional)* | Web technology detection |
| testssl.sh *(optional)* | TLS configuration review |
| Burp Suite Community | Manual web testing |
| Nuclei | Automated vulnerability scanning |
| OWASP ZAP *(optional)* | Security testing |
| FFUF *(optional)* | Content discovery |
| sqlmap *(optional)* | SQL Injection testing |

---

# Environment

- Windows 10
- Docker Desktop
- Go
- PowerShell
- Local vulnerable application
- Burp Suite Community

---

# Part A – Passive Reconnaissance

## Install Required Tools

Install Go.

```powershell
winget install GoLang.Go
```

Restart PowerShell.

Install reconnaissance tools.

```powershell
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest

go install github.com/tomnomnom/assetfinder@latest

go install github.com/projectdiscovery/httpx/cmd/httpx@latest
```

Add Go binaries to PATH.

```powershell
$env:PATH += ";$env:USERPROFILE\go\bin"
```

Verify installation.

```powershell
subfinder -version

assetfinder

httpx -version
```

---

# Create Output Directory

```powershell
mkdir task4\recon
```

---

# 1. Subdomain Enumeration

Using Subfinder.

```powershell
subfinder -d dodopayments.tech -o task4\recon\subdomains.txt
```
<img width="1366" height="768" alt="Screenshot 2026-07-30 181050" src="https://github.com/user-attachments/assets/02008dc1-7452-4f89-9875-ecaf4cab6a51" />

Using Assetfinder.

```powershell
assetfinder --subs-only dodopayments.tech >> task4\recon\subdomains.txt
```
<img width="1366" height="768" alt="Screenshot 2026-07-30 181140" src="https://github.com/user-attachments/assets/bf0a1baf-a8cd-41c8-9ec8-6ca4fd695fa7" />


Remove duplicate entries.

```powershell
Get-Content task4\recon\subdomains.txt |
Sort-Object -Unique |
Set-Content task4\recon\subdomains.txt
```

---

# 2. Certificate Transparency Logs

Open:

```
https://crt.sh/?q=dodopayments.tech
```

Export or save results.

Store as:

```
task4/recon/crt-sh-results.txt
```

---

# 3. Live Host Discovery

```powershell
httpx `
-l task4\recon\subdomains.txt `
-title `
-tech-detect `
-status-code `
-o task4\recon\live-hosts.txt
```
<img width="1366" height="768" alt="Screenshot 2026-07-30 181602" src="https://github.com/user-attachments/assets/36ed10dd-c766-4fd1-9b4c-77fb8841b7e9" />


Example Output

```
https://api.example.com [200]
Cloudflare
nginx

https://dashboard.example.com [302]
NextJS
```

---

# 4. TLS Review (Optional)

Using testssl.sh.

```powershell
testssl.sh https://example.domain
```

Review:

- TLS versions
- Cipher suites
- Certificate validity
- Security headers

---

# Risk Observations

Examples of information that may be valuable to an attacker:

- Public administration portals
- Development environments
- Staging applications
- Exposed APIs
- Outdated TLS versions
- Public cloud services
- Information leakage through HTTP headers

No exploitation or active testing was performed.

---

# Part B – Authorized Penetration Test

The penetration test was performed **only** against the designated vulnerable application running locally.

---

# Start the Application

```powershell
cd ledger-api-assignment

docker-compose up -d
```

Verify.

```powershell
docker ps
```
<img width="1366" height="768" alt="Screenshot 2026-07-30 195025" src="https://github.com/user-attachments/assets/78660df3-38b6-4639-851a-893d975289ca" />

Open application.

```
http://localhost:8080
```

---

# Install Nuclei

```powershell
go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
```

Update templates.

```powershell
nuclei -update-templates
```

---

# Run Nuclei

```powershell
mkdir task4\pentest

nuclei `
-u http://localhost:8080 `
-o task4\pentest\nuclei-results.txt
```
<img width="1366" height="768" alt="Screenshot 2026-07-30 194921" src="https://github.com/user-attachments/assets/8ec84ddd-52cc-4458-8cf1-a36566d49d04" />

---

# Manual Testing

Burp Suite Community was used for manual verification.

The following OWASP Top 10 categories were tested:

- Broken Access Control
- IDOR
- SQL Injection
- Cross Site Scripting
- SSRF
- Authentication Issues
- Session Management
- Security Misconfiguration
- Secrets Exposure

---

# Penetration Testing Methodology

1. Reconnaissance
2. Endpoint Discovery
3. Manual Testing
4. Automated Scanning
5. Validation
6. Documentation
7. Remediation Recommendations

---

# Reporting Format

Each finding includes:

- Title
- Description
- Severity
- CVSS v3.1 Score
- Affected Endpoint
- Steps to Reproduce
- Evidence
- Business Impact
- Remediation

Example

## Finding

**Title**

Sensitive information exposed

**Severity**

Medium

**CVSS**

5.3

**Endpoint**

```
GET /api/config
```

**Impact**

Application configuration information is publicly accessible.

**Remediation**

Restrict access to authenticated users.

---

# Evidence

Include screenshots of:

- Subfinder results
- Assetfinder results
- crt.sh
- httpx output
- Burp Suite
- Nuclei scan
- Docker application
- Vulnerability findings

---

# Mapping Findings to Defensive Controls

| Offensive Finding | Defensive Control |
|-------------------|-------------------|
| Secrets Exposure | Kubernetes Secrets (Task 1) |
| Weak Container Configuration | Kyverno Policy (Task 1) |
| Unsigned Image | Cosign Verification (Task 2) |
| Vulnerable Dependencies | Trivy Scan (Task 2) |
| Unauthorized Service Access | Istio AuthorizationPolicy (Task 3) |
| Unencrypted Traffic | Istio mTLS (Task 3) |
| Lateral Movement | Kubernetes NetworkPolicy (Task 3) |

---

# Outcome

This task demonstrates a complete security assessment workflow:

- Passive OSINT reconnaissance
- Attack surface enumeration
- Technology fingerprinting
- Authorized penetration testing
- Professional vulnerability reporting
- Security remediation guidance

All testing remained within the scope defined by the assessment and followed the provided rules of engagement.
