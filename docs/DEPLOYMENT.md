# 🚀 VeloRide - Cloud Deployment & Infrastructure Guide

This guide covers all deployment strategies for **VeloRide (Smart EV Rental & Subscription Platform)**, from 1-command Vercel production hosting to automated Infrastructure-as-Code (IaC) and containerization.

---

## 1. 🌐 Production Deployment to Vercel (Recommended)

The repository includes [`vercel.json`](../vercel.json), pre-configured for:
- Flutter Web Single-Page Application (SPA) routing (e.g. direct visits to `/wallet`, `/admin`, `/subscriptions` resolve cleanly without 404s).
- Immutable edge caching for static CanvasKit and WASM artifacts.

### A. Prerequisites
1. **Node.js**: If not installed, install via Windows Package Manager:
   ```powershell
   winget install OpenJS.NodeJS
   ```
2. **Flutter SDK**: Ensure Flutter is installed and in your PATH.

### B. First-Time Authentication (One-Time Only)
Authenticate the Vercel CLI with your free Vercel account:
```powershell
npx vercel login
```
- Select **Continue with GitHub** or enter your **Email**.
- Confirm in the browser window that opens.

### C. Build & Deploy
```powershell
# 1. Compile the production Flutter Web bundle
flutter build web --release

# 2. Deploy directly to Vercel Production
npx vercel --prod
```

### D. First-Time Deployment Prompts
When deploying for the first time, accept the defaults by pressing <kbd>Enter</kbd>:
```text
? Set up and deploy “d:\code\pden\rental-subscription-platform”? [Y/n] y
? Which scope do you want to deploy to? <Your Account>
? Link to existing project? [y/N] n
? What’s your project’s name? rental-subscription-platform
? In which directory is your code located? ./
? Want to modify these settings? [y/N] n
```
*Vercel will output your live URL: `https://rental-subscription-platform.vercel.app`.*

---

## 2. ⚡ Troubleshooting & FAQ

### Issue: `Error: No existing credentials found`
- **Cause**: Vercel CLI has not been authenticated on this machine yet.
- **Fix**: Run `npx vercel login` once, then re-run `npx vercel --prod`.

### Issue: Want an instant URL without logging in
- **Fix**: Run `npx vercel deploy --temporary` for an instant public share link.

---

## 3. 🐳 Containerized Docker Deployment

To run the platform inside a production Nginx container with Gzip compression and custom caching headers:

```powershell
# Build and run container in detached mode
docker-compose up --build -d

# View live running status
docker-compose ps
```
The application will be accessible at `http://localhost:8080`.

To stop the container:
```powershell
docker-compose down
```

---

## 4. 🤖 100% Code-Driven IaC & Automated Pipeline

### A. Cloud Service Health Check
Verify active connections and API tokens for Supabase, Razorpay, MSG91, and Resend:
```powershell
dart run scripts/verify_cloud_env.dart
```

### B. One-Command Build, Test & Deploy Pipeline
```powershell
# Standard deployment pipeline
.\scripts\deploy_cloud.ps1 -Target web

# Pipeline with PostgreSQL schema & seed migration applied to remote database
.\scripts\deploy_cloud.ps1 -Target web -ApplyMigrations
```

---

## 5. 🔄 Continuous Integration & Deployment (GitHub Actions)

Every push to `main` triggers [`.github/workflows/ci_cd_deploy.yml`](../.github/workflows/ci_cd_deploy.yml), which:
1. Validates code style (`flutter analyze` with 0 issues).
2. Runs all 41 automated unit & widget tests (`flutter test`).
3. Compiles the optimized production web build.
4. Generates production deployment artifacts.
