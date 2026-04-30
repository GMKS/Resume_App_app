# generate_social_fab_testcases.ps1
# Reads testcases_social_fab.csv and produces a richly-formatted Excel workbook
# Covers two features:
#   1. New Resume FAB Button Color Fix
#   2. Social Media Login (Google / Facebook / Twitter-X / LinkedIn)

$csvPath  = "C:\Resume_App_app\Resume_App_app\testcases_social_fab.csv"
$xlsxPath = "C:\Resume_App_app\Resume_App_app\testcases_social_fab.xlsx"

Add-Type -AssemblyName System.Drawing

function OleColor([System.Drawing.Color]$c) {
    return [System.Drawing.ColorTranslator]::ToOle($c)
}

$headerBg      = OleColor([System.Drawing.Color]::FromArgb(79, 70, 229))
$headerFg      = OleColor([System.Drawing.Color]::White)
$secFabBg      = OleColor([System.Drawing.Color]::FromArgb(99, 102, 241))
$secSocBg      = OleColor([System.Drawing.Color]::FromArgb(16, 185, 129))
$secFg         = OleColor([System.Drawing.Color]::White)
$positiveBg    = OleColor([System.Drawing.Color]::FromArgb(209, 250, 229))
$negativeBg    = OleColor([System.Drawing.Color]::FromArgb(254, 202, 202))
$uiBg          = OleColor([System.Drawing.Color]::FromArgb(237, 233, 254))
$functionalBg  = OleColor([System.Drawing.Color]::FromArgb(219, 234, 254))
$integrationBg = OleColor([System.Drawing.Color]::FromArgb(254, 243, 199))
$e2eBg         = OleColor([System.Drawing.Color]::FromArgb(209, 250, 229))
$perfBg        = OleColor([System.Drawing.Color]::FromArgb(252, 231, 243))
$securityBg    = OleColor([System.Drawing.Color]::FromArgb(255, 237, 213))
$compatBg      = OleColor([System.Drawing.Color]::FromArgb(240, 253, 244))
$regressionBg  = OleColor([System.Drawing.Color]::FromArgb(255, 251, 235))
$negTypeBg     = OleColor([System.Drawing.Color]::FromArgb(254, 226, 226))
$altRow        = OleColor([System.Drawing.Color]::FromArgb(248, 250, 252))

$rows = Import-Csv -Path $csvPath
Write-Host "Loaded $($rows.Count) test cases."

$excel = New-Object -ComObject Excel.Application
$excel.Visible       = $false
$excel.DisplayAlerts = $false
$wb = $excel.Workbooks.Add()

# ── Sheet 1: All Test Cases ──────────────────────────────────────────────────
$ws = $wb.Worksheets.Item(1)
$ws.Name = "All Test Cases"

$headers = @("TC ID","Test Type","Feature/Section","Test Scenario","Test Steps","Test Data","Expected Result","Positive/Negative")

for ($c = 0; $c -lt $headers.Count; $c++) {
    $cell = $ws.Cells.Item(1, $c+1)
    $cell.Value2              = $headers[$c]
    $cell.Font.Bold           = $true
    $cell.Font.Size           = 11
    $cell.Font.Color          = $headerFg
    $cell.Interior.Color      = $headerBg
    $cell.HorizontalAlignment = -4108
    $cell.VerticalAlignment   = -4108
}
$ws.Rows.Item(1).RowHeight = 22

$fabRows = $rows | Where-Object { $_."TC ID" -match "^TC_FAB" }
$socRows = $rows | Where-Object { $_."TC ID" -match "^TC_SOC" }

function Write-SectionHeader {
    param($ws, [int]$rowNum, [string]$label, $bgColor)
    $range = $ws.Range("A${rowNum}:H${rowNum}")
    $range.Merge()
    $range.Value2              = $label
    $range.Font.Bold           = $true
    $range.Font.Size           = 12
    $range.Font.Color          = $secFg
    $range.Interior.Color      = $bgColor
    $range.HorizontalAlignment = -4108
    $range.RowHeight           = 22
}

function Get-RowBg {
    param([string]$testType)
    switch ($testType) {
        "UI"            { return $uiBg }
        "Functional"    { return $functionalBg }
        "Integration"   { return $integrationBg }
        "E2E"           { return $e2eBg }
        "Performance"   { return $perfBg }
        "Security"      { return $securityBg }
        "Compatibility" { return $compatBg }
        "Regression"    { return $regressionBg }
        "Negative"      { return $negTypeBg }
        "Accessibility" { return $uiBg }
        default         { return $altRow }
    }
}

