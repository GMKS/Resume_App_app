param(
    [switch]$AnalyzeSize,
    [switch]$Arm64Only,
    [string]$VersionName
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$preferredJavaHome = $null
$gradlePropertiesPath = Join-Path $PSScriptRoot 'android\gradle.properties'

if (Test-Path $gradlePropertiesPath) {
    $gradleJavaHomeMatch = Select-String -Path $gradlePropertiesPath -Pattern '^org\.gradle\.java\.home=(.+)$'
    if ($gradleJavaHomeMatch) {
        $candidate = $gradleJavaHomeMatch.Matches[0].Groups[1].Value.Trim()
        if ($candidate -and (Test-Path $candidate)) {
            $preferredJavaHome = $candidate
        }
    }
}

if (-not $preferredJavaHome -and $env:LOCALAPPDATA) {
    $candidate = Join-Path $env:LOCALAPPDATA 'Programs\Microsoft\jdk-17'
    if (Test-Path $candidate) {
        $preferredJavaHome = $candidate
    }
}

if (-not $preferredJavaHome) {
    $candidate = 'C:\Program Files\Microsoft\jdk-17'
    if (Test-Path $candidate) {
        $preferredJavaHome = $candidate
    }
}

if ($preferredJavaHome) {
    $env:JAVA_HOME = $preferredJavaHome
    $env:Path = (Join-Path $preferredJavaHome 'bin') + ';' + $env:Path
    Write-Host "Using JAVA_HOME=$preferredJavaHome"
}

$pubspecVersionMatch = Select-String -Path 'pubspec.yaml' -Pattern '^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$'
if (-not $pubspecVersionMatch) {
    throw 'Unable to determine Flutter version from pubspec.yaml.'
}

$pubspecBuildNumber = [int64]$pubspecVersionMatch.Matches[0].Groups[2].Value
$pubspecVersionName = $pubspecVersionMatch.Matches[0].Groups[1].Value
$releaseVersionName = if ([string]::IsNullOrWhiteSpace($VersionName)) { $pubspecVersionName } else { $VersionName.Trim() }
$pubspecVersionChanged = $releaseVersionName -ne $pubspecVersionName
$lastBuildNumberPath = Join-Path $PSScriptRoot '.last_android_build_number'
$lastRecordedBuildNumber = 0

if (Test-Path $lastBuildNumberPath) {
    $lastRecordedValue = (Get-Content $lastBuildNumberPath | Select-Object -First 1).Trim()
    if ($lastRecordedValue) {
        $lastRecordedBuildNumber = [int64]$lastRecordedValue
    }
}

$nextBuildNumber = [Math]::Max(
    [DateTimeOffset]::UtcNow.ToUnixTimeSeconds(),
    [Math]::Max($pubspecBuildNumber + 1, $lastRecordedBuildNumber + 1)
)

if ($nextBuildNumber -le $pubspecBuildNumber -or $nextBuildNumber -le $lastRecordedBuildNumber) {
    throw "Computed build number $nextBuildNumber must be greater than the previous version codes (pubspec=$pubspecBuildNumber, lastBuild=$lastRecordedBuildNumber)."
}

if ($nextBuildNumber -eq $pubspecBuildNumber) {
    throw "Refusing to build with duplicate versionCode $nextBuildNumber. Increase the build number before packaging a new AAB."
}

# Keep Android versionCode in a safe range (Play's max is 2,100,000,000).
if ($nextBuildNumber -gt 2100000000) {
    throw "Computed build number $nextBuildNumber exceeds Android/Play maximum (2,100,000,000)."
}

function Update-PubspecVersion {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$VersionName,
        [Parameter(Mandatory = $true)][int64]$BuildNumber
    )

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $encoding = $null
    $bomLength = 0

    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $encoding = New-Object System.Text.UTF8Encoding($true)
        $bomLength = 3
    } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        $encoding = [System.Text.Encoding]::Unicode
        $bomLength = 2
    } elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        $encoding = [System.Text.Encoding]::BigEndianUnicode
        $bomLength = 2
    } else {
        $encoding = New-Object System.Text.UTF8Encoding($false)
        $bomLength = 0
    }

    $text = $encoding.GetString($bytes, $bomLength, $bytes.Length - $bomLength)

    $updated = [System.Text.RegularExpressions.Regex]::Replace(
        $text,
        '(?m)^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$',
        { param($m) "version: $VersionName+$BuildNumber" }
    )

    if ($updated -ne $text) {
        $outBytes = $encoding.GetBytes($updated)
        if ($bomLength -gt 0) {
            $bom = $bytes[0..($bomLength - 1)]
            $outBytes = $bom + $outBytes
        }
        [System.IO.File]::WriteAllBytes($Path, $outBytes)
        Write-Host "Synced pubspec.yaml version -> $VersionName+$BuildNumber"
    }
}

