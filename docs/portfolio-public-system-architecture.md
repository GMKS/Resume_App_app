# Public Portfolio System

## Executive Summary

The current Portfolio module is a local, resume-adjacent sharing surface inside the Flutter app. It can derive a URL from resume content, generate a QR code, and expose resume-linked projects/certificates, but it does not publish a recruiter-facing portfolio experience. As a result, `Copy Link`, `Share`, and `QR Code` do not produce a durable public asset with real hiring value.

The recommended solution is to add a public portfolio publishing system that is:

- additive to the existing Resume Builder flows
- owned by Firebase Auth + Firestore + Storage + Functions/Hosting
- compatible with the existing premium/subscription model
- recruiter-facing, browser-native, mobile-responsive, and SEO-aware
- safe for backward compatibility with current resumes, exports, backups, subscriptions, and AI features

This should not replace the current resume model. It should project a selected resume into a public portfolio document and website.

## Current State Assessment

### What exists today

- The in-app Portfolio UI lives in [lib/features/portfolio/screens/portfolio_tab_screen.dart](c:/Resume_App_app/lib/features/portfolio/screens/portfolio_tab_screen.dart).
- The current URL logic lives in [lib/features/portfolio/services/portfolio_profile_service.dart](c:/Resume_App_app/lib/features/portfolio/services/portfolio_profile_service.dart).
- The module is local-device driven and stores supplemental portfolio data in `SharedPreferences` through `StorageService.prefs`.
- Cloud infrastructure already exists for authenticated user data via Firebase Auth and Firestore in [lib/core/services/supabase_sync_service.dart](c:/Resume_App_app/lib/core/services/supabase_sync_service.dart).
- Firestore rules already protect user-owned data in [firestore.rules](c:/Resume_App_app/firestore.rules).
- Premium gating already exists in [lib/core/models/subscription_model.dart](c:/Resume_App_app/lib/core/models/subscription_model.dart) and [lib/core/services/free_plan_service.dart](c:/Resume_App_app/lib/core/services/free_plan_service.dart).

### What does not exist yet

- No public portfolio entity
- No persistent public URL
- No portfolio hosting layer
- No recruiter-facing page
- No portfolio-specific analytics
- No visibility/privacy model
- No custom slug support
- No password protection or recruiter-only share links
- No canonical portfolio storage in Firestore
- No public document projection for safe anonymous reads

## Product Architecture

### Recommended product model

Treat `Portfolio` as a published projection of a selected resume plus optional portfolio-specific metadata.

The selected resume remains the source of truth for:

- personal info
- summary
- skills
- experience
- education
- projects
- certifications
- resume download content

The portfolio layer adds:

- public ID / slug
- publication state
- privacy/visibility
- theme selection
- password protection metadata
- recruiter link tokens
- analytics counters
- optional overrides such as headline, CTA text, featured order, and custom branding

## Deliverable 1: Flutter UI Changes

### Existing screen to evolve

- [lib/features/portfolio/screens/portfolio_tab_screen.dart](c:/Resume_App_app/lib/features/portfolio/screens/portfolio_tab_screen.dart)

### Keep

- selected resume source
- copy link
- share
- QR code
- project/certification rendering

### Remove or merge

- remove `Portfolio Highlights`
- merge `Uploaded Certificates` into unified `Certifications`

### New in-app Portfolio control center

The Portfolio tab should become a publishing dashboard with these sections:

1. Portfolio Source
- resume selector
- active source resume badge
- last published timestamp

2. Public Portfolio Status
- active/inactive toggle
- visibility selector: `public`, `private`, `password_protected`, `recruiter_link`
- current URL card
- regenerate link
- edit custom slug for premium

3. Share Actions
- copy public URL
- share portfolio URL
- download QR
- share QR
- add QR to resume PDF

4. Recruiter Preview
- open public page in browser
- preview hero header
- preview contact CTA

5. Completeness Score
- score percentage
- missing-field checklist
- action suggestions

