$ErrorActionPreference = 'Stop'

$workspaceRoot = $PSScriptRoot
$csvPath = Join-Path $workspaceRoot 'resume_app_comprehensive_test_case_sheet.csv'
$xlsxPath = Join-Path $workspaceRoot 'resume_app_comprehensive_test_case_sheet.xlsx'
$summaryPath = Join-Path $workspaceRoot 'resume_app_comprehensive_test_case_sheet_summary.md'

$requiredColumns = @(
  'S.No',
  'Test Case ID',
  'Test Case Title / Name',
  'Feature Area',
  'Module Name',
  'Testing Type',
  'Testing Type Classification',
  'Scenario Variant',
  'Preconditions',
  'Test Steps',
  'Test Data',
  'Expected Result',
  'Actual Result',
  'Test Status',
  'Priority',
  'Severity',
  'Platforms',
  'Automation Candidate',
  'Defect ID / Link',
  'Defect Summary / Notes'
)

$scenarioVariants = @(
  [ordered]@{
    Name = 'Primary Flow'
    DataKey = 'CoreData'
    PreconditionNote = 'Latest supported build is installed, the user can reach the target feature from a clean app state, and all normal dependencies are available.'
    ExecutionLens = 'complete the intended workflow with valid input and standard user actions'
    OutcomePrefix = 'the primary scenario completes cleanly and'
  },
  [ordered]@{
    Name = 'Boundary & Validation'
    DataKey = 'EdgeData'
    PreconditionNote = 'The tester can submit missing, invalid, oversized, or boundary input values and observe validation responses safely.'
    ExecutionLens = 'challenge required fields, boundary values, and invalid combinations without corrupting saved data'
    OutcomePrefix = 'validation and guardrails work correctly and'
  },
  [ordered]@{
    Name = 'Failure & Recovery'
    DataKey = 'EdgeData'
    PreconditionNote = 'The tester can simulate dependency delay, network interruption, permission denial, expired session state, or transient service failure.'
    ExecutionLens = 'interrupt the flow and verify recovery, retry, or rollback behavior'
    OutcomePrefix = 'failures are handled safely and'
  },
  [ordered]@{
    Name = 'Persistence & Restore'
    DataKey = 'CoreData'
    PreconditionNote = 'The tester can save progress, reload the app or screen, and compare stored state before and after restoration.'
    ExecutionLens = 'save progress, leave and re-enter the flow, and confirm state restoration across app restarts or route changes'
    OutcomePrefix = 'saved data is restored correctly and'
  },
  [ordered]@{
    Name = 'Cross-Platform & Locale'
    DataKey = 'CoreData'
    PreconditionNote = 'Supported device, browser, viewport, and locale combinations are available for the module under test.'
    ExecutionLens = 'repeat the same business intent across supported platforms, responsive sizes, and locale settings'
    OutcomePrefix = 'behavior stays consistent across supported environments and'
  }
)

$testTypes = @(
  [ordered]@{
    Name = 'Functional Testing'
    Classification = 'Business Workflow Coverage'
    Focus = 'Validate the module fulfills its intended business goal with correct state changes and user-visible output.'
    ExpectedLens = 'the business outcome remains correct for the feature boundary'
    Priority = 'High'
    FillRgb = 'FFE3F2FD'
  },
  [ordered]@{
    Name = 'UI Testing'
    Classification = 'Visual and Interaction Coverage'
    Focus = 'Validate layout, control visibility, spacing, visual hierarchy, state presentation, and interaction affordances.'
    ExpectedLens = 'the interface remains clear, stable, and visually correct'
    Priority = 'Medium'
    FillRgb = 'FFF3E8FF'
  },
  [ordered]@{
    Name = 'Regression Testing'
    Classification = 'Change Safety Coverage'
    Focus = 'Validate previously working behavior after code, content, dependency, or configuration changes.'
    ExpectedLens = 'existing behavior remains intact after change'
    Priority = 'High'
    FillRgb = 'FFFFF7D6'
  },
  [ordered]@{
    Name = 'Integration Testing'
    Classification = 'Cross-Component Workflow Coverage'
    Focus = 'Validate the feature across connected screens, providers, storage, third-party services, and navigation boundaries.'
    ExpectedLens = 'connected systems stay synchronized and accurate'
    Priority = 'High'
    FillRgb = 'FFE8F5E9'
  },
  [ordered]@{
    Name = 'API Testing'
    Classification = 'Service Contract Coverage'
    Focus = 'Validate request payloads, response handling, retry logic, timeout behavior, and error mapping for network-backed flows.'
    ExpectedLens = 'service contracts and error handling remain reliable'
    Priority = 'High'
    FillRgb = 'FFFFE0B2'
  },
  [ordered]@{
    Name = 'Compatibility Testing'
    Classification = 'Platform and Environment Coverage'
    Focus = 'Validate supported device, browser, OS, viewport, and hardware combinations without behavioral drift.'
    ExpectedLens = 'supported environments behave consistently'
    Priority = 'High'
    FillRgb = 'FFE0F2F1'
  },
  [ordered]@{
    Name = 'Performance Testing'
    Classification = 'Speed and Scalability Coverage'
    Focus = 'Validate response time, rendering smoothness, memory trend, and resource usage under expected and stretched conditions.'
    ExpectedLens = 'performance remains within acceptable limits'
    Priority = 'High'
    FillRgb = 'FFFFE4E6'
  },
  [ordered]@{
    Name = 'Security Testing'
    Classification = 'Security and Privacy Coverage'
    Focus = 'Validate access control, sensitive data handling, token usage, session security, file safety, and abuse resistance.'
    ExpectedLens = 'data and privileged actions remain protected'
    Priority = 'High'
    FillRgb = 'FFFFCDD2'
  },
  [ordered]@{
    Name = 'Usability Testing'
    Classification = 'Task Clarity Coverage'
    Focus = 'Validate discoverability, learnability, guidance, friction level, and ease of task completion for a realistic user.'
    ExpectedLens = 'the task remains easy to understand and complete'
    Priority = 'Medium'
    FillRgb = 'FFF5F3FF'
  },
  [ordered]@{
    Name = 'Accessibility Testing'
    Classification = 'Inclusive Interaction Coverage'
    Focus = 'Validate semantics, focus order, screen reader compatibility, keyboard use, contrast, and text scaling support.'
    ExpectedLens = 'the feature remains usable with assistive and adaptive inputs'
    Priority = 'High'
    FillRgb = 'FFEDE9FE'
  },
  [ordered]@{
    Name = 'Localization Testing'
    Classification = 'Language and Locale Coverage'
    Focus = 'Validate translated strings, locale formatting, mixed-language content, and text expansion in supported locales.'
    ExpectedLens = 'locale-sensitive content renders correctly'
    Priority = 'Medium'
    FillRgb = 'FFE8EAF6'
  },
  [ordered]@{
    Name = 'End-to-End Testing'
    Classification = 'Full User Journey Coverage'
    Focus = 'Validate the complete user journey from entry point to final outcome with realistic cross-screen state and data flow.'
    ExpectedLens = 'the complete journey succeeds without broken handoffs'
    Priority = 'High'
    FillRgb = 'FFDCFCE7'
  }
)