$currentRow = 2
$fabCount   = $fabRows.Count
$socCount   = $socRows.Count
$secH1      = "FEATURE 1: New Resume FAB Button - Color and Visibility Fix  [$fabCount test cases]"
$secH2      = "FEATURE 2: Social Media Login / Sign-Up  (Google, Facebook, Twitter-X, LinkedIn)  [$socCount test cases]"

Write-SectionHeader $ws $currentRow $secH1 $secFabBg
$currentRow++

foreach ($row in $fabRows) {
    for ($c = 0; $c -lt $headers.Count; $c++) {
        $ws.Cells.Item($currentRow, $c+1).Value2 = $row.($headers[$c])
    }
    $ws.Range("A${currentRow}:H${currentRow}").Interior.Color = (Get-RowBg $row."Test Type")
    $pn = $row."Positive/Negative"
    if ($pn -eq "Positive") {
        $ws.Cells.Item($currentRow, 8).Interior.Color = $positiveBg
        $ws.Cells.Item($currentRow, 8).Font.Color     = OleColor([System.Drawing.Color]::FromArgb(22,163,74))
        $ws.Cells.Item($currentRow, 8).Font.Bold      = $true
    } elseif ($pn -eq "Negative") {
        $ws.Cells.Item($currentRow, 8).Interior.Color = $negativeBg
        $ws.Cells.Item($currentRow, 8).Font.Color     = OleColor([System.Drawing.Color]::FromArgb(185,28,28))
        $ws.Cells.Item($currentRow, 8).Font.Bold      = $true
    }
    $ws.Rows.Item($currentRow).RowHeight = 30
    $currentRow++
}

$currentRow++ # blank spacer

Write-SectionHeader $ws $currentRow $secH2 $secSocBg
$currentRow++

foreach ($row in $socRows) {
    for ($c = 0; $c -lt $headers.Count; $c++) {
        $ws.Cells.Item($currentRow, $c+1).Value2 = $row.($headers[$c])
    }
    $ws.Range("A${currentRow}:H${currentRow}").Interior.Color = (Get-RowBg $row."Test Type")
    $pn = $row."Positive/Negative"
    if ($pn -eq "Positive") {
        $ws.Cells.Item($currentRow, 8).Interior.Color = $positiveBg
        $ws.Cells.Item($currentRow, 8).Font.Color     = OleColor([System.Drawing.Color]::FromArgb(22,163,74))
        $ws.Cells.Item($currentRow, 8).Font.Bold      = $true
    } elseif ($pn -eq "Negative") {
        $ws.Cells.Item($currentRow, 8).Interior.Color = $negativeBg
        $ws.Cells.Item($currentRow, 8).Font.Color     = OleColor([System.Drawing.Color]::FromArgb(185,28,28))
        $ws.Cells.Item($currentRow, 8).Font.Bold      = $true
    }
    $ws.Rows.Item($currentRow).RowHeight = 30
    $currentRow++
}

# Borders on all data
$dataRange = $ws.Range("A1:H$($currentRow-1)")
$dataRange.Borders.Item(7).LineStyle  = 1
$dataRange.Borders.Item(8).LineStyle  = 1
$dataRange.Borders.Item(9).LineStyle  = 1
$dataRange.Borders.Item(10).LineStyle = 1
$dataRange.Borders.Item(11).LineStyle = 1
$dataRange.Borders.Item(12).LineStyle = 1
$dataRange.Borders.Item(7).Weight     = 2
$dataRange.Borders.Item(10).Weight    = 2

# Wrap text in verbose columns
$ws.Columns("D:G").WrapText = $true

$ws.Columns("A").ColumnWidth = 14
$ws.Columns("B").ColumnWidth = 14
$ws.Columns("C").ColumnWidth = 22
$ws.Columns("D").ColumnWidth = 40
$ws.Columns("E").ColumnWidth = 52
$ws.Columns("F").ColumnWidth = 28
$ws.Columns("G").ColumnWidth = 45
$ws.Columns("H").ColumnWidth = 18

$ws.Range("A1:H1").AutoFilter() | Out-Null
$ws.Application.ActiveWindow.SplitRow    = 1
$ws.Application.ActiveWindow.FreezePanes = $true

# ── Sheet 2: Summary ─────────────────────────────────────────────────────────
$ws2 = $wb.Worksheets.Add()
$ws2.Name = "Summary"
$ws2.Move([System.Reflection.Missing]::Value, $ws)
$ws2.Tab.Color = OleColor([System.Drawing.Color]::FromArgb(16,185,129))
$ws.Tab.Color  = OleColor([System.Drawing.Color]::FromArgb(79,70,229))

