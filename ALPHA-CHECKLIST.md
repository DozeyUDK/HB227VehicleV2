# Alpha release checklist

This checklist is for maintainers preparing a GitHub prerelease. The [main README](README.md) covers local development and installation.

- [ ] Confirm provenance and distribution terms for the files selected for publication. The MIT grant is scoped to original project-owned material in LICENSE.
- [ ] Build from a fresh checkout against the documented 227k runtime and matching native SDK. Check both DLL architectures and the two script packages.
- [ ] Run a first drive on stock SpireVillage from a separate game installation. Repeat in x86 and x64 with optional assets absent.
- [ ] Recheck the physics sandbox on steep mesh approaches and complete a route that combines ramps with hard steering.
- [ ] If publishing binary ZIPs, include HB227NativeBridge.dll, HB227NativeBridge.u and HB227VehicleV2.u. Use a System/ root directory in the x86 archive and System64/ in the x64 archive. Keep stock game data, the SDK and local logs outside the archives.

## Licensing and provenance

- The OldUnreal SDK used for the reference build ships SDKLICENSE.md. Its Core Modules section covers Epic's Core and Engine, with non-commercial terms. Its OldUnreal Modules section gives separate redistribution terms for the listed OldUnreal components. Check the terms of the specific module and SDK revision when including any third-party material.
- The native bridge builds against the external Core and Engine SDK. Review source publication and distribution of the resulting native DLLs and compiled UnrealScript packages individually. The SDK, game files and optional Armadillo audio remain external to this build.
- Confirm the provenance of the earlier vehicle implementations referenced by HB2Body.uc and HB2Driver.uc. Review HB227NativeBridgeClasses.h as well. It is a UCC-generated header for the bridge classes and is part of the staged source tree.
- The staged Bulldog assets are the body, left and right wheel meshes and three PCX textures from the local U2Vehicles export. The U2Vehicles release notes attribute the Bulldog to UT2003. Confirm redistribution terms for these assets before publishing the source files or a compiled package that embeds them. [U2Vehicles release notes](https://www.oldunreal.com/phpBB3/viewtopic.php?t=7555)
