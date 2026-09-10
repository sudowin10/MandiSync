@echo off
title MandiSync Flutter (Chrome Dev Mode)
cd /d "%~dp0"
echo Starting Flutter Chrome development server with Hot Reload...
flutter run -d chrome
pause
