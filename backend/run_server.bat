@echo off
echo Starting Task Master Data Collection Server...
cd /d "%~dp0"
dart run server.dart
pause
