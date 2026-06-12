# GitHub Pages Setup For Hairmap

Hairmap now includes static pages under `docs/`:

- `docs/index.html`
- `docs/privacy.html`
- `docs/terms.html`
- `docs/support.html`

These can be published with GitHub Pages and used in App Store Connect.

## Suggested URLs

After enabling GitHub Pages from the `docs/` folder on the `main` branch:

```text
https://kelvinfung398398-sudo.github.io/Hairmap/
https://kelvinfung398398-sudo.github.io/Hairmap/privacy.html
https://kelvinfung398398-sudo.github.io/Hairmap/terms.html
https://kelvinfung398398-sudo.github.io/Hairmap/support.html
```

## Steps

1. Open the GitHub repository settings.
2. Go to Pages.
3. Set source to `Deploy from a branch`.
4. Select branch `main`.
5. Select folder `/docs`.
6. Save.
7. Wait for GitHub Pages to publish.
8. Open the privacy/support URLs and confirm they load.
9. Use those URLs in App Store Connect.

## Reminder

The current privacy policy and terms are launch-preparation drafts. Review them before public release, especially if analytics, payment, advertising, crash reporting, or other third-party SDKs are added.
