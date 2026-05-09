Add-Type -AssemblyName System.Drawing

$sourcePath = Join-Path $PSScriptRoot '..\assets\branding\resumix_app_icon.png'
$outputPath = Join-Path $PSScriptRoot '..\assets\branding\resumix_feature_graphic.png'

$width = 1024
$height = 500

$bitmap = New-Object System.Drawing.Bitmap($width, $height)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

$backgroundRect = New-Object System.Drawing.Rectangle(0, 0, $width, $height)
$backgroundBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    $backgroundRect,
    [System.Drawing.Color]::FromArgb(255, 5, 20, 88),
    [System.Drawing.Color]::FromArgb(255, 13, 54, 188),
    20
)
$graphics.FillRectangle($backgroundBrush, $backgroundRect)

$glowBrush1 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(55, 58, 199, 255))
$glowBrush2 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(40, 30, 107, 255))
$graphics.FillEllipse($glowBrush1, -60, -120, 480, 480)
$graphics.FillEllipse($glowBrush2, 760, -60, 300, 300)
$graphics.FillEllipse($glowBrush2, 660, 260, 420, 260)

$icon = [System.Drawing.Image]::FromFile($sourcePath)
$iconSize = 380
$iconX = 60
$iconY = 60
$iconSourceRect = New-Object System.Drawing.Rectangle(76, 76, 872, 872)
$iconDestRect = New-Object System.Drawing.Rectangle($iconX, $iconY, $iconSize, $iconSize)

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

$shadowColor = [System.Drawing.Color]::FromArgb(75, 0, 0, 0)
for ($offset = 16; $offset -ge 1; $offset -= 5) {
    $shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb([Math]::Max(12, $shadowColor.A - (16 - $offset) * 3), 0, 0, 0))
    $graphics.FillEllipse($shadowBrush, $iconX + 22 - $offset, $iconY + 280 - [int]($offset / 2), $iconSize - 30 + ($offset * 2), 70 + $offset)
    $shadowBrush.Dispose()
}

$iconClipPath = New-RoundedRectanglePath -Rect $iconDestRect -Radius 52
$graphics.SetClip($iconClipPath)
$graphics.DrawImage($icon, $iconDestRect, $iconSourceRect, [System.Drawing.GraphicsUnit]::Pixel)
$graphics.ResetClip()
$iconClipPath.Dispose()

$titleFont = New-Object System.Drawing.Font('Segoe UI', 62, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$subtitleFont = New-Object System.Drawing.Font('Segoe UI', 24, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$chipFont = New-Object System.Drawing.Font('Segoe UI Semibold', 20, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)

$whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(248, 250, 255))
$mutedBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 226, 238))
$accentBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(70, 204, 255))
$greenBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(101, 255, 125))

$titleX = 500
$titleY = 110
$graphics.DrawString('Resumix', $titleFont, $whiteBrush, $titleX, $titleY)
$graphics.DrawString('AI Resume Builder', $subtitleFont, $mutedBrush, $titleX + 4, 195)

$chipPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(95, 102, 186, 255), 2)
$chipBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(45, 255, 255, 255))

function Draw-Chip {
    param(
        [System.Drawing.Graphics]$Graphics,
        [int]$X,
        [int]$Y,
        [int]$W,
        [string]$Label,
        [System.Drawing.Font]$Font,
        [System.Drawing.Brush]$TextBrush,
        [System.Drawing.Brush]$FillBrush,
        [System.Drawing.Pen]$BorderPen
    )

    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $radius = 22
    $diameter = $radius * 2
    $path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
    $path.AddArc($X + $W - $diameter, $Y, $diameter, $diameter, 270, 90)
    $path.AddArc($X + $W - $diameter, $Y + 44 - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($X, $Y + 44 - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    $Graphics.FillPath($FillBrush, $path)
    $Graphics.DrawPath($BorderPen, $path)
    $Graphics.DrawString($Label, $Font, $TextBrush, $X + 18, $Y + 9)
    $path.Dispose()
}

Draw-Chip -Graphics $graphics -X 504 -Y 250 -W 150 -Label 'Build' -Font $chipFont -TextBrush $whiteBrush -FillBrush $chipBrush -BorderPen $chipPen
Draw-Chip -Graphics $graphics -X 668 -Y 250 -W 150 -Label 'Apply' -Font $chipFont -TextBrush $accentBrush -FillBrush $chipBrush -BorderPen $chipPen
Draw-Chip -Graphics $graphics -X 832 -Y 250 -W 126 -Label 'Win' -Font $chipFont -TextBrush $greenBrush -FillBrush $chipBrush -BorderPen $chipPen

$bodyFont = New-Object System.Drawing.Font('Segoe UI', 22, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$bodyBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(232, 236, 247))
$graphics.DrawString('Create polished resumes tailored to your goals.', $bodyFont, $bodyBrush, 504, 334)
$graphics.DrawString('Build faster, apply smarter, and export clean PDFs.', $bodyFont, $bodyBrush, 504, 368)

$linePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(120, 78, 191, 255), 3)
$graphics.DrawLine($linePen, 504, 438, 948, 438)

$bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

$linePen.Dispose()
$bodyBrush.Dispose()
$bodyFont.Dispose()
$chipBrush.Dispose()
$chipPen.Dispose()
$greenBrush.Dispose()
$accentBrush.Dispose()
$mutedBrush.Dispose()
$whiteBrush.Dispose()
$chipFont.Dispose()
$subtitleFont.Dispose()
$titleFont.Dispose()
$icon.Dispose()
$glowBrush2.Dispose()
$glowBrush1.Dispose()
$backgroundBrush.Dispose()
$graphics.Dispose()
$bitmap.Dispose()

Write-Output "Generated feature graphic: $outputPath"