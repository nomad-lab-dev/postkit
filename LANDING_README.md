# PostKit — Landing

Static landing page + `/api/waitlist` Serverless Function wired to Resend.

## Deploy on Vercel (2 min)

```bash
vercel        # first time — link project
vercel --prod # ship
```

### Env vars to set (Vercel → Settings → Environment Variables)

| Key | Value |
|---|---|
| `RESEND_API_KEY` | your Resend secret (`re_...`) |
| `RESEND_AUDIENCE_ID` | UUID of the Audience you create in Resend → Audiences |
| `NOTIFY_EMAIL` | `hello@nomad-lab.io` |
| `NOTIFY_FROM` | `PostKit Waitlist <waitlist@nomad-lab.io>` (domain must be verified in Resend) |

Until `nomad-lab.io` is verified in Resend, set `NOTIFY_FROM=PostKit <onboarding@resend.dev>` — it works out of the box.

## What the endpoint does

`POST /api/waitlist` with `{ email, lang }`:
1. Adds the contact to your Resend Audience (ignores "already exists").
2. Sends a notification email to `NOTIFY_EMAIL` with IP + UA + lang.
3. Simple in-memory rate limit (5 req/min/IP).

`GET /api/geo` → `{ lang, country }`
- Uses Vercel's `x-vercel-ip-country` header to return `fr` for FR/BE/LU/MC/CH, else `en`.
- Frontend calls it on load and flips the UI language. User's manual toggle is persisted in localStorage and overrides geo detection on subsequent visits.
- Override with `?lang=fr` or `?lang=en` in the URL (useful for testing).

## Custom domain

Vercel → Project → Settings → Domains → add `postkit.app` (or whatever). CNAME or Nameservers, 30s.

## Local preview

The landing page works as a static file — open `PostKit Landing.html` directly. The form falls back to a local success state if `/api/waitlist` isn't reachable, so you can demo offline.
