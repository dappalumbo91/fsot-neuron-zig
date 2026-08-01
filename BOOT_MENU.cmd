@echo off
REM Default: LIVE connected mind (authority organism)
cd /d "%~dp0"
title FSOT Live Mind - Zig
echo.
echo ============================================================
echo   FSOT LIVE MIND  (Zig authority)
echo   ONE connected organism - not a gate parade
echo ============================================================
echo.
echo   Enter / 1 = LIVE MIND (default)
echo   g = product gates menu
echo   q = quit
echo.
set /p CHOICE=Select [Enter=LIVE MIND]: 
if /i "%CHOICE%"=="q" exit /b 0
if /i "%CHOICE%"=="g" goto :gates

set "EXE=%~dp0zig-out\bin\fsot_mind.exe"
if not exist "%EXE%" (
  echo Building...
  where zig >nul 2>&1
  if errorlevel 1 (echo ERROR: zig not on PATH & pause & exit /b 1)
  zig build -Doptimize=ReleaseFast
  if errorlevel 1 (echo BUILD FAILED & pause & exit /b 1)
)

echo.
echo Starting LIVE connected mind...
echo.
if "%CHOICE%"=="" goto :live
if "%CHOICE%"=="1" goto :live
if /i "%CHOICE%"=="mind" goto :live
if /i "%CHOICE%"=="L" (
  call "%~dp0BOOT_MIND.cmd"
  exit /b %ERRORLEVEL%
)
REM treat other as mode name for advanced users
"%EXE%" %CHOICE%
set ERR=%ERRORLEVEL%
echo.
pause
exit /b %ERR%

:live
"%EXE%" mind
set ERR=%ERRORLEVEL%
echo.
if %ERR%==0 echo FSOT_CONNECTED_ORGANISM_OK
pause
exit /b %ERR%

:gates
echo.
echo   2 phase-a  3 phase-b  4 phase-c  5 phase-d
echo   6 glia-ca  7 self-talk 8 isi-ks   9 compose
echo.
set /p G=Gate mode: 
if "%G%"=="2" set MODE=phase-a
if "%G%"=="3" set MODE=phase-b
if "%G%"=="4" set MODE=phase-c
if "%G%"=="5" set MODE=phase-d
if "%G%"=="6" set MODE=glia-ca
if "%G%"=="7" set MODE=self-talk
if "%G%"=="8" set MODE=isi-ks
if "%G%"=="9" set MODE=compose
if not defined MODE set MODE=%G%
set "EXE=%~dp0zig-out\bin\fsot_mind.exe"
"%EXE%" %MODE%
echo.
echo NOTE: live intelligence is mode mind / BOOT_MIND.cmd
pause
exit /b %ERRORLEVEL%
