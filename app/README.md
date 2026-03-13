# Hanti riyo

**Meel walba, riyo kasta Hanti riyo ayaa kuu dhow.**  
(Everywhere, any rental, Hanti riyo is close to you.)

A beautiful Flutter rental app built from the Hanti riyo Figma design. Find your perfect property with a clean, branded experience.

## Design System

- **Primary (Gold):** `#E7B904`
- **Dark text:** `#252B5C`, `#1F4C6B`
- **Background:** `#FCFCFC`
- **Typography:** Lato, Raleway (via Google Fonts)

## Screens

**Onboarding**
- Welcome, Choice (I want to rent / I want to list)

**Auth**
- Login Option, Login, Login (error state), Register, OTP, FAQ

**Account Setup**
- User (profile info), Location, Preferable (property types), Payment, Success

**Home**
- Home (search, categories, top locations, top agents, featured, explore)
- Location selector modal
- Estate detail, Agent profile

## Run

```bash
cd app
flutter pub get
flutter run
```

## API Setup (Autonomous Backend Integration)

The app now includes a lightweight API client and repositories with safe fallback data.

- Default API base URL: `https://api.example.com`
- Override base URL at build/run time:

```bash
flutter run --dart-define=API_BASE_URL=https://your-api-domain.com
```

Current repository-backed screens:
- `Saved` (`GET /favourites`, `DELETE /favourites/:user_id/:listing_id`)
- `Favorite toggle from listings` (`POST /favourites`, `DELETE /favourites/:user_id/:listing_id`)
- `Profile` (`/auth/me`, `PUT /users/:id`)
- `Messages` (`/chat/conversations`)
- `Chat` (`/chat/conversations/:id/messages`)
- `Notifications` (`/notifications`)
- `Home` (`/public/listings` with derived top locations/agents)
- `Estate Detail` (`/public/listings/:id`, `/listing-reviews`, nearby from `/public/listings`)
- `Agent Profile` (`/users/:id`, `/public/listings?user_id=:id`, `/listing-reviews?user_id=:id`)
- `Search` (`/public/listings?search=...`)
- `Explore` (`/public/listings`)
- `Transaction Summary` (`/public/listings/:id`, `/public/listings/:id/availability`, `/public/listings/:id/rental-quote`, `POST /listing-rentals`)
- `Add Estate` (`POST /listings`)
- `Settings` (`/chat/settings` read; local-safe save)
- `Account Setup` (`GET /auth/me`, `PUT /users/:id`, `POST /user-bank-accounts`)
- `Auth` (`POST /auth/login`, `POST /users` (register), `/auth/verify-otp`, `/auth/social-login`)
  - Additional auth actions: `POST /auth/forgot-password`, `POST /auth/resend-otp`, `POST /auth/logout`

Network notes:
- `ApiClient` now sends `Accept: application/json` by default.
- If auth token exists, `Authorization: Bearer <token>` is automatically attached.
- Auth token is stored in-memory in `core/network/api_session.dart` after auth success.
- Router now has auth-aware redirects: unauthenticated users are redirected from protected routes to `/login-option`.
- Router listens to auth session changes (`ApiSession.authState`) so redirects react immediately after login/logout.
- Route path constants are centralized in `core/router/app_routes.dart` to reduce navigation drift.

## Structure

```
lib/
├── core/           # Theme, colors, router, constants
├── features/
│   ├── onboarding/ # Welcome, Choice
│   ├── auth/       # Login, Register, OTP, FAQ
│   ├── account_setup/  # User, Location, Preferable, Payment
│   ├── home/       # Home, Estate detail, Agent profile
│   └── profile/    # Profile
├── shared/         # Buttons, text fields, setup scaffold
└── main.dart
```
