# Google Play — Data Safety form answers (Jobzone)

This is a fill-in guide for the **Data Safety** section in Play Console
(*App content → Data safety*). It mirrors what `docs/privacy-policy.html`
declares and what the app actually does today. Transcribe each answer into the
form. Re-check it whenever you add a data type, an SDK, or a backend that
touches personal data.

> Play's definitions, in short:
> - **Collected** = data leaves the device to your servers (or a processor's).
> - **Shared** = data is transferred to a *third party*. Sending data to a
>   **service provider that only processes it on your behalf is _not_ "sharing."**
>   All our backends (Supabase, Firebase Cloud Messaging, Meilisearch, Yandex
>   MapKit, Anthropic, Telegram) act as processors, so **Shared = No** for every
>   type below. Profile visibility to employers inside the app is *app
>   functionality*, not third-party sharing.
> - **Processed ephemerally** = used only in memory, not stored. We store most
>   data, so answer **No** unless noted.

---

## Section 1 — Data collection and security (the three gate questions)

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** — all traffic is HTTPS/TLS (Supabase, FCM, map tiles, edge functions). |
| Do you provide a way for users to request that their data be deleted? | **Yes** — users can request account + data deletion by email (see "Deletion" below). |

---

## Section 2 — Data types

For every type marked **Collected = Yes**, the form then asks:
*Shared?* → **No** (processors only, per the note above) for all of them ·
*Processed ephemerally?* → **No** unless stated ·
*Required or optional?* · *Purposes?*

### Personal info
| Data type | Collected | Required/Optional | Purposes |
|---|---|---|---|
| Name | Yes | Required | App functionality, Account management |
| Email address | Yes | Required | App functionality, Account management |
| Phone number | Yes | Required | App functionality, Account management |
| User IDs | Yes | Required | App functionality, Account management |
| Address | Yes | Optional | App functionality *(optional CV/contact field)* |
| Other info | Yes | Optional | App functionality *(headline, bio, work experience, education, skills, desired pay, availability — the CV/profile)* |

### Location
| Data type | Collected | Required/Optional | Purposes |
|---|---|---|---|
| Approximate location | Yes | Optional | App functionality *(nearby jobs, distance estimate)* |
| Precise location | Yes | Optional | App functionality *(only if the user grants the permission / sets a precise location)* |

### Messages
| Data type | Collected | Required/Optional | Purposes |
|---|---|---|---|
| Other in-app messages | Yes | Optional | App functionality *(seeker ↔ employer chat)* |

### Photos and videos
| Data type | Collected | Required/Optional | Purposes |
|---|---|---|---|
| Photos | Yes | Optional | App functionality *(profile photo)* |

### Files and docs
| Data type | Collected | Required/Optional | Purposes |
|---|---|---|---|
| Files and docs | Yes | Optional | App functionality *(uploaded résumé / CV files)* |

### App activity
| Data type | Collected | Required/Optional | Purposes |
|---|---|---|---|
| App interactions | Yes | Optional | App functionality, Personalization *(bookmarks, taps)* |
| In-app search history | Yes | Optional | Personalization *(job searches)* |
| Other user-generated content | Yes | Optional | App functionality *(cover letters, screening answers, application content; employer job postings & company profiles)* |

### Device or other IDs
| Data type | Collected | Required/Optional | Purposes |
|---|---|---|---|
| Device or other IDs | Yes | Optional | App functionality *(push-notification token for delivering notifications)* |

---

## What we do NOT collect (leave unchecked)

- Financial info (no in-app payments yet; Click/Payme is a future integration —
  revisit this form when it lands).
- Health & fitness, Calendar, Contacts, Audio files, Web browsing history.
- Race/ethnicity, political or religious beliefs, sexual orientation.
- Installed apps list.
- Crash logs / diagnostics / analytics — we don't ship an analytics or crash SDK
  today. **If you add Firebase Analytics/Crashlytics later, add "Crash logs",
  "Diagnostics", and the Analytics purpose here.**

## Advertising

- We do **not** share data for advertising, do **not** use third-party ad SDKs,
  and do **not** sell personal data. Leave all "Advertising or marketing"
  purposes unchecked.

---

## Deletion (Play requires this for apps with accounts)

- **Today:** users request account + data deletion by emailing
  **jamshid.beeline@gmail.com** (stated in the privacy policy, §6). Put this same
  address / instruction in the Data Safety deletion field.
- **Recommended before launch (Play increasingly expects it):** add a
  **web URL** where users can request deletion *without* installing the app, and
  ideally an **in-app "Delete account"** action (calls Supabase Auth admin delete
  + cascades the user's rows). The email path satisfies the minimum; the in-app +
  URL path is the stronger, future-proof option.

---

## Privacy policy URL (required field elsewhere in Play)

Host `docs/privacy-policy.html` at a public URL and paste it into
*Play Console → App content → Privacy policy*. Quickest option: enable
**GitHub Pages** on this repo (Settings → Pages → deploy from `main`/`docs`),
which serves it at `https://<org>.github.io/jobzone/privacy-policy.html`. Any
static host (Supabase Storage public bucket, Netlify, your domain) works too.

> Before publishing: replace the operator placeholder in the policy with your
> registered legal entity + address, set the effective date, and have counsel
> review it against Uzbekistan's personal-data law (O'zbekiston Respublikasining
> "Shaxsga doir ma'lumotlar to'g'risida"gi qonuni).
