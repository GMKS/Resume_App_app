$ErrorActionPreference = 'Stop'

$workspaceRoot = $PSScriptRoot
$sourceCsvPath = Join-Path $workspaceRoot 'resume_app_comprehensive_test_case_sheet.csv'
$outputCsvPath = Join-Path $workspaceRoot 'resume_app_test_suite_1000.csv'
$outputXlsxPath = Join-Path $workspaceRoot 'resume_app_test_suite_1000.xlsx'
$summaryPath = Join-Path $workspaceRoot 'resume_app_test_suite_1000_summary.md'

if (-not (Test-Path $sourceCsvPath)) {
  throw "Source CSV not found: $sourceCsvPath"
}

$requiredColumns = @(
  'Test Case ID',
  'Test Scenario',
  'Test Case Description',
  'Module / Feature',
  'Preconditions',
  'Test Steps',
  'Test Data',
  'Expected Result',
  'Actual Result',
  'Status',
  'Priority',
  'Severity',
  'Test Type',
  'Environment',
  'Browser/Device',
  'Automation Feasibility',
  'Remarks'
)

$scenarioOrder = @(
  'Primary Flow',
  'Boundary & Validation',
  'Failure & Recovery',
  'Persistence & Restore',
  'Cross-Platform & Locale'
)

