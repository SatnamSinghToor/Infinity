param(
    [ValidateSet('appbundle', 'apk')]
    [string]$Target = 'appbundle'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$signingConfig = Join-Path $projectRoot 'android/key.properties'
$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue

if ($flutterCommand) {
    $flutterExecutable = $flutterCommand.Source
} else {
    $localProperties = Join-Path $projectRoot 'android/local.properties'
    $flutterSdkLine = if (Test-Path -LiteralPath $localProperties -PathType Leaf) {
        Select-String -Path $localProperties -Pattern '^flutter\.sdk=(.+)$' | Select-Object -First 1
    }
    if (-not $flutterSdkLine) {
        throw 'Flutter was not found in PATH and android/local.properties has no flutter.sdk entry.'
    }
    $flutterSdk = $flutterSdkLine.Matches[0].Groups[1].Value.Trim() -replace '\\\\', '\'
    $flutterExecutable = Join-Path $flutterSdk 'bin/flutter.bat'
    if (-not (Test-Path -LiteralPath $flutterExecutable -PathType Leaf)) {
        throw "Flutter SDK executable not found at '$flutterExecutable'."
    }
}

if (-not (Test-Path -LiteralPath $signingConfig -PathType Leaf)) {
    throw 'Release signing is not configured. Create android/key.properties and set up the private upload keystore before building a distributable app.'
}

$versionLine = Select-String -Path (Join-Path $projectRoot 'pubspec.yaml') -Pattern '^version:\s*(.+)$' | Select-Object -First 1
if (-not $versionLine) {
    throw 'Could not read the app version from pubspec.yaml.'
}
$version = $versionLine.Matches[0].Groups[1].Value.Trim()
$buildStamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$symbols = Join-Path $projectRoot "release-symbols/android/$version-$buildStamp"
New-Item -ItemType Directory -Force -Path $symbols | Out-Null

Push-Location $projectRoot
try {
    & $flutterExecutable build $Target --release --obfuscate "--split-debug-info=$symbols"
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter release build failed with exit code $LASTEXITCODE."
    }
} finally {
    Pop-Location
}

Write-Host "Release built with Dart obfuscation and Android R8 shrinking. Keep the symbol files in '$symbols' private and back them up; they are required to symbolicate crash traces."
