# Security Policy

## Supported Versions

This repository contains **Terraform infrastructure modules** and a **GitHub Pages portfolio site**.
The code is provided as a public reference. Production deployments should always use the latest
version of the relevant modules.

| Component | Supported |
|---|---|
| `modules/azure_vnet` (latest) | ✅ |
| `examples/` (latest) | ✅ |
| Older branches / forks | ❌ |

---

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

If you discover a security issue in this repository (e.g. a hardcoded secret, an insecure
Terraform pattern, or a misconfiguration that could compromise infrastructure), please report
it privately using one of the methods below.

### Option 1 — GitHub Private Vulnerability Reporting (preferred)

1. Go to the **Security** tab of this repository.
2. Click **"Report a vulnerability"**.
3. Fill in the details and submit.

GitHub will notify the maintainer privately and no public disclosure occurs until a fix is ready.

### Option 2 — Email

Send details to the maintainer's email listed in the README.  
Please include:
- A description of the vulnerability
- Steps to reproduce
- The potential impact
- Any suggested remediation

---

## What counts as a vulnerability?

- Hardcoded credentials, tokens, or secrets in any committed file
- Insecure default Terraform configurations (open security groups, public storage, etc.)
- Workflow (GitHub Actions) privilege escalation or secret exposure risks
- Supply-chain risks (unpinned third-party actions)
- Cross-site scripting (XSS) or injection risks in the GitHub Pages site

---

## What to expect

- **Acknowledgement** within 48 hours
- **Status update** within 7 days
- **Fix or mitigation** typically within 14 days for confirmed issues

Thank you for helping keep this project secure.
