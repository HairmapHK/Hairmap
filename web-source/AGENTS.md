# Project Handover & Agent Guidelines (AGENTS.md)

This document is automatically loaded by AI Studio build agents to prevent design drift and maintain strict adherence to the application's UX/UI architecture. Follow these instructions when expanding, rewriting, or maintaining this codebase.

---

## 🚀 1. Core Architecture & Views Flow

The application is structured as a **Single Page Application (SPA)** with an interactive, responsive view routing system controlled inside `/src/App.tsx`. 

### State Routing & Roles
- **Customer Role (`userRole === 'customer'`)**:
  - `activeView` manages:
    - `'onboarding'`: Login / Registration page (User can register as Customer or Stylist). On log out, redirects here.
    - `'discovery'`: Storefront / search hub showcasing elite stylists and high-end salons.
    - `'inspiration'`: High-density visual Pinterest-style hairstyle grid for direct profile navigations.
    - `'stylist-profile'`: Professional profiles with bio, specialties, ratings, and pricing list.
    - `'salon-profile'`: Salon showcase.
    - `'booking'`: Booking checkout form. Includes custom date selection and a **simplified, neutral success popup** upon completion ("確定後顯示預約成功！").
    - `'chat'`: Message center for consulting with hair stylists.
    - `'profile'`: Client dashboard displaying upcoming reservation slots, with an integrated **Log Out (`登出`)** utility button.
- **Stylist Role (`userRole === 'stylist'`)**:
  - Automatically loads `<StylistDashboard />` in `/src/components/StylistDashboard.tsx` bypassing customer pages.
  - Features real-time tab switching between `'bookings'`, `'messages'`, `'schedule'`, and `'profile'`.

---

## 🎨 2. Design Language & CSS System

- **Framework**: Tailwind CSS (loaded in `/src/index.css` via `@import "tailwindcss";`).
- **Typography Pairing**:
  - **Headings (Editorial/Premium)**: Standard Serif/Sans fonts with high letter spacing tracking (`font-serif tracking-tight font-bold`) to create a fashion-forward, high-end "magazine" feel.
  - **Interface & Readability**: `Inter` or standard sans-serif for regular labels.
  - **Tech/Logistics Metadata**: Monospace (`font-mono`) for prices (`HK$`), timestamps, and console simulator streams.
- **Micro-Animations**: All page transition animations are run via `motion/react` with `<AnimatePresence>` for safe exits and entrances:
  ```typescript
  import { motion } from 'motion/react';
  ```
- **Icons**: Every UI glyph **MUST** be imported from `lucide-react`. Custom inline SVG shapes are forbidden.

---

## ⚙️ 3. Critical Component Guidelines & State Sync

### A. Customer Logout System
- In `/src/components/UserProfile.tsx`, a dedicated "Log Out" (登出) button is mounted on the core header. Calling `onLogout` clears client scopes and redirects to the onboarding welcome register pages instantly.

### B. Simple Success Notification
- Inside `Booking.tsx`, upon confirming a reservation, do **NOT** display a dark/resplendent full-screen cover. 
- Use the **simplified light-themed dialog** (`[color-scheme:light]` with a white card background, subtle shadows, and a clean "確定" call-to-action button) indicating "預約成功！髮型師會收到通知" along with basic scheduled booking facts.

### C. Stylist Dashboard & Database Persistence (`src/data.ts`)
- Inside `StylistDashboard.tsx`, stylists manage their professional profile inside the **"我的檔案名片管理"** block.
- **Bi-directional Sync**: When a stylist updates their profile (Avatar, Name, Title, Experience, communication Languages, Specialties, base Price, Bio), the state **directly mutates the matching object in `stylistsData`** (from `/src/data.ts`). Correct state mutation:
  ```typescript
  const targetStylist = stylistsData.find(s => s.id === initialStylistId);
  if (targetStylist) {
    targetStylist.name = profileName;
    targetStylist.title = profileTitle;
    // ...other detailed props
  }
  ```
- This ensures any customer switches immediately witness the updated stylist credentials, catalog specialties, custom works gallery photos, and fresh service charges in real-time.

---

## 🛠️ 4. Local Commands for Build and Verification

- **Lint check**: `npm run lint` or `tsc --noEmit`
- **Compiler build check**: `npm run build`
