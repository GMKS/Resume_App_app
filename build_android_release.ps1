param(
    [switch]$AnalyzeSize,
    [switch]$Arm64Only,
    [string]$AppDataNamespace = 'production'
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

function Get-PropertyValue {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Key
    )

    if (-not (Test-Path $Path)) {
        return $null
    }

    $prefix = "$Key="
    $line = Get-Content $Path | Where-Object { $_.StartsWith($prefix) } | Select-Object -First 1
    if (-not $line) {
        return $null
    }

    return $line.Substring($prefix.Length).Trim()
}

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

$normalizedAppDataNamespace = if ($null -eq $AppDataNamespace) {
    ''
} else {
    $AppDataNamespace.Trim().ToLowerInvariant()
}
if ([string]::IsNullOrWhiteSpace($normalizedAppDataNamespace)) {
    $normalizedAppDataNamespace = 'production'
}
$env:APP_DATA_NAMESPACE = $normalizedAppDataNamespace
Write-Host "Using APP_DATA_NAMESPACE=$normalizedAppDataNamespace"

$localPropertiesPath = Join-Path $PSScriptRoot 'android\local.properties'
$requiredPlayKeys = @(
    'PLAY_WEEKLY_PRODUCT_ID',
    'PLAY_MONTHLY_PRODUCT_ID',
    'PLAY_QUARTERLY_PRODUCT_ID',
    'PLAY_YEARLY_PRODUCT_ID'
)

$missingPlayKeys = @()
foreach ($key in $requiredPlayKeys) {
    $value = Get-PropertyValue -Path $localPropertiesPath -Key $key
    if ([string]::IsNullOrWhiteSpace($value)) {
        $missingPlayKeys += $key
    }
}

if ($missingPlayKeys.Count -gt 0) {
    throw "Google Play Billing is not production-ready. Missing Android product IDs in android/local.properties: $($missingPlayKeys -join ', ')"
}

foreach ($forbiddenKey in @('ENABLE_DUMMY_PAYMENTS', 'DISABLE_GOOGLE_PLAY_BILLING')) {
    $value = Get-PropertyValue -Path $localPropertiesPath -Key $forbiddenKey
    if ($null -ne $value -and @('1', 'true', 'yes', 'on').Contains($value.Trim().ToLowerInvariant())) {
        throw "Production AAB build blocked: $forbiddenKey must not be enabled in android/local.properties."
    }
}

$pubspecVersionMatch = Select-String -Path 'pubspec.yaml' -Pattern '^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$'
if (-not $pubspecVersionMatch) {
    throw 'Unable to determine Flutter version from pubspec.yaml.'
}

$pubspecBuildNumber = [int64]$pubspecVersionMatch.Matches[0].Groups[2].Value
$pubspecVersionName = $pubspecVersionMatch.Matches[0].Groups[1].Value
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

# Keep Android versionCode in a safe range (Play's max is 2,100,000,000).
if ($nextBuildNumber -gt 2100000000) {
    throw "Computed build number $nextBuildNumber exceeds Android/Play maximum (2,100,000,000)."
}

function Update-PubspecBuildNumber {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
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
        { param($m) "version: $($m.Groups[1].Value)+$BuildNumber" }
    )

    if ($updated -ne $text) {
        $outBytes = $encoding.GetBytes($updated)
        if ($bomLength -gt 0) {
            $bom = $bytes[0..($bomLength - 1)]
            $outBytes = $bom + $outBytes
        }
        [System.IO.File]::WriteAllBytes($Path, $outBytes)
        Write-Host "Synced pubspec.yaml build number -> $BuildNumber"
    }
}

Write-Host "Using Android versionCode=$nextBuildNumber"

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

if ($AnalyzeSize) {
    $buildArgs += '--analyze-size'
}

if (Test-Path (Join-Path $PSScriptRoot 'android\gradlew.bat')) {
    Write-Host 'Stopping existing Gradle daemons (if any)...'
    Push-Location (Join-Path $PSScriptRoot 'android')
    try {
        & .\gradlew.bat --stop | Out-Null
    } finally {
        Pop-Location
    }
}

flutter clean
flutter pub get
& flutter @buildArgs

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Set-Content -Path $lastBuildNumberPath -Value $nextBuildNumber
Update-PubspecBuildNumber -Path (Join-Path $PSScriptRoot 'pubspec.yaml') -BuildNumber $nextBuildNumber

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

    $jarsignerPath = if ($env:JAVA_HOME) {
        Join-Path $env:JAVA_HOME 'bin\jarsigner.exe'
    } else {
        $null
    }

    if ($jarsignerPath -and (Test-Path $jarsignerPath)) {
        & $jarsignerPath -verify -verbose -certs $destAabPath | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "AAB signature verification failed for $destAabPath"
        }
    }

    Write-Host "Saved AAB to $destAabPath"
} else {
    Write-Warning "Build succeeded but expected AAB not found at: $aabPath"
}