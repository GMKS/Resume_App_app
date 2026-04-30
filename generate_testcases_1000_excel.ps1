$ErrorActionPreference = 'Stop'

$workspaceRoot = $PSScriptRoot
$csvPath = Join-Path $workspaceRoot 'important_testcases_resume_app_1000.csv'
$xlsxPath = Join-Path $workspaceRoot 'important_testcases_resume_app_1000.xlsx'

$requiredColumns = @(
  'S.No',
  'Test Case ID',
  'Test Case Title / Name',
  'Description',
  'Preconditions',
  'Test Steps',
  'Test Data',
  'Expected Result',
  'Actual Result',
  'Status (Pass/Fail)',
  'Priority (High/Medium/Low)',
  'Severity',
  'Module / Feature Name'
)

$bucketConfigs = @(
  [ordered]@{
    Name = 'Functional Testing'
    Priority = 'High'
    Severity = 'Critical'
    Features = @(
      'User registration / login / logout',
      'Create new resume',
      'Edit resume personal info',
      'Edit resume summary',
      'Edit resume experience',
      'Edit resume education',
      'Edit resume skills',
      'Template selection & switching',
      'Resume preview rendering',
      'PDF generation & download',
      'Save / auto-save functionality',
      'Delete / duplicate resume',
      'Import / export data'
    )
    Variants = @(
      'Happy path execution',
      'Required field validation',
      'Invalid input handling',
      'Edit and resave flow',
      'Delete or duplicate flow',
      'Persistence after save',
      'Auto-save recovery',
      'Large data handling',
      'Offline or reconnect recovery',
      'Permission and session continuity'
    )
  },
  [ordered]@{
    Name = 'UI / UX Testing'
    Priority = 'Medium'
    Severity = 'Medium'
    Features = @(
      'Alignment and spacing',
      'Typography and font readability',
      'Responsive layout across screen sizes',
      'Dark mode / light mode',
      'Template design consistency',
      'Button visibility and accessibility',
      'Validation messages, scroll behavior, and profile image alignment'
    )
    Variants = @(
      'Desktop viewport review',
      'Tablet viewport review',
      'Mobile viewport review',
      'Dark theme review',
      'Light theme review',
      'Keyboard and focus review',
      'Screen reader and contrast review',
      'Validation message placement review',
      'Scroll and sticky element review',
      'Profile image and icon alignment review'
    )
  },
  [ordered]@{
    Name = 'Performance Testing'
    Priority = 'High'
    Severity = 'High'
    Features = @(
      'App launch time',
      'Resume loading time',
      'Template switching speed',
      'PDF generation time',
      'Large resume handling',
      'Memory and CPU usage'
    )
    Variants = @(
      'Cold start baseline',
      'Warm start baseline',
      'High data volume',
      'Repeated action loop',
      'Concurrent background tasks',
      'Low memory condition',
      'CPU stress condition',
      'Slow network condition',
      'Offline cache condition',
      'Long session endurance'
    )
  },
  [ordered]@{
    Name = 'Security Testing'
    Priority = 'High'
    Severity = 'Critical'
    Features = @(
      'Authentication validation',
      'Data encryption for local and API data',
      'Secure API calls',
      'Unauthorized access prevention',
      'Session timeout',
      'Input validation against injection',
      'File access permissions'
    )
    Variants = @(
      'Valid authenticated user',
      'Expired session',
      'Unauthorized user attempt',
      'Tampered request payload',
      'Malformed input payload',
      'Token refresh failure',
      'Local storage inspection',
      'File permission denial',
      'Brute-force or repeated request attempt',
      'Logout and session invalidation'
    )
  },
  [ordered]@{
    Name = 'Compatibility Testing'
    Priority = 'High'
    Severity = 'High'
    Features = @(
      'Android version compatibility',
      'iOS compatibility',
      'Small-screen device compatibility',
      'Large-screen device compatibility',
      'Chrome and Edge browser compatibility',
      'Safari browser compatibility'
    )
    Variants = @(
      'Create resume flow',
      'Edit experience flow',
      'Edit skills flow',
      'Template switching flow',
      'Preview and PDF flow',
      'Subscription purchase flow',
      'Image upload flow',
      'Autosave and restore flow',
      'Offline and reconnect flow',
      'Settings and theme flow'
    )
  },
  [ordered]@{
    Name = 'Integration Testing'
    Priority = 'High'
    Severity = 'High'
    Features = @(
      'Resume editor and template rendering integration',
      'Resume data to PDF generation integration',
      'API to backend sync integration',
      'Payment system integration',
      'Image upload to preview integration'
    )
    Variants = @(
      'Primary success path',
      'Partial data path',
      'Validation failure path',
      'Slow dependency path',
      'Timeout and retry path',
      'State persistence path',
      'Cross-screen navigation path',
      'Concurrent update path',
      'Rollback after failure path',
      'Post-update compatibility path'
    )
  },
  [ordered]@{
    Name = 'Regression Testing'
    Priority = 'High'
    Severity = 'High'
    Features = @(
      'Editing resume after app update',
      'Old resume rendering after updates',
      'Template stability after changes',
      'Premium / payment feature stability'
    )
    Variants = @(
      'Previously fixed bug replay',
      'Happy path smoke replay',
      'Saved draft replay',
      'Multi-resume replay',
      'Template switch replay',
      'PDF export replay',
      'Subscription replay',
      'Offline replay',
      'Localization replay',
      'Profile image replay'
    )
  },
  [ordered]@{
    Name = 'Mobile-Specific Testing'
    Priority = 'High'
    Severity = 'High'
    Features = @(
      'App installation and uninstallation',
      'Background and foreground behavior',
      'Push notifications',
      'Offline mode handling',
      'Network switching between WiFi and mobile data',
      'Battery usage'
    )
    Variants = @(
      'Fresh install',
      'Upgrade install',
      'Cold launch',
      'Resume editing in foreground',
      'App sent to background',
      'Notification received',
      'Offline editing',
      'Network transition',
      'Low battery mode',
      'Device restart recovery'
    )
  },
  [ordered]@{
    Name = 'Payment & Subscription Testing'
    Priority = 'High'
    Severity = 'Critical'
    Features = @(
      'Subscription purchase flows',
      'Free trial activation',
      'Upgrade and downgrade plans',
      'Payment failure handling',
      'Refund handling',
      'Feature unlock after payment',
      'Restore purchases'
    )
    Variants = @(
      'Successful purchase',
      'Cancelled purchase',
      'Declined payment',
      'Store timeout',
      'Free trial start',
      'Upgrade plan',
      'Downgrade plan',
      'Restore purchases',
      'Refund processed',
      'Feature entitlement sync'
    )
  },
  [ordered]@{
    Name = 'PDF & Export Testing'
    Priority = 'High'
    Severity = 'Critical'
    Features = @(
      'PDF layout accuracy',
      'Font consistency in export',
      'Text overlap prevention',
      'Page break correctness',
      'Multi-page resume export',
      'Image rendering in export',
      'ATS-friendly format validation',
      'Export file size optimization'
    )
    Variants = @(
      'Single-page simple resume',
      'Multi-page detailed resume',
      'Long text wrapping',
      'Large profile image',
      'Template switch before export',
      'Non-English content export',
      'Special character export',
      'Low storage export',
      'Repeat export cycle',
      'Share and download verification'
    )
  },
  [ordered]@{
    Name = 'Localization Testing'
    Priority = 'Medium'
    Severity = 'Medium'
    Features = @(
      'Language translation support',
      'Date format rendering',
      'Currency format rendering',
      'Localized text overflow handling'
    )
    Variants = @(
      'English default locale',
      'French locale',
      'Spanish locale',
      'German locale',
      'Arabic or RTL locale',
      'Long translated text',
      'Locale switch during editing',
      'Localized export preview',
      'Localized date and number rendering',
      'Fallback when translation is missing'
    )
  },
  [ordered]@{
    Name = 'Usability Testing'
    Priority = 'Medium'
    Severity = 'Medium'
    Features = @(
      'Create resume within five minutes',
      'Intuitive navigation flow',
      'Understandable error messages',
      'Easy template selection'
    )
    Variants = @(
      'First-time user journey',
      'Returning user journey',
      'Fast resume creation flow',
      'Guided editing flow',
      'Template comparison flow',
      'Preview review flow',
      'Export completion flow',
      'Error recovery flow',
      'Subscription decision flow',
      'Help or settings discovery flow'
    )
  },
  [ordered]@{
    Name = 'Error Handling & Negative Testing'
    Priority = 'High'
    Severity = 'High'
    Features = @(
      'Empty field submission',
      'Invalid email and phone formats',
      'Network failure during save',
      'PDF generation failure',
      'App crash scenario recovery',
      'Large image upload handling'
    )
    Variants = @(
      'Empty mandatory fields',
      'Whitespace-only input',
      'Malformed email or phone',
      'Excessively long text',
      'Large image upload',
      'Corrupted image upload',
      'Save during network loss',
      'Preview failure simulation',
      'PDF export failure simulation',
      'Unexpected app interruption'
    )
  },
  [ordered]@{
    Name = 'API Testing'
    Priority = 'High'
    Severity = 'High'
    Features = @(
      'Request and response validation',
      'HTTP status code handling',
      'Data consistency across API responses',
      'Timeout handling',
      'Retry mechanism'
    )
    Variants = @(
      '200 OK success',
      '400 validation error',
      '401 unauthorized',
      '403 forbidden',
      '404 not found',
      '429 rate limit',
      '500 server error',
      'Slow response timeout',
      'Retry after transient failure',
      'Data mismatch reconciliation'
    )
  },
  [ordered]@{
    Name = 'Automation Testing'
    Priority = 'High'
    Severity = 'Medium'
    Features = @(
      'Smoke automation coverage',
      'Regression suite automation',
      'API automation coverage',
      'UI automation for create, edit, and download flows'
    )
    Variants = @(
      'Smoke suite candidate',
      'High-value regression candidate',
      'API contract automation candidate',
      'UI happy path automation candidate',
      'Cross-browser automation candidate',
      'Visual regression candidate',
      'Performance monitor automation candidate',
      'Data-driven automation candidate',
      'CI pipeline gating candidate',
      'Post-release monitoring automation candidate'
    )
  },
  [ordered]@{
    Name = 'Analytics & Tracking Testing'
    Priority = 'Medium'
    Severity = 'Medium'
    Features = @(
      'Event tracking',
      'Funnel tracking',
      'Crash analytics',
      'User behavior tracking'
    )
    Variants = @(
      'Resume created event',
      'Resume edited event',
      'Template switched event',
      'Preview opened event',
      'PDF downloaded event',
      'Subscription started event',
      'Upgrade attempted event',
      'Purchase failure event',
      'Crash captured event',
      'Screen funnel progression event'
    )
  },
  [ordered]@{
    Name = 'Installation & Release Testing'
    Priority = 'High'
    Severity = 'High'
    Features = @(
      'APK / AAB installation',
      'App update flow',
      'Version upgrade compatibility',
      'Permissions handling'
    )
    Variants = @(
      'Clean install verification',
      'Upgrade from previous version',
      'Downgrade protection check',
      'Permission prompt handling',
      'First launch after install',
      'First launch after update',
      'Deep link and share intent check',
      'Rollback readiness check',
      'Store listing build sanity',
      'Release candidate smoke verification'
    )
  }
)

