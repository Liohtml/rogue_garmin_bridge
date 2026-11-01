# Echo Bike for Garmin

[![Build](https://github.com/Liohtml/rogue_garmin_bridge/actions/workflows/build.yml/badge.svg)](https://github.com/Liohtml/rogue_garmin_bridge/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A Garmin **Connect IQ watch app** that connects your **fēnix** or **epix** directly to
the **Rogue Echo Bike** (air bike) over Bluetooth LE and records a **native indoor
cycling activity** with the bike's power, cadence, speed and distance. No phone,
Raspberry Pi or other bridge is needed.

🇩🇪 [Deutsche Anleitung](README.de.md)

## Features

- Finds and connects to the Echo Bike console automatically (Bluetooth **FTMS**) and
  reconnects after dropouts.
- Live screens: power, cadence, heart rate, speed, distance, timer · averages, max,
  normalized power, lap power, calories, kcal/h, MET.
- Records a regular Garmin activity (*Indoor Cycling*). Power, cadence, speed and
  distance go into the **native FIT fields**, so Garmin Connect, Strava, TrainingPeaks
  and others show them like data from a power meter.
- Every other value the console sends (calories, kcal/h, console HR, MET, resistance)
  is stored as Connect IQ developer fields. Details: [docs/fit-fields.md](docs/fit-fields.md).
- Laps, pause/resume, save/discard, using the same buttons as Garmin's own activities.
- English and German UI. Speed and distance follow the watch's unit setting.
- Should also work with other FTMS indoor bikes (falls back to the first FTMS device it finds).

## Install

### Connect IQ store

Not published yet. See [docs/publishing.md](docs/publishing.md).

### Sideload (USB)

1. Download the `.prg` for your watch from the
   [latest release](https://github.com/Liohtml/rogue_garmin_bridge/releases/latest)
   (table below).
2. Connect the watch via USB. On macOS use [OpenMTP](https://openmtp.ganeshrvel.com/).
3. Copy the file to **`GARMIN/APPS/`**. You can rename it, e.g. to `EchoBike.prg`.
4. Unplug. **Echo Bike** now appears in the list of activities / apps.

Sideloaded apps do not update automatically.

## Supported watches

| Watch | File |
|---|---|
| epix™ (Gen 2) / quatix® 7 Sapphire | `EchoBike-epix2.prg` |
| epix™ Pro (Gen 2) 42mm | `EchoBike-epix2pro42mm.prg` |
| epix™ Pro (Gen 2) 47mm / quatix® 7 Pro | `EchoBike-epix2pro47mm.prg` |
| epix™ Pro (Gen 2) 51mm / D2™ Mach 1 Pro / tactix® 7 – AMOLED Edition | `EchoBike-epix2pro51mm.prg` |
| fēnix® 5 Plus | `EchoBike-fenix5plus.prg` |
| fēnix® 5S Plus | `EchoBike-fenix5splus.prg` |
| fēnix® 5X Plus | `EchoBike-fenix5xplus.prg` |
| fēnix® 6 / 6 Solar / 6 Dual Power | `EchoBike-fenix6.prg` |
| fēnix® 6 Pro / 6 Sapphire / 6 Pro Solar / 6 Pro Dual Power / quatix® 6 | `EchoBike-fenix6pro.prg` |
| fēnix® 6S / 6S Solar / 6S Dual Power | `EchoBike-fenix6s.prg` |
| fēnix® 6S Pro / 6S Sapphire / 6S Pro Solar / 6S Pro Dual Power | `EchoBike-fenix6spro.prg` |
| fēnix® 6X Pro / 6X Sapphire / 6X Pro Solar / tactix® Delta Sapphire / Delta Solar / Delta Solar - Ballistics Edition / quatix® 6X / 6X Solar / 6X Dual Power | `EchoBike-fenix6xpro.prg` |
| fēnix® 7 / quatix® 7 | `EchoBike-fenix7.prg` |
| fēnix® 7 Pro | `EchoBike-fenix7pro.prg` |
| fēnix® 7 Pro - Solar Edition (no Wi-Fi) | `EchoBike-fenix7pronowifi.prg` |
| fēnix® 7S | `EchoBike-fenix7s.prg` |
| fēnix® 7S Pro | `EchoBike-fenix7spro.prg` |
| fēnix® 7X / tactix® 7 / quatix® 7X Solar / Enduro™ 2 | `EchoBike-fenix7x.prg` |
| fēnix® 7X Pro | `EchoBike-fenix7xpro.prg` |
| fēnix® 7X Pro - Solar Edition (no Wi-Fi) | `EchoBike-fenix7xpronowifi.prg` |
| fēnix® 8 43mm | `EchoBike-fenix843mm.prg` |
| fēnix® 8 47mm / 51mm / tactix® 8 47mm / 51mm / quatix® 8 47mm / 51mm | `EchoBike-fenix847mm.prg` |
| fēnix® 8 Pro 47mm / 51mm / MicroLED / quatix® 8 Pro 47mm / 51mm | `EchoBike-fenix8pro47mm.prg` |
| fēnix® 8 Solar 47mm | `EchoBike-fenix8solar47mm.prg` |
| fēnix® 8 Solar 51mm / tactix® 8 Solar 51mm | `EchoBike-fenix8solar51mm.prg` |
| fēnix® 9 43mm | `EchoBike-fenix943mm.prg` |
| fēnix® 9 47mm / 51mm | `EchoBike-fenix947mm.prg` |
| fēnix® 9 Pro 43mm | `EchoBike-fenix9pro43mm.prg` |
| fēnix® 9 Pro 47mm | `EchoBike-fenix9pro47mm.prg` |
| fēnix® 9 Pro 51mm | `EchoBike-fenix9pro51mm.prg` |
| fēnix® 9 Pro Solar 47mm | `EchoBike-fenix9prosolar47mm.prg` |
| fēnix® 9 Pro Solar 51mm | `EchoBike-fenix9prosolar51mm.prg` |
| fēnix® E | `EchoBike-fenixe.prg` |

Not supported: the original epix (2015) and fēnix 3/5 (non-Plus). Their apps cannot
use Bluetooth LE.

## Usage

| Button | Action |
|---|---|
| **START/STOP** | start · pause → menu *Resume / Save / Discard* |
| **BACK/LAP** | lap while recording · menu while paused · exit before start |
| **UP / DOWN**, swipe, tap | switch data page |

Pedal the bike so the console wakes up, then open the app. The status line shows
*Searching → Connecting → device name*. The console must **not** be connected to
Zwift or another app at the same time: it accepts only one Bluetooth connection.

## Build from source

Requirements: Linux or macOS, Java 17+, `curl`, `unzip`, `python3`, `openssl`.

```bash
scripts/setup-sdk.sh            # downloads the Connect IQ SDK + device definitions (no login)
scripts/build.sh                # all watches -> dist/EchoBike-<device>.prg + dist/EchoBike.iq
scripts/build.sh fenix7         # one watch
scripts/build.sh --test fenix7  # unit-test build
```

`setup-sdk.sh` creates the device definitions from the device list that ships inside
the SDK compiler (`scripts/GenerateDevices.java`). Device files you already
installed with Garmin's SDK Manager are kept. If you use the SDK Manager and VS Code
with the Monkey C extension, open the folder and run *Monkey C: Build for Device*.

By downloading the SDK you accept the
[Garmin Connect IQ SDK License Agreement](https://developer.garmin.com/connect-iq/sdk/).

## Project layout

| Path | Content |
|---|---|
| `source/FtmsBleManager.mc` | BLE scan, connect, notifications, reconnect – [docs/ftms.md](docs/ftms.md) |
| `source/BikeData.mc` | FTMS Indoor Bike Data parser (all fields) |
| `source/Recorder.mc` | activity session, FIT fields, averages, NP, laps – [docs/fit-fields.md](docs/fit-fields.md) |
| `source/MainView.mc`, `source/MainDelegate.mc` | screens, buttons, pause menu |
| `source/test/` | unit tests (`(:test)`) |
| `resources/`, `resources-deu/` | strings (EN/DE), icon |
| `scripts/` | SDK setup, build, device definition generator |

## Contributing

Bug reports from real hardware are especially valuable: which watch, which console,
what you see in Garmin Connect. See [CONTRIBUTING.md](CONTRIBUTING.md).

## History

This repository started as a fork of
[Douglas-Christian/rogue_garmin_bridge](https://github.com/Douglas-Christian/rogue_garmin_bridge),
a Python/Raspberry Pi bridge that turns Echo Bike data into FIT files. That code has no
license and was removed here. This project is a separate, MIT-licensed rewrite that runs
directly on the watch. The original bridge is still available upstream.

## License & trademarks

[MIT](LICENSE) © 2026 Liohtml.

Not affiliated with, endorsed or sponsored by Rogue Fitness or Garmin. *Rogue* and
*Echo Bike* are trademarks of Rogue Fitness; *Garmin*, *fēnix*, *epix* and *Connect IQ*
are trademarks of Garmin Ltd. or its subsidiaries.