# Title row
$t = $ws2.Range("A1:F1")
$t.Merge()
$t.Value2              = "Resume Builder - Test Case Summary (FAB Button + Social Login)"
$t.Font.Bold           = $true
$t.Font.Size           = 16
$t.Font.Color          = $headerFg
$t.Interior.Color      = $headerBg
$t.HorizontalAlignment = -4108
$t.RowHeight           = 30

$sub = $ws2.Range("A2:F2")
$sub.Merge()
$sub.Value2              = "Features: (1) New Resume FAB Button Colour Fix   |   (2) Social Media Login: Google, Facebook, Twitter-X, LinkedIn"
$sub.Font.Italic         = $true
$sub.Font.Color          = OleColor([System.Drawing.Color]::FromArgb(71,85,105))
$sub.HorizontalAlignment = -4108

# Feature Coverage table
$r = 4
$hdrCols = @("Feature","Total TCs","Positive","Negative","Coverage Areas")
for ($ci = 0; $ci -lt $hdrCols.Count; $ci++) {
    $cell = $ws2.Cells.Item($r, $ci+1)
    $cell.Value2              = $hdrCols[$ci]
    $cell.Font.Bold           = $true
    $cell.Font.Color          = $headerFg
    $cell.Interior.Color      = $headerBg
    $cell.HorizontalAlignment = -4108
}
$ws2.Rows.Item($r).RowHeight = 20

$r++
$fabPos = ($fabRows | Where-Object { $_."Positive/Negative" -eq "Positive" }).Count
$fabNeg = ($fabRows | Where-Object { $_."Positive/Negative" -eq "Negative" }).Count
$ws2.Cells.Item($r,1).Value2 = "New Resume FAB Button"
$ws2.Cells.Item($r,1).Interior.Color = $uiBg
$ws2.Cells.Item($r,2).Value2 = $fabRows.Count
$ws2.Cells.Item($r,2).Interior.Color = $uiBg
$ws2.Cells.Item($r,2).HorizontalAlignment = -4108
$ws2.Cells.Item($r,3).Value2 = $fabPos
$ws2.Cells.Item($r,3).Interior.Color = $positiveBg
$ws2.Cells.Item($r,3).HorizontalAlignment = -4108
$ws2.Cells.Item($r,4).Value2 = $fabNeg
$ws2.Cells.Item($r,4).Interior.Color = $negativeBg
$ws2.Cells.Item($r,4).HorizontalAlignment = -4108
$ws2.Cells.Item($r,5).Value2 = "UI, Functional, Regression, Accessibility, Performance"

$r++
$socPos = ($socRows | Where-Object { $_."Positive/Negative" -eq "Positive" }).Count
$socNeg = ($socRows | Where-Object { $_."Positive/Negative" -eq "Negative" }).Count
$ws2.Cells.Item($r,1).Value2 = "Social Media Login"
$ws2.Cells.Item($r,1).Interior.Color = $e2eBg
$ws2.Cells.Item($r,2).Value2 = $socRows.Count
$ws2.Cells.Item($r,2).Interior.Color = $e2eBg
$ws2.Cells.Item($r,2).HorizontalAlignment = -4108
$ws2.Cells.Item($r,3).Value2 = $socPos
$ws2.Cells.Item($r,3).Interior.Color = $positiveBg
$ws2.Cells.Item($r,3).HorizontalAlignment = -4108
$ws2.Cells.Item($r,4).Value2 = $socNeg
$ws2.Cells.Item($r,4).Interior.Color = $negativeBg
$ws2.Cells.Item($r,4).HorizontalAlignment = -4108
$ws2.Cells.Item($r,5).Value2 = "UI, Functional, Integration, E2E, Performance, Security, Compatibility, Regression"

$r++
$grandTotal = $rows.Count
$grandPos   = ($rows | Where-Object { $_."Positive/Negative" -eq "Positive" }).Count
$grandNeg   = ($rows | Where-Object { $_."Positive/Negative" -eq "Negative" }).Count
for ($ci = 1; $ci -le 5; $ci++) {
    $ws2.Cells.Item($r,$ci).Interior.Color      = $headerBg
    $ws2.Cells.Item($r,$ci).Font.Color          = $headerFg
    $ws2.Cells.Item($r,$ci).Font.Bold           = $true
    $ws2.Cells.Item($r,$ci).HorizontalAlignment = -4108
}
$ws2.Cells.Item($r,1).Value2 = "TOTAL"
$ws2.Cells.Item($r,2).Value2 = $grandTotal
$ws2.Cells.Item($r,3).Value2 = $grandPos
$ws2.Cells.Item($r,4).Value2 = $grandNeg