function Get-BucketFocus {
  param([string]$BucketName)

  switch ($BucketName) {
    'Functional Testing' { 'core business behavior and data persistence' }
    'UI / UX Testing' { 'layout, readability, accessibility, and ease of use' }
    'Performance Testing' { 'response time, resource usage, and stability' }
    'Security Testing' { 'data protection, authorization, and safe input handling' }
    'Compatibility Testing' { 'consistent behavior across devices, browsers, and form factors' }
    'Integration Testing' { 'connected modules, data handoff, and downstream results' }
    'Regression Testing' { 'previously stable workflows after recent changes' }
    'Mobile-Specific Testing' { 'mobile lifecycle behavior, connectivity transitions, and battery impact' }
    'Payment & Subscription Testing' { 'billing state, entitlements, and store-driven outcomes' }
    'PDF & Export Testing' { 'document fidelity, file creation, and download/share behavior' }
    'Localization Testing' { 'locale-aware content, formatting, and text fit' }
    'Usability Testing' { 'user clarity, speed, and intuitive interaction' }
    'Error Handling & Negative Testing' { 'safe failure behavior and recovery messaging' }
    'API Testing' { 'request reliability, response validation, and retry behavior' }
    'Automation Testing' { 'repeatability, coverage potential, and CI suitability' }
    'Analytics & Tracking Testing' { 'telemetry accuracy, funnel visibility, and crash insight' }
    'Installation & Release Testing' { 'release readiness, installation safety, and post-update stability' }
    default { 'expected application behavior' }
  }
}

