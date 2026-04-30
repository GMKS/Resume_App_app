# csv_to_excel.ps1 - Reads testcases_500.csv and creates a true Excel .xlsx file

$csvPath  = "C:\Resume_App_app\Resume_App_app\testcases_500.csv"
$xlsxPath = "C:\Resume_App_app\Resume_App_app\testcases_resume_builder_500.xlsx"

# Read CSV
$rows = Import-Csv -Path $csvPath

# Start Excel
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

$wb = $excel.Workbooks.Add()
$ws = $wb.Worksheets.Item(1)
$ws.Name = "Test Cases"

# Column headers
$headers = @("TC ID","Test Type","Feature/Section","Test Scenario","Test Steps","Test Data","Expected Result","Positive/Negative")
for ($c = 0; $c -lt $headers.Count; $c++) {
    $ws.Cells.Item(1, $c+1).Value2 = $headers[$c]
}

# Style header row
$headerRange = $ws.Range("A1:H1")
$headerRange.Font.Bold = $true
$headerRange.Font.Color = [System.Drawing.ColorTranslator]::ToOle([System.Drawing.Color]::White)
$headerRange.Interior.Color = [System.Drawing.ColorTranslator]::ToOle([System.Drawing.Color]::FromArgb(0,70,127))
$headerRange.Font.Size = 11

# Write data rows
$rowIdx = 2
foreach ($row in $rows) {
    $ws.Cells.Item($rowIdx, 1).Value2 = $row."TC ID"
    $ws.Cells.Item($rowIdx, 2).Value2 = $row."Test Type"
    $ws.Cells.Item($rowIdx, 3).Value2 = $row."Feature/Section"
    $ws.Cells.Item($rowIdx, 4).Value2 = $row."Test Scenario"
    $ws.Cells.Item($rowIdx, 5).Value2 = $row."Test Steps"
    $ws.Cells.Item($rowIdx, 6).Value2 = $row."Test Data"
    $ws.Cells.Item($rowIdx, 7).Value2 = $row."Expected Result"
    $ws.Cells.Item($rowIdx, 8).Value2 = $row."Positive/Negative"

    # Color rows by Positive/Negative
    $pn = $row."Positive/Negative"
    $dataRange = $ws.Range("A${rowIdx}:H${rowIdx}")
    if ($pn -eq "Positive") {
        $dataRange.Interior.Color = [System.Drawing.ColorTranslator]::ToOle([System.Drawing.Color]::FromArgb(204,255,204))
    } elseif ($pn -eq "Negative") {
        $dataRange.Interior.Color = [System.Drawing.ColorTranslator]::ToOle([System.Drawing.Color]::FromArgb(255,204,204))
    }

    $rowIdx++
}

# AutoFilter on header
$ws.Range("A1:H1").AutoFilter() | Out-Null

# Freeze top row
$ws.Application.ActiveWindow.SplitRow = 1
$ws.Application.ActiveWindow.FreezePanes = $true

# AutoFit columns A-H
$ws.Columns("A:H").AutoFit() | Out-Null

# Save as xlsx (format 51)
if (Test-Path $xlsxPath) { Remove-Item $xlsxPath -Force }
$wb.SaveAs($xlsxPath, 51)
$wb.Close($false)
$excel.Quit()

[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
[System.GC]::Collect()

Write-Host "Done! File saved to: $xlsxPath"
