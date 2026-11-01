# What ends up in the FIT file

The app records a regular activity: `sport = cycling`, `sub_sport = indoor_cycling`,
named "Echo Bike". The watch firmware records heart rate (wrist or paired strap),
calories, timer, laps, Training Effect etc. itself, as in any other activity.

Bike data is added through Connect IQ `FitContributor` fields. Fields with a
**native number** tell Garmin Connect to treat them as the standard FIT field, so
they show up as normal power / cadence / speed charts. Native values use the FIT
profile scaling.

## Record messages (1 Hz)

| Field | Native # | Type | Value |
|---|---|---|---|
| power | 7 (`record.power`) | uint16 | W |
| cadence | 4 (`record.cadence`) | uint8 | rpm |
| speed | 6 (`record.speed`) | uint16 | m/s × 1000 |
| distance | 5 (`record.distance`) | uint32 | m × 100 (session distance) |
| echo_calories | – | uint16 | kcal from the console, since start |
| echo_kcal_per_hour | – | uint16 | kcal/h |
| echo_heart_rate | – | uint8 | bpm, only if the console sends HR |
| echo_met | – | float | MET, only if sent |
| echo_resistance | – | sint16 | only if sent |

When the console stops sending (more than 3 s without data) power, cadence and
speed are recorded as 0.

## Lap messages

| Field | Native # |
|---|---|
| lap_avg_power / lap_max_power | 19 / 20 |
| lap_avg_cadence / lap_max_cadence | 17 / 18 |
| lap_distance | 9 |
| lap_avg_speed / lap_max_speed | 13 / 14 |
| lap_normalized_power | 33 |
| lap_echo_calories | – |

## Session message

| Field | Native # |
|---|---|
| avg_power / max_power | 20 / 21 |
| avg_cadence / max_cadence | 18 / 19 |
| total_distance | 9 |
| avg_speed / max_speed | 14 / 15 |
| normalized_power | 34 |
| total_work | 48 (J) |
| echo_total_calories | – |

## How values are calculated (`source/Recorder.mc`)

- **Distance** comes from the console odometer as per-second deltas, counted only
  while the timer runs. A console reset or an implausible jump (> 25 m/s) is handled.
  If the console sends no distance, speed is integrated.
- **Calories** (Echo) work the same way from the console counter. If the console only
  sends kcal/h, that rate is integrated.
- **Average power** includes zeros. **Average cadence** excludes zeros (as Garmin does).
- **Normalized power**: 30 s rolling average, then the fourth root of the mean of its
  fourth powers.

## Known limitation

For an indoor activity without a speed sensor the watch may write its own (zero)
distance and speed. Whether Garmin Connect then shows the native-numbered developer value or the
watch's own value for **distance/speed** has not been verified on every firmware. Power
and cadence work the same way as in other Connect IQ power apps. Reports welcome.
