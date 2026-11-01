# Releasing and publishing

## GitHub release (sideload files)

1. Bump `version="x.y.z"` in `manifest.xml` and add a section to `CHANGELOG.md`.
2. Commit, then tag and push: `git tag v1.1.0 && git push origin v1.1.0`
3. The **Release** workflow builds every device and attaches the `.prg` files, a zip
   with all of them, and `EchoBike.iq` to a GitHub release.

On a fork, GitHub Actions has to be enabled once under **Actions → I understand my
workflows, go ahead and enable them**.

## Signing key

Every build is signed with a developer key (RSA 4096, DER/PKCS#8). The Connect IQ store
ties the app to the key used for the first upload, so **keep that key safe**.

```bash
openssl genrsa -out developer_key.pem 4096
openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key.der -nocrypt
base64 -w0 developer_key.der    # -> repository secret CIQ_DEVELOPER_KEY_B64
```

The release workflow uses the secret `CIQ_DEVELOPER_KEY_B64` when it is set. Without
it, a throw-away key is used: fine for sideloading, but not for store updates.

## Connect IQ store

1. Sign in at <https://apps.garmin.com/developer/> and accept the developer agreement.
2. **Upload an app** → `EchoBike.iq` from the release.
3. Fill in the listing (text below), add at least one screenshot per screen shape
   (simulator: *File → Save screenshot*) and submit. Garmin's review usually takes a
   few days.
4. Updates: upload the new `.iq` to the same app. It must be signed with the same key.

Store rules to keep in mind: the name must not suggest the app is made by Rogue or
Garmin. "Echo Bike" is used descriptively together with the disclaimer below.

### Listing text (English)

> **Echo Bike – FTMS recorder for the Rogue Echo Bike**
>
> Connects your watch directly to the Bluetooth console of the Rogue Echo Bike and
> records a native indoor cycling activity: power, cadence, speed and distance from the
> bike, plus heart rate from your watch. Averages, maxima, normalized power and laps
> show up in Garmin Connect and Strava like with any power meter.
>
> START = start/pause, BACK = lap, UP/DOWN = data pages. No phone or bridge needed.
> Works with any FTMS indoor bike. Open source: https://github.com/Liohtml/rogue_garmin_bridge
>
> Not affiliated with or endorsed by Rogue Fitness.

### Store-Text (Deutsch)

> **Echo Bike – FTMS-Recorder für das Rogue Echo Bike**
>
> Verbindet die Uhr direkt per Bluetooth mit der Konsole des Rogue Echo Bike und
> zeichnet eine native Indoor-Radfahren-Aktivität auf: Leistung, Trittfrequenz, Tempo
> und Distanz vom Bike, Puls von der Uhr. Durchschnitt, Maximum, Normalized Power und
> Runden erscheinen in Garmin Connect und Strava wie bei einem Powermeter.
>
> START = Start/Pause, BACK = Runde, UP/DOWN = Datenseiten. Kein Handy und keine Bridge
> nötig. Funktioniert mit jedem FTMS-Indoor-Bike. Open Source:
> https://github.com/Liohtml/rogue_garmin_bridge
>
> Keine Verbindung zu Rogue Fitness.
