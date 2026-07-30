@echo off
REM 60-minute internal think loop — live progress in data\results\THINK_LIVE.log
setlocal
cd /d "%~dp0"
if not exist "data\results" mkdir "data\results"
set EXE=%TEMP%\fsot_mind_think.exe
if not exist "%EXE%" (
  echo Building fsot_mind_think.exe ...
  zig build-exe -OReleaseFast "-femit-bin=%EXE%" --cache-dir "%TEMP%\fsot_zig_cache_think" --name fsot_mind_think src\main_mind.zig -lgdi32 -luser32 -lwinmm
  if errorlevel 1 exit /b 1
)
echo.
echo === FSOT THINK HOUR ===
echo Live log: %CD%\data\results\THINK_LIVE.log
echo Tail with:  powershell -Command "Get-Content 'data\results\THINK_LIVE.log' -Wait -Tail 15"
echo.
"%EXE%" think-hour
echo EXIT=%ERRORLEVEL%
pause
