# Bluetooth protocol (FTMS)

The Rogue Echo Bike console with Bluetooth implements the Bluetooth SIG
**Fitness Machine Service** (FTMS, service `0x1826`). This app is a BLE central and
only uses one characteristic:

| | UUID | Use |
|---|---|---|
| Fitness Machine Service | `00001826-0000-1000-8000-00805f9b34fb` | registered profile, scan filter |
| Indoor Bike Data | `00002ad2-0000-1000-8000-00805f9b34fb` | notifications (CCCD `0x2902` ← `01 00`) |

The app never writes to the Fitness Machine Control Point: the Echo Bike is an air
bike with no resistance to control.

## Connection flow (`source/FtmsBleManager.mc`)

1. `registerProfile()` with FTMS + Indoor Bike Data + CCCD.
2. Scan. The first device whose advertised name contains `echo` (and not `row`, to
   skip the Echo Rower) is paired right away. If none appears within 8 s, the first
   device that advertises the FTMS service UUID is used.
3. On connect: write `01 00` to the CCCD → notifications start (~1 Hz).
4. On disconnect, the watch reconnects to the paired device by itself. After 45 s
   without a reconnect, or 20 s stuck connecting, the app unpairs and scans again.
   If notifications stop for 10 s while connected, the CCCD is written again.

## Indoor Bike Data format (`source/BikeData.mc`)

Little-endian. A 16-bit flags field is followed by the fields whose flag is set, in
this order:

| Bit | Field | Type | Unit / resolution |
|---|---|---|---|
| 0 | **More Data** – instantaneous speed is present when this bit is **0** | uint16 | 0.01 km/h |
| 1 | Average speed | uint16 | 0.01 km/h |
| 2 | Instantaneous cadence | uint16 | 0.5 rpm |
| 3 | Average cadence | uint16 | 0.5 rpm |
| 4 | Total distance | uint24 | 1 m |
| 5 | Resistance level | sint16 | unitless |
| 6 | Instantaneous power | sint16 | 1 W |
| 7 | Average power | sint16 | 1 W |
| 8 | Expended energy: total / per hour / per minute | uint16 / uint16 / uint8 | kcal (`0xFFFF`/`0xFF` = n/a) |
| 9 | Heart rate | uint8 | bpm |
| 10 | Metabolic equivalent | uint8 | 0.1 MET |
| 11 | Elapsed time | uint16 | s |
| 12 | Remaining time | uint16 | s |

A notification may carry only part of a record (bit 0 set). Fields that are missing
from a packet keep their last value. A packet that is shorter than its flags announce
is ignored completely.

Which optional fields a console actually sends depends on its firmware. The app
records every field it receives. See `source/test/FtmsParserTest.mc` for example
packets.
