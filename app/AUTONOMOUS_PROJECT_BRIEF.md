# Autonomous Project Brief - e-Rental App

## Vision
- Build a complete real-estate product from the provided Figma source.
- Deliver a production-ready Flutter app and aligned project surfaces with strong brand consistency.
- Execute autonomously with minimal supervision, while preserving strict design fidelity where requested.

## Core Agreement
- Figma implementation must be visually strict: layout, spacing, typography, color, radius, icon style, image treatment, and interaction states.
- No unfinished runtime issues: app should run without blocking exceptions.
- No broken/blank image rendering: all remote assets must gracefully handle decode failures and fallback.
- Continue implementation autonomously across batches until all planned scope is completed.

## Scope

### 1) Mobile App (Flutter)
- Implement all user-facing screens from Figma with route wiring.
- Ensure consistent design system tokens and reusable components.
- Stabilize all runtime paths (navigation, image loading, responsive layout, empty/loading/error states).

### 2) Backend Connection
- Define missing API contracts and integrate app screens with backend endpoints.
- Add robust data layer patterns: models, repository/service layer, error handling, retries, and loading states.
- Replace temporary/mock data with real API-driven flows where backend is available.

### 3) Frontend/Admin Improvement
- Improve dashboard/admin visuals using the same Figma-derived brand language.
- Align color system, spacing, and component hierarchy with the mobile brand.
- Preserve usability and consistency while modernizing the UI.

## Delivery Phases

### Phase A - Figma Parity
- Screen-by-screen parity pass on existing routes.
- Shared component refinement first, then per-screen precision pass.

### Phase B - Stability and QA
- Remove runtime issues and layout overflows.
- Harden image handling for remote/SVG/expired links.
- Validate with analyzer and in-device runtime checks.

### Phase C - Backend Integration
- Implement API layer and connect major flows.
- Add graceful offline/error UX where endpoints fail.

### Phase D - Admin/Frontend Branding
- Apply consistent brand system and improved layout patterns.
- Final polish for accessibility and consistency.

## Definition of Done
- Major user flows function end-to-end.
- No blocking runtime exceptions in normal usage.
- No persistent layout overflow in core screens.
- Image rendering resilient to remote asset variations.
- Visual output matches Figma intent at 1:1 standard for agreed screens.

## Autonomy Rules
- Make implementation decisions proactively when details are missing.
- Prefer maintainable architecture and reusable primitives.
- Do not pause for routine choices; continue to completion unless blocked by missing credentials/permissions.
