# Reproduce neural Zig bio / structure gates (domain metrics under pin D1D38A).
# Usage (from repo root):
#   powershell -File .\scripts\reproduce_bio_gates.ps1
#   powershell -File .\scripts\reproduce_bio_gates.ps1 -SkipBuild

param(
    [switch]$SkipBuild
)

# Native exe writes progress to stderr; do not treat as terminating errors.
$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Split-Path -Parent $ScriptDir
Set-Location $Root

$Exe = Join-Path $Root "zig-out\bin\fsot_mind.exe"
$OutDir = Join-Path $Root "data\results"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$Log = Join-Path $OutDir "BIO_GATES_REPRO.log"

function Write-Log([string]$s) {
    Add-Content -Path $Log -Value $s
    Write-Host $s
}

Set-Content -Path $Log -Value ""
Write-Log "=== FSOT neural Zig bio gates ==="
Write-Log ("utc=" + (Get-Date -Format o))
Write-Log ("root=" + $Root)
Write-Log "pin=D1D38A (law spine: FSOT-2.1-Lean / Physical Archive)"
Write-Log "claims=docs/CLAIMS_AND_NONCLAIMS.md"
Write-Log ""

if (-not $SkipBuild) {
    Write-Log "building ReleaseFast..."
    & zig build -Doptimize=ReleaseFast 2>&1 | ForEach-Object { Write-Log "$_" }
    if ($LASTEXITCODE -ne 0) { throw "build failed" }
}

if (-not (Test-Path $Exe)) { throw "missing $Exe" }

Write-Log ""
Write-Log "=== GATE fixed (Allen ISI/adapt + structure) ==="
& $Exe fixed 2>&1 | ForEach-Object { Write-Log "$_" }
$ec1 = $LASTEXITCODE

Write-Log ""
Write-Log "=== GATE scalpel (class rates Pyr/PV/SST/VIP) ==="
& $Exe scalpel 2>&1 | ForEach-Object { Write-Log "$_" }
$ec2 = $LASTEXITCODE

Write-Log ""
Write-Log "=== GATE allen-dist (full CSV variance / KS) ==="
& $Exe allen-dist 2>&1 | ForEach-Object { Write-Log "$_" }
$ec3 = $LASTEXITCODE

Write-Log ""
Write-Log "=== SUMMARY ==="
$txt = Get-Content $Log -Raw
$needles = @(
    "FSOT_FIXED_BIO_ACCURATE_OK",
    "FSOT_ALLEN_ISI_RESIDUAL_CLOSED",
    "FSOT_EPHYS_NATIVE_UNITS_OK",
    "FSOT_EVERY_CELL_BIO_MATCH_OK",
    "FSOT_SCALPEL_RATES PASS",
    "FSOT_ALLEN_CLASS_RATES_CLOSED",
    "FSOT_EVERY_CELL_CLASS_RATE_OK",
    "FSOT_ALLEN_CSV_VARIANCE_OK",
    "FSOT_KS_ISI_ADAPT_OK",
    "gate_bio_isi=PASS",
    "gate_bio_adapt=PASS",
    "gate_bio_every_cell=PASS",
    "isi_abs_err_ms="
)
foreach ($n in $needles) {
    if ($txt -like ("*" + $n + "*")) {
        Write-Log ($n + ": FOUND")
    } else {
        Write-Log ($n + ": MISSING")
    }
}
Write-Log ("exit_fixed=" + $ec1 + " exit_scalpel=" + $ec2 + " exit_allen_dist=" + $ec3)
Write-Log ("log=" + $Log)

if (($ec1 -ne 0) -or ($ec2 -ne 0) -or ($ec3 -ne 0)) {
    Write-Host "BIO GATES FAIL - see log"
    exit 1
}
Write-Host "BIO GATES OK - see log"
exit 0
