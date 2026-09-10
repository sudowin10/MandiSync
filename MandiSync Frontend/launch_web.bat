@echo off
title MandiSync Flutter Web
echo ========================================================
echo Launching MandiSync Flutter Web on http://localhost:3000
echo Target Backend: http://10.0.41.4:8000
echo ========================================================
start "" "http://localhost:3000"
python -m http.server 3000 --directory "%~dp0build\web"
pause
