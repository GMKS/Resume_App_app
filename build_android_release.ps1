param(
    [switch]$AnalyzeSize,
    [switch]$Arm64Only,
    [string]$SplitDebugInfoDir = 'build/symbols'
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$targetPlatform = if ($Arm64Only) {
    'android-arm64'
} else {
    'android-arm,android-arm64'
}

$buildArgs = @(
    'build',
    'appbundle',
    '--release',
    '--target-platform', $targetPlatform,
    '--tree-shake-icons'
)

if ($AnalyzeSize) {
    $buildArgs += '--analyze-size'
} else {
    $buildArgs += @(
        '--obfuscate',
        "--split-debug-info=$SplitDebugInfoDir"
    )
}

$razorpayKeyId = $env:RAZORPAY_KEY_ID
if (-not [string]::IsNullOrWhiteSpace($razorpayKeyId)) {
    $buildArgs += "--dart-define=RAZORPAY_KEY_ID=$($razorpayKeyId.Trim())"
}

$playProductEnvKeys = @(
    'PLAY_WEEKLY_PRODUCT_ID',
    'PLAY_MONTHLY_PRODUCT_ID',
    'PLAY_QUARTERLY_PRODUCT_ID',
    'PLAY_YEARLY_PRODUCT_ID',
    'OTP_SEND_URL',
    'OTP_VERIFY_URL'
)

foreach ($key in $playProductEnvKeys) {
    $value = [Environment]::GetEnvironmentVariable($key)
    if (-not [string]::IsNullOrWhiteSpace($value)) {
        $buildArgs += "--dart-define=$key=$($value.Trim())"
    }
}

flutter clean
flutter pub get
& flutter @buildArgs

$bundlePath = Join-Path $PSScriptRoot 'build\app\outputs\bundle\release\app-release.aab'
if (Test-Path $bundlePath) {
    $bundle = Get-Item $bundlePath
    $bundleSizeMb = [math]::Round($bundle.Length / 1MB, 2)
    Write-Host "Built AAB: $($bundle.FullName) ($bundleSizeMb MB)"
}