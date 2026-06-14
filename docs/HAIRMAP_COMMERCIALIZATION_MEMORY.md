# Hairmap Commercialization Memory

This file is the working memory for Hairmap's commercialization, promotion, beta rollout, and operator/admin strategy. Read this before continuing future business, marketing, TestFlight, App Store, or admin-backend work.

Do not store private keys, passwords, Supabase service-role secrets, Apple credentials, or personal reviewer credentials in this file.

## Product Positioning

Hairmap is a Hong Kong-focused premium hair stylist and salon discovery, booking, inspiration, and profile-management app.

The product has two main sides:

- Customer side: discover stylists and salons, browse hairstyle inspiration, view portfolios, read/write reviews, upload photos, book appointments, and chat one-on-one with stylists.
- Stylist/salon side: manage today's bookings, customer messages, availability, services, portfolio, profile card, and salon/stylist submissions.

The intended feel is high-end, fashion-magazine, mobile-first, and practical for real booking. Visual consistency matters: fixed image sizes, iPhone-safe layouts, clean white/black contrast, amber accents, premium cards, and no image overflow.

## Current Strategic Goal

First goal: get a stable iOS build ready for real-device testing, then TestFlight.

Near-term sequence:

1. Finish functional QA on simulator.
2. Wait for Apple Developer Program approval.
3. Upload first TestFlight build.
4. Test privately on a real iPhone.
5. Open controlled external TestFlight testing.
6. Collect real stylist/salon data during beta.
7. Clean staging/test data before App Store launch.
8. Seed production with approved real salon/stylist records.

## Data And Approval Rules

Supabase is the backend for Auth, catalog data, bookings, messages, inspiration content, reviews, media URLs, admin operations, and approval workflows.

Important rule: new stylist and salon profile submissions must not become public immediately. They should be written as pending applications first, then become public only after admin approval.

Admin backend needs to support:

- Approve/reject stylist applications.
- Approve/reject salon applications.
- Edit or hide public stylist profiles.
- Edit or hide public salon profiles.
- Move stylists/salons to earlier homepage positions.
- Adjust ranking order manually.
- Moderate reviews, comments, and uploaded photos.
- Separate staging/test data from production data.

## Commercial Model

Recommended phased model:

Phase 1: Supply building

- Free verified listings for early stylists and salons.
- Offer premium-looking profile pages and booking flow as the value hook.
- Collect real portfolio photos, service menus, district, pricing, languages, and Instagram links.
- Use admin approval to keep quality high.

Phase 2: Booking and visibility monetization

- Featured placement subscription for stylists and salons.
- Sponsored ranking/homepage boosts with clear labeling.
- Lead or booking referral fee after a confirmed booking.
- Salon profile upgrade package with more photos, branded description, and promoted services.

Phase 3: SaaS tools for professionals

- Paid stylist dashboard features: schedule controls, client history, saved consultations, automated reminders, profile analytics, and portfolio management.
- Salon team plan: multiple stylists, shared booking calendar, branch management, and campaign tools.
- Optional deposit/payment handling later, only after the booking funnel is stable.

## Promotion Plan

Beta/TestFlight should use a controlled, playful campaign, but staging data must stay separate from production.

Suggested campaign:

- Private beta first with trusted testers.
- Then external TestFlight public link capped at a manageable number.
- Threads-focused content: UI demos, funny fake stylist cards, hairstyle memes, before/after inspiration, "rate this hair idea" posts.
- Encourage UGC: users upload hairstyle inspiration, comment, and share screenshots.
- Use meme/fictional stylist data only in staging/TestFlight. Remove it before production launch.

Content angles:

- "Hong Kong needs a better way to find a reliable hairstylist."
- "Stop choosing salons blindly from random photos."
- "Show the haircut you want, then book someone who can actually do it."
- "Pinterest inspiration plus real Hong Kong stylists."
- "A premium hair booking app built for Hong Kong."

## Stylist And Salon Acquisition

Collect real launch data before App Store release:

- Stylist name
- Salon name
- District
- Title/specialty
- Languages
- Experience
- Service list and prices
- Portfolio photos
- Avatar/headshot
- Salon interior photos
- Instagram or portfolio URL
- Consent to publish on Hairmap

Prioritize quality over quantity. A small number of convincing real profiles is better than many incomplete listings.

Initial target supply:

- 10-20 strong stylists
- 5-10 salons
- Good coverage across key districts such as Tsim Sha Tsui, Central, Causeway Bay, Mong Kok, Kwun Tong, Sha Tin, Tsuen Wan, Yuen Long, and Tseung Kwan O

## App Store Readiness Notes

Keep these ready before submission:

- Production Supabase project or clean production data state.
- Dedicated Apple reviewer accounts.
- Privacy policy and terms URLs.
- Support page.
- App Store screenshots.
- UGC moderation explanation.
- No fictional/meme data in production screenshots unless clearly marked as demo and acceptable for review.

Related files:

- `docs/BETA_OPERATIONS_PLAYBOOK.md`
- `docs/APP_STORE_METADATA_DRAFT.md`
- `docs/GITHUB_PAGES_SETUP.md`
- `docs/privacy.html`
- `docs/terms.html`
- `docs/support.html`

## Future Work Queue

Business/admin:

- Build a stronger admin dashboard for approval, editing, ranking, moderation, and data cleanup.
- Add clear staging vs production safeguards.
- Add CSV/import workflow for real stylist and salon onboarding.
- Add exportable feedback report from TestFlight testers.

Marketing:

- Draft first 20 Threads posts.
- Prepare short screen-recording scripts.
- Prepare beta tester recruitment copy.
- Prepare stylist outreach DM templates.
- Prepare salon partnership pitch.

Product:

- Finish real-device QA.
- Confirm Google/Apple/email login on physical iPhone.
- Confirm bookings sync to stylist dashboard.
- Confirm messages sync both directions.
- Confirm profile submissions stay pending until admin approval.
- Confirm image upload and multi-photo upload behavior.
- Confirm review/comment/photo moderation path.

## Working Principle

Hairmap should launch as a curated marketplace, not an open chaotic directory. The first public impression should be polished, trustworthy, and intentionally selected.
