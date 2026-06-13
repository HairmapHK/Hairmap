# GitHub Pages Setup For Hairmap

Hairmap now includes static pages under `docs/`:

- `docs/index.html`
- `docs/privacy.html`
- `docs/terms.html`
- `docs/support.html`

These can be published with GitHub Pages and used in App Store Connect. A GitHub Actions workflow is included at `.github/workflows/pages.yml`.

## Suggested URLs

After enabling GitHub Pages:

```text
https://kelvinfung398398-sudo.github.io/Hairmap/
https://kelvinfung398398-sudo.github.io/Hairmap/privacy.html
https://kelvinfung398398-sudo.github.io/Hairmap/terms.html
https://kelvinfung398398-sudo.github.io/Hairmap/support.html
```

## Steps

1. Open the GitHub repository settings.
2. Go to Pages.
3. Set source to `GitHub Actions`.
4. Save.
5. Go to Actions and run `Publish Hairmap Pages`, or push a docs change to `main`.
6. Wait for GitHub Pages to publish.
7. Open the privacy/support URLs and confirm they load.
8. Use those URLs in App Store Connect.

## Reminder

The current privacy policy and terms are launch-preparation drafts. Review them before public release, especially if analytics, payment, advertising, crash reporting, or other third-party SDKs are added.
