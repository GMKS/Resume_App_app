Add-Type -AssemblyName System.Drawing

$sourceDir = Join-Path $PSScriptRoot '..\assets\store_screenshots'
$targetWidth = 1920
$targetHeight = 1080
$targetAspect = $targetWidth / $targetHeight

$jobs = @(
    @{ Source = 'src_dashboard.png'; Target = 'phone_screenshot_01_dashboard.png'; TrimRight = 120; CropY = 24 },
    @{ Source = 'src_editor.png'; Target = 'phone_screenshot_02_editor.png'; TrimRight = 120; CropY = 0 },
    @{ Source = 'src_ai_generator.png'; Target = 'phone_screenshot_03_ai_generator.png'; TrimRight = 120; CropY = 0 },
    @{ Source = 'src_job_tracker.png'; Target = 'phone_screenshot_04_job_tracker.png'; TrimRight = 120; CropY = 0 },
    @{ Source = 'src_settings.png'; Target = 'phone_screenshot_05_settings.png'; TrimRight = 120; CropY = 0 }
)

foreach ($job in $jobs) {
    $sourcePath = Join-Path $sourceDir $job.Source
    $targetPath = Join-Path $sourceDir $job.Target

    $image = [System.Drawing.Image]::FromFile($sourcePath)
    $trimmedWidth = $image.Width - $job.TrimRight
    $trimmedHeight = $image.Height
    $sourceAspect = $trimmedWidth / $trimmedHeight

    if ($sourceAspect -gt $targetAspect) {
        $cropHeight = $trimmedHeight
        $cropWidth = [int][Math]::Round($cropHeight * $targetAspect)
        $cropX = [int][Math]::Round(($trimmedWidth - $cropWidth) / 2)
        $cropY = 0
    }
    else {
        $cropWidth = $trimmedWidth
        $cropHeight = [int][Math]::Round($cropWidth / $targetAspect)
        $cropX = 0
        $cropY = [int][Math]::Min($job.CropY, [Math]::Max(0, $trimmedHeight - $cropHeight))
    }

    $cropRect = New-Object System.Drawing.Rectangle($cropX, $cropY, $cropWidth, $cropHeight)
    $bitmap = New-Object System.Drawing.Bitmap($targetWidth, $targetHeight)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.Clear([System.Drawing.Color]::White)

    $destRect = New-Object System.Drawing.Rectangle(0, 0, $targetWidth, $targetHeight)
    $graphics.DrawImage($image, $destRect, $cropRect, [System.Drawing.GraphicsUnit]::Pixel)
    $bitmap.Save($targetPath, [System.Drawing.Imaging.ImageFormat]::Png)

    $graphics.Dispose()
    $bitmap.Dispose()
    $image.Dispose()

    Write-Output "Generated $targetPath"
}