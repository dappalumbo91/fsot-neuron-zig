# Build freestanding trinary kernel and run under QEMU (serial console).
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$zigCmd = Get-Command zig -ErrorAction SilentlyContinue
$zig = $null
if ($zigCmd) { $zig = $zigCmd.Source }
if (-not $zig) {
    $cand = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Filter zig.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
    if ($cand) { $zig = $cand }
}
if (-not $zig) { throw "zig not found on PATH" }

Write-Host "=== zig build kernel ==="
& $zig build kernel

$kernelSrc = Join-Path $PSScriptRoot "zig-out\bin\fsot_trit_kernel"
if (-not (Test-Path $kernelSrc)) {
    Write-Host "FAIL: kernel binary not found"
    exit 2
}

$qemuCmd = Get-Command qemu-system-x86_64 -ErrorAction SilentlyContinue
$qemu = $null
if ($qemuCmd) { $qemu = $qemuCmd.Source }
if (-not $qemu -and (Test-Path "C:\Program Files\qemu\qemu-system-x86_64.exe")) {
    $qemu = "C:\Program Files\qemu\qemu-system-x86_64.exe"
}
if (-not $qemu) {
    Write-Host "WARN: qemu-system-x86_64 not found - kernel at $kernelSrc"
    exit 0
}

# Copy artifacts to TEMP (no spaces) so QEMU path parsing is reliable on Windows
$kernel = Join-Path $env:TEMP "fsot_trit_kernel"
$serialLog = Join-Path $env:TEMP "fsot_trit_qemu_serial.log"
$errLog = Join-Path $env:TEMP "fsot_trit_qemu_err.log"
Copy-Item -Force $kernelSrc $kernel
Remove-Item $serialLog, $errLog -ErrorAction SilentlyContinue

Write-Host "=== QEMU (serial log, FULL Allen genetic FI - not smoke) ==="
Write-Host "budget: genetic pop + polish + class rates (may take several minutes under soft-FPU)"
$arg = "-display none -serial file:$serialLog -no-reboot -m 256M -kernel `"$kernel`""
$p = Start-Process -FilePath $qemu -ArgumentList $arg -PassThru -WindowStyle Hidden -RedirectStandardError $errLog

# Full Allen suite on soft-FPU: long headroom (host fixed ~1 min; QEMU multiplies)
$maxWaitSec = 900
$waited = 0
while (-not $p.HasExited -and $waited -lt $maxWaitSec) {
    Start-Sleep -Seconds 15
    $waited += 15
    if (Test-Path $serialLog) {
        $partial = Get-Content $serialLog -Raw -ErrorAction SilentlyContinue
        if ($partial -match "FSOT_ALLEN_BAREMETAL_FULL|FSOT_STAGE_ZIG_NEURON") {
            # allow a few more seconds for trailing lines
            Start-Sleep -Seconds 10
            break
        }
    }
    Write-Host ("  ... waited {0}s" -f $waited)
}
if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }

Write-Host "--- serial output ---"
if (Test-Path $serialLog) {
    Get-Content $serialLog
    $txt = Get-Content $serialLog -Raw
    if ($txt -match "FSOT_STAGE_ZIG_NEURON_FAIL") {
        Write-Host "=== QEMU GATE FAIL (stage reported FAIL) ==="
        exit 1
    }
    # Require full Allen biological accuracy — not smoke-only trit/brain
    $need = @(
        "FSOT_CODON PASS",
        "FSOT_GENOTYPE PASS",
        "FSOT_BRAIN PASS",
        "gate_bio_isi=PASS",
        "gate_bio_adapt=PASS",
        "gate_bio_every_cell=PASS",
        "FSOT_ALLEN_POP_BAREMETAL PASS",
        "FSOT_SCALPEL_RATES PASS",
        "FSOT_ALLEN_BAREMETAL_FULL PASS",
        "FSOT_ALLEN_ON_QEMU_OK"
    )
    $missing = @()
    foreach ($n in $need) {
        if ($txt -notmatch [regex]::Escape($n)) { $missing += $n }
    }
    if ($missing.Count -eq 0) {
        Write-Host "=== QEMU GATE PASS (full Allen genetic FI on bare metal) ==="
        exit 0
    }
    Write-Host "=== QEMU GATE FAIL (missing Allen bio lines) ==="
    $missing | ForEach-Object { Write-Host ("  missing: " + $_) }
    exit 1
}
Write-Host "no serial log"
if (Test-Path $errLog) { Get-Content $errLog }
exit 1
