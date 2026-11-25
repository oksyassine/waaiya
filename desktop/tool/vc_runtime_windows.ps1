# Puts the Microsoft Visual C++ runtime into a built Windows app, next to the programs that need it:
#
#   pwsh desktop/tool/vc_runtime_windows.ps1 -App desktop/build/windows/x64/runner/Release
#
# waaiya_desktop.exe, flutter_windows.dll and the plugin DLLs are MSVC builds that load msvcp140.dll,
# vcruntime140.dll and vcruntime140_1.dll; so does engine\onnxruntime.dll (ONNX Runtime's own MSVC build), loaded by
# engine\waaiya-filter.exe and engine\waaiya-blur.exe, whose DLLs are looked for in engine\ first, not next to
# waaiya_desktop.exe. Windows does not include this runtime: on a PC without the "Visual C++ Redistributable" the app
# would not start. The other engine programs (llvm-mingw, static) need only the Universal C Runtime that Windows 10
# and 11 have. So the runtime's DLLs go into both folders (and engine\links, when the zip has the save tools),
# app-local, as Microsoft allows for the files of Visual Studio's Redist folder
# (VC\Redist\MSVC\<version>\x64\Microsoft.VC14x.CRT). The Microsoft Store package is made from this folder
# (make_msix.ps1) and so carries them too, with no dependency on the VCLibs framework package.
# Then every DLL these programs import is checked (dumpbin /dependents): one of the runtime's that is not in the
# program's folder fails the build. Needs Visual Studio with the C++ tools, as on GitHub's Windows runners.
param([Parameter(Mandatory = $true)][string]$App)
$ErrorActionPreference = "Stop"

$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $vs) { throw "Visual Studio with the C++ tools not found (vswhere)" }
$crt = Get-ChildItem "$vs\VC\Redist\MSVC\*\x64\Microsoft.VC14*.CRT" -Directory |
    Where-Object { $_.Parent.Parent.Name -match '^\d+(\.\d+)+$' } |
    Sort-Object { [version]$_.Parent.Parent.Name } | Select-Object -Last 1
if (-not $crt) { throw "no Microsoft.VC14x.CRT folder under $vs\VC\Redist\MSVC" }
foreach ($f in "msvcp140.dll", "vcruntime140.dll", "vcruntime140_1.dll") {
    if (-not (Test-Path (Join-Path $crt.FullName $f))) { throw "$f not in $($crt.FullName)" }
}
$engine = Join-Path $App "engine"
$dirs = @($App, $engine)
# engine\links (zip only): yt-dlp.exe, qjs.exe, ffmpeg.exe, each finding its DLLs in its own folder
$links = Join-Path $engine "links"
if (Test-Path $links) { $dirs += $links }
foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) { throw "$dir not found (build the app and run bundle_windows.sh first)" }
    Copy-Item (Join-Path $crt.FullName "*.dll") $dir -Force
}
Write-Host "Visual C++ runtime $($crt.Parent.Parent.Name) ($((Get-ChildItem $crt.FullName -Filter *.dll).Name -join ', ')) -> $($dirs -join ', ')"

# every runtime DLL a program imports is in its folder (its exe's folder: DLLs are looked for there)
$dumpbin = Get-ChildItem "$vs\VC\Tools\MSVC\*\bin\Hostx64\x64\dumpbin.exe" | Select-Object -Last 1
if (-not $dumpbin) { throw "dumpbin.exe not found under $vs\VC\Tools\MSVC" }
$runtime = '^(msvcp140(_\w+)?|vcruntime140(_\w+)?|concrt140|vccorlib140)\.dll$'
foreach ($dir in $dirs) {
    $missing = @()
    foreach ($pe in Get-ChildItem $dir -File | Where-Object { $_.Extension -in ".exe", ".dll" }) {
        if ($pe.Name -match $runtime) { continue }
        $deps = & $dumpbin.FullName /nologo /dependents $pe.FullName | ForEach-Object { $_.Trim() } |
            Where-Object { $_ -match $runtime }
        foreach ($d in $deps) {
            Write-Host "  $($pe.Name) -> $d"
            if (-not (Test-Path (Join-Path $dir $d))) { $missing += "$($pe.Name) needs $d" }
        }
    }
    if ($missing) { throw "runtime DLLs missing in ${dir}: $($missing -join '; ')" }
}
