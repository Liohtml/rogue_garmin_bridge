# Echo Bike für Garmin

Eine **Connect-IQ-App** für Garmin **fēnix** und **epix**. Sie verbindet die Uhr per
Bluetooth LE direkt mit dem **Rogue Echo Bike** (Air Bike) und zeichnet eine **native
Aktivität „Indoor Radfahren"** mit Leistung, Trittfrequenz, Tempo und Distanz vom Bike
auf. Handy, Raspberry Pi oder eine andere Bridge braucht man dafür nicht.

🇬🇧 [English README](README.md)

## Funktionen

- Findet die Echo-Bike-Konsole automatisch (Bluetooth **FTMS**) und verbindet sich nach
  Abbrüchen von selbst neu.
- Datenseiten: Leistung, Trittfrequenz, Puls, Tempo, Distanz, Zeit · Ø/Max-Leistung,
  Normalized Power, Rundenleistung, Ø-Trittfrequenz, kcal, kcal/h, MET.
- Speichert eine normale Garmin-Aktivität. Leistung, Trittfrequenz, Tempo und Distanz
  landen in den **nativen FIT-Feldern**. Garmin Connect, Strava und andere zeigen sie
  deshalb wie Werte von einem Powermeter an.
- Alle weiteren Werte der Konsole (kcal, kcal/h, Puls der Konsole, MET, Widerstand)
  werden als Connect-IQ-Zusatzfelder gespeichert. Details: [docs/fit-fields.md](docs/fit-fields.md).
- Runden, Pause, Speichern und Verwerfen mit denselben Tasten wie bei Garmin-Aktivitäten.
- Deutsch und Englisch. Die Einheiten richten sich nach der Uhreinstellung.

## Installation

**Connect IQ Store:** noch nicht veröffentlicht, siehe [docs/publishing.md](docs/publishing.md).

**Sideload per USB:**

1. Die `.prg` für deine Uhr aus dem
   [neuesten Release](https://github.com/Liohtml/rogue_garmin_bridge/releases/latest)
   herunterladen (Tabelle unten).
2. Uhr per USB anschließen. Auf dem Mac geht das mit [OpenMTP](https://openmtp.ganeshrvel.com/).
3. Die Datei nach **`GARMIN/APPS/`** kopieren. Umbenennen ist erlaubt, z. B. in `EchoBike.prg`.
4. Uhr abstecken. **Echo Bike** erscheint dann in der Liste der Aktivitäten / Apps.

Sideload-Apps werden nicht automatisch aktualisiert.

## Unterstützte Uhren

| Modell | Datei |
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

Nicht unterstützt: die erste epix (2015) und fēnix 3/5 (ohne „Plus"). Auf diesen Uhren
können Apps kein Bluetooth LE nutzen.

## Bedienung

| Taste | Funktion |
|---|---|
| **START/STOP** | Start · Pause → Menü *Fortsetzen / Speichern / Verwerfen* |
| **BACK/LAP** | Runde während der Aufzeichnung · Menü in der Pause · App beenden vor dem Start |
| **UP / DOWN**, Wischen, Tippen | Datenseite wechseln |

Zuerst kurz in die Pedale treten, damit die Konsole aufwacht, dann die App öffnen. Die
Statuszeile zeigt *Suche → Verbinde → Gerätename*. Die Konsole darf **nicht**
gleichzeitig mit Zwift oder einer anderen App verbunden sein, weil sie nur eine
Bluetooth-Verbindung annimmt.

## Selbst bauen

Voraussetzungen: Linux oder macOS, Java 17+, `curl`, `unzip`, `python3`, `openssl`.

```bash
scripts/setup-sdk.sh            # Connect IQ SDK + Gerätedateien laden (ohne Login)
scripts/build.sh                # alle Uhren -> dist/EchoBike-<gerät>.prg + dist/EchoBike.iq
scripts/build.sh fenix7         # eine Uhr
scripts/build.sh --test fenix7  # Unit-Test-Build
```

Mit dem Download des SDK akzeptierst du das
[Garmin Connect IQ SDK License Agreement](https://developer.garmin.com/connect-iq/sdk/).

## Mitmachen

Fehlerberichte mit echter Hardware helfen am meisten: welche Uhr, welche Konsole und
was in Garmin Connect ankommt. Siehe [CONTRIBUTING.md](CONTRIBUTING.md).

## Lizenz & Marken

[MIT](LICENSE) © 2026 Liohtml. Das Projekt begann als Fork von
[Douglas-Christian/rogue_garmin_bridge](https://github.com/Douglas-Christian/rogue_garmin_bridge),
einer Python-Bridge ohne Lizenz. Deren Code wurde entfernt, die App hier ist eine
eigenständige Neuentwicklung.

Keine Verbindung zu Rogue Fitness oder Garmin. *Rogue* und *Echo Bike* sind Marken von
Rogue Fitness; *Garmin*, *fēnix*, *epix* und *Connect IQ* sind Marken von Garmin Ltd.
oder ihren Tochtergesellschaften.
