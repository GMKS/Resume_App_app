param(
    [string]$Source,
    [string]$Destination = "assets/branding/resumix_app_icon.png",
    [int]$Threshold = 245,
    [int]$Padding = 32,
    [int]$OutputSize = 1024
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$resolvedSource = (Resolve-Path $Source).Path
$resolvedDestination = if ([System.IO.Path]::IsPathRooted($Destination)) {
    $Destination
} else {
    Join-Path (Get-Location) $Destination
}

$destinationDirectory = Split-Path -Parent $resolvedDestination
if (-not (Test-Path $destinationDirectory)) {
    New-Item -ItemType Directory -Force -Path $destinationDirectory | Out-Null
}

$image = $null
$cropped = $null
$graphics = $null

try {
    $image = [System.Drawing.Bitmap]::FromFile($resolvedSource)

    $minX = $image.Width
    $minY = $image.Height
    $maxX = 0
    $maxY = 0

    for ($x = 0; $x -lt $image.Width; $x++) {
        for ($y = 0; $y -lt $image.Height; $y++) {
            $pixel = $image.GetPixel($x, $y)
            if ($pixel.R -lt $Threshold -or $pixel.G -lt $Threshold -or $pixel.B -lt $Threshold) {
                if ($x -lt $minX) { $minX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -gt $maxY) { $maxY = $y }
            }
        }
    }

    if ($minX -gt $maxX -or $minY -gt $maxY) {
        throw 'Could not detect icon bounds in the source image.'
    }

    $minX = [Math]::Max(0, $minX - $Padding)
    $minY = [Math]::Max(0, $minY - $Padding)
    $maxX = [Math]::Min($image.Width - 1, $maxX + $Padding)
    $maxY = [Math]::Min($image.Height - 1, $maxY + $Padding)

    $cropWidth = $maxX - $minX + 1
    $cropHeight = $maxY - $minY + 1
    $side = [Math]::Max($cropWidth, $cropHeight)

    $centerX = $minX + ($cropWidth / 2.0)
    $centerY = $minY + ($cropHeight / 2.0)

    $squareX = [Math]::Round($centerX - ($side / 2.0))
    $squareY = [Math]::Round($centerY - ($side / 2.0))

    $squareX = [Math]::Max(0, [Math]::Min($image.Width - $side, $squareX))
    $squareY = [Math]::Max(0, [Math]::Min($image.Height - $side, $squareY))

    $sourceRect = [System.Drawing.Rectangle]::new($squareX, $squareY, $side, $side)
    $destinationRect = [System.Drawing.Rectangle]::new(0, 0, $OutputSize, $OutputSize)

    $cropped = [System.Drawing.Bitmap]::new($OutputSize, $OutputSize)
    $graphics = [System.Drawing.Graphics]::FromImage($cropped)
    $graphics.Clear([System.Drawing.Color]::White)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.DrawImage($image, $destinationRect, $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)

    $cropped.Save($resolvedDestination, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Output "Prepared app icon: $resolvedDestination"
}
finally {
    if ($graphics -ne $null) { $graphics.Dispose() }
    if ($cropped -ne $null) { $cropped.Dispose() }
    if ($image -ne $null) { $image.Dispose() }
}