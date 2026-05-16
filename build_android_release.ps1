param(
    [ValidateSet('appbundle', 'apk')]
    [string]$Artifact = 'appbundle',
    [switch]$AnalyzeSize,
    [switch]$Arm64Only,
    [string]$SplitDebugInfoDir = 'build/symbols'
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$pubspecPath = Join-Path $PSScriptRoot 'pubspec.yaml'
$buildNumberStatePath = Join-Path $PSScriptRoot '.last_android_build_number'
$androidLocalPropertiesPath = Join-Path $PSScriptRoot 'android\local.properties'
$dotEnvPath = Join-Path $PSScriptRoot '.env'

function Get-LocalPropertyMap {
    param(
        [string]$Path
    )

    $properties = @{}

    if (-not (Test-Path $Path)) {
        return $properties
    }

    foreach ($line in Get-Content $Path) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $trimmed = $line.Trim()
        if ($trimmed.StartsWith('#')) {
            continue
        }

        $separatorIndex = $trimmed.IndexOf('=')
        if ($separatorIndex -lt 1) {
            continue
        }

        $key = $trimmed.Substring(0, $separatorIndex).Trim()
        $value = $trimmed.Substring($separatorIndex + 1).Trim()
        if (-not [string]::IsNullOrWhiteSpace($key)) {
            $properties[$key] = $value
        }
    }

    return $properties
}

function Get-ConfigValue {
    param(
        [string]$Key,
        [hashtable]$LocalProperties,
        [hashtable]$DotEnvProperties
    )

    $environmentValue = [Environment]::GetEnvironmentVariable($Key)
    if (-not [string]::IsNullOrWhiteSpace($environmentValue)) {
        return $environmentValue
    }

    if ($LocalProperties.ContainsKey($Key)) {
        return $LocalProperties[$Key]
    }

    if ($DotEnvProperties.ContainsKey($Key)) {
        return $DotEnvProperties[$Key]
    }

    return $null
}

$localProperties = Get-LocalPropertyMap -Path $androidLocalPropertiesPath
$dotEnvProperties = Get-LocalPropertyMap -Path $dotEnvPath

function Get-PubspecBuildNumber {
    param(
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        return 0L
    }

    $versionLine = Select-String -Path $Path -Pattern '^version:\s*.+\+(\d+)\s*$' | Select-Object -First 1
    if ($null -eq $versionLine) {
        return 0L
    }

    return [int64]$versionLine.Matches[0].Groups[1].Value
}

function Get-LastBuildNumber {
    param(
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        return 0L
    }

    $rawValue = (Get-Content $Path -TotalCount 1).Trim()
    if ([string]::IsNullOrWhiteSpace($rawValue)) {
        return 0L
    }

    try {
        return [int64]$rawValue
    }
    catch {
        return 0L
    }
}

$currentEpochSeconds = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$pubspecBuildNumber = Get-PubspecBuildNumber -Path $pubspecPath
$lastBuildNumber = Get-LastBuildNumber -Path $buildNumberStatePath
$buildNumber = [Math]::Max($currentEpochSeconds, [Math]::Max($pubspecBuildNumber + 1, $lastBuildNumber + 1))

Set-Content -Path $buildNumberStatePath -Value $buildNumber
Write-Host "Using Android version code: $buildNumber"

$isApkBuild = $Artifact -eq 'apk'

if ($AnalyzeSize -and $isApkBuild) {
    throw 'AnalyzeSize is only supported for appbundle builds.'
}

$targetPlatform = if ($Arm64Only -or $isApkBuild) {
    'android-arm64'
} else {
    'android-arm,android-arm64'
}

if ($isApkBuild -and -not $Arm64Only) {
    Write-Host 'APK builds default to arm64-only to avoid JVM out-of-memory crashes on low-memory Windows machines.'
}

$buildArgs = @(
    'build',
    $Artifact,
    '--release',
    '--build-number', $buildNumber,
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

$razorpayKeyId = Get-ConfigValue -Key 'RAZORPAY_KEY_ID' -LocalProperties $localProperties -DotEnvProperties $dotEnvProperties
if (-not [string]::IsNullOrWhiteSpace($razorpayKeyId)) {
    $buildArgs += "--dart-define=RAZORPAY_KEY_ID=$($razorpayKeyId.Trim())"
}

$playProductEnvKeys = @(
    'PLAY_WEEKLY_PRODUCT_ID',
    'PLAY_MONTHLY_PRODUCT_ID',
    'PLAY_QUARTERLY_PRODUCT_ID',
    'PLAY_YEARLY_PRODUCT_ID',
    'ENABLE_FACEBOOK_AUTH',
    'FACEBOOK_APP_ID',
    'FACEBOOK_CLIENT_TOKEN',
    'LINKEDIN_PROVIDER_ID',
    'OTP_BASE_URL',
    'OTP_SEND_URL',
    'OTP_VERIFY_URL'
)

$otpBaseUrl = Get-ConfigValue -Key 'OTP_BASE_URL' -LocalProperties $localProperties -DotEnvProperties $dotEnvProperties
$otpSendUrl = Get-ConfigValue -Key 'OTP_SEND_URL' -LocalProperties $localProperties -DotEnvProperties $dotEnvProperties
$otpVerifyUrl = Get-ConfigValue -Key 'OTP_VERIFY_URL' -LocalProperties $localProperties -DotEnvProperties $dotEnvProperties

foreach ($key in $playProductEnvKeys) {
    $value = switch ($key) {
        'OTP_BASE_URL' { $otpBaseUrl }
        'OTP_SEND_URL' { $otpSendUrl }
        'OTP_VERIFY_URL' { $otpVerifyUrl }
        default { Get-ConfigValue -Key $key -LocalProperties $localProperties -DotEnvProperties $dotEnvProperties }
    }

    if (-not [string]::IsNullOrWhiteSpace($value)) {
        $buildArgs += "--dart-define=$key=$($value.Trim())"
    }
}

flutter clean
flutter pub get
& flutter @buildArgs

if ($isApkBuild) {
    $apkPath = Join-Path $PSScriptRoot 'build\app\outputs\flutter-apk\app-release.apk'
    if (Test-Path $apkPath) {
        $apk = Get-Item $apkPath
        $apkSizeMb = [math]::Round($apk.Length / 1MB, 2)
        Write-Host "Built APK: $($apk.FullName) ($apkSizeMb MB)"
    }
} else {
    $bundlePath = Join-Path $PSScriptRoot 'build\app\outputs\bundle\release\app-release.aab'
    if (Test-Path $bundlePath) {
        $bundle = Get-Item $bundlePath
        $bundleSizeMb = [math]::Round($bundle.Length / 1MB, 2)
        Write-Host "Built AAB: $($bundle.FullName) ($bundleSizeMb MB)"
    }
}