function Get-Preconditions {
  param(
    [string]$BucketName,
    [string]$Feature,
    [string]$Variant
  )

  $base = 'Latest supported Resume Builder build is available, the tester can sign in if required, and a representative resume dataset is ready.'

  switch ($BucketName) {
    'Security Testing' {
      return "$base Test accounts, session tokens, and safe ways to simulate authorization or input-security conditions are available for $Feature during '$Variant'."
    }
    'Performance Testing' {
      return "$base Device or browser performance monitoring is enabled, and timing baselines are available for $Feature during '$Variant'."
    }
    'Compatibility Testing' {
      return "$base The target device, OS, browser, or viewport required for $Feature is available and configured for '$Variant'."
    }
    'Payment & Subscription Testing' {
      return "$base Sandbox billing accounts, test products, and entitlement verification steps are prepared for $Feature during '$Variant'."
    }
    'API Testing' {
      return "$base API logging, mockable backend responses, and timeout or retry controls are prepared for $Feature during '$Variant'."
    }
    'Installation & Release Testing' {
      return "$base The target install package, version baseline, and required permissions are prepared for $Feature during '$Variant'."
    }
    default {
      return "$base The workflow for $Feature is reachable and the environment is prepared for '$Variant'."
    }
  }
}

function Get-TestData {
  param(
    [string]$BucketName,
    [string]$Feature,
    [string]$Variant
  )

  switch ($BucketName) {
    'Functional Testing' { return "Valid, boundary, and invalid inputs for $Feature aligned to '$Variant'." }
    'UI / UX Testing' { return "Representative resume content, profile image assets, and viewport/theme settings aligned to '$Variant'." }
    'Performance Testing' { return "Small, medium, and large resume data sets with environment controls aligned to '$Variant'." }
    'Security Testing' { return "Authorized, unauthorized, malformed, and tampered inputs aligned to '$Variant' for $Feature." }
    'Compatibility Testing' { return "Representative resume data executed on the target browser, device, or screen profile for '$Variant'." }
    'Integration Testing' { return "Resume data, linked service responses, and state transitions aligned to '$Variant'." }
    'Regression Testing' { return "Known-good historical test data, previously fixed scenarios, and current build data aligned to '$Variant'." }
    'Mobile-Specific Testing' { return "Mobile device state, connectivity, notification payloads, and resume data aligned to '$Variant'." }
    'Payment & Subscription Testing' { return "Sandbox payment profiles, subscription plans, and entitlement states aligned to '$Variant'." }
    'PDF & Export Testing' { return "Single-page, multi-page, multilingual, and image-heavy resume data aligned to '$Variant'." }
    'Localization Testing' { return "Localized strings, translated labels, and locale-specific date or number values aligned to '$Variant'." }
    'Usability Testing' { return "Representative end-user data, first-time-user context, and common task flows aligned to '$Variant'." }
    'Error Handling & Negative Testing' { return "Invalid, empty, interrupted, or oversized data aligned to '$Variant' for $Feature." }
    'API Testing' { return "API payloads and mocked service responses aligned to '$Variant' for $Feature." }
    'Automation Testing' { return "Stable seed data, reusable fixtures, selectors, and assertions aligned to '$Variant'." }
    'Analytics & Tracking Testing' { return "Telemetry payloads, analytics identifiers, and user journey data aligned to '$Variant'." }
    'Installation & Release Testing' { return "Build artifacts, version metadata, install state, and permission settings aligned to '$Variant'." }
    default { return "Representative data aligned to '$Variant' for $Feature." }
  }
}

