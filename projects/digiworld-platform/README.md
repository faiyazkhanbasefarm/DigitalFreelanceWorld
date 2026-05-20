# ☁️ DigiWorld Platform

![Docker](https://img.shields.io/badge/Docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)
![nginx](https://img.shields.io/badge/nginx-%23009639.svg?style=flat&logo=nginx&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-6DA55F?style=flat&logo=node.js&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-%2307405e.svg?style=flat&logo=sqlite&logoColor=white)
![Stripe](https://img.shields.io/badge/Stripe-%23646EDE.svg?style=flat&logo=stripe&logoColor=white)
![JWT](https://img.shields.io/badge/JWT-black?style=flat&logo=jsonwebtokens&logoColor=white)

A production-grade, Docker-based freelance portfolio platform with SSO authentication, TOTP 2FA, contact form → email pipeline, and Stripe payment integration.

---

## Architecture

```
Internet → nginx (WAF + Rate Limit + SSO)
               ├── /              → Guest Landing Page
               ├── /dashboard     → Protected Portfolio Dashboard
               ├── /pay           → Stripe Payment Page (public)
               ├── /api/submit    → Contact Form → SQLite + Email
               ├── /api/payment/  → Stripe Payment API
               └── /api/admin/    → Admin Panel (JWT protected)
                        │
            ┌───────────┴───────────┐
            ▼                       ▼
     Auth Service              Data Service
   (JWT + TOTP 2FA)         (SQLite + Nodemailer
    Port 3000                  + Stripe API)
                               Port 4000
```

---

## Security Features

- **WAF Rules** — blocks SQLi, XSS, LFI, path traversal, and prompt injection at the nginx layer
- **JWT authentication** — tokens in `httpOnly`, `SameSite=Strict` cookies; never exposed to JavaScript
- **bcrypt** — password hashing at rounds=12
- **TOTP 2FA** — RFC 6238 time-based OTP required at every login
- **Rate limiting** — nginx `limit_req_zone` on login and API endpoints
- **Read-only containers** — `read_only: true`; only declared tmpfs volumes are writable
- **Dropped Linux capabilities** — `cap_drop: [ALL]` + `no-new-privileges: true`

---

## Tech Stack

| Layer | Technology |
|---|---|
| Reverse Proxy / WAF | nginx |
| Auth Service | Node.js · Express · jsonwebtoken · bcryptjs · speakeasy |
| Data Service | Node.js · Express · better-sqlite3 · Nodemailer · Stripe SDK |
| Database | SQLite (file-based, Docker volume) |
| Payments | Stripe Payment Intents API |
| Email | SMTP via Nodemailer (provider-agnostic) |
| Orchestration | Docker Compose |
| Frontend | Vanilla HTML/CSS/JS |

---

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/faiyazkhanbasefarm/DigitalFreelanceWorld.git
cd DigitalFreelanceWorld/myweb

# 2. Configure environment variables
cp .env.example .env
# Edit .env — fill in all values (see table below)

# 3. Start all services
docker compose up -d

# 4. Open in browser
open http://localhost
```

---

## Environment Variables

All secrets are loaded from `.env` via `env_file:` in `docker-compose.yml`.  
**`.env` is in `.gitignore` and must never be committed.**

| Variable | Description |
|---|---|
| `NODE_ENV` | Runtime environment (`production`) |
| `PORT` | Auth service port (default `3000`) |
| `DATA_PORT` | Data service port (default `4000`) |
| `DB_PATH` | Path to SQLite database inside container |
| `JWT_SECRET` | Random secret for signing JWTs (min 32 chars) |
| `ADMIN_USER` | Admin username |
| `ADMIN_PASS_HASH` | bcrypt hash of admin password (rounds=12) |
| `TOTP_SECRET` | Base32 TOTP secret for 2FA |
| `GMAIL_USER` | Sender email address |
| `GMAIL_APP_PASSWORD` | SMTP app password (not account password) |
| `STRIPE_PUBLISHABLE_KEY` | Stripe publishable key (frontend) |
| `STRIPE_SECRET_KEY` | Stripe secret key (backend only) |

See `.env.example` for the full template with generation instructions.

> ⚠️ **Never commit `.env` to version control.**
