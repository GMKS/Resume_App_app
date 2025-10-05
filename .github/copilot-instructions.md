# Copilot instructions for this repo

This Flutter app builds resumes with multiple templates (Modern, Classic, Minimal, Professional, Creative, One Page) and can export/share as PDF/DOCX/TXT. The app also supports a Node.js backend for cloud saves and OTP.

## How the app is structured

- lib/models: domain models, e.g. `saved_resume.dart`
- lib/screens: UI flows for creating, editing, previewing resumes. Each template has a form screen and some have a preview screen (e.g., `one_page_resume_form_screen.dart`, `one_page_resume_preview.dart`).
- lib/services: cross-cutting services for persistence, export/share, AI assistance, OTP, etc. One-page PDF generation is `services/one_page_pdf_exporter.dart`. Generic export is `services/share_export_service.dart`.
- widgets/: reusable input controls and form sections (skills picker, dynamic work/education sections, requirements banner, etc.).

## Key data shape

- A resume is `SavedResume` with a free-form `data` map holding fields used by different templates.
- One Page template stores structured sections in JSON strings:
  - `workExperiencesJson`: JSON array of items with keys `{ jobTitle, company, location, startDate, endDate, description, achievements? }`
  - `educationsJson`: JSON array with `{ degree, institution|university|school, startDate, endDate, description? }`
- Skills are CSV for One Page (`coreSkills`); other templates may use `skills`, `skillsCsv`, or arrays.

## Render/Export flow

- Preview widgets render native Flutter UI (e.g., `one_page_resume_preview.dart`).
- Export and Share go through `ShareExportService`:
  - `exportAndOpenPdf(resume)` routes by template; One Page uses `OnePagePdfExporter` for styled PDF if `ats_friendly` is not set.
  - If `ats_friendly == 'true'`, a minimal single-font PDF is created for ATS parsing.
  - Email/WhatsApp share call `share_plus` with the generated PDF.
- One Page styled PDF exporter mirrors the preview layout: left rail ~220px with contact, education, skills, awards; right content with banner (name/title), profile, and experience.

## Common pitfalls and conventions

- When adding fields for One Page, update both preview (`one_page_resume_preview.dart`) and PDF (`one_page_pdf_exporter.dart`). Keep keys consistent: `linkedIn` or `linkedin` both accepted; include `portfolio` when present.
- The minimal ATS export now reads One Page specifics: `coreSkills`, `workExperiencesJson`, `educationsJson`, `awards`, `languages`, `portfolio`.
- Date ranges prefer ISO strings; format compact as `yyyy-MM – yyyy-MM` or `Present`.
- Keep hidden JSON controllers in sync in the One Page form (`workExperiencesJson`, `educationsJson`). The form writes these on change for save/export.

## Build, run, and preview

- Local run (with cloud API): VS Code Task "Flutter: Run (Cloud API)" or:
  - `flutter run --dart-define=API_BASE_URL=https://resume-builder-api-8kc0.onrender.com/api`
- Build APK release (cloud API): Task "Flutter: Build APK (Cloud API) [release]".
- Saved resumes list (`saved_resumes_screen.dart`) provides menu actions: Edit, Save, Export (PDF/DOCX/TXT), Preview, Share (Email/WhatsApp), Print.
- Premium gating: actions like Export/Preview/Share check `PremiumService.isPremium`; use `PremiumService.showUpgradeDialog` for gating.

## External services

- PDF generation uses `pdf` package for styled exports; a hand-rolled minimal writer is used in `ShareExportService` for ATS-friendly mode.
- Sharing uses `share_plus`.
- Cloud API base URL is passed with `--dart-define=API_BASE_URL=...` and read in `node_api_service.dart`.

## Examples and patterns

- One Page preview builds a left rail + right content layout and splits comma CSV into chips/bullets; PDF mirrors this. See:
  - `lib/screens/one_page_resume_preview.dart`
  - `lib/services/one_page_pdf_exporter.dart`
- To add a new template:
  - Create form and preview screens under `lib/screens/`.
  - Add a styled exporter under `lib/services/` and route in `ShareExportService.exportAndOpenPdf`.
  - Update selection and saved list switch statements to include the new template.

## Testing/debug tips

- If Preview and Export differ, compare the preview widget and exporter side-by-side and align field names and section ordering. For One Page, keep the rail width near 220 to match layout.
- Use `SavedResumesScreen` → Preview to verify visual layout, then Export PDF and open to compare.
- For ATS-friendly checks, toggle the switch in the One Page form (`ats_friendly`).

If anything here is unclear or you need more conventions documented (e.g., other templates’ field keys), ask for specifics and we’ll expand this guide.