Write-Host "Using Android versionCode=$nextBuildNumber"
if ($pubspecVersionChanged) {
    Write-Host "Updating versionName from $pubspecVersionName to $releaseVersionName"
}

Update-PubspecVersion -Path (Join-Path $PSScriptRoot 'pubspec.yaml') -VersionName $releaseVersionName -BuildNumber $nextBuildNumber

$targetPlatform = if ($Arm64Only) {
    'android-arm64'
} else {
    'android-arm,android-arm64'
}

$buildArgs = @(
    'build',
    'appbundle',
    '--release',
    '--build-number', $nextBuildNumber,
    '--target-platform', $targetPlatform,
    '--tree-shake-icons',
    '--obfuscate',
    '--split-debug-info=build/symbols'
)

function Get-ConfigValue {
    param(
        [Parameter(Mandatory = $true)][string]$Key
    )

    $envValue = [Environment]::GetEnvironmentVariable($Key)
    if (-not [string]::IsNullOrWhiteSpace($envValue)) {
        return $envValue.Trim()
    }

    $localPropertiesPath = Join-Path $PSScriptRoot 'android\local.properties'
    if (Test-Path $localPropertiesPath) {
        $match = Select-String -Path $localPropertiesPath -Pattern ("^" + [Regex]::Escape($Key) + "=(.*)$") | Select-Object -First 1
        if ($match) {
            $value = $match.Matches[0].Groups[1].Value.Trim()
            if (-not [string]::IsNullOrWhiteSpace($value)) {
                return $value
            }
        }
    }

    $dotEnvPath = Join-Path $PSScriptRoot '.env'
    if (Test-Path $dotEnvPath) {
        $match = Select-String -Path $dotEnvPath -Pattern ("^" + [Regex]::Escape($Key) + "=(.*)$") | Select-Object -First 1
        if ($match) {
            $value = $match.Matches[0].Groups[1].Value.Trim()
            if (-not [string]::IsNullOrWhiteSpace($value)) {
                return $value
            }
        }
    }

    return ''
}

$otpBaseUrl = Get-ConfigValue -Key 'OTP_BASE_URL'
$otpSendUrl = Get-ConfigValue -Key 'OTP_SEND_URL'
$otpVerifyUrl = Get-ConfigValue -Key 'OTP_VERIFY_URL'
$aiBaseUrl = Get-ConfigValue -Key 'AI_BASE_URL'
$aiEnvironment = Get-ConfigValue -Key 'AI_ENV'
$razorpayKeyId = Get-ConfigValue -Key 'RAZORPAY_KEY_ID'

if (-not [string]::IsNullOrWhiteSpace($razorpayKeyId) -and
    [string]::IsNullOrWhiteSpace($otpBaseUrl) -and
    [string]::IsNullOrWhiteSpace($otpSendUrl) -and
    [string]::IsNullOrWhiteSpace($otpVerifyUrl)) {
    throw 'Razorpay checkout requires OTP_BASE_URL or OTP_SEND_URL / OTP_VERIFY_URL to be configured in environment variables, android/local.properties, or .env before building a release.'
}

if ([string]::IsNullOrWhiteSpace($aiBaseUrl)) {
    throw 'Production AI features require AI_BASE_URL to be configured in environment variables, android/local.properties, or .env before building a release.'
}

