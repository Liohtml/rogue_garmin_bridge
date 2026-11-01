# Contributing

Thanks for helping! Issues and pull requests are welcome, in English or German.

## Reporting bugs

Please use the bug report template and include:

- watch model and firmware version (*Settings → System → About*)
- app version and how you installed it (store / sideload)
- what the status line on the watch showed
- the FIT file and, for data problems, what Garmin Connect / Strava shows

Crash logs: `GARMIN/APPS/LOGS/CIQ_LOG.YML` on the watch. Sideloaded apps also write
their `System.println` output when an empty file named after the `.prg` exists, e.g.
`GARMIN/APPS/EchoBike.prg` → create `GARMIN/APPS/LOGS/EchoBike.TXT`.

## Development setup

```bash
scripts/setup-sdk.sh             # SDK + device definitions, no Garmin login needed
scripts/build.sh fenix7          # quick build for one watch
scripts/build.sh                 # all watches + store package (what CI runs)
scripts/build.sh --test fenix7   # unit tests
```

To run the unit tests or try the app in the simulator, you need the simulator files for
the device. Install them with Garmin's
[SDK Manager](https://developer.garmin.com/connect-iq/sdk/) (free Garmin account), then:

```bash
$CIQ_SDK/bin/connectiq &                                   # start the simulator
$CIQ_SDK/bin/monkeydo bin/EchoBike-test-fenix7.prg fenix7 -t   # run unit tests
$CIQ_SDK/bin/monkeydo bin/fenix7/EchoBike.prg fenix7           # run the app
```

The simulator cannot talk to a real Bluetooth bike. Test BLE changes on a real watch:
build, copy the `.prg` to `GARMIN/APPS/` and ride.

## Guidelines

- Keep the code passing strict type checking (`-l 3`, used by `scripts/build.sh`).
- New parser logic → add a case to `source/test/FtmsParserTest.mc`.
- Watch memory is small: avoid large arrays, keep strings in `resources/`.
- New user-visible text goes into **both** `resources/strings/strings.xml` and
  `resources-deu/strings/strings.xml`.
- Adding a watch: add its id to `manifest.xml` **and** `products.txt`, and update the
  tables in both READMEs. The watch needs Connect IQ API 3.2+ with Bluetooth LE.
- Update `CHANGELOG.md` under *Unreleased*.

By contributing you agree that your contribution is licensed under the [MIT License](LICENSE).
