# HB227VehicleV2 for Unreal 1

HB227VehicleV2 is an alpha ground-vehicle mod for **Unreal / Unreal Gold with OldUnreal 227k** on Windows. UnrealScript handles input, camera and world traces. `HB227NativeBridge` connects UnrealScript to the Core3D physics solver.

## Install a prebuilt archive

Choose the x86 ZIP for System/ or the x64 ZIP for System64/. Extract it into the root of an existing, matching Unreal 227k installation. The archive contains the native bridge DLL and the two script packages inside the correct System folder. The Bulldog meshes and skins are embedded in HB227VehicleV2.u. Use the launch command in [First drive on SpireVillage](#first-drive-on-spirevillage).

To build locally, use the source checkout or source ZIP and follow the steps below.

## Build prerequisites

- A separate Windows installation of Unreal with OldUnreal 227k. Use an Unreal installation path without spaces so UCC can parse its command line. The reference build uses engine version `227`, subversion `11` as reported by UCC.
- The matching OldUnreal native SDK with `Core/Inc`, `Engine/Inc` and `Core/Lib/<arch>` and `Engine/Lib/<arch>` for the architectures you build. Get the runtime and SDK from [OldUnreal](https://www.oldunreal.com/).
- Visual Studio Build Tools with the MSVC x86/x64 C++ tools and a Windows SDK.

## Where the files go

| From the clone or build | Where it goes in your Unreal installation |
| --- | --- |
| `HB227VehicleV2/` | `<UnrealRoot>/HB227VehicleV2/` |
| `HB227NativeBridge/` | `<UnrealRoot>/HB227NativeBridge/` |
| `HB227NativeBridge.dll` built for x86 | `<UnrealRoot>/System/` |
| `HB227NativeBridge.dll` built for x64 | `<UnrealRoot>/System64/` |
| `HB227NativeBridge.u` and `HB227VehicleV2.u` built by UCC | `<UnrealRoot>/System/`. Copy **the same two `.u` files** to `System64/` for x64. |
| `SpireVillage.unr` from your Unreal installation | `<UnrealRoot>/Maps/` |

`<UnrealRoot>` is the folder that contains `System/`, `Maps/` and `Textures/`. The two source packages sit alongside those folders. Keep their `Classes/`, `Inc/` and `Src/` subfolders intact.

## Build and install

### 1. Copy the two source packages

Close Unreal and UnrealEd. Set these three paths in PowerShell.

```powershell
$repo = 'D:\Projects\HB227VehicleV2'
$game = 'D:\Games\Unreal227k-dev'
$sdk  = 'D:\SDKs\OldUnreal227k'

Copy-Item -LiteralPath "$repo\HB227NativeBridge", "$repo\HB227VehicleV2" -Destination $game -Recurse -Force
Set-Location $game
```

### 2. Build the native DLLs

Build x86 first. The 32-bit UCC loads `System/HB227NativeBridge.dll` to resolve native functions while compiling UnrealScript. The second command is for installations that include `System64/`.

```powershell
.\HB227NativeBridge\Build-NativeBridge.ps1 -Arch x86 -SdkRoot $sdk
.\HB227NativeBridge\Build-NativeBridge.ps1 -Arch x64 -SdkRoot $sdk
```

### 3. Compile the UnrealScript packages

In `System/`, copy `Unreal.ini` to `HB227Build.ini` and retain the existing stock `EditPackages` entries. Add these two lines **once**, in this order, at the end of the list under `[Editor.EditorEngine]`.

```ini
EditPackages=HB227NativeBridge
EditPackages=HB227VehicleV2
```

For a rebuild, move the previous `System/HB227NativeBridge.u` and `System/HB227VehicleV2.u` into a backup folder before running UCC so it compiles both packages from source.

```powershell
Set-Location "$game\System"
.\UCC.exe make '-ini=HB227Build.ini' '-log=HB227Build.log' '-nohomedir'
Get-Item .\HB227NativeBridge.u, .\HB227VehicleV2.u
```

Confirm that both files were built and that `HB227Build.log` reports `0 warning(s)`. If UCC reports missing native exports, check the architecture and engine revision of the DLL in `System/`.

### 4. Install the script packages for x64

```powershell
Copy-Item -LiteralPath "$game\System\HB227NativeBridge.u", "$game\System\HB227VehicleV2.u" -Destination "$game\System64" -Force
```

For x86, the packages are already in `System/` after step 3.

If you use a custom x64 INI, keep the stock package paths. In [Core.System], the validation setup searched ..\System64\*.u first and ..\System\*.u second, so the game can also load the stock packages from System/.

## First drive on SpireVillage

From `System64/` for x64 or `System/` for x86, run the following command.

```powershell
.\Unreal.exe 'SpireVillage?game=HB227VehicleV2.HB2TestGame?Class=HB227VehicleV2.HB2Driver' -windowed
```

Use **W/S** to drive, **A/D** to steer, **Space** to brake and **F3** for the HUD. For a bug report, include your 227k subversion, architecture, map, steps to reproduce and the relevant Unreal log lines.

## Bulldog assets

Copy the complete HB227VehicleV2/ source directory. Its Models/ subdirectory contains the Unreal vertex meshes for the body, left wheel and right wheel. Textures/ contains the body skin and the headlight and tail-light textures. UCC imports these files into HB227VehicleV2.u when it compiles HB2Vis.uc. The same compiled package carries the visuals on x86 and x64.

The game and the matching 227k SDK are build prerequisites. The Bulldog visuals build from the files in this checkout. Engine audio is optional and uses ArmadilloSFX.Engine1 when the game installation has ArmadilloSFX.uax in Sounds/.

The source of the Bulldog assets and their publication status are recorded in the [release checklist](ALPHA-CHECKLIST.md).

## Source and development tools

- `HB227VehicleV2/Classes/` contains the game type, driver, chassis, visual actors and collision queries.
- `HB227NativeBridge/Src/` and `Inc/` contain the native bridge and solver. `Classes/` defines the bridge API exposed to UnrealScript.
- [Unreal MCP setup](tools/unreal-mcp/README.md#agent-installation) is optional for developers who use Cursor, Codex or Claude Code.

## License

Original project-owned code, build scripts and documentation are under the [MIT License](LICENSE). The Bulldog assets and the generated bridge header are outside this grant. See the [release checklist](ALPHA-CHECKLIST.md) for provenance and third-party distribution checks.

## Acknowledgements

- **Dots**, also known as **.:..:** on OldUnreal, for the Bulldog model extraction used here from U2Vehicles, for bringing the UT2003 Bulldog to Unreal 1, and for his Unreal mods. [U2Vehicles release thread](https://www.oldunreal.com/phpBB3/viewtopic.php?t=7555)
- **The OldUnreal team and the Unreal community** for developing, testing and maintaining the 227 patch and for keeping Unreal 1 modding active.
- **Epic Games and the original Unreal Tournament 2003 development team** for the Bulldog model and textures shipped with UT2003. The local asset export comes from the U2Vehicles port credited to Dots above.
- **Epic Games** for creating and releasing Unreal and making the game available to modders. [OldUnreal 227 release notes](https://www.oldunreal.com/patch/unreal/oldunreal/227ReleaseNotes.pdf)

HB227VehicleV2 is a free, non-commercial fan project.

## Alpha status

The collision sandbox has been exercised in x86 and x64. Steep mesh approaches can still lose speed, and a full drive combining ramps with hard steering remains to be tested. See the [release checklist](ALPHA-CHECKLIST.md) for outstanding release work.