6. Analytics Summary
- total views
- unique visitors
- downloads
- shares
- QR scans

### New Flutter files

- `lib/features/portfolio/models/portfolio_public_model.dart`
- `lib/features/portfolio/models/portfolio_visibility.dart`
- `lib/features/portfolio/models/portfolio_analytics_model.dart`
- `lib/features/portfolio/services/portfolio_publication_service.dart`
- `lib/features/portfolio/services/portfolio_repository.dart`
- `lib/features/portfolio/services/portfolio_completeness_service.dart`
- `lib/features/portfolio/services/portfolio_share_service.dart`
- `lib/features/portfolio/providers/portfolio_provider.dart`
- `lib/features/portfolio/widgets/portfolio_status_card.dart`
- `lib/features/portfolio/widgets/portfolio_visibility_sheet.dart`
- `lib/features/portfolio/widgets/portfolio_completeness_card.dart`
- `lib/features/portfolio/widgets/portfolio_analytics_card.dart`

### Minimal change principle

Do not alter:

- resume editing flows
- export flows
- AI flows
- backup and restore flows
- subscription purchase flows

Portfolio should read from resumes and publish outward. It should not re-own the resume domain model.

## Deliverable 2: Firebase Schema

### Canonical collections

```text
users/{uid}
users/{uid}/resumes/{resumeId}
users/{uid}/portfolio_settings/default
users/{uid}/portfolios/{portfolioId}

portfolios/{portfolioId}
portfolio_slugs/{slug}
portfolios/{portfolioId}/analytics/{eventId}
portfolios/{portfolioId}/daily_stats/{yyyyMMdd}
```

### Why dual storage

- `users/{uid}/portfolios/{portfolioId}` is the owner/canonical document with private controls.
- `portfolios/{portfolioId}` is the public projection document optimized for public rendering.
- `portfolio_slugs/{slug}` enforces global uniqueness for custom URLs.

### Suggested `users/{uid}/portfolios/{portfolioId}` shape

```json
{
  "portfolioId": "pf_01JZ...",
  "ownerUid": "uid_123",
  "resumeId": "resume_abc",
  "status": "active",
  "visibility": "public",
  "slug": null,
  "defaultPath": "/p/pf_01JZ...",
  "publicUrl": "https://portfolio.resumix.ai/p/pf_01JZ...",
  "themeId": "basic_light",
  "customBrandingEnabled": false,
  "passwordProtected": false,
  "passwordHash": null,
  "recruiterLinkEnabled": false,
  "allowResumeDownload": true,
  "allowContact": true,
  "allowAnalytics": true,
  "publishedAt": "server_timestamp",
  "lastRepublishedAt": "server_timestamp",
  "lastViewedAt": null,
  "createdAt": "server_timestamp",
  "updatedAt": "server_timestamp",
  "completenessScore": 82,
  "missingFields": ["profile_photo", "linkedin"],
  "stats": {
    "views": 0,
    "uniqueVisitors": 0,
    "resumeDownloads": 0,
    "qrScans": 0,
    "shares": 0
  },
  "overrides": {
    "headline": null,
    "about": null,
    "contactCta": null,
    "featuredProjectIds": []
  }
}
```

### Suggested `portfolios/{portfolioId}` public projection shape

```json
{
  "portfolioId": "pf_01JZ...",
  "ownerUid": "uid_123",
  "status": "active",
  "visibility": "public",
  "slug": null,
  "publicUrl": "https://portfolio.resumix.ai/p/pf_01JZ...",
  "themeId": "basic_light",
  "seo": {
    "title": "Jane Doe | Senior Product Designer",
    "description": "Portfolio of Jane Doe, Senior Product Designer",
    "ogImageUrl": "https://.../portfolio_og/pf_01JZ....png"
  },
  "profile": {
    "fullName": "Jane Doe",
    "title": "Senior Product Designer",
    "location": "Bengaluru, India",
    "photoUrl": "https://..."
  },
  "summary": "...",
  "skills": [
    { "name": "Figma", "category": "Design" }
  ],
  "experience": [],
  "projects": [],
  "education": [],
  "certifications": [],
  "contact": {
    "email": "masked-or-public-email@...",
    "linkedIn": "https://linkedin.com/in/...",
    "github": "https://github.com/...",
    "website": "https://..."
  },
  "resume": {
    "downloadUrl": "https://.../resume.pdf",
    "updatedAt": "server_timestamp"
  },
  "flags": {
    "allowResumeDownload": true,
    "allowContact": true
  },
  "publishedAt": "server_timestamp",
  "updatedAt": "server_timestamp"
}
```

