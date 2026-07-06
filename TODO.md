# TODO

1) Create basic Garmin WatchFace
   - [x] Clock (24-hour, center)
   - [x] Heartrate (4-position)
   - [x] Step count (1-position)
   - [x] Stair count (2-position)
   - [x] Weather forecast (5-position)
   - [x] Compass (8-position)
   - [x] Watch battery (10-position)
   - [x] Bluetooth connection status to phone (6-position)
   - [x] Home Assistant connection status (7-position) - via a background service (watch faces can't make network calls directly); needs its own ha_url/ha_token configured via the watchface's own App Settings, separate from the App's
   - [x] Date DD/MM (11-position)

2) Create basic Garmin App
   - [x] Display
   - [x] Buttons

3) ~~Create Connector from Watchface to Launch the App~~
   Not possible on Connect IQ: watch faces cannot call `System.exitTo()`
   (restricted to watch-apps/widgets) or `WatchUi.pushView()` (throws
   `OperationNotAllowedException` from a watch face). The App is a
   separate, standalone Watch App opened the normal Garmin way (hold
   button / app list / widget loop) - no tap-to-launch link exists.

4) Create connection to HomeAssistant from App and Watchface
   - [ ] GPS from phone to HA?
   - [X] Display device state - ehhh, Kind of?  Didn't like.
   - [x] Garage Door view scaffolded (state label + Up/Down buttons) - placeholder actions only, not yet wired to real HA REST calls
   - [ ] Lights control view