if ($aiBaseUrl -notmatch '^https?://') {
    throw "AI_BASE_URL must be an absolute http/https URL. Current value: $aiBaseUrl"
}

if ([string]::IsNullOrWhiteSpace($aiEnvironment)) {
    Write-Warning 'AI_ENV is not configured. Defaulting runtime diagnostics to production.'
}

if ($AnalyzeSize) {
    $buildArgs += '--analyze-size'
}

Write-Host 'Release checklist:'
Write-Host "- versionCode: $nextBuildNumber (previous pubspec=$pubspecBuildNumber, lastBuild=$lastRecordedBuildNumber)"
Write-Host "- versionName: $releaseVersionName"
Write-Host '- Google Play Billing: enabled in production builds and product IDs loaded from release config'
Write-Host "- AI backend: $aiBaseUrl"
if (-not [string]::IsNullOrWhiteSpace($aiEnvironment)) {
    Write-Host "- AI environment: $aiEnvironment"
}
Write-Host '- Dummy/test payments: disabled for signed release builds'
Write-Host '- Build output: release app bundle for Play Console upload'

function Ensure-FlutterDependencies {
    $packageConfigPath = Join-Path $PSScriptRoot '.dart_tool\package_config.json'
    $pubspecLockPath = Join-Path $PSScriptRoot 'pubspec.lock'

    $needsGet = -not (Test-Path $packageConfigPath)
    if (-not $needsGet -and (Test-Path $pubspecLockPath)) {
        $packageConfigTime = (Get-Item $packageConfigPath).LastWriteTimeUtc
        $pubspecTime = (Get-Item 'pubspec.yaml').LastWriteTimeUtc
        $lockTime = (Get-Item $pubspecLockPath).LastWriteTimeUtc
        if ($pubspecTime -gt $packageConfigTime -or $lockTime -gt $packageConfigTime) {
            $needsGet = $true
        }
    }

    if ($needsGet) {
        Write-Host 'Refreshing Flutter dependencies...'
        flutter pub get
    } else {
        Write-Host 'Skipping flutter pub get; dependency cache is current.'
    }
}

Ensure-FlutterDependencies
& flutter @buildArgs --build-name $releaseVersionName

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Set-Content -Path $lastBuildNumberPath -Value $nextBuildNumber

$aabPath = Join-Path $PSScriptRoot 'build\app\outputs\bundle\release\app-release.aab'

if (-not (Test-Path $aabPath)) {
    $candidateRoots = @(
        (Join-Path $PSScriptRoot 'build\app\outputs'),
        (Join-Path $PSScriptRoot 'android\app\build\outputs')
    )

    $candidates = foreach ($root in $candidateRoots) {
        if (Test-Path $root) {
            Get-ChildItem -Path $root -Recurse -Filter '*.aab' -File -ErrorAction SilentlyContinue
        }
    }

    $newest = $candidates | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($newest) {
        $aabPath = $newest.FullName
    }
}

if (Test-Path $aabPath) {
    $releaseArtifactsDir = Join-Path $PSScriptRoot 'release-artifacts'
    New-Item -ItemType Directory -Path $releaseArtifactsDir -Force | Out-Null

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $destAabPath = Join-Path $releaseArtifactsDir ("app-release-$nextBuildNumber-$timestamp.aab")

    $sourceHash = (Get-FileHash -LiteralPath $aabPath -Algorithm SHA256).Hash
    $copied = $false

    foreach ($attempt in 1..3) {
        if (Test-Path $destAabPath) {
            Remove-Item -LiteralPath $destAabPath -Force
        }

        [System.IO.File]::Copy($aabPath, $destAabPath, $true)
        $destHash = (Get-FileHash -LiteralPath $destAabPath -Algorithm SHA256).Hash

        if ($destHash -eq $sourceHash) {
            $copied = $true
            break
        }
    }

    if (-not $copied) {
        throw "Copied AAB failed integrity verification. Source hash: $sourceHash"
    }

    Write-Host "Saved AAB to $destAabPath"
} else {
    Write-Warning "Build succeeded but expected AAB not found at: $aabPath"
}