function Get-TestSteps {
  param(
    [string]$BucketName,
    [string]$Feature,
    [string]$Variant
  )

  return @(
    "1. Launch the latest supported Resume Builder build and prepare the environment for $BucketName.",
    "2. Navigate to the workflow, screen, or service path that exercises $Feature.",
    "3. Execute the '$Variant' scenario using the prepared data and observe the app behavior for $Feature.",
    "4. Verify the resulting data, UI state, downstream integration, and user feedback match the expected $BucketName outcome."
  ) -join ' '
}

function Get-ExpectedResult {
  param(
    [string]$BucketName,
    [string]$Feature,
    [string]$Variant
  )

  switch ($BucketName) {
    'Functional Testing' {
      return "$Feature works correctly for '$Variant', persists the right data, and does not block the user from completing the intended workflow."
    }
    'UI / UX Testing' {
      return "$Feature remains visually consistent and accessible for '$Variant', with no broken alignment, clipping, unreadable text, or confusing interaction."
    }
    'Performance Testing' {
      return "$Feature stays within acceptable performance thresholds for '$Variant', with stable memory or CPU behavior and no visible lag or crash."
    }
    'Security Testing' {
      return "$Feature enforces the required security controls for '$Variant', blocks unsafe access or input, and preserves confidentiality and integrity of user data."
    }
    'Compatibility Testing' {
      return "$Feature behaves consistently for '$Variant' across the targeted device, browser, or screen profile without layout, interaction, or data issues."
    }
    'Integration Testing' {
      return "$Feature exchanges data correctly with connected modules during '$Variant', and the full handoff chain completes without mismatch or silent failure."
    }
    'Regression Testing' {
      return "$Feature continues to behave like the previously accepted baseline for '$Variant', and no earlier fix or stable path is broken."
    }
    'Mobile-Specific Testing' {
      return "$Feature remains stable during '$Variant' on mobile, with correct lifecycle handling, connectivity behavior, and acceptable resource usage."
    }
    'Payment & Subscription Testing' {
      return "$Feature handles '$Variant' correctly by updating billing state, entitlements, messaging, and locked or unlocked features without inconsistency."
    }
    'PDF & Export Testing' {
      return "$Feature produces a correct export result for '$Variant', with accurate layout, valid file output, readable text, and no corruption or overlap."
    }
    'Localization Testing' {
      return "$Feature renders localized content correctly for '$Variant', with proper formatting, readable text, and no translation fallback defects that block the flow."
    }
    'Usability Testing' {
      return "$Feature remains understandable and efficient for '$Variant', helping the user complete the task quickly with clear guidance and recoverable errors."
    }
    'Error Handling & Negative Testing' {
      return "$Feature handles '$Variant' safely by preventing data corruption, showing clear feedback, and allowing graceful recovery without an app crash."
    }
    'API Testing' {
      return "$Feature processes '$Variant' correctly at the API layer, with proper validation, status handling, retry behavior, and consistent returned data."
    }
    'Automation Testing' {
      return "$Feature is suitable for '$Variant' automation with stable setup, deterministic assertions, and strong value for recurring verification in CI or regression runs."
    }
    'Analytics & Tracking Testing' {
      return "$Feature emits correct telemetry for '$Variant', with accurate event timing, payload structure, and funnel or crash visibility for downstream analytics."
    }
    'Installation & Release Testing' {
      return "$Feature supports '$Variant' safely in release conditions, including correct install or update behavior, permissions, and post-release startup stability."
    }
    default {
      return "$Feature behaves correctly for '$Variant' and meets the expected user-visible outcome."
    }
  }
}

