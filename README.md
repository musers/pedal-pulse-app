# 🛵 VeloRide India - Fullstack Two-Wheeler Rental & Subscription Platform

A production-grade, service-based two-wheeler mobility platform built for Indian urban transit (Bengaluru launch). Built with **Flutter (Android, iOS, Web)**, **PostgreSQL (Supabase)**, **Razorpay**, **Google Maps**, **MSG91 SMS**, and **Resend Email**.

---

## 🌟 Key Highlights

- **Cross-Platform Responsive Experience**: Single unified Flutter/Dart codebase with adaptive layouts for Desktop Web, Tablets, and Mobile devices (Android & iOS).
- **Instant Two-Wheeler DL Verification**: Driver license KYC upload and verification workflow compliant with Karnataka State transport regulations.
- **Interactive Bengaluru Hub Explorer**: Real-time hub map pins, live available bike counters, user GPS distance calculations (Haversine formula), and operating hours.
- **Server-Authoritative Pricing & Checkout**: Base fare + 18% GST + 100% Refundable Security Deposit with HMAC-SHA256 cryptographic Razorpay signature verification.
- **Hub Operations Admin Portal (`/admin`)**: Operations desk with Fleet Inventory Status, QR Dispatch Desk, Return Inspection & Deposit Release Desk, and KYC Approval Queue.
- **Automated Communication Stack**: MSG91 SMS for time-sensitive booking alerts, Resend for GST tax invoices, and FCM push notifications.
- **Zero Double-Booking Guarantee**: PostgreSQL concurrency trigger (`prevent_double_booking()`) preventing overlapping reservations at the database engine level.
- **Zero-Rewrite Migration Path**: Clean Architecture repository abstractions enabling seamless transition from Supabase to **Spring Boot + PostgreSQL**.

---

## 🖥️ Local Setup & Run Guide

### 1. Prerequisites
Ensure you have the following installed on your machine:
- **Flutter SDK**: 3.47.0 or newer ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Dart SDK**: 3.13.0 or newer (comes bundled with Flutter)
- **Google Chrome**: For running the web application locally
- **VS Code / Android Studio / Antigravity IDE**: (Optional, recommended)

Verify your Flutter environment by running:
```bash
flutter doctor
```

---

### 2. Clone & Install Dependencies
```bash
# Navigate to the project root directory
cd rental-subscription-platform

# Fetch all Flutter & Dart packages
flutter pub get
```

---

### 3. Run Locally in Offline / Demo Mode (No Cloud Keys Required)
The platform comes equipped with complete in-memory mock repositories and seed data, allowing immediate local execution:

#### A. Run in Google Chrome (Web)
```bash
flutter run -d chrome
```
> **Tip**: Once running in Chrome, press `r` in your terminal for instant Hot Reload or `R` for Hot Restart.

#### B. Run on Android Emulator or Connected Device
```bash
flutter run -d android
```

#### C. Run on iOS Simulator (macOS only)
```bash
flutter run -d ios
```

---

### 4. Pre-Seeded Test Credentials

You can test both Customer and Admin workflows immediately using the pre-seeded accounts:

| Role | Mobile Number | OTP | Notes |
| :--- | :--- | :--- | :--- |
| **Verified Customer** | `+91 98765 00000` | `123456` | Pre-verified Driving License; ready to book |
| **New Customer** | `+91 91234 56789` | `123456` | Tests the DL submission & KYC workflow |
| **Hub Admin / Staff** | `+91 99999 00001` | `123456` | Full administrative access to `/admin` |

---

### 5. Application Navigation & Routes

- **Explore Fleet / Home**: `/` — Browse available electric scooters and petrol cruisers across Bengaluru hubs.
- **Vehicle Details**: `/bike/:id` — Detailed specs, battery status, inclusions, and refundable deposit terms.
- **Booking & Checkout**: `/booking/:id` — Rental duration picker, pickup/return hub selection, and Razorpay checkout.
- **My Bookings**: `/my-bookings` — Active and past trip itineraries with QR handover simulation.
- **Customer Profile & KYC**: `/profile` — DL verification status and profile management.
- **Hub Operations Desk**: `/admin` — Fleet dispatch, vehicle returns, and KYC verification queues.

---

### 6. Run Automated Tests & Code Analysis

```bash
# Run static code analysis (0 warnings / 0 errors)
flutter analyze

# Run all 21 automated unit and widget tests
flutter test

# Run tests with detailed output
flutter test --reporter expanded
```

---

### 7. Build Production Web Bundle

To create an optimized production release build for web hosting (Vercel, Firebase Hosting, Netlify, or Cloudflare Pages):

```bash
flutter build web --release
```
The compiled static assets will be generated in `build/web/`.

---

### 8. Connect to Live Cloud Services (Path 2)

To connect live Supabase, Razorpay, MSG91, and Resend services, supply the API keys via `--dart-define` flags or a `.env` configuration:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-supabase-publishable-key \
  --dart-define=RAZORPAY_KEY_ID=rzp_test_your_key_id \
  --dart-define=RAZORPAY_KEY_SECRET=your_razorpay_secret \
  --dart-define=MSG91_AUTH_KEY=your_msg91_auth_key \
  --dart-define=RESEND_API_KEY=your_resend_api_key
```

---

## 🏛️ Project Architecture

```
lib/
├── core/                  # Design tokens, theme, GoRouter, constants, responsive breakpoints
├── domain/                # Pure entities (Bike, Station, Booking, UserProfile) & Repository contracts
├── data/
│   ├── datasources/       # SupabaseDataSource & MockDataSource
│   └── repositories/      # Supabase & Mock repository implementations
├── services/              # External service adapters
│   ├── auth/              # AuthService (SupabaseAuthService, MockAuthService)
│   ├── maps/              # MapService (GoogleMapService, MockMapService)
│   ├── payment/           # PaymentService (RazorpayPaymentService, HMAC-SHA256 verification)
│   ├── sms/               # SmsService (Msg91SmsService)
│   ├── email/             # EmailService (ResendEmailService)
│   └── notification/      # NotificationService (FcmNotificationService)
└── presentation/          # Riverpod state providers and responsive UI
    ├── common/            # Shared providers (auth, payment, repos)
    ├── customer/          # Explore, Bike Details, Booking, My Bookings, Profile
    └── admin/             # Operations Shell, Fleet, Dispatch, Return, KYC
```

---

## 🗄️ Database Migrations (PostgreSQL)

Located in `supabase/migrations/`:
- `001_initial_schema.sql`: Tables (`profiles`, `stations`, `bike_categories`, `bikes`, `bookings`, `rental_logs`) and concurrency triggers.
- `002_rls_policies.sql`: Row Level Security policies.
- `003_seed_data.sql`: Seed data for Bengaluru hubs and initial fleet (Ather 450X, Ola S1 Pro, Activa 6G, Hunter 350, MT-15).

To push migrations to your Supabase project:
```bash
supabase db push
```

---

## 📄 License
Proprietary • VeloRide India Mobility Pvt Ltd.
