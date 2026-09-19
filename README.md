# 🛵 VeloRide India - Smart EV Rental & Subscription Platform

A production-grade, service-based urban two-wheeler mobility platform built for **Hyderabad (Miyapur & Kondapur Hubs)** with a **100% Electric Vehicle (EV) fleet**. Built with **Flutter (Android, iOS, Web)**, **PostgreSQL (Supabase)**, **Razorpay**, **Google Maps**, **MSG91 SMS**, and **Resend Email**.

---

## 🌟 Key Highlights

- **Hyderabad EV Mobility Grid**: Live smart hubs in **Miyapur** (Metro Station Terminal Hub) and **Kondapur** (HITEC City & Botanical Garden Hub).
- **100% Electric Connected Fleet**: Ather 450X Gen 3, Ola S1 Pro Gen 2, TVS iQube S, River Indie Utility SUV, and Bajaj Chetak Premium EV (Petrol/ICE fleet coming soon).
- **VeloCash In-App Digital Wallet & Referral Engine (`/wallet`)**:
  - Main Cash & Promotional Bonus Cash dual-balance architecture.
  - Cashback incentive tiers on top-up (e.g. ₹1,000 + ₹100 Free).
  - Instant security deposit refunds credited directly to wallet.
  - 1-Tap checkout when balance covers order; automated split-payment when balance is partial.
  - Viral Referral Program with 1-tap WhatsApp sharing and code redemption.
- **Weekly & Monthly Mobility Passes (`/subscriptions`)**: Long-term passes with unlimited/capped km, free maintenance guarantees, doorstep delivery, and auto-renewal.
- **Dynamic Promo Engine & Admin Coupon Desk (`/admin`)**: Create time-bound promotional campaigns with percentage caps, minimum order values, and live redemption stats.
- **100% Code-Driven Cloud Deployment (IaC)**: Automated deployment scripts (`scripts/deploy_cloud.ps1`), credential verifiers (`scripts/verify_cloud_env.dart`), multi-stage Docker containerization, and GitHub Actions CI/CD workflow.

---

## 🖥️ Local Setup & Run Guide

### 1. Prerequisites
- **Flutter SDK**: 3.29.0 or newer ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Dart SDK**: 3.7.0 or newer (bundled with Flutter)
- **Google Chrome**: For running the web application locally

```bash
flutter doctor
```

---

### 2. Run Locally in Offline / Demo Mode (No Cloud Keys Required)
The platform comes equipped with complete in-memory mock repositories and seed data, allowing immediate local execution:

#### A. Run in Google Chrome (Web)
```bash
flutter run -d chrome
```

#### B. Run on Android or iOS
```bash
flutter run -d android
# or
flutter run -d ios
```

---

### 3. Pre-Seeded Test Credentials

| Role | Mobile Number | OTP | Notes |
| :--- | :--- | :--- | :--- |
| **Verified Customer** | `+91 98765 00000` | `123456` | Pre-verified DL, ₹550 pre-funded VeloCash wallet |
| **New Customer** | `+91 91234 56789` | `123456` | Tests the DL KYC & referral onboarding |
| **Hub Admin / Staff** | `+91 99999 00001` | `123456` | Full administrative access to `/admin` |

---

### 4. Application Routes

- **Explore EV Fleet / Home**: `/` — Browse available electric scooters across Miyapur and Kondapur hubs.
- **VeloCash Digital Wallet**: `/wallet` — Balance breakdown, cashback top-up packages, transaction ledger & viral referrals.
- **Passes & Subscriptions**: `/subscriptions` — Weekly commute and monthly pro passes.
- **Subscription Checkout**: `/subscription-checkout/:planId` — 1-Tap / Split-payment pass activation.
- **Vehicle Details & Booking**: `/booking/:id` — Live duration selector, hub picker, and Razorpay checkout.
- **My Bookings & Passes**: `/my-bookings` — Active and past trip itineraries with QR handover simulation.
- **Customer Profile & KYC**: `/profile` — Driving License status and VeloCash wallet launcher.
- **Hub Operations Desk**: `/admin` — Fleet dispatch, vehicle returns, KYC queue, and Dynamic Coupon Engine.

---

## 🚀 100% Code-Based Cloud Deployment & IaC

You can test, migrate, build, and deploy the entire platform **entirely via code & CLI automation**:

### A. Verify Cloud Service Credentials
```bash
dart run scripts/verify_cloud_env.dart
```

### B. One-Command Automated Cloud Deployment
```powershell
# Run full automated deployment (Analyzer -> Test Suite -> Release Web Build)
.\scripts\deploy_cloud.ps1 -Target web

# Or with live remote PostgreSQL migration sync
.\scripts\deploy_cloud.ps1 -Target web -ApplyMigrations
```

### C. Containerized Docker Deployment
```bash
# Build and run with Docker Compose
docker-compose up --build -d
```

### D. Automated GitHub Actions CI/CD
Pushing to `main` triggers `.github/workflows/ci_cd_deploy.yml`, which automatically runs static code analysis, executes 40+ unit tests, validates cloud infrastructure, and compiles the production web distribution.

---

## 🧪 Testing & Code Quality

```bash
# Run static code analysis (0 issues)
flutter analyze

# Run all 41 automated unit and widget tests
flutter test
```