### Analytics model

Use raw events plus aggregate counters.

Raw events:

```text
portfolios/{portfolioId}/analytics/{eventId}
```

Aggregate stats:

```text
portfolios/{portfolioId}/daily_stats/{yyyyMMdd}
```

Example event:

```json
{
  "type": "view",
  "source": "direct",
  "visitorHash": "sha256(ip+ua+salt)",
  "userAgent": "stored only if policy allows",
  "referer": "https://linkedin.com/...",
  "country": "IN",
  "city": "Bengaluru",
  "createdAt": "server_timestamp"
}
```

## Deliverable 3: Firestore Rules

### Rule strategy

1. Owner docs are readable/writable only by the authenticated owner.
2. Public portfolio projection docs are readable anonymously only when `status == active` and `visibility == public`.
3. Password-protected and recruiter-link portfolios should not expose full content through direct Firestore reads. Those must be served through a backend endpoint.
4. Analytics writes should not be directly client-writable from anonymous web pages. Use Cloud Functions or a server endpoint to sanitize and aggregate.

### Recommended rules extension

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function signedIn() {
      return request.auth != null;
    }

    function ownsUser(userId) {
      return signedIn() && request.auth.uid == userId;
    }

    match /users/{userId} {
      allow read, write: if ownsUser(userId);

      match /resumes/{resumeId} {
        allow read, write: if ownsUser(userId);
      }

      match /portfolios/{portfolioId} {
        allow read, write: if ownsUser(userId);
      }

      match /portfolio_settings/{docId} {
        allow read, write: if ownsUser(userId);
      }
    }

    match /portfolios/{portfolioId} {
      allow read: if resource.data.status == 'active'
        && resource.data.visibility == 'public';
      allow create, update, delete: if signedIn()
        && request.resource.data.ownerUid == request.auth.uid;

      match /analytics/{eventId} {
        allow read: if signedIn() && resource.data.ownerUid == request.auth.uid;
        allow write: if false;
      }

      match /daily_stats/{dayId} {
        allow read: if signedIn() && resource.data.ownerUid == request.auth.uid;
        allow write: if false;
      }
    }

    match /portfolio_slugs/{slug} {
      allow read: if false;
      allow write: if signedIn();
    }
  }
}
```

### Important note

Do not rely on Firestore rules alone for password-protected and recruiter-only access. Those cases need a server-controlled access flow.

## Deliverable 4: API Architecture

### Recommended backend layer

Use Firebase Functions 2nd gen for portfolio publication and analytics because:

- Firestore already exists in the app
- Firebase Auth already exists in the app
- public web access and analytics need controlled server logic
- privacy modes need server-enforced access decisions

### Functions to add

1. `createPortfolioFromResume`
- input: `resumeId`
- output: `portfolioId`, `publicUrl`
- responsibilities:
  - ensure auth
  - generate unique ID
  - project resume into public portfolio doc
  - generate default URL

2. `updatePortfolioSettings`
- input: visibility, theme, allow download, allow contact, slug
- output: updated metadata
- responsibilities:
  - validate premium-only settings
  - reserve slug when premium
  - update projection doc

3. `regeneratePortfolioLink`
- input: `portfolioId`
- output: new URL
- responsibilities:
  - rotate recruiter token if applicable
  - optionally rotate public ID for privacy reset

4. `publishPortfolio`
- input: `portfolioId`
- output: published URL
- responsibilities:
  - compute completeness score
  - render public projection
  - generate QR payload
  - optionally trigger OG image generation

5. `trackPortfolioEvent`
- input: event type (`view`, `download_resume`, `share`, `qr_scan`, `contact_click`)
- output: accepted flag
- responsibilities:
  - sanitize referer/user-agent
  - dedupe unique visitors
  - update daily aggregates

6. `validatePortfolioAccess`
- input: portfolio ID + password or recruiter token
- output: signed access token / short-lived session
- responsibilities:
  - handle password-protected and recruiter-only visibility

7. `renderPortfolioMeta`
- input: slug or portfolioId
- output: title, description, OG image metadata
- responsibilities:
  - support crawler previews and social sharing

### Public page access model

- `public`: static/SSR page can read public projection directly
- `private`: public route renders unavailable page
- `password_protected`: page requests password, backend validates, then returns authorized payload
- `recruiter_link`: URL contains signed token or path-bound access code, backend validates before serving data

## Deliverable 5: Hosting Strategy

### Recommended approach

Use a dedicated recruiter-facing web surface at:

- `https://portfolio.resumix.ai/p/{portfolioId}`
- `https://portfolio.resumix.ai/{username}` for premium custom URLs

