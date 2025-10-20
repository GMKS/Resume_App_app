$lines = Get-Content 'c:\Users\SIS4\Resume_App_app\lib\services\ai_service.dart' -TotalCount 1417
$lines | Out-File 'c:\Users\SIS4\Resume_App_app\lib\services\ai_service_temp.dart' -Encoding utf8
Start-Sleep -Milliseconds 500
Move-Item -Path 'c:\Users\SIS4\Resume_App_app\lib\services\ai_service_temp.dart' -Destination 'c:\Users\SIS4\Resume_App_app\lib\services\ai_service.dart' -Force