function Escape-XmlText {
  param([string]$Text)

  if ($null -eq $Text) {
    return ''
  }

  return [System.Security.SecurityElement]::Escape($Text)
}

function Get-ExcelColumnName {
  param([int]$Index)

  $name = ''
  $dividend = $Index
  while ($dividend -gt 0) {
    $modulo = ($dividend - 1) % 26
    $name = [char](65 + $modulo) + $name
    $dividend = [math]::Floor(($dividend - $modulo) / 26)
  }

  return $name
}

function New-InlineCell {
  param(
    [string]$CellReference,
    [string]$Value,
    [int]$StyleIndex
  )

  $escapedValue = Escape-XmlText $Value
  return ('<c r="{0}" t="inlineStr" s="{1}"><is><t xml:space="preserve">{2}</t></is></c>' -f $CellReference, $StyleIndex, $escapedValue)
}

$rows = New-Object System.Collections.Generic.List[object]
$caseNumber = 1

foreach ($bucket in $bucketConfigs) {
  foreach ($feature in $bucket.Features) {
    foreach ($variant in $bucket.Variants) {
      $row = [ordered]@{
        'S.No' = $caseNumber
        'Test Case ID' = 'TC_' + $caseNumber.ToString('D4')
        'Test Case Title / Name' = "$($bucket.Name) - $feature - $variant"
        'Description' = "Validate $feature under $($bucket.Name) for the '$variant' scenario in the Resume Builder app."
        'Preconditions' = Get-Preconditions -BucketName $bucket.Name -Feature $feature -Variant $variant
        'Test Steps' = Get-TestSteps -BucketName $bucket.Name -Feature $feature -Variant $variant
        'Test Data' = Get-TestData -BucketName $bucket.Name -Feature $feature -Variant $variant
        'Expected Result' = Get-ExpectedResult -BucketName $bucket.Name -Feature $feature -Variant $variant
        'Actual Result' = ''
        'Status (Pass/Fail)' = 'Not Executed'
        'Priority (High/Medium/Low)' = $bucket.Priority
        'Severity' = $bucket.Severity
        'Module / Feature Name' = $feature
      }

      $rows.Add([pscustomobject]$row)
      $caseNumber++
    }
  }
}

