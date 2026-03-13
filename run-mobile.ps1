# Run Flutter app on physical phone with API calling
# Prerequisites: Backend running, phone on same WiFi, USB debugging enabled

$ErrorActionPreference = "Stop"

Write-Host "`n=== Hantario Rental - Mobile Setup ===" -ForegroundColor Cyan

# Get local IP (skip loopback, prefer WiFi/Ethernet)
$ip = $null
try {
    $adapters = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | 
        Where-Object { $_.IPAddress -notlike "127.*" -and $_.PrefixOrigin -ne "WellKnown" }
    $ip = ($adapters | Select-Object -First 1).IPAddress
} catch {
    $ip = (Get-NetIPConfiguration -ErrorAction SilentlyContinue | 
        Where-Object { $_.IPv4DefaultGateway -ne $null } | 
        Select-Object -First 1).IPv4Address.IPAddress
}

if (-not $ip) {
    Write-Host "Could not detect your local IP. Enter it manually (e.g. 192.168.1.5): " -NoNewline
    $ip = Read-Host
}

$apiUrl = "http://${ip}:3000/api"
Write-Host "Using API URL: $apiUrl" -ForegroundColor Green
Write-Host "Ensure your phone is on the same WiFi and backend is running (npm run start in backend/)" -ForegroundColor Yellow

# Check backend
$backendCheck = $null
try {
    $backendCheck = Invoke-WebRequest -Uri "http://${ip}:3000/health" -TimeoutSec 2 -UseBasicParsing -ErrorAction SilentlyContinue
} catch {}

if (-not $backendCheck -or $backendCheck.StatusCode -ne 200) {
    Write-Host "`nWARNING: Backend not reachable at http://${ip}:3000" -ForegroundColor Red
    Write-Host "Start the backend first: cd backend && npm run start" -ForegroundColor Yellow
    Write-Host "Continue anyway? (y/n): " -NoNewline
    if ((Read-Host) -ne "y") { exit 1 }
}

# Run Flutter
Push-Location $PSScriptRoot\app
try {
    flutter pub get
    Write-Host "`nLaunching app on connected device..." -ForegroundColor Cyan
    flutter run --dart-define=API_BASE_URL=$apiUrl
} finally {
    Pop-Location
}
