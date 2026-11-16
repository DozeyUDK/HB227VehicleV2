# Build HB227NativeBridge.dll against a local OldUnreal 227k SDK.
param(
  [ValidateSet('x64','x86')]
  [string]$Arch = 'x64',
  [Parameter(Mandatory)][string]$SdkRoot,
  [switch]$VerifyOnly
)
$ErrorActionPreference = 'Stop'
$Pkg = $PSScriptRoot
$DevRoot = Split-Path -Parent $Pkg
$Sdk = (Resolve-Path -LiteralPath $SdkRoot).Path
$OutDir = if ($Arch -eq 'x64') { Join-Path $DevRoot 'System64' } else { Join-Path $DevRoot 'System' }
if (-not $VerifyOnly -and -not (Test-Path -LiteralPath $OutDir -PathType Container)) {
  throw "Missing Unreal installation folder: $OutDir"
}

$CoreLib = Join-Path $Sdk "Core\Lib\$Arch\Core.lib"
$EngLib  = Join-Path $Sdk "Engine\Lib\$Arch\Engine.lib"
foreach ($inputPath in (Join-Path $Sdk 'Core\Inc'), (Join-Path $Sdk 'Engine\Inc'), $CoreLib, $EngLib) {
  if (-not (Test-Path -LiteralPath $inputPath)) { throw "Missing SDK input: $inputPath" }
}
$VsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path -LiteralPath $VsWhere -PathType Leaf)) { throw "Visual Studio Installer (vswhere.exe) not found: $VsWhere" }
$Vs = & $VsWhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $Vs) { throw 'VS Build Tools not found' }
$ArchArg = if ($Arch -eq 'x64') { 'amd64' } else { 'x86' }
$DevShell = Join-Path $Vs 'Common7\Tools\Launch-VsDevShell.ps1'
Write-Host "Entering VS DevShell $ArchArg from $Vs"
& $DevShell -Arch $ArchArg -SkipAutomaticLocation | Out-Null

$ObjDir = Join-Path $Pkg "build\$Arch"
New-Item -ItemType Directory -Force -Path $ObjDir | Out-Null
$Obj = Join-Path $ObjDir 'HB227NativeBridgeMain.obj'
$Dll = if ($VerifyOnly) {
  Join-Path $ObjDir 'HB227NativeBridge.verify.dll'
} else {
  Join-Path $OutDir 'HB227NativeBridge.dll'
}
$Pdb = Join-Path $ObjDir 'HB227NativeBridge.pdb'

$Includes = @(
  "/I$Pkg\Inc",
  "/I$Pkg\Src",
  "/I$Sdk\Core\Inc",
  "/I$Sdk\Engine\Inc"
)
$Defs = @(
  '/DWIN32=1',
  '/D_WIN32=1',
  '/D_WINDOWS=1',
  '/DWINDOWS=1',
  '/DUNICODE=1',
  '/D_UNICODE=1',
  '/D_CRT_SECURE_NO_WARNINGS=1',
  '/D_CRT_NO_VA_START_VALIDATION',
  '/DUTGLR_UNREAL_227_BUILD',
  '/DUSES_SSE_INTRINSICS=1',
  '/DHB227NATIVEBRIDGE_API=__declspec(dllexport)',
  '/DNDEBUG',
  '/D_RELEASE',
  '/DRELEASE'
)
if ($Arch -eq 'x64') { $Defs += @('/DWIN64=1','/D_WIN64=1') }

$Src = Join-Path $Pkg 'Src\HB227NativeBridgeMain.cpp'
$ClArgs = @('/nologo','/c','/O2','/MD','/EHsc','/GS','/fp:precise','/Zc:wchar_t','/W3',"/Fo$Obj") + $Includes + $Defs + @($Src)
Write-Host "cl $($ClArgs -join ' ')"
& cl @ClArgs
if ($LASTEXITCODE -ne 0) { throw "cl failed: $LASTEXITCODE" }

$Machine = if ($Arch -eq 'x64') { 'X64' } else { 'X86' }
$LinkArgs = @(
  '/nologo','/DLL','/INCREMENTAL:NO',"/MACHINE:$Machine",
  "/OUT:$Dll",
  "/PDB:$Pdb",
  "/IMPLIB:$ObjDir\HB227NativeBridge.lib",
  $Obj, $CoreLib, $EngLib,
  'kernel32.lib','user32.lib','advapi32.lib'
)
Write-Host "link $($LinkArgs -join ' ')"
& link @LinkArgs
if ($LASTEXITCODE -ne 0) { throw "link failed: $LASTEXITCODE" }
Get-Item $Dll | Format-List FullName, Length
Get-FileHash -Algorithm SHA256 -LiteralPath $Dll | Format-List
$Mode = if ($VerifyOnly) { 'VERIFY BUILD' } else { 'DEPLOY BUILD' }
Write-Host "$Mode OK: $Dll" -ForegroundColor Green
