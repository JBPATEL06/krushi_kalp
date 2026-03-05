@echo off
echo ========================================
echo  Krushi Kalp - Release Build (Obfuscated)
echo ========================================

echo.
echo [1/3] Cleaning previous build...
call flutter clean

echo.
echo [2/3] Getting dependencies...
call flutter pub get

echo.
echo [3/3] Building obfuscated APK...
call flutter build apk --obfuscate --split-debug-info=debug-info/

echo.
echo ========================================
echo  Build Complete!
echo  APK: build\app\outputs\flutter-apk\app-release.apk
echo  Debug symbols: debug-info\
echo ========================================
echo.
echo IMPORTANT: Keep the debug-info folder safe!
echo It is needed to read Crashlytics stack traces.
pause