$typeDefinitions = [ordered]@{
  'Functional Testing' = [ordered]@{
    SourceType = 'Functional Testing'
    ColorName = 'Green'
    FillRgb = 'FFC6EFCE'
    DefaultPriority = 'High'
    DefaultSeverity = 'Major'
    Automation = 'Yes'
    DescriptionTemplate = 'Validate core business behavior for {0} under the {1} scenario.'
    RemarksTemplate = 'Color Code: Green | Source Coverage: Functional Testing | Feature Area: {0}'
  }
  'Regression Testing' = [ordered]@{
    SourceType = 'Regression Testing'
    ColorName = 'Blue'
    FillRgb = 'FFBDD7EE'
    DefaultPriority = 'High'
    DefaultSeverity = 'Major'
    Automation = 'Yes'
    DescriptionTemplate = 'Confirm previously working behavior for {0} remains intact under the {1} scenario after recent changes.'
    RemarksTemplate = 'Color Code: Blue | Source Coverage: Regression Testing | Feature Area: {0}'
  }
  'UI/UX Testing' = [ordered]@{
    SourceType = 'UI Testing'
    ColorName = 'Purple'
    FillRgb = 'FFE4D4F4'
    DefaultPriority = 'Medium'
    DefaultSeverity = 'Minor'
    Automation = 'No'
    DescriptionTemplate = 'Validate layout, interaction clarity, visual consistency, and state feedback for {0} under the {1} scenario.'
    RemarksTemplate = 'Color Code: Purple | Source Coverage: UI Testing | Feature Area: {0}'
  }
  'System Testing' = [ordered]@{
    SourceType = 'End-to-End Testing'
    ColorName = 'Slate Gray'
    FillRgb = 'FFE5E7EB'
    DefaultPriority = 'High'
    DefaultSeverity = 'Major'
    Automation = 'Yes'
    DescriptionTemplate = 'Validate the complete in-app behavior for {0} within the live system context under the {1} scenario.'
    RemarksTemplate = 'Color Code: Slate Gray | Adapted from End-to-End Testing for System coverage | Feature Area: {0}'
  }
  'Integration Testing' = [ordered]@{
    SourceType = 'Integration Testing'
    ColorName = 'Mint'
    FillRgb = 'FFD9EAD3'
    DefaultPriority = 'High'
    DefaultSeverity = 'Major'
    Automation = 'Yes'
    DescriptionTemplate = 'Validate component, storage, navigation, or service handoff for {0} under the {1} scenario.'
    RemarksTemplate = 'Color Code: Mint | Source Coverage: Integration Testing | Feature Area: {0}'
  }
  'API Testing' = [ordered]@{
    SourceType = 'API Testing'
    ColorName = 'Orange'
    FillRgb = 'FFFCE5CD'
    DefaultPriority = 'High'
    DefaultSeverity = 'Major'
    Automation = 'Yes'
    DescriptionTemplate = 'Validate request, response, timeout, retry, and error-mapping behavior for {0} under the {1} scenario.'
    RemarksTemplate = 'Color Code: Orange | Source Coverage: API Testing | Feature Area: {0}'
  }
  'Performance Testing' = [ordered]@{
    SourceType = 'Performance Testing'
    ColorName = 'Red'
    FillRgb = 'FFF4CCCC'
    DefaultPriority = 'High'
    DefaultSeverity = 'Major'
    Automation = 'Yes'
    DescriptionTemplate = 'Validate response time, rendering, memory, and stability for {0} under the {1} scenario.'
    RemarksTemplate = 'Color Code: Red | Source Coverage: Performance Testing | Feature Area: {0}'
  }
  'Security Testing' = [ordered]@{
    SourceType = 'Security Testing'
    ColorName = 'Dark Red'
    FillRgb = 'FFE6B8AF'
    DefaultPriority = 'High'
    DefaultSeverity = 'Critical'
    Automation = 'Yes'
    DescriptionTemplate = 'Validate access control, sensitive data handling, abuse resistance, and secure failure behavior for {0} under the {1} scenario.'
    RemarksTemplate = 'Color Code: Dark Red | Source Coverage: Security Testing | Feature Area: {0}'
  }
  'Usability Testing' = [ordered]@{
    SourceType = 'Usability Testing'
    ColorName = 'Peach'
    FillRgb = 'FFFFE5CC'
    DefaultPriority = 'Medium'
    DefaultSeverity = 'Minor'
    Automation = 'No'
    DescriptionTemplate = 'Validate discoverability, task clarity, and ease of completion for {0} under the {1} scenario.'
    RemarksTemplate = 'Color Code: Peach | Source Coverage: Usability Testing | Feature Area: {0}'
  }
  'Compatibility Testing' = [ordered]@{
    SourceType = 'Compatibility Testing'
    ColorName = 'Teal'
    FillRgb = 'FFD9E2E3'
    DefaultPriority = 'High'
    DefaultSeverity = 'Major'
    Automation = 'Yes'
    DescriptionTemplate = 'Validate supported browser, device, and OS consistency for {0} under the {1} scenario.'
    RemarksTemplate = 'Color Code: Teal | Source Coverage: Compatibility Testing | Feature Area: {0}'
  }
  'Accessibility Testing' = [ordered]@{
    SourceType = 'Accessibility Testing'
    ColorName = 'Yellow'
    FillRgb = 'FFFFF2CC'
    DefaultPriority = 'High'
    DefaultSeverity = 'Major'
    Automation = 'Yes'
    DescriptionTemplate = 'Validate keyboard, focus, screen-reader, scaling, and contrast behavior for {0} under the {1} scenario.'
    RemarksTemplate = 'Color Code: Yellow | Source Coverage: Accessibility Testing | Feature Area: {0}'
  }
  'Smoke Testing' = [ordered]@{
    SourceType = 'Functional Testing'
    ColorName = 'Light Blue'
    FillRgb = 'FFDDEBF7'
    DefaultPriority = 'High'
    DefaultSeverity = 'Critical'
    Automation = 'Yes'
    DescriptionTemplate = 'Quickly verify the release-blocking critical path for {0} under the {1} scenario.'
    RemarksTemplate = 'Color Code: Light Blue | Derived from Functional Testing for release smoke validation | Feature Area: {0}'
  }
  'Sanity Testing' = [ordered]@{
    SourceType = 'Regression Testing'
    ColorName = 'Pink'
    FillRgb = 'FFFCE4EC'
    DefaultPriority = 'High'
    DefaultSeverity = 'Major'
    Automation = 'Yes'
    DescriptionTemplate = 'Perform targeted post-change validation for {0} under the {1} scenario.'
    RemarksTemplate = 'Color Code: Pink | Derived from Regression Testing for targeted sanity validation | Feature Area: {0}'
  }
}

