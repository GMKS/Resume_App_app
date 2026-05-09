param(
    [ValidateSet('portrait', 'landscape')]
    [string]$Orientation = 'portrait'
)

Add-Type -AssemblyName System.Drawing

$inputDir = Join-Path $PSScriptRoot '..\assets\play_console_phone_input'
$outputRoot = Join-Path $PSScriptRoot '..\assets\play_console_phone_ready'

if ($Orientation -eq 'portrait') {
    $targetWidth = 1080
    $targetHeight = 1920
    $fitWidth = 930
    $fitHeight = 1700
    $suffix = 'play_ready_1080x1920'
}
else {
    $targetWidth = 1920
    $targetHeight = 1080
    $fitWidth = 1540
    $fitHeight = 940
    $suffix = 'play_ready_1920x1080'
}

$outputDir = Join-Path $outputRoot $suffix
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

$files = Get-ChildItem -Path $inputDir -File | Where-Object {
    $_.Extension -match '^\.(png|jpe?g)$'
}
if (-not $files) {
    Write-Output "No input screenshots found in $inputDir"
    exit 0
}

function New-RoundedRectanglePath {
    param(
        [System.Drawing.Rectangle]$Rect,
        [int]$Radius
    )

    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $diameter = $Radius * 2
    $path.AddArc($Rect.X, $Rect.Y, $diameter, $diameter, 180, 90)
    $path.AddArc($Rect.Right - $diameter, $Rect.Y, $diameter, $diameter, 270, 90)
    $path.AddArc($Rect.Right - $diameter, $Rect.Bottom - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($Rect.X, $Rect.Bottom - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

foreach ($file in $files) {
    $source = [System.Drawing.Image]::FromFile($file.FullName)

    $scale = [Math]::Min($fitWidth / $source.Width, $fitHeight / $source.Height)
    $renderWidth = [int][Math]::Round($source.Width * $scale)
    $renderHeight = [int][Math]::Round($source.Height * $scale)
    $renderX = [int][Math]::Round(($targetWidth - $renderWidth) / 2)
    $renderY = [int][Math]::Round(($targetHeight - $renderHeight) / 2)

    $canvas = New-Object System.Drawing.Bitmap($targetWidth, $targetHeight)
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

    $backgroundRect = [System.Drawing.Rectangle]::new(0, 0, $targetWidth, $targetHeight)
    $backgroundBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $backgroundRect,
        [System.Drawing.Color]::FromArgb(255, 248, 250, 255),
        [System.Drawing.Color]::FromArgb(255, 236, 241, 255),
        90
    )
    $graphics.FillRectangle($backgroundBrush, $backgroundRect)

    $accent1 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(36, 88, 112, 255))
    $accent2 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(26, 138, 92, 255))
    $graphics.FillEllipse($accent1, -120, -80, 520, 520)
    $graphics.FillEllipse($accent2, $targetWidth - 340, $targetHeight - 360, 420, 420)

    $shadowRect = [System.Drawing.Rectangle]::new(
        [int]($renderX + 14),
        [int]($renderY + 18),
        [int]$renderWidth,
        [int]$renderHeight
    )
    $shadowPath = New-RoundedRectanglePath -Rect $shadowRect -Radius 36
    $shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(48, 20, 32, 72))
    $graphics.FillPath($shadowBrush, $shadowPath)

    $frameRect = [System.Drawing.Rectangle]::new(
        [int]($renderX - 10),
        [int]($renderY - 10),
        [int]($renderWidth + 20),
        [int]($renderHeight + 20)
    )
    $framePath = New-RoundedRectanglePath -Rect $frameRect -Radius 42
    $frameBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(245, 255, 255, 255))
    $framePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(70, 96, 116, 255), 2)
    $graphics.FillPath($frameBrush, $framePath)
    $graphics.DrawPath($framePen, $framePath)

    $clipRect = [System.Drawing.Rectangle]::new(
        [int]$renderX,
        [int]$renderY,
        [int]$renderWidth,
        [int]$renderHeight
    )
    $clipPath = New-RoundedRectanglePath -Rect $clipRect -Radius 32
    $graphics.SetClip($clipPath)
    $graphics.DrawImage(
        $source,
        ([System.Drawing.Rectangle]::new([int]$renderX, [int]$renderY, [int]$renderWidth, [int]$renderHeight)),
        ([System.Drawing.Rectangle]::new(0, 0, [int]$source.Width, [int]$source.Height)),
        [System.Drawing.GraphicsUnit]::Pixel
    )
    $graphics.ResetClip()

    $labelFont = New-Object System.Drawing.Font('Segoe UI Semibold', 24, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $labelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 58, 72, 120))
    $labelText = if ($Orientation -eq 'portrait') { 'Play Console 9:16 ready' } else { 'Play Console 16:9 ready' }
    $graphics.DrawString($labelText, $labelFont, $labelBrush, 42, 32)

    $outputPath = Join-Path $outputDir ($file.BaseName + '_' + $suffix + '.png')
    $canvas.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

    $labelBrush.Dispose()
    $labelFont.Dispose()
    $clipPath.Dispose()
    $framePen.Dispose()
    $frameBrush.Dispose()
    $framePath.Dispose()
    $shadowBrush.Dispose()
    $shadowPath.Dispose()
    $accent2.Dispose()
    $accent1.Dispose()
    $backgroundBrush.Dispose()
    $graphics.Dispose()
    $canvas.Dispose()
    $source.Dispose()

    Write-Output "Generated $outputPath"
}