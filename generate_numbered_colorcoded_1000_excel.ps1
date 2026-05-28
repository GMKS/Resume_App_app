$ErrorActionPreference = 'Stop'

$workspaceRoot = $PSScriptRoot
$sourceCsvPath = Join-Path $workspaceRoot 'resume_app_test_suite_1000_requested_columns.csv'
$outputXlsxPath = Join-Path $workspaceRoot 'resume_app_test_suite_1000_numbered_colorcoded.xlsx'

if (-not (Test-Path $sourceCsvPath)) {
  throw "Source CSV not found: $sourceCsvPath"
}

$requiredColumns = @(
  'Test Case ID',
  'Test Scenario',
  'Test Case Title',
  'Module Name',
  'Requirement ID',
  'Preconditions',
  'Test Steps',
  'Test Data',
  'Expected Result',
  'Actual Result'
)

$rows = Import-Csv -Path $sourceCsvPath
foreach ($column in $requiredColumns) {
  if ($column -notin $rows[0].PSObject.Properties.Name) {
    throw "Missing required column '$column' in $sourceCsvPath"
  }
}

function Convert-ToNumberedText {
  param(
    [AllowNull()][string]$Text
  )

  if ([string]::IsNullOrWhiteSpace($Text)) {
    return ''
  }

  $normalized = ($Text -replace "`r`n?", ' ' -replace '\s+', ' ').Trim()
  if ([string]::IsNullOrWhiteSpace($normalized)) {
    return ''
  }

  $numberedMatches = [regex]::Matches(
    $normalized,
    '(?s)(\d+\.\s.*?)(?=(?:\s+\d+\.\s)|$)'
  )

  if ($numberedMatches.Count -gt 0) {
    $parts = foreach ($match in $numberedMatches) {
      ($match.Groups[1].Value -replace '^\d+\.\s*', '').Trim()
    }
  } else {
    $parts = $normalized -split '(?<=[.!?])\s+' |
      Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
      ForEach-Object { $_.Trim() }
  }

  $index = 1
  return ($parts | ForEach-Object {
    $line = "$index. $_"
    $index++
    $line
  }) -join "`n"
}

function Convert-HslToOleColor {
  param(
    [double]$Hue,
    [double]$Saturation,
    [double]$Lightness
  )

  $h = (($Hue % 360) + 360) % 360 / 360
  $s = [Math]::Max(0, [Math]::Min(1, $Saturation))
  $l = [Math]::Max(0, [Math]::Min(1, $Lightness))

  if ($s -eq 0) {
    $r = $l
    $g = $l
    $b = $l
  } else {
    if ($l -lt 0.5) {
      $q = $l * (1 + $s)
    } else {
      $q = $l + $s - ($l * $s)
    }
    $p = 2 * $l - $q

    function Get-RgbChannel {
      param([double]$p, [double]$q, [double]$t)

      if ($t -lt 0) { $t += 1 }
      if ($t -gt 1) { $t -= 1 }
      if ($t -lt (1.0 / 6.0)) { return $p + (($q - $p) * 6 * $t) }
      if ($t -lt 0.5) { return $q }
      if ($t -lt (2.0 / 3.0)) { return $p + (($q - $p) * ((2.0 / 3.0) - $t) * 6) }
      return $p
    }

    $r = Get-RgbChannel -p $p -q $q -t ($h + (1.0 / 3.0))
    $g = Get-RgbChannel -p $p -q $q -t $h
    $b = Get-RgbChannel -p $p -q $q -t ($h - (1.0 / 3.0))
  }

  $color = [System.Drawing.Color]::FromArgb(
    [int][Math]::Round($r * 255),
    [int][Math]::Round($g * 255),
    [int][Math]::Round($b * 255)
  )

  return [System.Drawing.ColorTranslator]::ToOle($color)
}

$moduleOrder = New-Object System.Collections.Generic.List[string]
$moduleSeen = @{}
foreach ($row in $rows) {
  $moduleName = [string]$row.'Module Name'
  if (-not $moduleSeen.ContainsKey($moduleName)) {
    $moduleSeen[$moduleName] = $true
    $moduleOrder.Add($moduleName) | Out-Null
  }
}

