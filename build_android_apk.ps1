param(
    [switch]$Release,
    [switch]$SplitPerAbi,
    [string]$AppDataNamespace
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

function Get-PreferredJavaHome {
    $gradlePropertiesPath = Join-Path $PSScriptRoot 'android\gradle.properties'

    if (Test-Path $gradlePropertiesPath) {
        $gradleJavaHomeMatch = Select-String -Path $gradlePropertiesPath -Pattern '^org\.gradle\.java\.home=(.+)$'
        if ($gradleJavaHomeMatch) {
            $candidate = $gradleJavaHomeMatch.Matches[0].Groups[1].Value.Trim()
            if ($candidate -and (Test-Path $candidate)) {
                return $candidate
            }
        }
    }

    if ($env:LOCALAPPDATA) {
        $candidate = Join-Path $env:LOCALAPPDATA 'Programs\Microsoft\jdk-17'
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    $fallback = 'C:\Program Files\Microsoft\jdk-17'
    if (Test-Path $fallback) {
        return $fallback
    }

    return $null
}

$preferredJavaHome = Get-PreferredJavaHome
if (-not $preferredJavaHome) {
    throw 'JDK 17 was not found. Update android/gradle.properties or install Microsoft JDK 17.'
}

$env:JAVA_HOME = $preferredJavaHome
$env:Path = (Join-Path $preferredJavaHome 'bin') + ';' + $env:Path
Write-Host "Using JAVA_HOME=$preferredJavaHome"

$normalizedAppDataNamespace = if ($null -eq $AppDataNamespace) {
    ''
} else {
    $AppDataNamespace.Trim().ToLowerInvariant()
}
if ([string]::IsNullOrWhiteSpace($normalizedAppDataNamespace)) {
    $normalizedAppDataNamespace = if ($Release) { 'production' } else { 'debug' }
}
$env:APP_DATA_NAMESPACE = $normalizedAppDataNamespace
Write-Host "Using APP_DATA_NAMESPACE=$normalizedAppDataNamespace"

$buildArgs = @('build', 'apk')
if ($Release) {
    $buildArgs += '--release'
} else {
    $buildArgs += '--debug'
}

if ($SplitPerAbi) {
    $buildArgs += '--split-per-abi'
}

& flutter @buildArgs
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}