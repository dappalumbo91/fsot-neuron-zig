@echo off
REM =============================================================================
REM FSOT THINK HOUR — biologically accurate long think process
REM =============================================================================
REM Process (not LLM epochs):
REM   seed + literature experience encode (wake_encode + DA tag)
REM   → episodic retrace / probe (wake_probe)
REM   → curiosity discover + pending questions
REM   → LTM warm (disk → STM)
REM   → compose unique ideas
REM   → sleep: wake_rest → NREM (low ACh/NE) → replay (DA tag)
REM       light: CPU pair replay | every 4th: VRAM FSOT-GPU consensus
REM   → LTM spill when STM full (growth unbounded)
REM   STUCK → auto-stop (no thrash)
REM
REM Metrics (bio, not GSM8K):
REM   episodic_retrace  curiosity_hit  sleep/replay  mean_da/ach  STM/LTM
REM =============================================================================
setlocal
cd /d "%~dp0"

if not exist "data\results" mkdir "data\results"
if not exist "data\ltm" mkdir "data\ltm"

echo.
echo === FSOT BIO THINK HOUR ===
echo Doctrine: experience learning + sleep consolidation — NOT LLM chain-of-thought
echo.
echo Building ReleaseFast mind...
zig build -Doptimize=ReleaseFast
if errorlevel 1 (
  echo BUILD FAIL
  exit /b 1
)

set EXE=zig-out\bin\fsot_mind.exe
if not exist "%EXE%" (
  echo missing %EXE%
  exit /b 1
)

echo.
echo Live log:    %CD%\data\results\THINK_LIVE.log
echo Genetic:     %CD%\data\results\THINK_GENETIC.log
echo Accuracy:    %CD%\data\results\THINK_ACCURACY.jsonl
echo Pending:     %CD%\data\results\THINK_PENDING_QUESTIONS.jsonl
echo LTM disk:    %CD%\data\ltm\
echo.
echo Tail live:   powershell -Command "Get-Content 'data\results\THINK_LIVE.log' -Wait -Tail 20"
echo.
echo Starting think-hour (max 60 min; may stop earlier if stuck)...
echo.

"%EXE%" think-hour
set EC=%ERRORLEVEL%
echo.
echo EXIT=%EC%
echo.
echo === RUN SUMMARY (last accuracy line) ===
if exist "data\results\THINK_ACCURACY.jsonl" (
  powershell -NoProfile -Command "Get-Content 'data\results\THINK_ACCURACY.jsonl' -Tail 1"
)
if exist "data\results\THINK_LIVE.log" (
  echo === LIVE DONE LINE ===
  powershell -NoProfile -Command "Select-String -Path 'data\results\THINK_LIVE.log' -Pattern 'THINK_DONE|THINK_BIO|THINK_ORGANS' | Select-Object -Last 5"
)
pause
exit /b %EC%
