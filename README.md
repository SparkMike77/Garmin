# Garmin Venu 2 — Watchface + Home Assistant Control App

Two Connect IQ projects for the Garmin Venu 2:

- **WatchFace/** — 24-hour clock face with heart rate, steps, stairs, weather,
  compass, battery, date, and a Home Assistant reachability indicator.
- **App/** — standalone watch app for controlling Home Assistant devices
  (garage door, lights) from your wrist.

Both talk to Home Assistant's REST API over the phone's Bluetooth connection
to Garmin Connect Mobile (the Venu 2 has no wifi of its own).

## Prerequisites

- [VS Code](https://code.visualstudio.com/) with the **Monkey C** extension
  (`garmin.monkey-c`)
- [Connect IQ SDK Manager](https://developer.garmin.com/connect-iq/sdk/) —
  use it to install the Connect IQ SDK and the **Venu 2** device image
- Java 8 or later (required by the SDK toolchain)
- A Home Assistant instance reachable from your phone, with at least one
  entity you want to control/monitor (e.g. a garage door cover, a light)

## 1. Developer signing key

Connect IQ apps must be signed with a personal developer key. This repo does
not ship one — generate your own:

1. In VS Code, open the Command Palette and run **"Monkey C: Generate
   Developer Key"**.
2. Save the generated key pair into the `keys/` folder at the repo root as
   `developer_key.der` (public/signing key) and `developer_key_private.pem`.
   `keys/` is gitignored, so this stays local to your machine.
3. Point the extension at it: create (or edit) `.vscode/settings.json` in the
   repo root (also gitignored) with:

   ```json
   {
     "monkeyC.developerKeyPath": "${workspaceFolder}/keys/developer_key.der"
   }
   ```

Without this, builds will fail or the extension will prompt you to browse to
a key file each time.

## 2. Home Assistant long-lived access token

1. In Home Assistant, go to your **Profile** (click your username, bottom
   left) → scroll to **Long-Lived Access Tokens** → **Create Token**.
2. Name it something like `garmin-venu2` and copy the token — Home Assistant
   only shows it once.
3. You'll also need the base URL of your Home Assistant instance (e.g. a
   Nabu Casa remote URL like `https://xxxx.ui.nabu.casa`, or your local
   `http://homeassistant.local:8123` if reachable from your phone). No
   trailing slash needed.

## 3. Home Assistant entity IDs (App only)

The control app needs the `entity_id` of each device you want to operate:

- In Home Assistant, go to **Developer Tools → States** (or **Settings →
  Devices & Services → Entities**) and find the entity, e.g.
  `cover.my_garage_door` or `light.living_room_lamp`.

## 4. Putting it all together

Each project has a `resources/settings/settings.xml.template` with the
fields you need to fill in. **Copy it to `settings.xml` in the same folder**
(the `.template` suffix removed) — `settings.xml` is gitignored so your real
values never get committed:

```
WatchFace/resources/settings/settings.xml.template  →  WatchFace/resources/settings/settings.xml
App/resources/settings/settings.xml.template         →  App/resources/settings/settings.xml
```

Fill in:

| File | Property | Value |
|---|---|---|
| Both | `ha_url` | Your Home Assistant base URL (step 2) |
| Both | `ha_token` | Your long-lived access token (step 2) |
| App only | `ha_garage_entity` | Garage door/cover entity ID (step 3) |
| App only | `ha_light_entity` | Light entity ID (step 3) |

The WatchFace and App have separate settings files, so you can point them at
different Home Assistant instances/tokens if you want — but normally you'll
just copy the same `ha_url`/`ha_token` into both.

> These same settings can also be edited later from your phone, in Garmin
> Connect Mobile → device → **App Settings**, without rebuilding — the
> `settings.xml` you create here is just the default shipped with the build.

## 5. Building and running

From VS Code with a project folder open (`App/` or `WatchFace/`):

- **Command Palette → "Monkey C: Build for Device"** (or **Run** to launch
  in the simulator), choosing the **venu2** target.
- Simulator run requires the Connect IQ SDK's device simulator, installed via
  the SDK Manager.

## 6. Installing on a physical Venu 2 (Windows, over USB)

The Venu 2 connects over USB as an MTP device, not a drive letter, so it
won't show up in a normal file copy dialog. After building a `.prg`:

```powershell
$shell = New-Object -ComObject Shell.Application
$device = $shell.Namespace(0x11).Items() | Where-Object { $_.Name -like "*Venu 2*" }
$internal = ($device.GetFolder.Items() | Where-Object { $_.Name -eq "Internal Storage" }).GetFolder
$apps = ($internal.Items() | Where-Object { $_.Name -eq "GARMIN" }).GetFolder
$appsFolder = ($apps.Items() | Where-Object { $_.Name -eq "APPS" }).GetFolder
$appsFolder.CopyHere("C:\path\to\Built.prg", 0x14)
```

Eject/disconnect the watch afterward so it rescans and registers the new
watch face or app.

## Security notes

- Never commit `keys/` or `settings.xml` — both are gitignored on purpose
  because they contain your personal signing key and Home Assistant
  credentials.
- If a real token or key is ever accidentally committed, rotating/revoking
  it in Home Assistant (or regenerating the developer key) is not optional —
  removing it from a later commit doesn't remove it from git history, and
  this repo is public.