### Do not use Flutter Web as the public portfolio renderer

For SEO, social previews, and recruiter link quality, the public site should be server-rendered or prerendered HTML, not a Flutter web shell.

### Recommended stack

- Firebase Hosting for domain and edge delivery
- Next.js on Firebase App Hosting or Hosting + Cloud Run SSR
- Firestore as data source
- Firebase Storage for profile photos, certificate attachments, QR PNGs, OG images, and exported resume PDFs

### Why this is the right split

- Flutter app remains the authenticated creator experience
- public portfolio website becomes a browser-first recruiter experience
- social crawlers can read proper meta tags
- WhatsApp/LinkedIn previews become reliable

## Deliverable 6: Analytics Implementation

### Metrics to track

- portfolio views
- unique visitors
- resume downloads
- QR scans
- share actions
- contact button clicks
- project link clicks

### Event pipeline

1. Public page emits event request to `trackPortfolioEvent`
2. Function validates event shape and enriches metadata
3. Function writes raw event + increments aggregates
4. Flutter owner dashboard reads aggregate counters only

### Owner dashboard UI

Add to Portfolio tab:

- views last 7 days
- unique visitors last 7 days
- resume download count
- top referrers
- latest views timeline for premium

## Deliverable 7: Public Portfolio Page Design

### Page sections

1. Hero Header
- profile photo
- full name
- professional title
- location
- primary CTA: `Contact`
- secondary CTA: `Download Resume`

2. About
- professional summary

3. Skills
- grouped chips by category when available

4. Work Experience
- company
- role
- duration
- top responsibilities/achievements

5. Projects
- project name
- description
- technologies
- live link
- GitHub link

6. Education

7. Certifications
- name
- issuer
- issue date
- verification link
- optional attachment preview/download

8. Contact Links
- email
- LinkedIn
- GitHub
- website

9. Resume Download

### UX requirements

- mobile first
- recruiter-readable typography
- low-friction CTA placement
- accessible color contrast
- printable section layout
- no login requirement for public viewing

### SEO requirements

- unique title per portfolio
- meta description per portfolio
- Open Graph tags
- Twitter card tags
- canonical URL
- share preview image

## Deliverable 8: Database Migration Plan

### Phase 0: No-breaking migration

Keep current local Portfolio screen working until the public system is live.

### Phase 1: Introduce new schema behind feature flag

- add Firestore portfolio collections
- add Functions
- add hosting app
- keep current local-only link logic as fallback

### Phase 2: Migrate local supplemental data

Current local-only keys in [lib/features/portfolio/screens/portfolio_tab_screen.dart](c:/Resume_App_app/lib/features/portfolio/screens/portfolio_tab_screen.dart):

- `portfolio_projects`
- `portfolio_certificates`
- `portfolio_selected_resume_id`