$typeOrder = @(
  'Functional Testing',
  'System Testing',
  'Integration Testing',
  'Regression Testing',
  'Smoke Testing',
  'Sanity Testing',
  'UI/UX Testing',
  'API Testing',
  'Performance Testing',
  'Security Testing',
  'Usability Testing',
  'Compatibility Testing',
  'Accessibility Testing'
)

$specialTypeModules = [ordered]@{
  'Integration Testing' = @(
    'Resume Editor Shell',
    'Template Selection',
    'PDF Export / Print / Share',
    'Backup & Sync'
  )
  'API Testing' = @(
    'Phone / Twilio Authentication',
    'AI Resume Generator',
    'Job Search'
  )
  'Performance Testing' = @(
    'App Bootstrap & Splash',
    'PDF Export / Print / Share'
  )
  'Security Testing' = @(
    'Phone / Twilio Authentication',
    'Subscription & Entitlements'
  )
  'Usability Testing' = @(
    'Dashboard Home & Shortcuts',
    'Cover Letter Builder'
  )
  'Compatibility Testing' = @(
    'Template Selection',
    'Subscription & Entitlements'
  )
  'Accessibility Testing' = @(
    'Resume Editor Shell'
  )
  'Smoke Testing' = @(
    'App Bootstrap & Splash',
    'Phone / Twilio Authentication'
  )
  'Sanity Testing' = @(
    'Subscription & Entitlements',
    'PDF Export / Print / Share'
  )
}

function Get-OrderedUniqueValues {
  param(
    [object[]]$Rows,
    [string]$PropertyName
  )

  $seen = @{}
  $values = New-Object System.Collections.Generic.List[string]

  foreach ($row in $Rows) {
    $value = [string]$row.$PropertyName
    if (-not $seen.ContainsKey($value)) {
      $seen[$value] = $true
      $values.Add($value) | Out-Null
    }
  }

  return $values.ToArray()
}

function Get-EnvironmentValue {
  param(
    [string]$Platforms,
    [string]$TestType
  )

  if ($TestType -eq 'API Testing') {
    return 'API'
  }

  $values = New-Object System.Collections.Generic.List[string]
  if ($Platforms -match 'Android|iOS') {
    $values.Add('Mobile') | Out-Null
  }
  if ($Platforms -match 'Web|Windows') {
    $values.Add('Web') | Out-Null
  }

  if ($values.Count -eq 0) {
    return 'Mobile'
  }

  return ($values | Select-Object -Unique) -join ', '
}

function Get-BrowserDeviceValue {
  param(
    [string]$Platforms,
    [string]$TestType
  )

  if ($TestType -eq 'API Testing') {
    return 'Postman / REST Client / API Automation Runner'
  }

  $values = New-Object System.Collections.Generic.List[string]
  if ($Platforms -match 'Android') {
    $values.Add('Pixel 7 / Android 14') | Out-Null
  }
  if ($Platforms -match 'iOS') {
    $values.Add('iPhone 15 / iOS 18') | Out-Null
  }
  if ($Platforms -match 'Windows') {
    $values.Add('Windows 11 Laptop') | Out-Null
  }
  if ($Platforms -match 'Web') {
    $values.Add('Chrome Latest, Edge Latest, Safari Latest') | Out-Null
  }

  return ($values | Select-Object -Unique) -join ' | '
}

function Get-PriorityValue {
  param(
    [psobject]$SourceRow,
    [hashtable]$TypeDefinition
  )

  $sourcePriority = [string]$SourceRow.Priority
  if ([string]::IsNullOrWhiteSpace($sourcePriority)) {
    return $TypeDefinition.DefaultPriority
  }
  return $sourcePriority
}

