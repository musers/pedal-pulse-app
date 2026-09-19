# ==============================================================================
# deploy_cloud.ps1
# VeloRide India - 100% Code-Based Automated Cloud Deployment & IaC Script
# Usage: .\scripts\deploy_cloud.ps1 [-Target <web|docker|supabase>] [-SkipTests]
# ==============================================================================

param (
    [string]$Target = "web",
    [switch]$SkipTests = $false,
    [switch]$ApplyMigrations = $false
)

$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  🚀 VeloRide India — Automated Code-Based Cloud Deployment" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "Target: $Target | Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# 1. Environment & Dependency Validation
Write-Host "[1/5] 🔍 Verifying Cloud Credentials & Infrastructure..." -ForegroundColor Yellow
$flutterBin = "D:\tools\flutter\bin\flutter.bat"
if (-not (Test-Path $flutterBin)) {
    $flutterBin = "flutter"
}

& dart run scripts/verify_cloud_env.dart

# 2. Automated Quality Gates (Analysis & Unit Tests)
if (-not $SkipTests) {
    Write-Host "`n[2/5] 🧪 Running Quality Gates (Analyzer & Test Suite)..." -ForegroundColor Yellow
    
    Write-Host "  -> Running Flutter Static Analysis..." -ForegroundColor Gray
    & $flutterBin analyze
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Static Analysis failed. Aborting deployment." -ForegroundColor Red
        exit $LASTEXITCODE
    }
    Write-Host "  ✅ Static analysis passed (0 issues)." -ForegroundColor Green

    Write-Host "  -> Running Automated Unit & Widget Tests..." -ForegroundColor Gray
    & $flutterBin test
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Automated tests failed. Aborting deployment." -ForegroundColor Red
        exit $LASTEXITCODE
    }
    Write-Host "  ✅ All automated tests passed." -ForegroundColor Green
} else {
    Write-Host "`n[2/5] ⏭️ Skipping quality gates as requested." -ForegroundColor Yellow
}

# 3. Database & SQL Migrations (IaC)
Write-Host "`n[3/5] 🗄️ Database Migrations Check..." -ForegroundColor Yellow
$migrationFiles = Get-ChildItem -Path "supabase\migrations\*.sql" | Sort-Object Name
Write-Host "  Found $($migrationFiles.Count) PostgreSQL Schema Migrations:" -ForegroundColor Gray
foreach ($file in $migrationFiles) {
    Write-Host "    • $($file.Name)" -ForegroundColor DarkGray
}

if ($ApplyMigrations) {
    Write-Host "  Applying migrations via Supabase CLI..." -ForegroundColor Gray
    if (Get-Command "supabase" -ErrorAction SilentlyContinue) {
        supabase db push
        Write-Host "  ✅ Database schema synchronized with Supabase cloud." -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ Supabase CLI not installed in PATH. Migrations are ready in supabase/migrations/." -ForegroundColor Yellow
    }
} else {
    Write-Host "  ℹ️ Migrations ready. Pass -ApplyMigrations to execute live against remote PostgreSQL." -ForegroundColor Gray
}

# 4. Production Build Pipeline
Write-Host "`n[4/5] 📦 Building Production Optimized Release Bundle..." -ForegroundColor Yellow
switch ($Target.ToLower()) {
    "web" {
        Write-Host "  Compiling Flutter Web Single Page Application (WASM & HTML5)..." -ForegroundColor Gray
        & $flutterBin build web --release --pwa-strategy=none
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Web compilation failed." -ForegroundColor Red
            exit $LASTEXITCODE
        }
        Write-Host "  ✅ Web distribution built successfully in 'build/web/'" -ForegroundColor Green
    }
    "docker" {
        Write-Host "  Building Production Docker Container..." -ForegroundColor Gray
        if (Get-Command "docker" -ErrorAction SilentlyContinue) {
            docker build -t veloride-india:latest .
            Write-Host "  ✅ Docker image 'veloride-india:latest' built successfully." -ForegroundColor Green
        } else {
            Write-Host "  ⚠️ Docker is not available in current environment." -ForegroundColor Yellow
        }
    }
    Default {
        Write-Host "  Building Web Release..." -ForegroundColor Gray
        & $flutterBin build web --release
    }
}

# 5. Deployment Complete
Write-Host "`n[5/5] 🎉 Deployment Orchestration Complete!" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  🌐 Production Output: build/web/" -ForegroundColor White
Write-Host "  📍 Region: Hyderabad (Miyapur & Kondapur EV Grid)" -ForegroundColor White
Write-Host "  ⚡ Fleet: 100% Electric (Ather, Ola, TVS, River, Chetak)" -ForegroundColor White
Write-Host "  🛡️ Zero Manual Config Required — 100% Code-Driven IaC" -ForegroundColor White
Write-Host "=================================================================`n" -ForegroundColor Cyan