Migration steps:

1. on first open after upgrade, read local data
2. create owner portfolio doc
3. write supplemental manual certificates/projects into Firestore owner doc
4. mark local migration complete in preferences
5. keep reading local fallback for one release as safety

### Phase 3: Public projection generation

- derive public content from selected resume + migrated extras
- write `portfolios/{portfolioId}`
- generate QR / OG / resume asset URLs

### Phase 4: Deprecate legacy link derivation

Replace `PortfolioProfileService.resolvePortfolioUrl(...)` as the copy/share source with the published portfolio URL once the new backend is enabled.

## Deliverable 9: Premium Monetization Plan

### Current reality

Portfolio is currently effectively premium-gated through the existing subscription model.

### Recommended entitlement split

Additive feature flags:

- `portfolio_public_basic`
- `portfolio_qr_basic`
- `portfolio_resume_download_basic`
- `portfolio_custom_slug`
- `portfolio_password_protection`
- `portfolio_analytics_advanced`
- `portfolio_custom_branding`
- `portfolio_multiple_versions`

### Free tier

- one active public portfolio
- default generated URL
- basic theme
- QR code
- resume download
- basic contact links

### Premium tier

- custom slug
- advanced themes
- password protection
- recruiter-only links
- analytics dashboard
- visit tracking
- custom branding
- multiple portfolio versions per user

### Backward compatibility for subscriptions

Grant all new portfolio entitlements automatically to existing premium users.

## Deliverable 10: Production-Ready Implementation Roadmap

### Sprint 1: Data + backend foundation

- create portfolio models
- add Firestore collections
- add Functions for create/update/publish/regenerate
- add Storage buckets/folders
- add feature flags

### Sprint 2: Flutter publishing dashboard

- replace current local link card with publish state card
- add visibility controls
- add copy/share/regenerate URL actions
- add completeness score
- add migration of local extras

### Sprint 3: Public web app

- implement SSR portfolio page
- implement public routing by ID and slug
- add SEO/meta tags
- add OG image generation
- add resume download

### Sprint 4: Privacy + recruiter access

- password protected flow
- recruiter token link flow
- deactivate/reactivate portfolio
- portfolio versioning for premium

### Sprint 5: Analytics

- event capture
- aggregation
- owner dashboard cards
- premium advanced analytics

### Sprint 6: Hardening

- load testing for public portfolio traffic
- abuse protection / rate limits
- audit Firestore rules
- audit hosting headers and cache settings
- QA for migration, publish/unpublish, and subscription entitlement edges

## Required Code Changes by Area

### Flutter app

- evolve [lib/features/portfolio/screens/portfolio_tab_screen.dart](c:/Resume_App_app/lib/features/portfolio/screens/portfolio_tab_screen.dart)
- add repository/services/providers for portfolio publication
- keep resume source selection intact

### Firebase rules

- extend [firestore.rules](c:/Resume_App_app/firestore.rules)

### Firebase configuration

- extend [firebase.json](c:/Resume_App_app/firebase.json) with hosting/app hosting config

### Cloud backend

- add `functions/src/portfolio/*` or equivalent Firebase Functions workspace

### Public web frontend

- create a dedicated `portfolio-web/` app or similar hosted SSR package

## Non-Negotiable Backward Compatibility Rules

1. Resume documents remain unchanged as the source of truth.
2. Export flows continue to operate independently of portfolio publication.
3. AI, subscriptions, and backup flows remain unaffected.
4. Existing users without portfolio setup should not see broken links.
5. Legacy local portfolio data should migrate forward without data loss.

## Recommended First Build Slice

If implementation starts immediately, the first production slice should be:

1. publish/unpublish one public portfolio per user
2. generated `portfolioId` URL only
3. public browser page with hero/about/skills/experience/projects/certifications
4. copy/share/QR backed by real public URL
5. resume download
6. completeness score

That slice delivers real recruiter value quickly while keeping privacy modes, custom slugs, and advanced analytics for follow-up sprints.