if ($rows.Count -ne 1000) {
  throw "Expected exactly 1000 test cases, but generated $($rows.Count)."
}

$rows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

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

  $lastRow = $rows.Count + 1
  $lastColumnName = Get-ExcelColumnName $requiredColumns.Count
  $sheetRange = "A1:${lastColumnName}${lastRow}"

  $columnWidths = @(8, 14, 42, 44, 34, 52, 28, 42, 24, 18, 18, 14, 28)
  $colsXml = for ($i = 0; $i -lt $columnWidths.Count; $i++) {
    $columnIndex = $i + 1
    ('<col min="{0}" max="{0}" width="{1}" customWidth="1"/>' -f $columnIndex, $columnWidths[$i])
  }

  $headerCells = for ($columnIndex = 0; $columnIndex -lt $requiredColumns.Count; $columnIndex++) {
    $cellRef = "$(Get-ExcelColumnName ($columnIndex + 1))1"
    New-InlineCell -CellReference $cellRef -Value $requiredColumns[$columnIndex] -StyleIndex 1
  }

  $rowXml = New-Object System.Collections.Generic.List[string]
  $rowXml.Add(('<row r="1" ht="22" customHeight="1">{0}</row>' -f ($headerCells -join '')))

  $rowIndex = 2
  foreach ($row in $rows) {
    $cells = for ($columnIndex = 0; $columnIndex -lt $requiredColumns.Count; $columnIndex++) {
      $columnName = $requiredColumns[$columnIndex]
      $cellRef = "$(Get-ExcelColumnName ($columnIndex + 1))$rowIndex"
      New-InlineCell -CellReference $cellRef -Value ([string]$row.$columnName) -StyleIndex 2
    }

    $rowXml.Add(('<row r="{0}">{1}</row>' -f $rowIndex, ($cells -join '')))
    $rowIndex++
  }

  $worksheetXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheetViews>
    <sheetView workbookViewId="0">
      <pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>
    </sheetView>
  </sheetViews>
  <sheetFormatPr defaultRowHeight="15"/>
  <cols>
    $($colsXml -join "`n    ")
  </cols>
  <sheetData>
    $($rowXml -join "`n    ")
  </sheetData>
  <autoFilter ref="$sheetRange"/>
