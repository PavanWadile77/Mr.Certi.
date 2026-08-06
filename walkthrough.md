# Mr.Certi — Codebase Walkthrough

## Overview

Mr.Certi is a web-based E-Certificate Distribution Platform. Organizers upload templates, manage participants, bulk-generate personalized certificates (via Canvas), and send email delivery links. Participants log in to view and download their certificates. The entire backend is Firebase (Auth, Firestore, Storage), with EmailJS for email sending.

---

## Project Structure

```
Mr.Certi.H/
├── index.html              # Landing page with hero, features, auth modal
├── organizer.html          # Organizer dashboard (templates, participants, certs, email)
├── participant.html        # Participant dashboard (view/download certs, profile)
├── view-certificate.html   # Public certificate viewer (accessed via link)
├── server.js               # Local Node.js dev server (port 3000)
├── firebase-config.js      # Firebase initialization and exports
├── cors.json               # CORS config for Firebase Storage
├── .gitignore
├── README.md
├── css/
│   ├── global.css          # Design system, landing page, modals, toasts, responsive
│   ├── auth.css            # Auth form styles (login/signup/forgot)
│   └── dashboard.css       # Dashboard layout, sidebar, tables, cards, cert grids
└── js/
    ├── auth.js             # Firebase Auth module (login, signup, forgot password)
    ├── landing.js          # Landing page interactivity (modal, scroll, role selector)
    ├── organizer.js        # Organizer dashboard logic (CRUD, CSV, templates, cert gen, email)
    └── participant.js      # Participant dashboard logic (view certs, profile update)
```

---

## Pages & Routes

| Page | File | Purpose |
|---|---|---|
| Landing | `index.html` | Marketing page + auth modal (login/signup/forgot) |
| Organizer Dashboard | `organizer.html` | Full CRUD for participants, template editor, certificate generation, email sending |
| Participant Dashboard | `participant.html` | View/download certificates, edit profile |
| Certificate Viewer | `view-certificate.html?id=...` | Public page; shows certificate image from Firestore via participant ID |

---

## Firebase Configuration

All Firebase modules are loaded via CDN (`firebasejs/10.12.0`). Config is repeated in:

- `firebase-config.js` — centralized; exports `app`, `auth`, `db`, `storage`, `analytics`
- `auth.js` — standalone copy for auth flows
- `organizer.js` — inline config
- `participant.js` — inline config
- `view-certificate.html` — inline config with anonymous auth

**Firestore Collections:**

| Collection | Document ID | Key Fields |
|---|---|---|
| `users` | `uid` | `id`, `name`, `email`, `role` (`organizer`/`participant`), `createdAt` |
| `participants` | `uuid` | `id`, `name`, `email`, `teamName`, `certificateUrl`, `status` (`pending`/`generated`/`sent`), `createdBy`, `createdAt` |
| `certificates` | `uuid` | `id`, `templateUrl` (base64 data URL), `createdBy`, `createdAt`, `nameX`, `nameY`, `nameFontSize`, `nameColor`, `nameFontFamily`, `nameAlign`, `teamX`, `teamY`, `teamFontSize`, `teamColor`, `teamFontFamily`, `teamAlign` |

---

## Authentication Flow (`js/auth.js`)

- **Signup:** `createUserWithEmailAndPassword` → saves user doc to Firestore `users/{uid}` + creates participant doc in `participants/{uid}` (if role=participant). Non-blocking Firestore writes.
- **Login:** `signInWithEmailAndPassword` → reads role from Firestore `users/{uid}`, stores to `localStorage`, redirects to `organizer.html` or `participant.html`.
- **Auth State Observer:** `onAuthStateChanged` auto-redirects logged-in users from landing to their dashboard.
- **Forgot Password:** `sendPasswordResetEmail`.
- **Role Enforcement:** Both organizer and participant pages verify `localStorage.getItem('mr_certi_role')` AND Firestore user doc on load. Mismatch redirects to `index.html`.
- **Error Mapping:** Human-readable Firebase auth error messages.

---

## Landing Page (`index.html` + `js/landing.js`)

- Animated background orbs, floating card mockup, stats display
- Navbar scroll-to-shrink effect
- Auth modal with three states: Login, Signup, Forgot Password
- Role selector (Organizer / Participant) during signup
- Password visibility toggle
- Smooth scroll for anchor links
- Intersection Observer for stat animations

---

## Organizer Dashboard (`organizer.html` + `js/organizer.js`)

### Panels (tabbed navigation)
1. **Overview** — Stats cards, quick action buttons, recent participants table
2. **Participants** — Full table with search, status filter, select-all, bulk actions
3. **Templates** — Upload zone, template editor canvas, saved templates list
4. **Certificates** — Generation progress bar, search, grid of generated certs with download
5. **Send Emails** — Subject/body editor, send-all, send-pending, delivery status table

### Participant CRUD
- Add/edit via modal, delete with confirm
- CSV import with drag-and-drop, parsing (header detection: name, email, and automatically mapping team name columns if `team_name`, `Team Name`, or `team` is present), preview table, batch Firestore writes
- Search by name/email/team, filter by status (pending/generated/sent)
- Bulk select for generate/send

