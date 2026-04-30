# Run the Flutter web app on a FIXED port so IndexedDB data persists between sessions.
# IndexedDB is scoped to the browser origin (scheme + host + port).
# Using a random port (the default) creates a new origin every run and wipes all saved resumes.
# On Windows, keep Flutter's temp files inside the workspace to avoid stale global
# temp paths breaking Chrome attach with missing app.dill.incremental.dill errors.
#
# Usage:  .\run_web.ps1
# Or in VS Code press F5 and choose "Flutter Web (Chrome)"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$flutterTemp = Join-Path $projectRoot '.flutter_web_temp'

$flutterCommand = if (Get-Command flutter -ErrorAction SilentlyContinue) {
	'flutter'
} elseif (Test-Path 'C:\Flutter\flutter\bin\flutter.bat') {
	'C:\Flutter\flutter\bin\flutter.bat'
} else {
	throw 'Flutter SDK was not found. Install Flutter or add it to PATH.'
}

New-Item -ItemType Directory -Force -Path $flutterTemp | Out-Null

$env:TEMP = $flutterTemp
$env:TMP = $flutterTemp

& $flutterCommand run -d chrome --web-port=5000
