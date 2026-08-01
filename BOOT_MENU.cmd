@echo off
REM Double-click menu for FSOT Zig authority (uses zig-out if present).
cd /d "%~dp0"
title FSOT Neuron Zig
echo.
echo ============================================================
echo   FSOT NEURON ZIG  -  authority mind
echo ============================================================
echo.

set "EXE=%~dp0zig-out\bin\fsot_mind.exe"
if not exist "%EXE%" (
  echo Building zig-out\bin\fsot_mind.exe ...
  where zig >nul 2>&1
  if errorlevel 1 (
    echo ERROR: zig not on PATH
    pause
    exit /b 1
  )
  zig build -Doptimize=ReleaseFast
  if errorlevel 1 (
    echo BUILD FAILED
    pause
    exit /b 1
  )
)

echo   1 phase-a   2 phase-b   3 phase-c   4 phase-d
echo   5 glia-ca   6 self-talk 7 isi-ks    8 bio-learn
echo   9 compose   t think     a all-product  q quit
echo   L live-mind (BOOT_MIND.cmd connected organism)
echo.
set /p CHOICE=Select mode: 
if /i "%CHOICE%"=="q" exit /b 0
if /i "%CHOICE%"=="L" (
  call "%~dp0BOOT_MIND.cmd"
  exit /b %ERRORLEVEL%
)
if "%CHOICE%"=="1" set MODE=phase-a
if "%CHOICE%"=="2" set MODE=phase-b
if "%CHOICE%"=="3" set MODE=phase-c
if "%CHOICE%"=="4" set MODE=phase-d
if /i "%CHOICE%"=="5" set MODE=glia-ca
if /i "%CHOICE%"=="6" set MODE=self-talk
if "%CHOICE%"=="7" set MODE=isi-ks
if "%CHOICE%"=="8" set MODE=bio-learn
if "%CHOICE%"=="9" set MODE=compose
if /i "%CHOICE%"=="t" set MODE=think
if /i "%CHOICE%"=="a" goto :all
if not defined MODE set MODE=%CHOICE%

echo.
echo Running: %MODE%
"%EXE%" %MODE%
set ERR=%ERRORLEVEL%
echo.
if %ERR%==0 (echo FSOT_OK) else (echo FAILED exit=%ERR%)
pause
exit /b %ERR%

:all
for %%m in (phase-a phase-b phase-c phase-d glia-ca self-talk) do (
  echo.
  echo ----- %%m -----
  "%EXE%" %%m
  if errorlevel 1 set ERR=1
)
if not defined ERR set ERR=0
pause
exit /b %ERR%
