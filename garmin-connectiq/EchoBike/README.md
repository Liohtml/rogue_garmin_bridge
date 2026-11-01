# Echo Bike – Connect IQ App für Garmin fēnix & epix

Watch-App, die sich per **Bluetooth LE (FTMS)** direkt mit dem **Rogue Echo Bike**
verbindet, alle Werte live anzeigt und sie in eine **native Garmin-Aktivität
„Indoor Radfahren"** schreibt. Ein Raspberry Pi oder Handy wird dafür nicht gebraucht.

## Was aufgezeichnet wird

| Wert vom Echo Bike (FTMS 0x2AD2) | Im FIT-File | Anzeige in Garmin Connect |
|---|---|---|
| Leistung (W) | `record.power` (nativeNum 7) | Leistungskurve, Ø / Max, NP, Arbeit (kJ) |
| Trittfrequenz (U/min) | `record.cadence` (nativeNum 4) | Trittfrequenzkurve, Ø / Max |
| Geschwindigkeit | `record.speed` (nativeNum 6) | Tempokurve, Ø / Max |
| Distanz (Konsole) | `record.distance` / `session.total_distance` (nativeNum 5 / 9) | Distanz |
| Ø/Max Leistung, Ø/Max Kadenz, Ø/Max Tempo, NP, Arbeit | Lap- und Session-Felder (nativeNum) | Zusammenfassung und Runden |
| Kalorien der Konsole, kcal/h | Developer-Felder `echo_calories`, `echo_kcal_per_hour` | Connect-IQ-Diagramm |
| Puls der Konsole (falls vorhanden) | Developer-Feld `echo_heart_rate` | Connect-IQ-Diagramm |
| MET, Widerstand (falls die Konsole sie sendet) | Developer-Felder `echo_met`, `echo_resistance` | Connect-IQ-Diagramm |

Puls (Handgelenk oder gekoppelter Brustgurt), Kalorien, Training Effect usw. zeichnet die
Uhr wie bei jeder anderen Aktivität selbst nativ auf.

## Installation (Sideload per USB)