$moduleColorMap = @{}
for ($index = 0; $index -lt $moduleOrder.Count; $index++) {
  $moduleColorMap[$moduleOrder[$index]] = Convert-HslToOleColor `
    -Hue (($index * 360.0) / [Math]::Max(1, $moduleOrder.Count)) `
    -Saturation 0.55 `
    -Lightness 0.83
}

$excel = $null
$workbook = $null

try {
  $excel = New-Object -ComObject Excel.Application
  $excel.Visible = $false
  $excel.DisplayAlerts = $false

  $workbook = $excel.Workbooks.Add()
  $sheet = $workbook.Worksheets.Item(1)
  $sheet.Name = '1000 Test Cases'

  $legendSheet = if ($workbook.Worksheets.Count -ge 2) {
    $workbook.Worksheets.Item(2)
  } else {
    $workbook.Worksheets.Add()
  }
  $legendSheet.Name = 'Module Legend'

  for ($sheetIndex = $workbook.Worksheets.Count; $sheetIndex -ge 3; $sheetIndex--) {
    $workbook.Worksheets.Item($sheetIndex).Delete()
  }

  for ($columnIndex = 0; $columnIndex -lt $requiredColumns.Count; $columnIndex++) {
    $cell = $sheet.Cells.Item(1, $columnIndex + 1)
    $cell.Value2 = $requiredColumns[$columnIndex]
    $cell.Font.Bold = $true
    $cell.Font.Color = [System.Drawing.ColorTranslator]::ToOle([System.Drawing.Color]::White)
    $cell.Interior.Color = [System.Drawing.ColorTranslator]::ToOle([System.Drawing.Color]::FromArgb(31, 41, 55))
  }

  $rowIndex = 2
  foreach ($row in $rows) {
    $sheet.Cells.Item($rowIndex, 1).Value2 = [string]$row.'Test Case ID'
    $sheet.Cells.Item($rowIndex, 2).Value2 = [string]$row.'Test Scenario'
    $sheet.Cells.Item($rowIndex, 3).Value2 = [string]$row.'Test Case Title'

    $moduleName = [string]$row.'Module Name'
    $moduleCell = $sheet.Cells.Item($rowIndex, 4)
    $moduleCell.Value2 = $moduleName
    $moduleCell.Interior.Color = $moduleColorMap[$moduleName]
    $moduleCell.Font.Bold = $true

    $sheet.Cells.Item($rowIndex, 5).Value2 = [string]$row.'Requirement ID'
    $sheet.Cells.Item($rowIndex, 6).Value2 = Convert-ToNumberedText -Text ([string]$row.Preconditions)
    $sheet.Cells.Item($rowIndex, 7).Value2 = Convert-ToNumberedText -Text ([string]$row.'Test Steps')
    $sheet.Cells.Item($rowIndex, 8).Value2 = [string]$row.'Test Data'
    $sheet.Cells.Item($rowIndex, 9).Value2 = Convert-ToNumberedText -Text ([string]$row.'Expected Result')
    $sheet.Cells.Item($rowIndex, 10).Value2 = [string]$row.'Actual Result'

    $rowIndex++
  }

  $usedRowCount = $rowIndex - 1
  $tableRange = $sheet.Range("A1:J$usedRowCount")
  $tableRange.VerticalAlignment = -4160
  $tableRange.Borders.LineStyle = 1
  $sheet.Range("A1:J1").AutoFilter() | Out-Null

  foreach ($columnLetter in @('F', 'G', 'H', 'I', 'J')) {
    $sheet.Columns.Item($columnLetter).WrapText = $true
  }

  $sheet.Columns.Item('A').ColumnWidth = 14
  $sheet.Columns.Item('B').ColumnWidth = 24
  $sheet.Columns.Item('C').ColumnWidth = 40
  $sheet.Columns.Item('D').ColumnWidth = 34
  $sheet.Columns.Item('E').ColumnWidth = 14
  $sheet.Columns.Item('F').ColumnWidth = 46
  $sheet.Columns.Item('G').ColumnWidth = 54
  $sheet.Columns.Item('H').ColumnWidth = 28
  $sheet.Columns.Item('I').ColumnWidth = 46
  $sheet.Columns.Item('J').ColumnWidth = 24

  $sheet.Rows.Item(1).Font.Size = 11
  $sheet.Rows.Item(1).RowHeight = 24
  $sheet.UsedRange.Rows.AutoFit() | Out-Null
  $sheet.Application.ActiveWindow.SplitRow = 1
  $sheet.Application.ActiveWindow.FreezePanes = $true

  $legendHeaders = @('Module Name', 'Requirement ID', 'Color Key')
  for ($columnIndex = 0; $columnIndex -lt $legendHeaders.Count; $columnIndex++) {
    $cell = $legendSheet.Cells.Item(1, $columnIndex + 1)
    $cell.Value2 = $legendHeaders[$columnIndex]
    $cell.Font.Bold = $true
    $cell.Font.Color = [System.Drawing.ColorTranslator]::ToOle([System.Drawing.Color]::White)
    $cell.Interior.Color = [System.Drawing.ColorTranslator]::ToOle([System.Drawing.Color]::FromArgb(55, 65, 81))
  }

  $legendRow = 2
  foreach ($moduleName in $moduleOrder) {
    $legendSheet.Cells.Item($legendRow, 1).Value2 = $moduleName
    $legendSheet.Cells.Item($legendRow, 2).Value2 = ($rows | Where-Object { $_.'Module Name' -eq $moduleName } | Select-Object -First 1).'Requirement ID'
    $legendSheet.Cells.Item($legendRow, 3).Value2 = ' '
    $legendSheet.Cells.Item($legendRow, 3).Interior.Color = $moduleColorMap[$moduleName]
    $legendRow++
  }

  $legendSheet.Columns.Item('A').ColumnWidth = 38
  $legendSheet.Columns.Item('B').ColumnWidth = 16
  $legendSheet.Columns.Item('C').ColumnWidth = 14
  $legendSheet.UsedRange.Borders.LineStyle = 1
  $legendSheet.Range("A1:C$($legendRow - 1)").VerticalAlignment = -4160
  $legendSheet.Rows.Item(1).RowHeight = 24

  if (Test-Path $outputXlsxPath) {
    Remove-Item $outputXlsxPath -Force
  }

  $workbook.SaveAs($outputXlsxPath, 51)
  $workbook.Saved = $true
  Write-Host "Generated Excel workbook: $outputXlsxPath"
  Write-Host "Rows exported: $($rows.Count)"
}
finally {
  if ($workbook -ne $null) {
    try {
      $workbook.Close($false)
    } catch {
      Write-Warning "Workbook close warning: $($_.Exception.Message)"
    }
    [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($workbook)
  }
  if ($excel -ne $null) {
    try {
      $excel.Quit()
    } catch {
      Write-Warning "Excel quit warning: $($_.Exception.Message)"
    }
    [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel)
  }
  [GC]::Collect()
  [GC]::WaitForPendingFinalizers()
}