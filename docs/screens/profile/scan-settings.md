# Screen: Scan Settings

**Path:** `TabBar / Profile / Scan Settings`
**View:** `ScanSettingsView`
**ViewModel:** `ScanSettingsViewModel`
**Stories:** PB-008, PB-019

---

## Purpose

Configure the classification pipeline. API key, batch size, cloud toggle, manual retrigger.

## Specs

- **Sections:**
  - **Classification Engine:**
    - Toggle: "Use cloud AI" (on/off). Off = Core ML only.
    - API provider picker: Gemini Flash (default) / Custom endpoint
    - API key field (secure, masked)
    - "Test connection" button
  - **Batch Settings:**
    - Batch window size: 30 days (default), adjustable stepper (7/14/30/60/90 days)
    - Concurrent requests: 1-5 slider (default 3)
  - **Scan Actions:**
    - "Scan new assets" → scan only unclassified
    - "Rescan all assets" → re-classify everything (confirmation required)
    - "Reset all classifications" → nuclear option (double confirmation)
  - **Stats:**
    - Total assets in library
    - Classified / Unclassified count
    - Last scan date
    - API calls used this session

## Interactions

| Action | Result |
|--------|--------|
| Toggle cloud AI off | Only Core ML used. Pillars may be less accurate. |
| Enter API key | Saved to Keychain (not SwiftData) |
| Tap "Test connection" | API call → success/failure toast |
| Adjust batch window | Saved, applies to next scan |
| Tap "Scan new" | Start incremental scan |
| Tap "Rescan all" | Confirmation → full rescan |
| Tap "Reset all" | Double confirmation → remove all classifications |

## Edge Cases

- **Invalid API key:** Test connection fails with clear error message
- **Cloud off + rescan:** Core ML only, less accurate but free/fast
- **Reset all:** Double confirmation ("Are you sure?" + "Type RESET to confirm"). Irreversible.
- **API rate limit hit during scan:** Pause, show error, offer to resume later
- **Keychain access denied:** Show error, explain
- **Batch window larger than library history:** Scans everything in one batch

## Acceptance Criteria

- [ ] Cloud toggle works, affects pipeline
- [ ] API key stored in Keychain (secure)
- [ ] Test connection works
- [ ] Batch settings persist
- [ ] Scan new works
- [ ] Rescan all with confirmation
- [ ] Reset all with double confirmation
- [ ] Stats display correct numbers
- [ ] Rate limit handling
