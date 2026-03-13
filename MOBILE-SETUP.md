# Run App on Physical Phone with API

This guide helps you run the Hantario Rental app on your physical phone with API calls to your local backend.

## Prerequisites

1. **Backend running** – MySQL/PostgreSQL, Redis, MongoDB (or Docker)
2. **Phone and computer on same WiFi**
3. **Flutter installed** – [flutter.dev](https://flutter.dev)
4. **USB debugging enabled** (Android) or **Developer mode** (iOS)

---

## Quick Start

### 1. Start the backend

```bash
cd backend
npm install
npm run start
```

Backend should be available at `http://localhost:3000` (and on your LAN IP).

### 2. Connect your phone

- **Android**: Enable USB debugging, connect via USB
- **iOS**: Connect via USB (Mac only for iOS)

### 3. Run the app

```powershell
# From project root
.\run-mobile.ps1
```

This script will:
- Detect your computer’s local IP
- Run the Flutter app with `API_BASE_URL=http://YOUR_IP:3000/api`
- Install the app on the connected device

---

## Manual Run

If you prefer to run manually:

1. Find your local IP:
   - Windows: `ipconfig` → IPv4 under your WiFi adapter
   - Example: `192.168.1.5`

2. Run Flutter:

```bash
cd app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://YOUR_IP:3000/api
```

Example (IP `192.168.1.5`):

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.5:3000/api
```

---

## Troubleshooting

### “Connection refused” or app can’t reach API

1. Confirm phone and PC are on the same WiFi.
2. Confirm backend is running: `curl http://YOUR_IP:3000/health`
3. Windows: allow Node/backend through the firewall, or temporarily disable it to test.

### Backend not reachable from phone

- Backend listens on `0.0.0.0` (all interfaces), so this should work.
- If using Docker, ensure ports are exposed on the host.

### Flutter not finding device

- **Android**: Run `adb devices` – your device should appear.
- Enable USB debugging: Settings → Developer options → USB debugging.
- **iOS**: Use a Mac with Xcode and an iOS Simulator or device.

---

## API Base URL

- Default: `https://api.example.com` (compiled in if no override)
- Override: `--dart-define=API_BASE_URL=http://YOUR_IP:3000/api`

The Flutter app appends paths like `/auth/login`, `/public/listings` to this base URL.