### Template Upload & Editor
- Upload PNG/JPG/PDF via file picker or drag-and-drop
- File converted to base64 data URL (compressed to <900KB) and saved directly to Firestore (bypasses Firebase Storage)
- Template Editor Canvas: renders uploaded template, overlays "Sample Name" and "Sample Team Name" (if team names are present in the imported data) with configurable:
  - **X/Y Position** (% of canvas) — click-to-place on canvas (automatically switches focus to the nearest element)
  - **Font Size** (px, auto-scaled on downscale, support smart fitting)
  - **Font Color** — native color picker + hex input + preset swatches
  - **Font Family** — 30+ Google fonts organized in groups (serif, cursive, modern)
  - **Alignment** — left/center/right
  - **Primary-Anchored Dynamic Text Fitting & Spacing Layout**:
   - Implemented dynamic text scaling to automatically shrink font sizes down to fit names within safe margins (max 80% width) and prevent overflow.
   - Anchored the **Participant Name** exactly at its original, auto-detected center coordinate (`autoY`) above the divider line.
   - Positioned the **Team Name** independently and dynamically below the Participant Name with a scaled vertical margin, ensuring the presence of a Team Name does not shift the Participant Name's vertical placement or alter the template's layout boundaries.
- Settings saved to Firestore `certificates/{id}` document (saves both name and team name styles)

### Certificate Generation (`generateCerts`)
1. Load template image onto hidden Canvas
2. Downscale proportionally (max 1400px wide)
3. Render participant name using editor settings at specified position
4. Export as JPEG base64 (~50% quality, auto-compress if >900KB)
5. Save to Firestore `participants/{id}.certificateUrl` + set status to `generated`
6. Optionally send email (non-blocking) via EmailJS → status becomes `sent`
7. Progress bar updates per participant

### Email via EmailJS
- EmailJS Service ID, Template ID, Public Key configured in `organizer.js:457-459`
- Sends to participants with a link to `view-certificate.html?id={participantId}`
- Bulk send, send-to-selected, send-pending, and single-send all supported
- 1.5s delay between sends to avoid rate limits

### Print All
- Opens a new window, renders all generated certs as full-page images, triggers browser print dialog

---

## Participant Dashboard (`participant.html` + `js/participant.js`)

- **My Certificates:** Queries `participants` collection by email match. Shows certificate hero card with preview image, status badge, download and view-full-size buttons.
- **Profile:** Editable name saved to Firestore `users/{uid}`, updates sidebar avatar + greeting.
- Mobile sidebar toggle.

---

## Public Certificate Viewer (`view-certificate.html`)

- Accessed via `?id={participantId}` query param
- Dark-themed presentational layout
- Attempts anonymous Firebase Auth (Firestore rules may require auth), then fetches `participants/{id}` doc
- Displays certificate image with download and print buttons
- Error states for: missing ID, not found, not yet generated, permission denied, network failure

---

## Styling Architecture

### `css/global.css` — Design System
- CSS custom properties (sky/gray palettes, shadows, radii, transitions)
- Reset, scrollbar, animated background orbs
- Navbar (fixed, glassmorphism, scroll effect)
- Button variants: primary (gradient), ghost, secondary, outline, danger
- Hero section with certificate mockup card and floating badges
- Features grid, How It Works section (angled clip-path), CTA card
- Auth modal overlay with scale transition
- Badges, toast notifications, page loading overlay
- Responsive breakpoints at 1024px, 768px

### `css/auth.css` — Auth Forms
- Modal brand header, role selector grid
- Form inputs, input wrapper with password toggle
- Checkbox, forgot link, error/success message blocks
- Auth button (gradient, full-width)
- Form label rows

### `css/dashboard.css` — Dashboard Layout
- Fixed sidebar (260px) with brand, nav items, user card, logout
- Main content offset with sticky topbar
- Panel system (`display: none` / `.active`)
- Stats cards with colored accent blobs
- Card component (header/body/footer)
- Table styling with hover, empty state
- Search bar, filter select
- Upload zone (dashed border, drag-over state)
- Progress bar
- Certificate grid (auto-fill) and cert item cards
- Generic modal overlay
- Participant cert hero (gradient)
- Responsive: sidebar slides off on mobile, overlay toggle

---

## Local Development

- `server.js` — simple Node.js HTTP server (port 3000) serving static files with MIME types
- `cors.json` — CORS configuration for localhost origins (ports 3000, 5500, 5173)

---

## Key Firebase Security Notes

- Template images are stored as base64 data URLs in Firestore documents (not Firebase Storage), to simplify CORS/rules
- `view-certificate.html` attempts anonymous auth first; the Firestore `participants` collection must allow public read or authenticated read
- Role enforcement is done client-side with Firestore verification + localStorage fallback

---

## Dependencies (External)

| Service | Purpose |
|---|---|
| Firebase (CDN 10.12.0) | Auth, Firestore, Storage, Analytics |
| Google Fonts (Inter + 30+ fonts) | UI + certificate rendering |
| EmailJS | Transactional email delivery |
| Canvas API (native) | Certificate image generation |
