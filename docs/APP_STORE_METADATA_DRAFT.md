# Hairmap App Store Metadata Draft

Use this as the starting copy for App Store Connect. Keep final URLs, reviewer accounts, and support contacts outside public commits if they include private credentials.

## App Info

- App name: Hairmap
- Subtitle: Discover stylists and book salon appointments
- Primary category: Lifestyle
- Secondary category: Business
- Content rights: Hairmap owns or has permission to use bundled screenshots, app icons, and in-app demo assets.

## Promotional Text

Find standout Hong Kong hair stylists, explore real hairstyle inspiration, and book salon appointments with a premium mobile experience.

## Description

Hairmap is a high-end hairstyle discovery and appointment platform for Hong Kong customers, stylists, and salons.

Customers can browse featured stylists, compare salons, explore hairstyle inspiration, upload their own looks, chat with stylists, and manage bookings in one place. Stylist profiles include portfolio photos, services, prices, reviews, languages, and salon details so customers can choose with confidence.

Stylists can manage booking requests, customer messages, available time slots, and their public profile from a dedicated dashboard. Salon and stylist submissions can be reviewed by platform admins before becoming public.

Key features:
- Discover stylists, salons, and rankings
- Browse fixed-size hairstyle portfolios and inspiration cards
- Book appointments with selectable services, dates, and times
- Chat one-on-one with stylists
- Upload photos for inspiration posts and reviews
- Manage customer bookings and stylist schedules
- Admin approval flow for new stylists and salons

## Keywords

hair,salon,stylist,haircut,hair color,booking,beauty,Hong Kong,髮型,髮型師,沙龍,剪髮,染髮,預約,香港

## Support And Legal URLs

- Support URL: `https://kelvinfung398398-sudo.github.io/Hairmap/support.html`
- Privacy Policy URL: `https://kelvinfung398398-sudo.github.io/Hairmap/privacy.html`
- Terms URL: `https://kelvinfung398398-sudo.github.io/Hairmap/terms.html`
- Marketing URL: `https://kelvinfung398398-sudo.github.io/Hairmap/`

Enable GitHub Pages from the `docs/` folder first. See `docs/GITHUB_PAGES_SETUP.md`.

## Reviewer Notes

Before submission, create dedicated non-personal reviewer accounts in Supabase and list them here.

```text
Customer reviewer account:
Email: REVIEW_CUSTOMER_EMAIL
Password: REVIEW_CUSTOMER_PASSWORD

Stylist reviewer account:
Email: REVIEW_STYLIST_EMAIL
Password: REVIEW_STYLIST_PASSWORD

Admin reviewer account, only if Apple needs admin access:
Email: REVIEW_ADMIN_EMAIL
Password: REVIEW_ADMIN_PASSWORD
```

Suggested review path:
1. Log in as a customer.
2. Open Discovery and view stylist, salon, and ranking tabs.
3. Open Inspiration, view a post, like/comment, and test upload.
4. Create a booking with Master Leo.
5. Log out and log in as the stylist reviewer.
6. Confirm the booking appears in the stylist dashboard.
7. Send a message back to the customer.

## Privacy Nutrition Label Draft

Disclose these data categories if production features remain as currently implemented:

- Contact Info: name, email address, phone number
- User Content: photos, reviews, messages, comments, appointment notes
- Identifiers: Supabase user ID, profile ID
- Purchases: not collected unless in-app payments are added later
- Location: not precise GPS currently; salon district/location text is shown and searched
- Usage Data: not collected unless analytics are added later
- Diagnostics: not collected unless crash/analytics SDKs are added later

Current app does not implement third-party advertising tracking. If analytics or ads are added later, update App Privacy and ATT handling before submission.

## Age Rating Guidance

Hairmap is a salon booking app, but it includes user-generated photos, comments, chat, and reviews. Complete the App Store age rating questionnaire conservatively and document moderation/reporting behavior in review notes.

## Screenshot Checklist

Capture from a real iPhone or simulator after final UI polish:

- Onboarding/login
- Discovery stylist cards
- Discovery salon cards
- Rankings
- Stylist profile portfolio and review form
- Salon profile
- Inspiration feed
- Inspiration detail/comments
- Booking flow
- Customer messages
- Customer profile/bookings
- Stylist dashboard bookings
- Stylist dashboard messages
- Stylist schedule
- Stylist profile editor
- Admin approval panel