</worksheet>
"@

  $stylesXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="2">
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
  </fonts>
  <fills count="3">
    <fill><patternFill patternType="none"/></fill>
    <fill><patternFill patternType="gray125"/></fill>
    <fill>
      <patternFill patternType="solid">
        <fgColor rgb="FF3B5BDB"/>
        <bgColor indexed="64"/>
      </patternFill>
    </fill>
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
  <cellXfs count="3">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
    <xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1">
      <alignment horizontal="center" vertical="center" wrapText="1"/>
    </xf>
    <xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1" applyAlignment="1">
      <alignment vertical="top" wrapText="1"/>
    </xf>
  </cellXfs>
  <cellStyles count="1">
    <cellStyle name="Normal" xfId="0" builtinId="0"/>
  </cellStyles>
</styleSheet>
"@

  $workbookXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="Resume App 1000 Tests" sheetId="1" r:id="rId1"/>
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
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
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
  <dc:title>Resume App 1000 Test Cases</dc:title>
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
      <vt:variant><vt:i4>1</vt:i4></vt:variant>
    </vt:vector>
  </HeadingPairs>
  <TitlesOfParts>
    <vt:vector size="1" baseType="lpstr">
      <vt:lpstr>Resume App 1000 Tests</vt:lpstr>
    </vt:vector>
  </TitlesOfParts>
  <Company></Company>
  <LinksUpToDate>false</LinksUpToDate>
  <SharedDoc>false</SharedDoc>
  <HyperlinksChanged>false</HyperlinksChanged>
  <AppVersion>16.0300</AppVersion>
</Properties>
"@

  [System.IO.File]::WriteAllText((Join-Path $tempRoot '[Content_Types].xml'), $contentTypesXml, [System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText((Join-Path $relsDir '.rels'), $packageRelsXml, [System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText((Join-Path $docPropsDir 'core.xml'), $coreXml, [System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText((Join-Path $docPropsDir 'app.xml'), $appXml, [System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText((Join-Path $xlDir 'workbook.xml'), $workbookXml, [System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText((Join-Path $xlRelsDir 'workbook.xml.rels'), $workbookRelsXml, [System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText((Join-Path $xlDir 'styles.xml'), $stylesXml, [System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText((Join-Path $xlWorksheetsDir 'sheet1.xml'), $worksheetXml, [System.Text.UTF8Encoding]::new($false))

  if (Test-Path $xlsxPath) {
    Remove-Item $xlsxPath -Force
  }

  [System.IO.Compression.ZipFile]::CreateFromDirectory($tempRoot, $xlsxPath)

  Write-Host "Created CSV file : $csvPath"
  Write-Host "Created Excel workbook: $xlsxPath"
  Write-Host "Generated test cases : $($rows.Count)"
}
finally {
  if (Test-Path $tempRoot) {
    Remove-Item $tempRoot -Recurse -Force
  }
}