# Multiplayer development builds

The public Workshop item (`3804774101`) is the release channel. Test builds
use a separate mod ID, `PZ_Pulse_Expanded_Dev`, so they can be installed as
local files without updating that item.

## Build a test bundle

From the repository root, run:

```powershell
.\Scripts\build-dev-bundle.ps1
```

The command creates a timestamped directory under `artifacts/dev` containing
`mods/PZPulseExpandedDev` and `PZPulseExpandedDev.zip`. It changes only the
copied `mod.info` ID/name and the copied PZ Pulse extension registration's
mod ID. The repository source, public Workshop staging, and subscribed
Workshop files remain untouched. The command prints the ZIP's SHA-256 hash.

## Install for a multiplayer test

1. Stop the test server. Back up its configuration before changing the mod
   list. Keep its world/save files intact.
2. Extract `mods/PZPulseExpandedDev` into the server account's `Zomboid/mods`
   directory. Install the same directory under each test client's `Zomboid/mods`.
   Compare the bundle SHA-256 before distributing it.
3. In the server's active `.ini`, replace `PZ_Pulse_Expanded` with
   `PZ_Pulse_Expanded_Dev` on `Mods=`. Keep PZ Pulse and the other required
   mods. Remove only the public PZ Pulse Expanded item ID `3804774101` from
   `WorkshopItems=` for the test. The development mod has no Workshop ID.
4. On each client, enable the development mod and disable the public PZ Pulse
   Expanded mod for this test. Restart the server and clients, then verify the
   PZ Pulse extension manifest names `PZ_Pulse_Expanded_Dev` and the expected
   test build. A client missing the local development folder cannot join with
   the intended code.

Do not enable both Expanded IDs together: they would register two Needs
Expanded panels. For a public release, test the intended source, then use
`Scripts/publish-to-pz-workshop.ps1` separately to stage the release payload.
That release command does not upload to Steam.

This local-file route requires filesystem access to the server and each test
client. If the host cannot accept local mods, use a separate test Workshop
item and server profile; never publish test code to item `3804774101`.
