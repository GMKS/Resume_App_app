$ErrorActionPreference = 'Stop'

$workspaceRoot = $PSScriptRoot
$sourceCsvPath = Join-Path $workspaceRoot 'important_testcases_resume_app_1000.csv'
$colorWorkbookPath = Join-Path $workspaceRoot 'important_testcases_resume_app_1000_color_coded.xlsx'
$categoryWorkbookPath = Join-Path $workspaceRoot 'important_testcases_resume_app_1000_by_category.xlsx'
$subsetCsvPath = Join-Path $workspaceRoot 'important_testcases_resume_app_high_priority_subset_260.csv'
$subsetWorkbookPath = Join-Path $workspaceRoot 'important_testcases_resume_app_high_priority_subset_260.xlsx'

if (-not (Test-Path $sourceCsvPath)) {
  throw "Source file not found: $sourceCsvPath"
}

$rows = Import-Csv -Path $sourceCsvPath
if ($rows.Count -ne 1000) {
  throw "Expected 1000 test cases in source CSV, found $($rows.Count)."
}

$headers = @(
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

$columnWidths = @(8, 14, 42, 44, 34, 52, 28, 42, 24, 18, 18, 14, 28)

function Get-CategoryName {
  param([psobject]$Row)

  $title = [string]$Row.'Test Case Title / Name'
  if ($title -match '^(.*?) - ') {
    return $matches[1]
  }

  return 'Uncategorized'
}

function Get-PriorityRank {
  param([string]$Priority)

  switch ($Priority) {
    'High' { return 3 }
    'Medium' { return 2 }
    'Low' { return 1 }
    default { return 0 }
  }
}

function Get-SeverityRank {
  param([string]$Severity)

  switch ($Severity) {
    'Critical' { return 4 }
    'High' { return 3 }
    'Medium' { return 2 }
    'Low' { return 1 }
    default { return 0 }
  }
}

function Get-SafeSheetName {
  param(
    [string]$Name,
    [hashtable]$UsedNames
  )

  $sheetName = $Name -replace '[\\/\?\*\[\]:]', '_'
  $sheetName = $sheetName -replace '&', 'and'
  $sheetName = $sheetName -replace '\s+', ' '
  $sheetName = $sheetName.Trim()

  if ($sheetName.Length -gt 31) {
    $sheetName = $sheetName.Substring(0, 31)
  }

  if ([string]::IsNullOrWhiteSpace($sheetName)) {
    $sheetName = 'Sheet'
  }

  $baseName = $sheetName
  $suffix = 1
  while ($UsedNames.ContainsKey($sheetName)) {
    $suffixText = "_$suffix"
    $maxBaseLength = 31 - $suffixText.Length
    $sheetName = $baseName
    if ($sheetName.Length -gt $maxBaseLength) {
      $sheetName = $sheetName.Substring(0, $maxBaseLength)
    }
    $sheetName = "$sheetName$suffixText"
    $suffix++
  }

  $UsedNames[$sheetName] = $true
  return $sheetName
}

function New-SubsetRows {
  param([object[]]$InputRows)

  $output = New-Object System.Collections.Generic.List[object]
  $sequence = 1

  foreach ($row in $InputRows) {
    $output.Add([pscustomobject][ordered]@{
      'S.No' = $sequence
      'Test Case ID' = $row.'Test Case ID'
      'Test Case Title / Name' = $row.'Test Case Title / Name'
      'Description' = $row.Description
      'Preconditions' = $row.Preconditions
      'Test Steps' = $row.'Test Steps'
      'Test Data' = $row.'Test Data'
      'Expected Result' = $row.'Expected Result'
      'Actual Result' = $row.'Actual Result'
      'Status (Pass/Fail)' = $row.'Status (Pass/Fail)'
      'Priority (High/Medium/Low)' = $row.'Priority (High/Medium/Low)'
      'Severity' = $row.Severity
      'Module / Feature Name' = $row.'Module / Feature Name'
    }) | Out-Null
    $sequence++
  }

  return $output.ToArray()
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

function Get-RowStyleIndex {
  param(
    [psobject]$Row,
    [bool]$ApplyRowColor
  )

  if (-not $ApplyRowColor) {
    return 2
  }

  switch ([string]$Row.Severity) {
    'Critical' { return 3 }
    'High' { return 4 }
    'Medium' { return 5 }
    'Low' { return 6 }
    default { return 2 }
  }
}

function New-WorksheetXml {
  param(
    [object[]]$SheetRows,
    [string[]]$Headers,
    [int[]]$ColumnWidths,
    [bool]$ApplyRowColor
  )

  $lastRow = if ($SheetRows.Count -gt 0) { $SheetRows.Count + 1 } else { 1 }
  $lastColumnName = Get-ExcelColumnName $Headers.Count
  $sheetRange = "A1:${lastColumnName}${lastRow}"

  $colsXml = for ($index = 0; $index -lt $ColumnWidths.Count; $index++) {
    $columnIndex = $index + 1
    '<col min="{0}" max="{0}" width="{1}" customWidth="1"/>' -f $columnIndex, $ColumnWidths[$index]
  }

  $headerCells = for ($columnIndex = 0; $columnIndex -lt $Headers.Count; $columnIndex++) {
    $cellRef = "$(Get-ExcelColumnName ($columnIndex + 1))1"
    New-InlineCell -CellReference $cellRef -Value $Headers[$columnIndex] -StyleIndex 1
  }

  $rowXml = New-Object System.Collections.Generic.List[string]
  $rowXml.Add(('<row r="1" ht="22" customHeight="1">{0}</row>' -f ($headerCells -join '')))

  $rowIndex = 2
  foreach ($row in $SheetRows) {
    $styleIndex = Get-RowStyleIndex -Row $row -ApplyRowColor $ApplyRowColor
    $cells = for ($columnIndex = 0; $columnIndex -lt $Headers.Count; $columnIndex++) {
      $columnName = $Headers[$columnIndex]
      $cellRef = "$(Get-ExcelColumnName ($columnIndex + 1))$rowIndex"
      New-InlineCell -CellReference $cellRef -Value ([string]$row.$columnName) -StyleIndex $styleIndex
    }

    $rowXml.Add(('<row r="{0}">{1}</row>' -f $rowIndex, ($cells -join '')))
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
  <fills count="7">
    <fill><patternFill patternType="none"/></fill>
    <fill><patternFill patternType="gray125"/></fill>
    <fill>
      <patternFill patternType="solid">
        <fgColor rgb="FF3B5BDB"/>
        <bgColor indexed="64"/>
      </patternFill>
    </fill>
    <fill>
      <patternFill patternType="solid">
        <fgColor rgb="FFFFE6E6"/>
        <bgColor indexed="64"/>
      </patternFill>
    </fill>
    <fill>
      <patternFill patternType="solid">
        <fgColor rgb="FFFFF3E0"/>
        <bgColor indexed="64"/>
      </patternFill>
    </fill>
    <fill>
      <patternFill patternType="solid">
        <fgColor rgb="FFFFF9C4"/>
        <bgColor indexed="64"/>
      </patternFill>
    </fill>
    <fill>
      <patternFill patternType="solid">
        <fgColor rgb="FFE8F5E9"/>
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
  <cellXfs count="7">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
    <xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1">
      <alignment horizontal="center" vertical="center" wrapText="1"/>
    </xf>
    <xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1" applyAlignment="1">
      <alignment vertical="top" wrapText="1"/>
    </xf>
    <xf numFmtId="0" fontId="0" fillId="3" borderId="1" xfId="0" applyFill="1" applyBorder="1" applyAlignment="1">
      <alignment vertical="top" wrapText="1"/>
    </xf>
    <xf numFmtId="0" fontId="0" fillId="4" borderId="1" xfId="0" applyFill="1" applyBorder="1" applyAlignment="1">
      <alignment vertical="top" wrapText="1"/>
    </xf>
    <xf numFmtId="0" fontId="0" fillId="5" borderId="1" xfId="0" applyFill="1" applyBorder="1" applyAlignment="1">
      <alignment vertical="top" wrapText="1"/>
    </xf>
    <xf numFmtId="0" fontId="0" fillId="6" borderId="1" xfId="0" applyFill="1" applyBorder="1" applyAlignment="1">
      <alignment vertical="top" wrapText="1"/>
    </xf>
  </cellXfs>
  <cellStyles count="1">
    <cellStyle name="Normal" xfId="0" builtinId="0"/>
  </cellStyles>
</styleSheet>
"@
}

function New-WorkbookXml {
  param([object[]]$SheetDefinitions)

  $sheetEntries = for ($index = 0; $index -lt $SheetDefinitions.Count; $index++) {
    $sheetId = $index + 1
    $sheetName = Escape-XmlText $SheetDefinitions[$index].Name
    '<sheet name="{0}" sheetId="{1}" r:id="rId{1}"/>' -f $sheetName, $sheetId
  }

  return @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <bookViews>
    <workbookView xWindow="0" yWindow="0" windowWidth="24000" windowHeight="12000"/>
  </bookViews>
  <sheets>
    $($sheetEntries -join "`n    ")
  </sheets>
</workbook>
"@
}

function New-WorkbookRelsXml {
  param([int]$SheetCount)

  $relationships = New-Object System.Collections.Generic.List[string]
  for ($index = 1; $index -le $SheetCount; $index++) {
    $relationships.Add(('<Relationship Id="rId{0}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet{0}.xml"/>' -f $index)) | Out-Null
  }
  $styleRelationshipId = $SheetCount + 1
  $relationships.Add(('<Relationship Id="rId{0}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>' -f $styleRelationshipId)) | Out-Null

  return @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  $($relationships -join "`n  ")
</Relationships>
"@
}

function New-ContentTypesXml {
  param([int]$SheetCount)

  $sheetOverrides = for ($index = 1; $index -le $SheetCount; $index++) {
    '<Override PartName="/xl/worksheets/sheet{0}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' -f $index
  }

  return @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  $($sheetOverrides -join "`n  ")
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
  param([string[]]$SheetNames)

  $sheetNameEntries = for ($index = 0; $index -lt $SheetNames.Count; $index++) {
    '<vt:lpstr>{0}</vt:lpstr>' -f (Escape-XmlText $SheetNames[$index])
  }

  return @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>Microsoft Excel</Application>
  <DocSecurity>0</DocSecurity>
  <ScaleCrop>false</ScaleCrop>
  <HeadingPairs>
    <vt:vector size="2" baseType="variant">
      <vt:variant><vt:lpstr>Worksheets</vt:lpstr></vt:variant>
      <vt:variant><vt:i4>$($SheetNames.Count)</vt:i4></vt:variant>
    </vt:vector>
  </HeadingPairs>
  <TitlesOfParts>
    <vt:vector size="$($SheetNames.Count)" baseType="lpstr">
      $($sheetNameEntries -join "`n      ")
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
    [string]$WorkbookTitle,
    [object[]]$SheetDefinitions
  )

  Add-Type -AssemblyName System.IO.Compression.FileSystem

  $tempRoot = Join-Path $workspaceRoot ([System.IO.Path]::GetRandomFileName())
  $zipPath = Join-Path $workspaceRoot ([System.IO.Path]::GetRandomFileName() + '.zip')
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

    for ($sheetIndex = 0; $sheetIndex -lt $SheetDefinitions.Count; $sheetIndex++) {
      $sheet = $SheetDefinitions[$sheetIndex]
      $sheetXml = New-WorksheetXml -SheetRows $sheet.Rows -Headers $headers -ColumnWidths $columnWidths -ApplyRowColor $sheet.ApplyRowColor
      [System.IO.File]::WriteAllText(
        (Join-Path $xlWorksheetsDir ("sheet{0}.xml" -f ($sheetIndex + 1))),
        $sheetXml,
        [System.Text.UTF8Encoding]::new($false)
      )
    }

    [System.IO.File]::WriteAllText((Join-Path $tempRoot '[Content_Types].xml'), (New-ContentTypesXml -SheetCount $SheetDefinitions.Count), [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $relsDir '.rels'), (New-PackageRelsXml), [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $docPropsDir 'core.xml'), (New-CoreXml -Title $WorkbookTitle), [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $docPropsDir 'app.xml'), (New-AppXml -SheetNames ($SheetDefinitions | ForEach-Object { $_.Name })), [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $xlDir 'workbook.xml'), (New-WorkbookXml -SheetDefinitions $SheetDefinitions), [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $xlRelsDir 'workbook.xml.rels'), (New-WorkbookRelsXml -SheetCount $SheetDefinitions.Count), [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $xlDir 'styles.xml'), (New-StylesXml), [System.Text.UTF8Encoding]::new($false))

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

$sortedRows = $rows | Sort-Object @(
  @{ Expression = { Get-PriorityRank $_.'Priority (High/Medium/Low)' }; Descending = $true },
  @{ Expression = { Get-SeverityRank $_.Severity }; Descending = $true },
  @{ Expression = { Get-CategoryName $_ } },
  @{ Expression = { $_.'Module / Feature Name' } },
  @{ Expression = { $_.'Test Case ID' } }
)

$highPriorityGroups = $rows |
  Where-Object { $_.'Priority (High/Medium/Low)' -eq 'High' } |
  Group-Object { Get-CategoryName $_ } |
  Sort-Object Name

$subsetSelection = New-Object System.Collections.Generic.List[object]
foreach ($group in $highPriorityGroups) {
  $groupRows = $group.Group | Sort-Object @(
    @{ Expression = { Get-SeverityRank $_.Severity }; Descending = $true },
    @{ Expression = { $_.'Test Case ID' } }
  )

  foreach ($row in ($groupRows | Select-Object -First 20)) {
    $subsetSelection.Add($row) | Out-Null
  }
}

$subsetRows = New-SubsetRows -InputRows ($subsetSelection.ToArray() | Sort-Object @(
  @{ Expression = { Get-CategoryName $_ } },
  @{ Expression = { Get-SeverityRank $_.Severity }; Descending = $true },
  @{ Expression = { $_.'Test Case ID' } }
))

$subsetRows | Export-Csv -Path $subsetCsvPath -NoTypeInformation -Encoding UTF8

$colorWorkbookSheets = @(
  [pscustomobject]@{
    Name = 'All Test Cases'
    Rows = $sortedRows
    ApplyRowColor = $true
  }
)

$usedSheetNames = @{}
$categoryWorkbookSheets = $rows |
  Group-Object { Get-CategoryName $_ } |
  Sort-Object Name |
  ForEach-Object {
    [pscustomobject]@{
      Name = Get-SafeSheetName -Name $_.Name -UsedNames $usedSheetNames
      Rows = ($_.Group | Sort-Object @(
        @{ Expression = { Get-PriorityRank $_.'Priority (High/Medium/Low)' }; Descending = $true },
        @{ Expression = { Get-SeverityRank $_.Severity }; Descending = $true },
        @{ Expression = { $_.'Test Case ID' } }
      ))
      ApplyRowColor = $true
    }
  }

$automationRows = New-SubsetRows -InputRows ($subsetRows |
  Where-Object {
    (Get-CategoryName $_) -in @(
      'Automation Testing',
      'Regression Testing',
      'API Testing',
      'Functional Testing',
      'PDF & Export Testing'
    )
  } |
  Select-Object -First 120)

$subsetWorkbookSheets = @(
  [pscustomobject]@{
    Name = 'High Priority Subset'
    Rows = $subsetRows
    ApplyRowColor = $true
  },
  [pscustomobject]@{
    Name = 'Automation Focus'
    Rows = $automationRows
    ApplyRowColor = $true
  }
)

New-XlsxWorkbook -WorkbookPath $colorWorkbookPath -WorkbookTitle 'Resume App 1000 Color-Coded Test Cases' -SheetDefinitions $colorWorkbookSheets
New-XlsxWorkbook -WorkbookPath $categoryWorkbookPath -WorkbookTitle 'Resume App 1000 Test Cases by Category' -SheetDefinitions $categoryWorkbookSheets
New-XlsxWorkbook -WorkbookPath $subsetWorkbookPath -WorkbookTitle 'Resume App High-Priority Subset' -SheetDefinitions $subsetWorkbookSheets

Write-Host "Created color-coded workbook      : $colorWorkbookPath"
Write-Host "Created category workbook         : $categoryWorkbookPath"
Write-Host "Created high-priority subset CSV  : $subsetCsvPath"
Write-Host "Created high-priority subset XLSX : $subsetWorkbookPath"
Write-Host "High-priority subset size         : $($subsetRows.Count)"