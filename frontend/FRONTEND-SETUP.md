# Frontend Setup (Datta Able - Rental App)

React + Vite admin template configured for the rental properties backend.

## Prerequisites

- Node.js 18+
- Backend running on http://localhost:3000

## Quick Start

```bash
cd frontend
npm install
npm start
```

Frontend runs at **http://localhost:5173**

## Configuration

Edit `.env`:

| Variable | Description | Default |
|----------|-------------|---------|
| VITE_APP_API_URL | Backend API base URL | http://localhost:3000/api |
| VITE_APP_BASE_NAME | App base path (for routing) | / |
| VITE_APP_GOOGLE_MAPS_API_KEY | Google Maps (optional) | - |
| VITE_APP_PORT | Dev server port | 5173 |

## Scripts

- `npm start` - Dev server (Vite)
- `npm run build` - Production build
- `npm run preview` - Preview production build locally
- `npm run lint` - Run ESLint

## Ports

- **Frontend**: 5173 (avoids conflict with backend on 3000)
- **Backend**: 3000

Ensure both are running for full functionality.