function Get-SeverityValue {
  param(
    [psobject]$SourceRow,
    [hashtable]$TypeDefinition
  )

  $sourceSeverity = [string]$SourceRow.Severity
  if ([string]::IsNullOrWhiteSpace($sourceSeverity)) {
    return $TypeDefinition.DefaultSeverity
  }

  if ($TypeDefinition.DefaultSeverity -eq 'Critical') {
    return 'Critical'
  }

  switch ($sourceSeverity) {
    'High' { return 'Major' }
    'Medium' { return 'Minor' }
    'Low' { return 'Minor' }
    default { return $sourceSeverity }
  }
}

function Get-DescriptionValue {
  param(
    [psobject]$SourceRow,
    [string]$OutputType
  )

  $typeDef = $typeDefinitions[$OutputType]
  return [string]::Format(
    $typeDef.DescriptionTemplate,
    [string]$SourceRow.'Module Name',
    [string]$SourceRow.'Scenario Variant'
  )
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

function New-WorksheetXml {
  param(
    [object[]]$Rows,
    [string[]]$Headers,
    [int[]]$ColumnWidths,
    [hashtable]$TypeStyleMap
  )

  $lastRow = if ($Rows.Count -gt 0) { $Rows.Count + 1 } else { 1 }
  $lastColumn = Get-ExcelColumnName $Headers.Count
  $sheetRange = "A1:${lastColumn}${lastRow}"

  $colsXml = for ($i = 0; $i -lt $ColumnWidths.Count; $i++) {
    $columnIndex = $i + 1
    '<col min="{0}" max="{0}" width="{1}" customWidth="1"/>' -f $columnIndex, $ColumnWidths[$i]
  }

  $headerCells = for ($i = 0; $i -lt $Headers.Count; $i++) {
    $cellRef = "$(Get-ExcelColumnName ($i + 1))1"
    New-InlineCell -CellReference $cellRef -Value $Headers[$i] -StyleIndex 1
  }

  $rowXml = New-Object System.Collections.Generic.List[string]
  $rowXml.Add(('<row r="1" ht="22" customHeight="1">{0}</row>' -f ($headerCells -join ''))) | Out-Null

  $rowIndex = 2
  foreach ($row in $Rows) {
    $styleIndex = $TypeStyleMap[[string]$row.'Test Type']
    $cells = for ($i = 0; $i -lt $Headers.Count; $i++) {
      $columnName = $Headers[$i]
      $cellRef = "$(Get-ExcelColumnName ($i + 1))$rowIndex"
      New-InlineCell -CellReference $cellRef -Value ([string]$row.$columnName) -StyleIndex $styleIndex
    }

    $rowXml.Add(('<row r="{0}">{1}</row>' -f $rowIndex, ($cells -join ''))) | Out-Null
    $rowIndex++
  }

  return @"
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
}

function New-StylesXml {
  param(
    [string[]]$TypeNames,
    [hashtable]$TypeDefinitions,
    [ref]$TypeStyleMap
  )

  $fills = New-Object System.Collections.Generic.List[string]
  $fills.Add('<fill><patternFill patternType="none"/></fill>') | Out-Null
  $fills.Add('<fill><patternFill patternType="gray125"/></fill>') | Out-Null
  $fills.Add('<fill><patternFill patternType="solid"><fgColor rgb="FF1F4E78"/><bgColor indexed="64"/></patternFill></fill>') | Out-Null

  $cellXfs = New-Object System.Collections.Generic.List[string]
  $cellXfs.Add('<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>') | Out-Null
  $cellXfs.Add('<xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment horizontal="center" vertical="center" wrapText="1"/></xf>') | Out-Null

  $styleIndex = 2
  foreach ($typeName in $TypeNames) {
    $fillId = $fills.Count
    $fills.Add(('<fill><patternFill patternType="solid"><fgColor rgb="{0}"/><bgColor indexed="64"/></patternFill></fill>' -f $TypeDefinitions[$typeName].FillRgb)) | Out-Null
    $cellXfs.Add(('<xf numFmtId="0" fontId="0" fillId="{0}" borderId="1" xfId="0" applyFill="1" applyBorder="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>' -f $fillId)) | Out-Null
    $TypeStyleMap.Value[$typeName] = $styleIndex
    $styleIndex++
  }

  return @"
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
}

function New-WorkbookXml {
  return @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <bookViews>
    <workbookView xWindow="0" yWindow="0" windowWidth="24000" windowHeight="12000"/>
  </bookViews>
  <sheets>
    <sheet name="All Test Cases" sheetId="1" r:id="rId1"/>
  </sheets>
</workbook>
"@
}

function New-WorkbookRelsXml {
  return @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>
"@
}

function New-ContentTypesXml {
  return @"
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
}

function New-PackageRelsXml {
  return @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>
"@
}

function New-CoreXml {
  param([string]$Title)

  $utcNow = (Get-Date).ToUniversalTime().ToString('s') + 'Z'
  $escapedTitle = Escape-XmlText $Title

  return @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:creator>GitHub Copilot</dc:creator>
  <cp:lastModifiedBy>GitHub Copilot</cp:lastModifiedBy>
  <dcterms:created xsi:type="dcterms:W3CDTF">$utcNow</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">$utcNow</dcterms:modified>
  <dc:title>$escapedTitle</dc:title>
</cp:coreProperties>
"@
}

function New-AppXml {
  return @"
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
      <vt:lpstr>All Test Cases</vt:lpstr>
    </vt:vector>
  </TitlesOfParts>
  <Company></Company>
  <LinksUpToDate>false</LinksUpToDate>
  <SharedDoc>false</SharedDoc>
  <HyperlinksChanged>false</HyperlinksChanged>
  <AppVersion>16.0300</AppVersion>
</Properties>
"@
}

function New-XlsxWorkbook {
  param(
    [string]$WorkbookPath,
    [object[]]$Rows,
    [string[]]$Headers,
    [int[]]$ColumnWidths,
    [string[]]$TypeNames,
    [hashtable]$TypeDefinitions,
    [string]$WorkbookTitle
  )

  Add-Type -AssemblyName System.IO.Compression.FileSystem

  $typeStyleMap = @{}
  $tempRoot = Join-Path $workspaceRoot ([System.IO.Path]::GetRandomFileName())
  $zipPath = Join-Path $workspaceRoot ([System.IO.Path]::GetRandomFileName() + '.zip')
  $null = New-Item -ItemType Directory -Path $tempRoot

  try {
    $relsDir = Join-Path $tempRoot '_rels'
    $docPropsDir = Join-Path $tempRoot 'docProps'
    $xlDir = Join-Path $tempRoot 'xl'
    $xlRelsDir = Join-Path $xlDir '_rels'
    $worksheetsDir = Join-Path $xlDir 'worksheets'

    foreach ($dir in @($relsDir, $docPropsDir, $xlDir, $xlRelsDir, $worksheetsDir)) {
      $null = New-Item -ItemType Directory -Path $dir
    }

    $stylesXml = New-StylesXml -TypeNames $TypeNames -TypeDefinitions $TypeDefinitions -TypeStyleMap ([ref]$typeStyleMap)
    $sheetXml = New-WorksheetXml -Rows $Rows -Headers $Headers -ColumnWidths $ColumnWidths -TypeStyleMap $typeStyleMap

    [System.IO.File]::WriteAllText((Join-Path $tempRoot '[Content_Types].xml'), (New-ContentTypesXml), [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $relsDir '.rels'), (New-PackageRelsXml), [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $docPropsDir 'core.xml'), (New-CoreXml -Title $WorkbookTitle), [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $docPropsDir 'app.xml'), (New-AppXml), [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $xlDir 'workbook.xml'), (New-WorkbookXml), [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $xlRelsDir 'workbook.xml.rels'), (New-WorkbookRelsXml), [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $xlDir 'styles.xml'), $stylesXml, [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $worksheetsDir 'sheet1.xml'), $sheetXml, [System.Text.UTF8Encoding]::new($false))

    if (Test-Path $WorkbookPath) {
      Remove-Item $WorkbookPath -Force
    }
    if (Test-Path $zipPath) {
      Remove-Item $zipPath -Force
    }

    [System.IO.Compression.ZipFile]::CreateFromDirectory($tempRoot, $zipPath)
    Move-Item -Path $zipPath -Destination $WorkbookPath -Force
  }
  finally {
    if (Test-Path $tempRoot) {
      Remove-Item $tempRoot -Recurse -Force
    }
    if (Test-Path $zipPath) {
      Remove-Item $zipPath -Force
    }
  }
}

$sourceRows = Import-Csv -Path $sourceCsvPath

$moduleOrder = Get-OrderedUniqueValues -Rows $sourceRows -PropertyName 'Module Name'
$moduleOrderMap = @{}
for ($i = 0; $i -lt $moduleOrder.Count; $i++) {
  $moduleOrderMap[$moduleOrder[$i]] = $i
}

$scenarioOrderMap = @{}
for ($i = 0; $i -lt $scenarioOrder.Count; $i++) {
  $scenarioOrderMap[$scenarioOrder[$i]] = $i
}

$typeOrderMap = @{}
for ($i = 0; $i -lt $typeOrder.Count; $i++) {
  $typeOrderMap[$typeOrder[$i]] = $i
}

$rowLookup = @{}
foreach ($row in $sourceRows) {
  $key = '{0}|{1}|{2}' -f $row.'Module Name', $row.'Testing Type', $row.'Scenario Variant'
  $rowLookup[$key] = $row
}

$selectedCombos = New-Object System.Collections.Generic.List[object]
$commonTypes = @('Functional Testing', 'Regression Testing', 'UI/UX Testing', 'System Testing')

foreach ($moduleName in $moduleOrder) {
  foreach ($typeName in $commonTypes) {
    $selectedCombos.Add([pscustomobject]@{
      ModuleName = $moduleName
      OutputType = $typeName
      SourceType = $typeDefinitions[$typeName].SourceType
    }) | Out-Null
  }
}

foreach ($entry in $specialTypeModules.GetEnumerator()) {
  foreach ($moduleName in $entry.Value) {
    $selectedCombos.Add([pscustomobject]@{
      ModuleName = $moduleName
      OutputType = $entry.Key
      SourceType = $typeDefinitions[$entry.Key].SourceType
    }) | Out-Null
  }
}

if ($selectedCombos.Count -ne 200) {
  throw "Expected 200 module/type combinations, but built $($selectedCombos.Count)."
}

$generatedRows = New-Object System.Collections.Generic.List[object]
$testCaseNumber = 1

$sortedCombos = $selectedCombos | Sort-Object @(
  @{ Expression = { $moduleOrderMap[$_.ModuleName] } },
  @{ Expression = { $typeOrderMap[$_.OutputType] } }
)

foreach ($combo in $sortedCombos) {
  foreach ($scenarioName in $scenarioOrder) {
    $lookupKey = '{0}|{1}|{2}' -f $combo.ModuleName, $combo.SourceType, $scenarioName
    if (-not $rowLookup.ContainsKey($lookupKey)) {
      throw "Missing source row for: $lookupKey"
    }

    $sourceRow = $rowLookup[$lookupKey]
    $typeDef = $typeDefinitions[$combo.OutputType]

    $generatedRows.Add([pscustomobject][ordered]@{
      'Test Case ID' = 'QA_TC_' + $testCaseNumber.ToString('D4')
      'Test Scenario' = [string]$sourceRow.'Scenario Variant'
      'Test Case Description' = (Get-DescriptionValue -SourceRow $sourceRow -OutputType $combo.OutputType)
      'Module / Feature' = ('{0} / {1}' -f [string]$sourceRow.'Feature Area', [string]$sourceRow.'Module Name')
      'Preconditions' = [string]$sourceRow.Preconditions
      'Test Steps' = [string]$sourceRow.'Test Steps'
      'Test Data' = [string]$sourceRow.'Test Data'
      'Expected Result' = [string]$sourceRow.'Expected Result'
      'Actual Result' = ''
      'Status' = ''
      'Priority' = (Get-PriorityValue -SourceRow $sourceRow -TypeDefinition $typeDef)
      'Severity' = (Get-SeverityValue -SourceRow $sourceRow -TypeDefinition $typeDef)
      'Test Type' = $combo.OutputType
      'Environment' = (Get-EnvironmentValue -Platforms ([string]$sourceRow.Platforms) -TestType $combo.OutputType)
      'Browser/Device' = (Get-BrowserDeviceValue -Platforms ([string]$sourceRow.Platforms) -TestType $combo.OutputType)
      'Automation Feasibility' = [string]$typeDef.Automation
      'Remarks' = ([string]::Format($typeDef.RemarksTemplate, [string]$sourceRow.'Feature Area'))
    }) | Out-Null

    $testCaseNumber++
  }
}

if ($generatedRows.Count -ne 1000) {
  throw "Expected 1000 generated test cases, but created $($generatedRows.Count)."
}

$dedupeCount = ($generatedRows | Group-Object 'Module / Feature', 'Test Type', 'Test Scenario').Count
if ($dedupeCount -ne 1000) {
  throw 'Duplicate test cases detected in the generated output.'
}

$orderedOutputRows = $generatedRows | Select-Object $requiredColumns
$orderedOutputRows | Export-Csv -Path $outputCsvPath -NoTypeInformation -Encoding UTF8

$columnWidths = @(16, 20, 44, 30, 40, 70, 34, 42, 18, 12, 12, 12, 18, 14, 34, 16, 42)
New-XlsxWorkbook -WorkbookPath $outputXlsxPath -Rows $orderedOutputRows -Headers $requiredColumns -ColumnWidths $columnWidths -TypeNames $typeOrder -TypeDefinitions $typeDefinitions -WorkbookTitle 'Resume App Test Suite 1000'

$summaryLines = New-Object System.Collections.Generic.List[string]
$summaryLines.Add('# Resume App 1000 Test Case Suite') | Out-Null
$summaryLines.Add('') | Out-Null
$summaryLines.Add("- Generated CSV: $(Split-Path $outputCsvPath -Leaf)") | Out-Null
$summaryLines.Add("- Generated workbook: $(Split-Path $outputXlsxPath -Leaf)") | Out-Null
$summaryLines.Add("- Total test cases: $($orderedOutputRows.Count)") | Out-Null
$summaryLines.Add("- Distinct modules covered: $((($orderedOutputRows | ForEach-Object { $_.'Module / Feature' } | Select-Object -Unique).Count))") | Out-Null
$summaryLines.Add('') | Out-Null
$summaryLines.Add('## Coverage By Test Type') | Out-Null

foreach ($group in ($orderedOutputRows | Group-Object 'Test Type' | Sort-Object Name)) {
  $summaryLines.Add("- $($group.Name): $($group.Count)") | Out-Null
}

$summaryLines.Add('') | Out-Null
$summaryLines.Add('## Color Legend') | Out-Null
foreach ($typeName in $typeOrder) {
  $summaryLines.Add("- ${typeName}: $($typeDefinitions[$typeName].ColorName)") | Out-Null
}

[System.IO.File]::WriteAllLines($summaryPath, $summaryLines)

Write-Host "Generated 1000 test cases: $outputCsvPath"
Write-Host "Generated color-coded workbook: $outputXlsxPath"
Write-Host "Generated summary: $summaryPath"