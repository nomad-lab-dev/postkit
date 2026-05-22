# PostKit Pro — StoreKit 2 Setup Guide

## Overview

This guide covers everything you need to do outside of code to get the subscription system working in both testing (Xcode sandbox) and production (App Store).

---

## PART 1: Xcode StoreKit Configuration (Local Testing)

This lets you test purchases in the simulator without App Store Connect.

### Step 1: Create the StoreKit Configuration File

1. In Xcode: **File > New > File**
2. Search for **StoreKit Configuration File**
3. Name it `PostKit.storekit`
4. Save it in `PostKit/Configuration/` (create the folder)
5. **Do NOT check** "Sync this file with an app in App Store Connect" (we'll do that later)

### Step 2: Add Products

In the `.storekit` file editor:

**Product 1 — Monthly:**
- Click **+** > **Add Auto-Renewable Subscription**
- Subscription Group: `PostKit Pro` (reference name: `postkit_pro`)
- Product ID: `pro_monthly`
- Reference Name: `PostKit Pro Monthly`
- Price: $9.99
- Subscription Duration: 1 Month
- Display Name (EN): `Monthly`
- Description (EN): `Unlimited AI posts, scanning, and templates`

**Product 2 — Yearly:**
- Click **+** > **Add Auto-Renewable Subscription** (same group)
- Product ID: `pro_yearly`
- Reference Name: `PostKit Pro Yearly`
- Price: $79.99
- Subscription Duration: 1 Year
- Display Name (EN): `Yearly`
- Description (EN): `Unlimited AI posts, scanning, and templates — save 33%`

### Step 3: Set as Active Configuration

1. **Product > Scheme > Edit Scheme** (or Cmd+Shift+<)
2. Select **Run** in the left sidebar
3. Go to the **Options** tab
4. Set **StoreKit Configuration** to `PostKit.storekit`

### Step 4: Test in Simulator

- Build and run
- Purchases will go through instantly (no real Apple ID needed)
- Use **Debug > StoreKit > Manage Transactions** to view/delete test transactions
- Use **Debug > StoreKit > Subscription Renewal Rate** to speed up renewals for testing

---

## PART 2: App Store Connect (Production)

### Step 5: Create App in App Store Connect

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. **My Apps** > **+** > **New App**
3. Platform: iOS
4. Name: PostKit
5. Bundle ID: select from dropdown (must match your Xcode bundle identifier)
6. SKU: `postkit` (or whatever you want)
7. Primary Language: English

### Step 6: Create Subscription Group

1. In your app page, go to **Monetization** > **Subscriptions**
2. Click **+** next to Subscription Groups
3. Group Reference Name: `PostKit Pro`

### Step 7: Create Products in the Group

**Monthly:**
1. Click **+** > **Create Subscription**
2. Reference Name: `PostKit Pro Monthly`
3. Product ID: `pro_monthly` (MUST match the code)
4. Duration: 1 Month
5. Subscription Price: $9.99 USD (then set other territories or let Apple auto-calculate)
6. Add Localization (EN):
   - Display Name: `Monthly`
   - Description: `Unlimited AI posts, scanning, and templates`
7. Add a Review Screenshot (required for review — take a screenshot of the paywall)

**Yearly:**
1. Same process, Product ID: `pro_yearly`
2. Duration: 1 Year
3. Price: $79.99 USD
4. Display Name: `Yearly`
5. Description: `Unlimited AI posts, scanning, and templates — save 33%`

### Step 8: Review Information

For each subscription, you need:
- **Review Screenshot**: Screenshot of PaywallView showing the product
- **Review Notes**: Brief explanation (e.g., "Subscription unlocks unlimited AI-powered post creation, photo scanning, and template usage")

### Step 9: App Privacy

In **App Privacy** section, declare:
- **Purchases**: Yes (subscription data)
- **Identifiers**: Device ID (for StoreKit transaction verification)

---

## PART 3: Sandbox Testing (Real Device)

### Step 10: Create Sandbox Tester Account

1. In App Store Connect: **Users and Access** > **Sandbox** (left sidebar) > **Testers**
2. Click **+** to add a new sandbox tester
3. Use a real email you have access to (Apple sends a verification email)
4. Set a password you'll remember
5. Territory: your local territory (France, US, etc.)

### Step 11: Test on Device

1. On your iPhone: **Settings > App Store > Sandbox Account**
2. Sign in with the sandbox tester credentials
3. Build and run the app from Xcode on the real device
4. Purchases will be sandbox (no real charge)
5. Sandbox subscriptions renew faster:

| Real Duration | Sandbox Duration |
|---------------|------------------|
| 1 week        | 3 minutes        |
| 1 month       | 5 minutes        |
| 2 months      | 10 minutes       |
| 3 months      | 15 minutes       |
| 6 months      | 30 minutes       |
| 1 year        | 1 hour           |

---

## PART 4: Pre-Submission Checklist

### Before submitting to App Review:

- [ ] Both products (`pro_monthly`, `pro_yearly`) are "Ready to Submit" in App Store Connect
- [ ] Review screenshots uploaded for each product
- [ ] App Privacy declarations completed
- [ ] Paywall shows correct prices (from StoreKit, not hardcoded)
- [ ] "Restore Purchases" button is visible and functional (Apple rejects apps without it)
- [ ] Subscription auto-renewal legal text is displayed (already in PaywallView)
- [ ] Terms of Use and Privacy Policy URLs set in App Store Connect
- [ ] `PostKit.storekit` configuration is NOT set in Release scheme (only Debug)
- [ ] Test full flow on real device with sandbox account:
  - Purchase monthly -> verify Pro access
  - Purchase yearly -> verify Pro access
  - Cancel -> verify access revoked after period ends
  - Restore -> verify re-activation
  - Token gate: AI share -> 1st free -> 2nd blocked -> paywall -> purchase -> share completes

### Common Rejection Reasons:

1. **No Restore button** — Already handled in PaywallView
2. **Hardcoded prices** — We use `product.displayPrice` from StoreKit
3. **Missing legal text** — Already in `legalSection` of PaywallView
4. **No Terms/Privacy links** — Must add in App Store Connect AND optionally in Settings
5. **Subscription not clearly explained** — Our benefits list covers this

---

## PART 5: Syncing StoreKit Config with App Store Connect

Once products exist in App Store Connect, you can sync:

1. Open `PostKit.storekit` in Xcode
2. **Editor > Sync with App Store Connect**
3. Sign in with your Apple ID
4. Select your app and subscription group
5. Products will sync — prices and metadata will match production

This ensures your local testing uses the exact same product IDs, prices, and configurations as production.

---

## Product IDs Summary

| Product ID     | Type                   | Price    | Duration |
|----------------|------------------------|----------|----------|
| `pro_monthly`  | Auto-Renewable Sub     | $9.99    | 1 Month  |
| `pro_yearly`   | Auto-Renewable Sub     | $79.99   | 1 Year   |

Group: `PostKit Pro` (ref: `postkit_pro`)

---

## Code-Side Reference

Files involved:
- `Dependencies/SubscriptionClient.swift` — StoreKit 2 API wrapper (product IDs defined here)
- `Features/Paywall/PaywallFeature.swift` — Purchase/restore logic
- `Features/Paywall/PaywallView.swift` — Paywall UI
- `Models/FilledSlot.swift` — Token gating in PostEditorFeature
- `Dependencies/UserDefaultsClient.swift` — Daily token tracking

Branch: `feat/storekit-subscription`