1. Datei für dein Modell aus `release/` auswählen (Tabelle unten).
2. Uhr per USB-Kabel an den Rechner anschließen. Auf dem Mac braucht man dafür
   [OpenMTP](https://openmtp.ganeshrvel.com/).
3. Die Datei in den Ordner **`GARMIN/APPS/`** auf der Uhr kopieren.
   Den Dateinamen kannst du beliebig ändern, z. B. in `EchoBike.prg`.
4. Uhr abstecken. Danach erscheint **„Echo Bike"** in der Liste der Aktivitäten / Apps.

> Sideload-Apps laufen ohne Store. Sie werden nicht automatisch aktualisiert und
> erscheinen nicht in der Connect IQ App auf dem Handy.

| Modell | Datei |
|---|---|
| epix™ (Gen 2) / quatix® 7 Sapphire | `release/EchoBike-epix2.prg` |
| epix™ Pro (Gen 2) 42mm | `release/EchoBike-epix2pro42mm.prg` |
| epix™ Pro (Gen 2) 47mm / quatix® 7 Pro | `release/EchoBike-epix2pro47mm.prg` |
| epix™ Pro (Gen 2) 51mm / D2™ Mach 1 Pro / tactix® 7 – AMOLED Edition | `release/EchoBike-epix2pro51mm.prg` |
| fēnix® 5 Plus | `release/EchoBike-fenix5plus.prg` |
| fēnix® 5S Plus | `release/EchoBike-fenix5splus.prg` |
| fēnix® 5X Plus | `release/EchoBike-fenix5xplus.prg` |
| fēnix® 6 / 6 Solar / 6 Dual Power | `release/EchoBike-fenix6.prg` |
| fēnix® 6 Pro / 6 Sapphire / 6 Pro Solar / 6 Pro Dual Power / quatix® 6 | `release/EchoBike-fenix6pro.prg` |
| fēnix® 6S / 6S Solar / 6S Dual Power | `release/EchoBike-fenix6s.prg` |
| fēnix® 6S Pro / 6S Sapphire / 6S Pro Solar / 6S Pro Dual Power | `release/EchoBike-fenix6spro.prg` |
| fēnix® 6X Pro / 6X Sapphire / 6X Pro Solar / tactix® Delta Sapphire / Delta Solar / Delta Solar - Ballistics Edition / quatix® 6X / 6X Solar / 6X Dual Power | `release/EchoBike-fenix6xpro.prg` |
| fēnix® 7 / quatix® 7 | `release/EchoBike-fenix7.prg` |
| fēnix® 7 Pro | `release/EchoBike-fenix7pro.prg` |
| fēnix® 7 Pro - Solar Edition (no Wi-Fi) | `release/EchoBike-fenix7pronowifi.prg` |
| fēnix® 7S | `release/EchoBike-fenix7s.prg` |
| fēnix® 7S Pro | `release/EchoBike-fenix7spro.prg` |
| fēnix® 7X / tactix® 7 / quatix® 7X Solar / Enduro™ 2 | `release/EchoBike-fenix7x.prg` |
| fēnix® 7X Pro | `release/EchoBike-fenix7xpro.prg` |
| fēnix® 7X Pro - Solar Edition (no Wi-Fi) | `release/EchoBike-fenix7xpronowifi.prg` |
| fēnix® 8 43mm | `release/EchoBike-fenix843mm.prg` |
| fēnix® 8 47mm / 51mm / tactix® 8 47mm / 51mm / quatix® 8 47mm / 51mm | `release/EchoBike-fenix847mm.prg` |
| fēnix® 8 Pro 47mm / 51mm / MicroLED / quatix® 8 Pro 47mm / 51mm | `release/EchoBike-fenix8pro47mm.prg` |
| fēnix® 8 Solar 47mm | `release/EchoBike-fenix8solar47mm.prg` |
| fēnix® 8 Solar 51mm / tactix® 8 Solar 51mm | `release/EchoBike-fenix8solar51mm.prg` |
| fēnix® 9 43mm | `release/EchoBike-fenix943mm.prg` |
| fēnix® 9 47mm / 51mm | `release/EchoBike-fenix947mm.prg` |
| fēnix® 9 Pro 43mm | `release/EchoBike-fenix9pro43mm.prg` |
| fēnix® 9 Pro 47mm | `release/EchoBike-fenix9pro47mm.prg` |
| fēnix® 9 Pro 51mm | `release/EchoBike-fenix9pro51mm.prg` |
| fēnix® 9 Pro Solar 47mm | `release/EchoBike-fenix9prosolar47mm.prg` |
| fēnix® 9 Pro Solar 51mm | `release/EchoBike-fenix9prosolar51mm.prg` |
| fēnix® E | `release/EchoBike-fenixe.prg` |

Die erste epix (2015) wird nicht unterstützt: Sie hat keine Bluetooth-LE-API für Apps.

## Bedienung

| Taste | Funktion |
|---|---|
| **START/STOP** | Aufzeichnung starten / pausieren (Pause-Menü: Fortsetzen · Speichern · Verwerfen) |
| **BACK/LAP** | während der Aufzeichnung: Runde · in der Pause: Menü · vor dem Start: App beenden |
| **UP / DOWN**, Wischen, Tippen | Seite wechseln (Seite 1: Live-Werte · Seite 2: Ø/Max/NP/Runde/kcal) |

Nach dem Start sucht die App automatisch nach einem Gerät mit „Echo" im Namen.
Findet sie innerhalb von 8 s keins, verbindet sie sich mit dem ersten FTMS-Gerät, das sie
sieht. Damit das Bike gefunden wird, muss die Konsole an sein (in die Pedale treten) und
darf **nicht** gleichzeitig mit Zwift oder einer anderen App verbunden sein. Reißt die
Verbindung ab, verbindet sich die App von selbst neu. In dieser Zeit wird 0 W aufgezeichnet.

## Garmin Connect IQ Store

`release/EchoBike.iq` ist das fertige Store-Paket für alle oben genannten Modelle.

1. Unter <https://apps.garmin.com/developer/> mit dem Garmin-Konto anmelden und
   die Developer Agreement akzeptieren.
2. **Upload an App** → `EchoBike.iq` hochladen. Danach Beschreibung, Screenshots und
   Kategorie „Fitness" ausfüllen und zur Prüfung einreichen. Die Freigabe durch Garmin
   dauert meist ein paar Tage.
3. **Wichtig:** Jedes spätere Update muss mit **demselben Developer-Key** signiert sein.
   Am besten baust du das Store-Paket deshalb mit deinem eigenen Key neu:
   `CIQ_KEY=/pfad/zu/deinem/developer_key.der ./build.sh`

## Selbst bauen

Voraussetzungen: Java 17+ und das [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/).
Die Gerätedateien installierst du über den SDK-Manager.

```bash
./build.sh                # alle Modelle + bin/EchoBike.iq
./build.sh fenix7 epix2   # nur einzelne Modelle
```

Ohne SDK-Manager-Login lassen sich die Gerätedefinitionen auch aus dem Compiler
erzeugen, siehe `../tools/GenerateDevices.java`:

```bash
unzip -p $CIQ_SDK/bin/monkeybrains.jar com/garmin/monkeybrains/devices/devices.xml > devices.xml
javac -cp $CIQ_SDK/bin/monkeybrains.jar ../tools/GenerateDevices.java -d /tmp/gen
java -cp $CIQ_SDK/bin/monkeybrains.jar:/tmp/gen GenerateDevices devices.xml ~/.Garmin/ConnectIQ/Devices '(fenix|epix).*'
```

## Quellcode

| Datei | Inhalt |
|---|---|
| `source/FtmsBleManager.mc` | BLE-Scan, Verbindung, CCCD-Abo, Reconnect |
| `source/BikeData.mc` | FTMS-Parser für Indoor Bike Data (alle 13 Felder) |
| `source/Recorder.mc` | ActivityRecording-Session, FIT-Felder, Ø/Max/NP/Runden |
| `source/MainView.mc` | Anzeige (rund, 218–466 px, MIP und AMOLED) |
| `source/MainDelegate.mc` | Tasten und Pause-Menü |