$ws2.Range("A4:E${r}").Borders.Item(11).LineStyle = 1
$ws2.Range("A4:E${r}").Borders.Item(12).LineStyle = 1
$ws2.Range("A4:E${r}").Borders.Item(7).LineStyle  = 2
$ws2.Range("A4:E${r}").Borders.Item(10).LineStyle = 2

# Test Type Breakdown
$r += 2
$ws2.Range("A$r").Value2     = "Test Type Breakdown"
$ws2.Range("A$r").Font.Bold  = $true
$ws2.Range("A$r").Font.Size  = 12
$r++

$hdr2 = @("Test Type","FAB Count","Social Count","Total")
for ($ci = 0; $ci -lt $hdr2.Count; $ci++) {
    $ws2.Cells.Item($r,$ci+1).Value2              = $hdr2[$ci]
    $ws2.Cells.Item($r,$ci+1).Font.Bold           = $true
    $ws2.Cells.Item($r,$ci+1).Font.Color          = $headerFg
    $ws2.Cells.Item($r,$ci+1).Interior.Color      = $headerBg
    $ws2.Cells.Item($r,$ci+1).HorizontalAlignment = -4108
}
$r++

$types   = @("UI","Functional","Integration","E2E","Performance","Security","Compatibility","Regression","Negative","Accessibility")
$typeBgs = @($uiBg,$functionalBg,$integrationBg,$e2eBg,$perfBg,$securityBg,$compatBg,$regressionBg,$negTypeBg,$uiBg)
for ($ti = 0; $ti -lt $types.Count; $ti++) {
    $ty    = $types[$ti]
    $fCnt  = ($fabRows | Where-Object { $_."Test Type" -eq $ty }).Count
    $sCnt  = ($socRows | Where-Object { $_."Test Type" -eq $ty }).Count
    $tot   = $fCnt + $sCnt
    if ($tot -eq 0) { continue }
    $ws2.Cells.Item($r,1).Value2              = $ty
    $ws2.Cells.Item($r,1).Interior.Color      = $typeBgs[$ti]
    $ws2.Cells.Item($r,2).Value2              = $fCnt
    $ws2.Cells.Item($r,2).Interior.Color      = $typeBgs[$ti]
    $ws2.Cells.Item($r,2).HorizontalAlignment = -4108
    $ws2.Cells.Item($r,3).Value2              = $sCnt
    $ws2.Cells.Item($r,3).Interior.Color      = $typeBgs[$ti]
    $ws2.Cells.Item($r,3).HorizontalAlignment = -4108
    $ws2.Cells.Item($r,4).Value2              = $tot
    $ws2.Cells.Item($r,4).Interior.Color      = $typeBgs[$ti]
    $ws2.Cells.Item($r,4).Font.Bold           = $true
    $ws2.Cells.Item($r,4).HorizontalAlignment = -4108
    $r++
}

# Legend
$r += 2
$ws2.Range("A$r").Value2    = "Legend: Row colours by Test Type"
$ws2.Range("A$r").Font.Bold = $true
$ws2.Range("A$r").Font.Size = 12
$r++

$legendLabels = @("UI / Accessibility","Functional","Integration","E2E (End-to-End)","Performance","Security","Compatibility","Regression","Negative (test type)","Positive result (last column)","Negative result (last column)")
$legendColors = @($uiBg,$functionalBg,$integrationBg,$e2eBg,$perfBg,$securityBg,$compatBg,$regressionBg,$negTypeBg,$positiveBg,$negativeBg)
for ($li = 0; $li -lt $legendLabels.Count; $li++) {
    $ws2.Cells.Item($r,1).Value2         = $legendLabels[$li]
    $ws2.Cells.Item($r,1).Interior.Color = $legendColors[$li]
    $r++
}

$ws2.Columns("A").ColumnWidth = 45
$ws2.Columns("B").ColumnWidth = 14
$ws2.Columns("C").ColumnWidth = 16
$ws2.Columns("D").ColumnWidth = 12
$ws2.Columns("E").ColumnWidth = 62

# ── Save ────────────────────────────────────────────────────────────────────
if (Test-Path $xlsxPath) { Remove-Item $xlsxPath -Force }
$wb.SaveAs($xlsxPath, 51)
$wb.Close($false)
$excel.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
[System.GC]::Collect()

Write-Host ""
Write-Host "============================================="
Write-Host "  Saved: $xlsxPath"
Write-Host "  Total test cases : $grandTotal"
Write-Host "    FAB Button      : $($fabRows.Count)  (Pos: $fabPos  Neg: $fabNeg)"
Write-Host "    Social Login    : $($socRows.Count)  (Pos: $socPos  Neg: $socNeg)"
Write-Host "============================================="