$modules = @(
  [ordered]@{ Area = 'Core App'; Name = 'App Bootstrap & Splash'; Navigation = 'launch the app from a cold start'; Action = 'observe initialization, dependency setup, cached state restore, and startup routing'; CoreData = 'valid cached preferences, existing local resumes, and normal device permissions'; EdgeData = 'missing preferences, delayed storage readiness, revoked permissions, and dependency startup lag'; Outcome = 'startup completes without blocking defects and routes the user to the correct next screen'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Core App'; Name = 'Onboarding Flow'; Navigation = 'open the onboarding experience as a first-time user'; Action = 'advance, skip, resume, and complete onboarding steps'; CoreData = 'fresh install state, default locale, and valid first-run preferences'; EdgeData = 'interrupted onboarding state, rotated screens, and partially completed walkthrough progress'; Outcome = 'onboarding progress persists correctly and users can continue to the intended app entry point'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Authentication'; Name = 'Phone / Twilio Authentication'; Navigation = 'open the phone sign-in flow'; Action = 'enter a phone number, request OTP, verify the OTP, and continue into the app'; CoreData = 'valid phone number, valid OTP, and reachable auth service'; EdgeData = 'invalid phone format, expired OTP, wrong OTP, timeout, and denied SMS retrieval permissions'; Outcome = 'authentication succeeds for valid input and provides safe recovery for invalid or interrupted flows'; Platforms = 'Android, iOS, Web' },
  [ordered]@{ Area = 'Authentication'; Name = 'Social Authentication'; Navigation = 'open the social sign-in options'; Action = 'authenticate with Google or Facebook and return to the app'; CoreData = 'valid provider account, valid consent flow, and successful callback'; EdgeData = 'user-cancelled consent, provider SDK failure, missing config, expired session, and callback interruption'; Outcome = 'social authentication is reliable, secure, and routes the user to the correct post-login screen'; Platforms = 'Android, iOS, Web' },
  [ordered]@{ Area = 'Dashboard'; Name = 'Dashboard Home & Shortcuts'; Navigation = 'open the dashboard after startup or login'; Action = 'review stats, shortcuts, recent activity, and tab entry points'; CoreData = 'populated resume data, active subscription state, and valid local preferences'; EdgeData = 'empty-state data, stale badges, slow data hydration, and mixed sync states'; Outcome = 'dashboard widgets remain accurate, responsive, and route to the correct destinations'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Resume Management'; Name = 'Resume List & Search'; Navigation = 'open the resumes tab or home list'; Action = 'view, search, filter, and sort saved resumes'; CoreData = 'multiple resumes with distinct titles, templates, and updated dates'; EdgeData = 'no resumes, duplicate titles, long titles, and partially synced records'; Outcome = 'resume listing remains accurate, searchable, and stable across state changes'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Resume Management'; Name = 'Resume Creation & Duplication'; Navigation = 'start a new resume or duplicate an existing resume'; Action = 'create a resume, prefill defaults, and duplicate selected data into a new record'; CoreData = 'valid default profile data and an existing resume available for duplication'; EdgeData = 'long titles, duplicate names, interrupted save, and missing optional defaults'; Outcome = 'new resumes are created correctly with the right initial metadata and no data bleed'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Resume Management'; Name = 'Resume Card Actions'; Navigation = 'open a screen that shows resume cards'; Action = 'open, rename, duplicate, delete, share, and preview a resume from its card actions'; CoreData = 'single and multiple saved resumes with complete metadata'; EdgeData = 'rapid repeated taps, deleted backing record, and stale card state after mutations'; Outcome = 'card actions remain accurate, idempotent where needed, and consistent with stored data'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Editor'; Name = 'Resume Editor Shell'; Navigation = 'open the resume editor for an existing or newly created resume'; Action = 'move between sections, save progress, reorder sections, and use top-level customization actions'; CoreData = 'partially completed resume with standard section order and theme settings'; EdgeData = 'many sections, rapid navigation, unsaved changes, and reordered section persistence'; Outcome = 'the editor shell preserves state, navigation, and data integrity across editing actions'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Editor'; Name = 'Personal Information Section'; Navigation = 'open the Personal Information section in the editor'; Action = 'add and edit name, title, contact details, links, and profile image data'; CoreData = 'valid names, phone numbers, emails, URLs, and address values'; EdgeData = 'invalid emails, malformed URLs, oversized images, missing required values, and non-Latin text'; Outcome = 'personal details validate, persist, and render correctly across editor and preview flows'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Editor'; Name = 'Professional Summary Section'; Navigation = 'open the Professional Summary section'; Action = 'create, refine, clear, and re-save summary content'; CoreData = 'short and medium-length summary text with valid characters'; EdgeData = 'empty summary, extremely long summary, emoji, mixed locale text, and pasted formatted content'; Outcome = 'summary content saves correctly and appears consistently in templates and exports'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Editor'; Name = 'Work Experience Section'; Navigation = 'open the Experience section'; Action = 'add, edit, reorder, and delete work experience entries'; CoreData = 'single and multiple jobs with valid dates, locations, and achievements'; EdgeData = 'overlapping dates, current-role flags, long achievement bullets, and empty optional values'; Outcome = 'experience records stay correctly ordered, validated, and reflected in preview and PDF output'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Editor'; Name = 'Education Section'; Navigation = 'open the Education section'; Action = 'create, update, reorder, and remove education entries'; CoreData = 'valid institution, degree, field, and date ranges'; EdgeData = 'missing end dates, invalid years, long institution names, and duplicate entries'; Outcome = 'education data remains valid, persistent, and visible in downstream flows'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Editor'; Name = 'Skills Section'; Navigation = 'open the Skills section'; Action = 'add, edit, deduplicate, and remove skill entries and proficiency values'; CoreData = 'valid distinct skills with supported proficiency selections'; EdgeData = 'duplicate skills, excessive skill counts, empty names, and mixed casing'; Outcome = 'skills remain normalized, editable, and correctly rendered across templates and analytics tools'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Editor'; Name = 'Projects Section'; Navigation = 'open the Projects section'; Action = 'add and maintain project titles, descriptions, technologies, and URLs'; CoreData = 'valid titles, descriptions, technology lists, and reachable URLs'; EdgeData = 'broken URLs, long descriptions, many technologies, and empty optional fields'; Outcome = 'project records persist safely and render correctly in previews, PDFs, and AI-assisted flows'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Editor'; Name = 'Certifications Section'; Navigation = 'open the Certifications section'; Action = 'manage certification names, issuers, dates, and status fields'; CoreData = 'valid certification names, issuers, and dates'; EdgeData = 'missing issuer, future dates, expired items, and duplicate records'; Outcome = 'certification records save, validate, and present correctly in resume outputs'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Editor'; Name = 'Languages Section'; Navigation = 'open the Languages section'; Action = 'add, edit, and remove language and proficiency entries'; CoreData = 'valid language names with supported proficiency values'; EdgeData = 'duplicate languages, empty names, mixed scripts, and unsupported proficiency text'; Outcome = 'language records remain consistent, validated, and visible throughout the app'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Editor'; Name = 'Custom Sections & Section Order'; Navigation = 'open custom section creation or section reordering controls in the editor'; Action = 'create custom sections, reorder them, edit content, and verify downstream persistence'; CoreData = 'resume with standard sections and one or more valid custom section drafts'; EdgeData = 'duplicate custom section names, empty custom content, reordered sections with unsaved changes, and imported custom section data'; Outcome = 'custom sections save, reorder, and render consistently without duplicating or losing content'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Templates'; Name = 'Template Selection'; Navigation = 'open template selection for a chosen resume'; Action = 'browse templates, preview them, change filters, and apply a selected template'; CoreData = 'resumes with complete data, standard color scheme, and supported templates'; EdgeData = 'rapid template switching, missing optional sections, unsupported color combinations, and large resume content'; Outcome = 'template previews render correctly, selected templates apply reliably, and the chosen template persists to the resume'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Preview'; Name = 'Resume Preview'; Navigation = 'open the Preview screen for a selected resume'; Action = 'render the live preview and inspect content, ordering, layout, and paging'; CoreData = 'complete resume with standard-length content and stable template settings'; EdgeData = 'very long content, missing optional sections, translated content, and recently changed template state'; Outcome = 'preview output matches saved data without rendering exceptions or mismatched section order'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Preview'; Name = 'PDF Export / Print / Share'; Navigation = 'open preview and use export, print, or share actions'; Action = 'generate a PDF, save it, print it, and share it through supported channels'; CoreData = 'complete resume, valid file system access, and supported print/share target'; EdgeData = 'large documents, denied file permissions, cancelled share flow, and transient PDF generation issues'; Outcome = 'PDF output is generated without corruption and user actions complete or fail gracefully'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'ATS'; Name = 'ATS Analyzer'; Navigation = 'open ATS Analyzer for a selected resume'; Action = 'run resume analysis and review ATS score, suggestions, and findings'; CoreData = 'complete resume with common sections and readable content'; EdgeData = 'sparse resume data, duplicated keywords, malformed text, and missing summary or experience'; Outcome = 'ATS analysis completes consistently and returns actionable, stable results'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'ATS'; Name = 'ATS Optimization'; Navigation = 'open ATS Optimization tools for a chosen resume'; Action = 'review optimization suggestions and apply supported improvements'; CoreData = 'resume with valid sections, measurable achievements, and common role keywords'; EdgeData = 'keyword-poor content, overstuffed keywords, empty sections, and translated text'; Outcome = 'optimization feedback is relevant, safe to apply, and consistent with the selected resume'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'AI'; Name = 'AI Assistant Hub'; Navigation = 'open the AI assistant hub'; Action = 'review tool availability, launch AI tools, and pass the selected resume context into downstream screens'; CoreData = 'configured AI key, selected resume, and reachable network'; EdgeData = 'missing AI key, missing resume, API throttling, and unavailable external services'; Outcome = 'AI tool entry points remain clear, gated correctly, and safe under dependency failures'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'AI'; Name = 'AI Resume Generator'; Navigation = 'open AI Resume Generator'; Action = 'generate resume content from prompt inputs and map it into editable sections'; CoreData = 'valid role prompt, experience level, and user preferences'; EdgeData = 'empty prompt, conflicting prompt inputs, long prompts, and service timeout'; Outcome = 'generated content is coherent, editable, and assigned to the correct resume fields'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'AI'; Name = 'LinkedIn Import'; Navigation = 'open LinkedIn Import'; Action = 'import structured profile data and map it into resume sections'; CoreData = 'complete import payload with valid names, roles, dates, and links'; EdgeData = 'partial import payload, malformed dates, duplicate entries, and unsupported field formats'; Outcome = 'imported profile data is mapped safely without corrupting existing resume content'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'AI'; Name = 'AI Job Tailor'; Navigation = 'open AI Job Tailor with a chosen resume'; Action = 'submit a job description, tailor resume content, and review proposed changes'; CoreData = 'valid job description and a complete resume context'; EdgeData = 'very long job description, empty required sections, and interrupted AI response'; Outcome = 'tailored output remains relevant, reviewable, and safe to accept or discard'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'AI'; Name = 'AI Content Enhancer'; Navigation = 'open an AI content-enhancement tool for a selected resume section'; Action = 'enhance or expand source text and apply accepted output back into the editor'; CoreData = 'valid source text, selected target section, and active AI configuration'; EdgeData = 'empty source text, repeated regenerate actions, overlong content, and canceled edits'; Outcome = 'AI-assisted content enhancement remains stable, traceable, and compatible with manual editing workflows'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'AI'; Name = 'AI Rewrite / Bullet Generator'; Navigation = 'open AI rewrite or bullet-generation tools from an editable resume section'; Action = 'rewrite content, generate bullets, and accept or discard the proposal'; CoreData = 'valid editable source text with a selected target section'; EdgeData = 'empty prompt, rapid repeated generation, unsupported special characters, and interrupted AI response'; Outcome = 'rewrite and bullet-generation tools produce usable output without overwriting user intent unexpectedly'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'AI'; Name = 'Resume Roast & Style Converter'; Navigation = 'open Resume Roast or the location-specific style converter'; Action = 'analyze a resume and generate critique, tone guidance, or style conversion output'; CoreData = 'resume with valid content and a supported target context'; EdgeData = 'missing AI key, unsupported locale combination, sparse resume, and partially translated content'; Outcome = 'analysis tools return meaningful results and fail gracefully when prerequisites are missing'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Career Tools'; Name = 'Career Tools Hub'; Navigation = 'open the career tools tab'; Action = 'review available tools, select a resume, and navigate into the chosen workflow'; CoreData = 'at least one saved resume and normal tool availability'; EdgeData = 'no resume available, stale selected resume, and rapid tool switching'; Outcome = 'career tool entry points remain discoverable, context-aware, and stable'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Career Tools'; Name = 'Job Tracker'; Navigation = 'open Job Tracker'; Action = 'create, edit, filter, and transition job applications across statuses'; CoreData = 'valid employer, role, stage, date, and notes values'; EdgeData = 'duplicate entries, invalid stage transitions, long notes, and empty required fields'; Outcome = 'job application records remain accurate and status transitions are reliable'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Career Tools'; Name = 'Job Search'; Navigation = 'open Job Search'; Action = 'browse recommendations, search listings, and review opening details'; CoreData = 'valid search input, active internet, and standard content payloads'; EdgeData = 'no results, slow API, malformed content, and interrupted navigation'; Outcome = 'job search results remain stable, readable, and relevant to the selected user context'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Career Tools'; Name = 'Career Path Guidance'; Navigation = 'open Career Path guidance'; Action = 'review suggested paths, compare roles, and inspect guidance content'; CoreData = 'selected career context, active internet, and valid guidance payloads'; EdgeData = 'empty recommendations, stale context, malformed content, and interrupted navigation'; Outcome = 'career path guidance remains coherent, context-aware, and easy to navigate'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Career Tools'; Name = 'Career Articles'; Navigation = 'open Career Articles'; Action = 'browse article lists, open details, and return to related tools'; CoreData = 'available article metadata, thumbnails, and article detail content'; EdgeData = 'missing article assets, broken details, no network, and empty states'; Outcome = 'article discovery and reading flows remain stable and do not break surrounding navigation'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Career Tools'; Name = 'Cover Letter Builder'; Navigation = 'open the cover letter workflow'; Action = 'generate or edit a cover letter and save, export, or share the result'; CoreData = 'selected resume, valid prompt or job context, and normal AI or template availability'; EdgeData = 'missing resume context, empty prompt, interrupted generation, and export cancellation'; Outcome = 'cover letter output is relevant, persistent where expected, and safe under failure modes'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Career Tools'; Name = 'Interview Prep'; Navigation = 'open Interview Prep'; Action = 'generate or review interview questions, answers, and preparation guidance'; CoreData = 'selected resume, target role context, and normal AI/network availability'; EdgeData = 'missing role context, empty prompt, partial AI result, and repeated regenerate actions'; Outcome = 'interview preparation content remains relevant, reviewable, and stable'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Career Tools'; Name = 'Skill Analyzer'; Navigation = 'open Skill Analyzer'; Action = 'analyze skill coverage, review suggestions, and compare gaps against the selected context'; CoreData = 'selected resume with skill content and valid target role context'; EdgeData = 'skill-poor resume, duplicated skills, empty target role, and interrupted analysis'; Outcome = 'skill analysis remains consistent and actionable without corrupting resume data'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Portfolio'; Name = 'Portfolio Tab'; Navigation = 'open the portfolio tab'; Action = 'review portfolio content, linked items, certifications, achievements, and related assets'; CoreData = 'resume-linked portfolio data with valid assets and metadata'; EdgeData = 'missing assets, long descriptions, stale data, and empty states'; Outcome = 'portfolio content remains readable, linked correctly, and visually stable'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Settings'; Name = 'Profile Management'; Navigation = 'open profile settings'; Action = 'update personal profile preferences, saved account data, and display-related information'; CoreData = 'valid profile values, stable local storage, and an authenticated user state'; EdgeData = 'invalid profile values, interrupted save, stale cached data, and missing optional fields'; Outcome = 'profile changes persist correctly and surface accurately across connected screens'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Settings'; Name = 'Notification Preferences'; Navigation = 'open notification settings'; Action = 'toggle notifications, review permission state, and confirm preference persistence'; CoreData = 'granted notification permissions and valid saved preference state'; EdgeData = 'revoked permissions, denied prompts, stale preference cache, and interrupted save'; Outcome = 'notification preferences persist correctly and respect platform permission state'; Platforms = 'Android, iOS, Web' },
  [ordered]@{ Area = 'Settings'; Name = 'Privacy / Help / Legal'; Navigation = 'open privacy, help, or legal information screens'; Action = 'browse support content, privacy policy, help articles, and legal references'; CoreData = 'valid static or remote content and reachable help entry points'; EdgeData = 'missing documents, slow content load, stale links, and interrupted navigation'; Outcome = 'support and legal content remains accessible, readable, and linked correctly'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Subscription'; Name = 'Subscription & Entitlements'; Navigation = 'open subscription management or premium feature gates'; Action = 'review plans, purchase or restore entitlements, and verify premium access'; CoreData = 'valid store connectivity, stable subscription state, and supported entitlement metadata'; EdgeData = 'declined purchase, store timeout, stale entitlement cache, and restore mismatch'; Outcome = 'premium access, plan state, and purchase recovery remain accurate and secure'; Platforms = 'Android, iOS, Web' },
  [ordered]@{ Area = 'Settings'; Name = 'Backup & Sync'; Navigation = 'open backup or restore controls'; Action = 'create a backup, sync data, restore data, and resolve merge behavior'; CoreData = 'valid local resume data, stable sync code or backup target, and reachable storage'; EdgeData = 'invalid sync code, no backup payload, conflicting timestamps, and interrupted restore'; Outcome = 'backup and restore operations preserve data integrity and merge the correct source of truth'; Platforms = 'Android, iOS, Windows, Web' },
  [ordered]@{ Area = 'Settings'; Name = 'Theme / Language / App Preferences'; Navigation = 'open app preferences'; Action = 'change theme, language, and other persistent preference values and re-open affected screens'; CoreData = 'valid preference values and a stable saved preference store'; EdgeData = 'unsupported theme switch timing, missing translation values, stale cached preferences, and app restart during save'; Outcome = 'preference changes persist correctly and update the UI without breaking feature behavior'; Platforms = 'Android, iOS, Windows, Web' }
)

function Resolve-WritablePath {
  param([string]$PreferredPath)

  if (-not (Test-Path $PreferredPath)) {
    return $PreferredPath
  }

  try {
    $stream = [System.IO.File]::Open($PreferredPath, 'Open', 'ReadWrite', 'None')
    $stream.Close()
    Remove-Item $PreferredPath -Force
    return $PreferredPath
  }
  catch {
    $directory = Split-Path $PreferredPath -Parent
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($PreferredPath)
    $extension = [System.IO.Path]::GetExtension($PreferredPath)
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    return (Join-Path $directory ("${baseName}_${stamp}${extension}"))
  }
}

function Escape-XmlText {
  param([AllowNull()][string]$Value)

  if ($null -eq $Value) {
    return ''
  }

  return $Value.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;')
}

function Get-ExcelColumnName {
  param([int]$Index)

  $value = $Index
  $letters = ''

  while ($value -gt 0) {
    $remainder = ($value - 1) % 26
    $letters = [char](65 + $remainder) + $letters
    $value = [math]::Floor(($value - 1) / 26)
  }

  return $letters
}

function New-InlineCell {
  param(
    [string]$CellReference,
    [AllowNull()][string]$Value,
    [int]$StyleIndex
  )

  $escapedValue = Escape-XmlText $Value
  return ('<c r="{0}" t="inlineStr" s="{1}"><is><t xml:space="preserve">{2}</t></is></c>' -f $CellReference, $StyleIndex, $escapedValue)
}

function New-BlankValueArray {
  param(
    [int]$Count,
    [string]$FirstValue = ''
  )

  $values = New-Object object[] $Count
  for ($i = 0; $i -lt $Count; $i++) {
    $values[$i] = ''
  }

  if ($Count -gt 0) {
    $values[0] = $FirstValue
  }

  return $values
}

function New-RepeatedStyleArray {
  param(
    [int]$Count,
    [int]$StyleIndex
  )

  $styles = New-Object int[] $Count
  for ($i = 0; $i -lt $Count; $i++) {
    $styles[$i] = $StyleIndex
  }

  return $styles
}

function New-WorksheetRow {
  param(
    [int]$RowIndex,
    [object[]]$Values,
    [int[]]$StyleIndices
  )

  $cells = New-Object System.Collections.Generic.List[string]

  for ($i = 0; $i -lt $Values.Count; $i++) {
    $styleIndex = if ($StyleIndices.Count -eq 1) { $StyleIndices[0] } else { $StyleIndices[$i] }
    $cellRef = "$(Get-ExcelColumnName ($i + 1))$RowIndex"
    $cells.Add((New-InlineCell -CellReference $cellRef -Value ([string]$Values[$i]) -StyleIndex $styleIndex))
  }

  return ('<row r="{0}">{1}</row>' -f $RowIndex, ($cells -join ''))
}

function Get-Priority {
  param($Type, $Module)

  if ($Type.Priority -eq 'High') {
    return 'High'
  }

  if ($Module.Area -in @('Authentication', 'Preview', 'Subscription') -and $Type.Name -in @('UI Testing', 'Usability Testing', 'Accessibility Testing')) {
    return 'High'
  }

  return 'Medium'
}

function Get-Severity {
  param($Type, $Module)

  if ($Type.Name -eq 'Security Testing') {
    return 'Critical'
  }

  if ($Type.Name -eq 'End-to-End Testing' -and $Module.Area -in @('Core App', 'Authentication', 'Preview', 'Subscription', 'Settings')) {
    return 'Critical'
  }

  if ($Type.Name -eq 'API Testing' -and $Module.Area -in @('Authentication', 'AI', 'Career Tools', 'Subscription', 'Settings')) {
    return 'Critical'
  }

  if ($Type.Name -in @('Functional Testing', 'Regression Testing', 'Integration Testing', 'Compatibility Testing', 'Performance Testing', 'Accessibility Testing', 'End-to-End Testing')) {
    return 'High'
  }

  return 'Medium'
}

function Get-AutomationCandidate {
  param([string]$TestType)

  switch ($TestType) {
    'Functional Testing' { return 'High' }
    'Regression Testing' { return 'High' }
    'Integration Testing' { return 'High' }
    'API Testing' { return 'High' }
    'Compatibility Testing' { return 'Medium' }
    'Performance Testing' { return 'Medium' }
    'Security Testing' { return 'Medium' }
    'Usability Testing' { return 'Low' }
    'Accessibility Testing' { return 'High' }
    'Localization Testing' { return 'Medium' }
    'End-to-End Testing' { return 'High' }
    default { return 'Medium' }
  }
}

function Get-Preconditions {
  param($Type, $Module, $Variant)

  $typeNote = switch ($Type.Name) {
    'API Testing' { 'Request and response monitoring is available for the relevant network calls.' }
    'Compatibility Testing' { 'Supported browser, device, viewport, or OS combinations are prepared for comparison.' }
    'Performance Testing' { 'Response time, render, memory, and CPU measurement tools are enabled.' }
    'Security Testing' { 'Authorized and unauthorized user states, token/session controls, and safe inspection methods are available.' }
    'Accessibility Testing' { 'Keyboard-only navigation, screen reader support, zoom scaling, and contrast inspection can be exercised.' }
    'Localization Testing' { 'Supported language and locale switches are available, including translated content samples.' }
    default { 'The tester can reach the target module through supported navigation without unrelated blockers.' }
  }

  return "$($Variant.PreconditionNote) $typeNote The module under test is $($Module.Name) in the $($Module.Area) area, and the run covers $($Module.Platforms)."
}

function Get-TestData {
  param($Type, $Module, $Variant)

  $baseData = $Module[$Variant.DataKey]

  switch ($Type.Name) {
    'API Testing' { return "$baseData; include success, validation error, timeout, empty payload, retry, and malformed payload conditions relevant to $($Module.Name)." }
    'Compatibility Testing' { return "$baseData; include supported Android, iOS, Windows, Chrome, Edge, responsive web, and device-class combinations relevant to $($Module.Name)." }
    'Performance Testing' { return "$baseData; include baseline response, repeated actions, large datasets, and constrained device or network conditions." }
    'Security Testing' { return "$baseData; include authorized state, unauthorized attempt, tampered payload, expired session, and sensitive data inspection conditions." }
    'Accessibility Testing' { return "$baseData; include keyboard-only traversal, screen reader labels, 200 percent text scale, focus order, and contrast checks." }
    'Localization Testing' { return "$baseData; include English, Spanish, mixed-language content, long translated strings, and locale-sensitive formatting values." }
    'End-to-End Testing' { return "$baseData; include realistic user data spanning the full workflow start-to-finish for $($Module.Name)." }
    default { return $baseData }
  }
}

function Get-TestSteps {
  param($Type, $Module, $Variant)

  $dataLens = Get-TestData -Type $Type -Module $Module -Variant $Variant

  switch ($Type.Name) {
    'Functional Testing' {
      return "1. Launch the app and $($Module.Navigation). 2. Perform $($Module.Action). 3. Use $dataLens and apply the $($Variant.Name) lens by ensuring you $($Variant.ExecutionLens). 4. Verify the functional outcome, saved state, and user feedback for $($Module.Name)."
    }
    'UI Testing' {
      return "1. Launch the app and $($Module.Navigation). 2. Perform $($Module.Action). 3. Use $dataLens while checking labels, spacing, hierarchy, alignment, and state styling under the $($Variant.Name) scenario. 4. Verify no clipping, overlap, hidden controls, or inconsistent visual feedback appear in $($Module.Name)."
    }
    'Regression Testing' {
      return "1. Prepare a baseline state for $($Module.Name) that previously worked. 2. Launch the app and $($Module.Navigation). 3. Perform $($Module.Action) using $dataLens and replay the $($Variant.Name) scenario. 4. Compare current behavior with the known-good outcome and verify no existing behavior regresses."
    }
    'Integration Testing' {
      return "1. Launch the app and $($Module.Navigation). 2. Perform $($Module.Action) across the connected screens, providers, storage, or services involved. 3. Use $dataLens while applying the $($Variant.Name) scenario. 4. Verify data, navigation, and downstream dependencies stay synchronized throughout the workflow."
    }
    'API Testing' {
      return "1. Enable request and response monitoring for the calls involved in $($Module.Name). 2. Launch the app and $($Module.Navigation). 3. Perform $($Module.Action) using $dataLens and observe payload, status, retry, and error handling. 4. Verify the UI, stored state, and retry behavior match the service result for the $($Variant.Name) scenario."
    }
    'Compatibility Testing' {
      return "1. Prepare the supported device, browser, OS, and viewport combinations relevant to $($Module.Name). 2. Launch the app and $($Module.Navigation). 3. Perform $($Module.Action) using $dataLens while repeating the $($Variant.Name) scenario across the targeted environments. 4. Verify behavior, layout, and persistence remain consistent across supported combinations."
    }
    'Performance Testing' {
      return "1. Enable response-time, render, memory, and CPU monitoring. 2. Launch the app and $($Module.Navigation). 3. Perform $($Module.Action) using $dataLens while applying the $($Variant.Name) workload pattern. 4. Record timing, smoothness, stability, and degradation signals and verify they remain within acceptable limits."
    }
    'Security Testing' {
      return "1. Prepare authorized and unauthorized states plus any required session or token controls. 2. Launch the app and $($Module.Navigation). 3. Perform $($Module.Action) using $dataLens and attempt the $($Variant.Name) abuse or protection scenario. 4. Verify access control, data protection, logging, and failure behavior remain secure in $($Module.Name)."
    }
    'Usability Testing' {
      return "1. Launch the app and $($Module.Navigation). 2. Perform $($Module.Action) as a realistic user goal. 3. Use $dataLens while applying the $($Variant.Name) lens and observe task clarity, guidance, friction, and error recovery cues. 4. Verify the task can be completed efficiently without confusing interactions or unclear feedback."
    }
    'Accessibility Testing' {
      return "1. Launch the app and $($Module.Navigation) with assistive or adaptive settings ready. 2. Perform $($Module.Action). 3. Use $dataLens while applying the $($Variant.Name) scenario with keyboard, focus, semantics, zoom, and contrast checks. 4. Verify $($Module.Name) remains operable and understandable for assistive-technology users."
    }
    'Localization Testing' {
      return "1. Switch the app to the target locale and launch the app. 2. $($Module.Navigation.Substring(0,1).ToUpper() + $Module.Navigation.Substring(1)). 3. Perform $($Module.Action) using $dataLens under the $($Variant.Name) scenario. 4. Verify translations, formatting, truncation, text expansion, and mixed-language data render correctly in $($Module.Name)."
    }
    'End-to-End Testing' {
      return "1. Start from the real entry point that leads to $($Module.Name). 2. Complete $($Module.Action) as part of the broader user journey. 3. Use $dataLens and apply the $($Variant.Name) scenario across the connected upstream and downstream screens. 4. Verify the entire journey finishes with the correct persisted data, user-visible output, and recovery behavior."
    }
    default {
      return "1. Launch the app and $($Module.Navigation). 2. Perform $($Module.Action). 3. Use $dataLens and apply the $($Variant.Name) scenario. 4. Verify the observed outcome matches the intent of $($Type.Name)."
    }
  }
}

function Get-ExpectedResult {
  param($Type, $Module, $Variant)

  return "$($Type.Focus) Under the $($Variant.Name) scenario, $($Variant.OutcomePrefix) $($Module.Outcome), and $($Type.ExpectedLens)."
}

function Get-ColumnsXml {
  param([double[]]$ColumnWidths)

  $cols = New-Object System.Collections.Generic.List[string]
  for ($i = 0; $i -lt $ColumnWidths.Count; $i++) {
    $columnIndex = $i + 1
    $cols.Add(('<col min="{0}" max="{0}" width="{1}" customWidth="1"/>' -f $columnIndex, $ColumnWidths[$i]))
  }

  return ($cols -join "`n    ")
}

function New-WorksheetXml {
  param(
    [double[]]$ColumnWidths,
    [System.Collections.Generic.List[string]]$Rows,
    [string]$AutoFilterRange,
    [bool]$FreezeTopRow
  )

  $sheetViewXml = if ($FreezeTopRow) {
    @'
  <sheetViews>
    <sheetView workbookViewId="0">
      <pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>
    </sheetView>
  </sheetViews>
'@
  }
  else {
    @'
  <sheetViews>
    <sheetView workbookViewId="0"/>
  </sheetViews>
'@
  }

  $autoFilterXml = if ([string]::IsNullOrWhiteSpace($AutoFilterRange)) {
    ''
  }
  else {
    ('  <autoFilter ref="{0}"/>' -f $AutoFilterRange)
  }

  $colsXml = Get-ColumnsXml -ColumnWidths $ColumnWidths

  return @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
$sheetViewXml  <sheetFormatPr defaultRowHeight="15"/>
  <cols>
    $colsXml
  </cols>
  <sheetData>
    $($Rows -join "`n    ")
  </sheetData>
$autoFilterXml
</worksheet>
"@
}

$rows = New-Object System.Collections.Generic.List[object]
$caseNumber = 1

foreach ($module in $modules) {
  foreach ($type in $testTypes) {
    foreach ($variant in $scenarioVariants) {
      $rows.Add([pscustomobject][ordered]@{
        'S.No' = $caseNumber
        'Test Case ID' = 'TC_' + $caseNumber.ToString('D4')
        'Test Case Title / Name' = "$($type.Name) - $($module.Name) - $($variant.Name)"
        'Feature Area' = $module.Area
        'Module Name' = $module.Name
        'Testing Type' = $type.Name
        'Testing Type Classification' = $type.Classification
        'Scenario Variant' = $variant.Name
        'Preconditions' = Get-Preconditions -Type $type -Module $module -Variant $variant
        'Test Steps' = Get-TestSteps -Type $type -Module $module -Variant $variant
        'Test Data' = Get-TestData -Type $type -Module $module -Variant $variant
        'Expected Result' = Get-ExpectedResult -Type $type -Module $module -Variant $variant
        'Actual Result' = ''
        'Test Status' = 'Not Executed'
        'Priority' = Get-Priority -Type $type -Module $module
        'Severity' = Get-Severity -Type $type -Module $module
        'Platforms' = $module.Platforms
        'Automation Candidate' = Get-AutomationCandidate -TestType $type.Name
        'Defect ID / Link' = ''
        'Defect Summary / Notes' = ''
      }) | Out-Null

      $caseNumber++
    }
  }
}

$expectedCount = $modules.Count * $testTypes.Count * $scenarioVariants.Count
if ($rows.Count -ne $expectedCount) {
  throw "Expected $expectedCount test cases, but generated $($rows.Count)."
}

if ($rows.Count -lt 2000) {
  throw "Expected at least 2000 test cases, but generated $($rows.Count)."
}

$csvPath = Resolve-WritablePath -PreferredPath $csvPath
$xlsxPath = Resolve-WritablePath -PreferredPath $xlsxPath
$summaryPath = Resolve-WritablePath -PreferredPath $summaryPath

$rows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

$typeStyleMap = @{}
for ($i = 0; $i -lt $testTypes.Count; $i++) {
  $typeStyleMap[$testTypes[$i].Name] = 5 + $i
}

$sheet1Rows = New-Object System.Collections.Generic.List[string]
$sheet1Rows.Add((New-WorksheetRow -RowIndex 1 -Values $requiredColumns -StyleIndices (New-RepeatedStyleArray -Count $requiredColumns.Count -StyleIndex 1)))

$sheet1RowIndex = 2
foreach ($row in $rows) {
  $values = foreach ($column in $requiredColumns) { [string]$row.$column }
  $styleIndex = $typeStyleMap[$row.'Testing Type']
  $sheet1Rows.Add((New-WorksheetRow -RowIndex $sheet1RowIndex -Values $values -StyleIndices (New-RepeatedStyleArray -Count $requiredColumns.Count -StyleIndex $styleIndex)))
  $sheet1RowIndex++
}

$sheet1LastColumn = Get-ExcelColumnName $requiredColumns.Count
$sheet1Range = "A1:${sheet1LastColumn}$($sheet1Rows.Count)"

$summaryRows = New-Object System.Collections.Generic.List[string]
$summaryColumnCount = 6
$summaryRowIndex = 1

$summaryRows.Add((New-WorksheetRow -RowIndex $summaryRowIndex -Values (New-BlankValueArray -Count $summaryColumnCount -FirstValue 'Resume App Comprehensive Test Coverage Summary') -StyleIndices (New-RepeatedStyleArray -Count $summaryColumnCount -StyleIndex 2)))
$summaryRowIndex++
$summaryRows.Add((New-WorksheetRow -RowIndex $summaryRowIndex -Values @('Metric', 'Value', '', '', '', '') -StyleIndices @(1, 1, 1, 1, 1, 1)))
$summaryRowIndex++

$metrics = @(
  [ordered]@{ Label = 'Total Test Cases'; Value = [string]$rows.Count },
  [ordered]@{ Label = 'Feature Areas Covered'; Value = [string](($rows | Select-Object -ExpandProperty 'Feature Area' -Unique).Count) },
  [ordered]@{ Label = 'Modules Covered'; Value = [string](($rows | Select-Object -ExpandProperty 'Module Name' -Unique).Count) },
  [ordered]@{ Label = 'Testing Types Covered'; Value = [string](($rows | Select-Object -ExpandProperty 'Testing Type' -Unique).Count) },
  [ordered]@{ Label = 'High Priority Cases'; Value = [string](($rows | Where-Object { $_.Priority -eq 'High' }).Count) },
  [ordered]@{ Label = 'Medium Priority Cases'; Value = [string](($rows | Where-Object { $_.Priority -eq 'Medium' }).Count) },
  [ordered]@{ Label = 'Default Execution Status'; Value = 'Not Executed' },
  [ordered]@{ Label = 'High Automation Candidates'; Value = [string](($rows | Where-Object { $_.'Automation Candidate' -eq 'High' }).Count) }
)

foreach ($metric in $metrics) {
  $summaryRows.Add((New-WorksheetRow -RowIndex $summaryRowIndex -Values @($metric.Label, $metric.Value, '', '', '', '') -StyleIndices @(3, 4, 4, 4, 4, 4)))
  $summaryRowIndex++
}

$summaryRowIndex++
$summaryRows.Add((New-WorksheetRow -RowIndex $summaryRowIndex -Values (New-BlankValueArray -Count $summaryColumnCount -FirstValue 'Coverage By Testing Type') -StyleIndices (New-RepeatedStyleArray -Count $summaryColumnCount -StyleIndex 2)))
$summaryRowIndex++
$summaryRows.Add((New-WorksheetRow -RowIndex $summaryRowIndex -Values @('Testing Type', 'Count', '', '', '', '') -StyleIndices @(1, 1, 1, 1, 1, 1)))
$summaryRowIndex++

foreach ($group in ($rows | Group-Object 'Testing Type' | Sort-Object Name)) {
  $styleIndex = $typeStyleMap[$group.Name]
  $summaryRows.Add((New-WorksheetRow -RowIndex $summaryRowIndex -Values @($group.Name, [string]$group.Count, '', '', '', '') -StyleIndices (New-RepeatedStyleArray -Count $summaryColumnCount -StyleIndex $styleIndex)))
  $summaryRowIndex++
}

$summaryRowIndex++
$summaryRows.Add((New-WorksheetRow -RowIndex $summaryRowIndex -Values (New-BlankValueArray -Count $summaryColumnCount -FirstValue 'Coverage By Module') -StyleIndices (New-RepeatedStyleArray -Count $summaryColumnCount -StyleIndex 2)))
$summaryRowIndex++
$summaryRows.Add((New-WorksheetRow -RowIndex $summaryRowIndex -Values @('Module Name', 'Count', '', '', '', '') -StyleIndices @(1, 1, 1, 1, 1, 1)))
$summaryRowIndex++

foreach ($group in ($rows | Group-Object 'Module Name' | Sort-Object Name)) {
  $summaryRows.Add((New-WorksheetRow -RowIndex $summaryRowIndex -Values @($group.Name, [string]$group.Count, '', '', '', '') -StyleIndices @(4, 4, 4, 4, 4, 4)))
  $summaryRowIndex++
}

$summaryRowIndex++
$summaryRows.Add((New-WorksheetRow -RowIndex $summaryRowIndex -Values (New-BlankValueArray -Count $summaryColumnCount -FirstValue 'Coverage By Feature Area') -StyleIndices (New-RepeatedStyleArray -Count $summaryColumnCount -StyleIndex 2)))
$summaryRowIndex++
$summaryRows.Add((New-WorksheetRow -RowIndex $summaryRowIndex -Values @('Feature Area', 'Count', '', '', '', '') -StyleIndices @(1, 1, 1, 1, 1, 1)))
$summaryRowIndex++

foreach ($group in ($rows | Group-Object 'Feature Area' | Sort-Object Name)) {
  $summaryRows.Add((New-WorksheetRow -RowIndex $summaryRowIndex -Values @($group.Name, [string]$group.Count, '', '', '', '') -StyleIndices @(4, 4, 4, 4, 4, 4)))
  $summaryRowIndex++
}

$legendRows = New-Object System.Collections.Generic.List[string]
$legendColumnCount = 6
$legendRowIndex = 1

$legendRows.Add((New-WorksheetRow -RowIndex $legendRowIndex -Values (New-BlankValueArray -Count $legendColumnCount -FirstValue 'Testing Type Color Legend') -StyleIndices (New-RepeatedStyleArray -Count $legendColumnCount -StyleIndex 2)))
$legendRowIndex++
$legendRows.Add((New-WorksheetRow -RowIndex $legendRowIndex -Values @('Testing Type', 'Classification', 'Default Priority', 'Default Severity', 'Coverage Focus', 'Color Usage') -StyleIndices @(1, 1, 1, 1, 1, 1)))
$legendRowIndex++

foreach ($type in $testTypes) {
  $styleIndex = $typeStyleMap[$type.Name]
  $severity = Get-Severity -Type $type -Module ([pscustomobject]@{ Area = 'Core App' })
  $legendRows.Add((New-WorksheetRow -RowIndex $legendRowIndex -Values @($type.Name, $type.Classification, $type.Priority, $severity, $type.Focus, 'Row fill in All Test Cases sheet indicates this testing type.') -StyleIndices (New-RepeatedStyleArray -Count $legendColumnCount -StyleIndex $styleIndex)))
  $legendRowIndex++
}

$legendRowIndex++
$legendRows.Add((New-WorksheetRow -RowIndex $legendRowIndex -Values (New-BlankValueArray -Count $legendColumnCount -FirstValue 'Execution Tracking Guidance') -StyleIndices (New-RepeatedStyleArray -Count $legendColumnCount -StyleIndex 2)))
$legendRowIndex++
$legendRows.Add((New-WorksheetRow -RowIndex $legendRowIndex -Values @('Tracking Column', 'Purpose', 'Suggested Use', '', '', '') -StyleIndices @(1, 1, 1, 1, 1, 1)))
$legendRowIndex++

$guidanceRows = @(
  @('Test Status', 'Execution progress tracking', 'Use values such as Not Executed, In Progress, Passed, Failed, Blocked.'),
  @('Actual Result', 'Observed system behavior', 'Capture concise execution evidence or the observed output.'),
  @('Defect ID / Link', 'Defect traceability', 'Record issue tracker ID or URL when a case fails.'),
  @('Defect Summary / Notes', 'Failure detail and tester notes', 'Add root symptom, repro clue, or coverage note.'),
  @('Priority and Severity', 'Execution order and impact tracking', 'Use High first for release-critical flows, keep severity aligned to user impact.')
)

foreach ($guidance in $guidanceRows) {
  $legendRows.Add((New-WorksheetRow -RowIndex $legendRowIndex -Values @($guidance[0], $guidance[1], $guidance[2], '', '', '') -StyleIndices @(4, 4, 4, 4, 4, 4)))
  $legendRowIndex++
}

$fills = New-Object System.Collections.Generic.List[string]
$fills.Add('<fill><patternFill patternType="none"/></fill>')
$fills.Add('<fill><patternFill patternType="gray125"/></fill>')
$fills.Add('<fill><patternFill patternType="solid"><fgColor rgb="FF1E3A5F"/><bgColor indexed="64"/></patternFill></fill>')
$fills.Add('<fill><patternFill patternType="solid"><fgColor rgb="FF334155"/><bgColor indexed="64"/></patternFill></fill>')
$fills.Add('<fill><patternFill patternType="solid"><fgColor rgb="FFF8FAFC"/><bgColor indexed="64"/></patternFill></fill>')

foreach ($type in $testTypes) {
  $fills.Add(('<fill><patternFill patternType="solid"><fgColor rgb="{0}"/><bgColor indexed="64"/></patternFill></fill>' -f $type.FillRgb))
}

$cellXfs = New-Object System.Collections.Generic.List[string]
$cellXfs.Add('<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>')
$cellXfs.Add('<xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment horizontal="center" vertical="center" wrapText="1"/></xf>')
$cellXfs.Add('<xf numFmtId="0" fontId="1" fillId="3" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment horizontal="left" vertical="center" wrapText="1"/></xf>')
$cellXfs.Add('<xf numFmtId="0" fontId="2" fillId="4" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>')
$cellXfs.Add('<xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>')

for ($i = 0; $i -lt $testTypes.Count; $i++) {
  $fillId = 5 + $i
  $cellXfs.Add(('<xf numFmtId="0" fontId="0" fillId="{0}" borderId="1" xfId="0" applyFill="1" applyBorder="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>' -f $fillId))
}

$stylesXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="3">
    <font>
      <sz val="10"/>
      <name val="Calibri"/>
      <family val="2"/>
    </font>
    <font>
      <b/>
      <sz val="11"/>
      <color rgb="FFFFFFFF"/>
      <name val="Calibri"/>
      <family val="2"/>
    </font>
    <font>
      <b/>
      <sz val="10"/>
      <color rgb="FF0F172A"/>
      <name val="Calibri"/>
      <family val="2"/>
    </font>
  </fonts>
  <fills count="$($fills.Count)">
    $($fills -join "`n    ")
  </fills>
  <borders count="2">
    <border>
      <left/><right/><top/><bottom/><diagonal/>
    </border>
    <border>
      <left style="thin"><color rgb="FFD9DEE7"/></left>
      <right style="thin"><color rgb="FFD9DEE7"/></right>
      <top style="thin"><color rgb="FFD9DEE7"/></top>
      <bottom style="thin"><color rgb="FFD9DEE7"/></bottom>
      <diagonal/>
    </border>
  </borders>
  <cellStyleXfs count="1">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>
  </cellStyleXfs>
  <cellXfs count="$($cellXfs.Count)">
    $($cellXfs -join "`n    ")
  </cellXfs>
  <cellStyles count="1">
    <cellStyle name="Normal" xfId="0" builtinId="0"/>
  </cellStyles>
</styleSheet>
"@

$sheet1Xml = New-WorksheetXml -ColumnWidths @(8, 14, 42, 18, 28, 20, 26, 18, 34, 58, 30, 44, 22, 16, 14, 14, 22, 18, 20, 30) -Rows $sheet1Rows -AutoFilterRange $sheet1Range -FreezeTopRow $true
$sheet2Xml = New-WorksheetXml -ColumnWidths @(30, 14, 8, 8, 8, 8) -Rows $summaryRows -AutoFilterRange '' -FreezeTopRow $false
$sheet3Xml = New-WorksheetXml -ColumnWidths @(24, 28, 18, 18, 70, 34) -Rows $legendRows -AutoFilterRange '' -FreezeTopRow $false

$workbookXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="All Test Cases" sheetId="1" r:id="rId1"/>
    <sheet name="Coverage Summary" sheetId="2" r:id="rId2"/>
    <sheet name="Color Legend" sheetId="3" r:id="rId3"/>
  </sheets>
</workbook>
"@

$contentTypesXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/worksheets/sheet3.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>
"@

$packageRelsXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>
"@

$workbookRelsXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet3.xml"/>
  <Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>
"@

$utcNow = (Get-Date).ToUniversalTime().ToString('s') + 'Z'
$coreXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:creator>GitHub Copilot</dc:creator>
  <cp:lastModifiedBy>GitHub Copilot</cp:lastModifiedBy>
  <dcterms:created xsi:type="dcterms:W3CDTF">$utcNow</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">$utcNow</dcterms:modified>
  <dc:title>Resume App Comprehensive Test Case Sheet</dc:title>
</cp:coreProperties>
"@

$appXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>Microsoft Excel</Application>
  <DocSecurity>0</DocSecurity>
  <ScaleCrop>false</ScaleCrop>
  <HeadingPairs>
    <vt:vector size="2" baseType="variant">
      <vt:variant><vt:lpstr>Worksheets</vt:lpstr></vt:variant>
      <vt:variant><vt:i4>3</vt:i4></vt:variant>
    </vt:vector>
  </HeadingPairs>
  <TitlesOfParts>
    <vt:vector size="3" baseType="lpstr">
      <vt:lpstr>All Test Cases</vt:lpstr>
      <vt:lpstr>Coverage Summary</vt:lpstr>
      <vt:lpstr>Color Legend</vt:lpstr>
    </vt:vector>
  </TitlesOfParts>
  <Company></Company>
  <LinksUpToDate>false</LinksUpToDate>
  <SharedDoc>false</SharedDoc>
  <HyperlinksChanged>false</HyperlinksChanged>
  <AppVersion>16.0300</AppVersion>
</Properties>
"@

$summaryLines = New-Object System.Collections.Generic.List[string]
$summaryLines.Add('# Resume App Comprehensive Test Case Sheet')
$summaryLines.Add('')
$summaryLines.Add("- Generated CSV: $(Split-Path $csvPath -Leaf)")
$summaryLines.Add("- Generated workbook: $(Split-Path $xlsxPath -Leaf)")
$summaryLines.Add("- Total test cases: $($rows.Count)")
$summaryLines.Add("- Feature areas covered: $((($rows | Select-Object -ExpandProperty 'Feature Area' -Unique).Count))")
$summaryLines.Add("- Modules covered: $((($rows | Select-Object -ExpandProperty 'Module Name' -Unique).Count))")
$summaryLines.Add("- Testing types covered: $((($rows | Select-Object -ExpandProperty 'Testing Type' -Unique).Count))")
$summaryLines.Add('')
$summaryLines.Add('## Testing Type Coverage')
$summaryLines.Add('')

foreach ($group in ($rows | Group-Object 'Testing Type' | Sort-Object Name)) {
  $summaryLines.Add("- $($group.Name): $($group.Count) test cases")
}

$summaryLines.Add('')
$summaryLines.Add('## Module Coverage')
$summaryLines.Add('')

foreach ($group in ($rows | Group-Object 'Module Name' | Sort-Object Name)) {
  $summaryLines.Add("- $($group.Name): $($group.Count) test cases")
}

$summaryLines | Set-Content -Path $summaryPath -Encoding UTF8

Add-Type -AssemblyName System.IO.Compression.FileSystem

$tempRoot = Join-Path $workspaceRoot ([System.IO.Path]::GetRandomFileName())
$null = New-Item -ItemType Directory -Path $tempRoot

try {
  $relsDir = Join-Path $tempRoot '_rels'
  $docPropsDir = Join-Path $tempRoot 'docProps'
  $xlDir = Join-Path $tempRoot 'xl'
  $xlRelsDir = Join-Path $xlDir '_rels'
  $xlWorksheetsDir = Join-Path $xlDir 'worksheets'

  foreach ($dir in @($relsDir, $docPropsDir, $xlDir, $xlRelsDir, $xlWorksheetsDir)) {
    $null = New-Item -ItemType Directory -Path $dir
  }

  [System.IO.File]::WriteAllText((Join-Path $tempRoot '[Content_Types].xml'), $contentTypesXml, [System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText((Join-Path $relsDir '.rels'), $packageRelsXml, [System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText((Join-Path $docPropsDir 'core.xml'), $coreXml, [System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText((Join-Path $docPropsDir 'app.xml'), $appXml, [System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText((Join-Path $xlDir 'workbook.xml'), $workbookXml, [System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText((Join-Path $xlRelsDir 'workbook.xml.rels'), $workbookRelsXml, [System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText((Join-Path $xlDir 'styles.xml'), $stylesXml, [System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText((Join-Path $xlWorksheetsDir 'sheet1.xml'), $sheet1Xml, [System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText((Join-Path $xlWorksheetsDir 'sheet2.xml'), $sheet2Xml, [System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText((Join-Path $xlWorksheetsDir 'sheet3.xml'), $sheet3Xml, [System.Text.UTF8Encoding]::new($false))

  if (Test-Path $xlsxPath) {
    Remove-Item $xlsxPath -Force
  }

  [System.IO.Compression.ZipFile]::CreateFromDirectory($tempRoot, $xlsxPath)
}
finally {
  if (Test-Path $tempRoot) {
    Remove-Item $tempRoot -Recurse -Force
  }
}

Write-Host "Created CSV file      : $csvPath"
Write-Host "Created Excel workbook: $xlsxPath"
Write-Host "Created summary file  : $summaryPath"
Write-Host "Generated test cases  : $($rows.Count)"
Write-Host "Modules covered       : $($modules.Count)"
Write-Host "Testing types covered : $($testTypes.Count)"