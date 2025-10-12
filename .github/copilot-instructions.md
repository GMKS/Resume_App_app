# Copilot instructions for this repo

Flutter app for building resumes with multiple templates (Classic, Modern, Minimal, Professional, Creative, One Page). Exports/share via PDF/DOCX/TXT. Optional Node.js backend for auth/cloud saves/OTP.

## Big picture architecture

- Data model: `SavedResume` wraps a flexible `data` map; templates read different keys. See `lib/models/saved_resume.dart`.
- UI: Forms and previews live under `lib/screens/…` (ex: `one_page_resume_form_screen.dart`, `one_page_resume_preview.dart`). Reusable inputs in `lib/widgets/…` (dynamic sections, skills pickers, export options).
- Services: Cross-cutting logic under `lib/services/…`:
  - PDF export: `share_export_service.dart` orchestrates routing and sharing; template exporters like `one_page_pdf_exporter.dart`, `classic_pdf_exporter.dart`, `colorful_minimal_pdf_exporter.dart` mirror preview layout.
  - Cloud API: `node_api_service.dart` with base URL via `--dart-define=API_BASE_URL=…`, token stored with `shared_preferences`.
  - Premium gating: `premium_service.dart` controls features/templates; use `PremiumService.isPremiumWithDialog` before gated actions.

## Key data shapes and conventions

- One Page template stores structured sections as JSON strings in `data`:
  - `workExperiencesJson`: array of `{ jobTitle, company, location, startDate, endDate, description, achievements? }`
  - `educationsJson`: array of `{ degree, institution|university|school, startDate, endDate, description? }`
- Skills inputs vary by template: One Page uses comma CSV `coreSkills`; others may use `skills` or `skillsCsv` (string or array). Exporters try multiple keys.
- Contact/social keys: `linkedIn` or `linkedin` accepted; include `portfolio` where present. Dates prefer ISO; render compact as `yyyy-MM – yyyy-MM` or `Present`.
- Images: For One Page, `profilePhotoBase64` should be raw base64 (no data URI prefix). Creative template exporter strips a prefix if present.

## Export/share flow (what runs where)

- Callers use `ShareExportService.exportAndOpenPdf(resume)` or `shareViaEmail/WhatsApp`.
- Routing: Colorful Minimal → `ColorfulMinimalPdfExporter`; One Page → `OnePagePdfExporter`; Classic → `ClassicPdfExporter`; otherwise a generic fallback.
- Fallbacks: If styled export fails, a generic PDF is created; final fallback is a minimal single-font PDF built from `_buildPlainTextForDoc` (good for ATS/text-mode). TXT export UI also advertises ATS-friendly content.
- One Page PDF mirrors preview: left rail ~220px with contact/education/skills/awards; right content with name/title, profile, and experience.
- Sharing: Uses `share_plus`; WhatsApp has a URL-launch fallback (see `ShareExportService._launchWhatsAppFallback`).

## Build/run and debugging

- Run with cloud API: VS Code task “Flutter: Run (Cloud API)” or `flutter run --dart-define=API_BASE_URL=https://resume-builder-api-8kc0.onrender.com/api`.
 - Run with local API: `flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3001/api` (replace 127.0.0.1 with your PC IP for Android devices).
- Build APK: task “Flutter: Build APK (Cloud API) [release]”.
- Entry point `lib/main.dart` boots UI quickly then initializes services in parallel (currency, premium, API, storage).
- Saved list (`saved_resumes_screen.dart`) is the hub for Edit/Preview/Export/Share. Watch console “DEBUG:” logs in `ShareExportService` during export failures.

## Patterns to follow (and pitfalls to avoid)

- When adding/modifying One Page fields, update both preview (`one_page_resume_preview.dart`) and PDF (`one_page_pdf_exporter.dart`). Keep JSON controllers in sync in forms (`workExperiencesJson`, `educationsJson`).
- Exporters are tolerant to key variants (e.g., `skills` vs `skillsCsv` vs `coreSkills`; `linkedIn` vs `linkedin`), but keep new fields consistent across preview and exporter.
- Premium gating: Before enabling export/share/AI-only features, check `PremiumService.isPremium` and surface `PremiumService.showUpgradeDialog` when needed.
- Template names vary in switches (e.g., "One Page" vs identifiers elsewhere). Match existing switch cases in `ShareExportService` and screens when adding a template.

## Extending the app

- New template: add form/preview under `lib/screens`, create a styled exporter under `lib/services`, and add routing in `ShareExportService._generatePdf`. Mirror preview layout in exporter.
- Cloud API usage: configure `API_BASE_URL` via dart-define; see `README.md` and `server.js` for local/dev server and deployment tips.

Questions or gaps? If other templates’ field keys or flows are unclear, call them out and we’ll expand this guide.
