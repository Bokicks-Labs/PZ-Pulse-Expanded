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
mod ID. It does not add diagnostic code to the copied payload.
The repository release payload, public Workshop staging, and subscribed
Workshop files remain untouched. The command prints the ZIP's SHA-256 hash.

## Install for a multiplayer test

1. Stop the test server. Back up its configuration before changing the mod
   list. Keep its world/save files intact.
2. Extract the ZIP at the server account's `Zomboid` directory, **not** inside
   `Zomboid/mods/PZPulseExpandedDev`. The ZIP already contains the `mods` folder.
   The resulting metadata file must be exactly
   `Zomboid/mods/PZPulseExpandedDev/42/mod.info`, with no additional `mods` or
   `PZPulseExpandedDev` folder between those components. Extract the same ZIP
   at each test client's `Zomboid` directory. Compare its SHA-256 before
   distributing it.
3. In the server's active `.ini`, replace `PZ_Pulse_Expanded` with
   `PZ_Pulse_Expanded_Dev` on `Mods=`. Keep PZ Pulse and the other required
   mods. Remove only the public PZ Pulse Expanded item ID `3804774101` from
   `WorkshopItems=` for the test. The development mod has no Workshop ID.
4. On each client, enable the development mod and disable the public PZ Pulse
   Expanded mod for this test. Restart the server and clients, then verify the
   PZ Pulse extension manifest names `PZ_Pulse_Expanded_Dev`. A client missing
   the local development folder cannot join with
   the intended code.

For a focused Nature's Call test, join the server with the updated bundle,
confirm both bars appear after the first owner sync, then watch them through
at least one usual snapshot gap (the prior client log showed gaps up to about
57 seconds). A brief 2-minute observation is enough to cover the configured
90-second grace period once. If a bar still disappears, record the time and
save the client `Zomboid/console.txt` before starting another session.

Do not enable both Expanded IDs together: they would register two Needs
Expanded panels. For a public release, test the intended source, then use
`Scripts/publish-to-pz-workshop.ps1` separately to stage the release payload.
That release command does not upload to Steam.

This local-file route requires filesystem access to the server and each test
client. If the host cannot accept local mods, use a separate test Workshop
item and server profile; never publish test code to item `3804774101`.
