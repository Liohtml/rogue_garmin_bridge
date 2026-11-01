//
// Latest values reported by the Rogue Echo Bike via the Bluetooth FTMS
// "Indoor Bike Data" characteristic (0x2AD2).
//
// Every field stays null until the bike has reported it at least once, so
// the UI and the recorder can tell "not supported by the bike" apart from 0.
//

import Toybox.Lang;
import Toybox.System;

class BikeData {
    var speedKmh as Float?;          // instantaneous speed, km/h
    var avgSpeedKmh as Float?;       // console average speed, km/h
    var cadence as Float?;           // instantaneous cadence, rpm
    var avgCadence as Float?;        // console average cadence, rpm
    var totalDistanceM as Number?;   // console total distance, m
    var resistance as Number?;       // resistance level (unitless)
    var power as Number?;            // instantaneous power, W
    var avgPower as Number?;         // console average power, W
    var totalKcal as Number?;        // console total energy, kcal
    var kcalPerHour as Number?;      // console energy rate, kcal/h
    var kcalPerMin as Number?;       // console energy rate, kcal/min
    var heartRate as Number?;        // HR forwarded by the bike console, bpm
    var met as Float?;               // metabolic equivalent
    var elapsedS as Number?;         // console elapsed time, s
    var remainingS as Number?;       // console remaining time, s

    var lastFlags as Number = 0;     // flags of the last packet (diagnostics)
    var packets as Number = 0;       // number of packets received
    var lastPacketMs as Number?;     // System.getTimer() of the last packet

    function initialize() {
    }

    //! True when a packet arrived within the last 3 seconds.
    function isFresh() as Boolean {
        var t = lastPacketMs;
        return t != null && (System.getTimer() - t) < 3000;
    }

    //! Forget instantaneous values (used after a disconnect).
    function clearInstant() as Void {
        speedKmh = null;
        cadence = null;
        power = null;
        heartRate = null;
        kcalPerHour = null;
        kcalPerMin = null;
    }
}

//
// Parser for the FTMS Indoor Bike Data characteristic
// (Bluetooth SIG Fitness Machine Service 1.0, section 4.9).
//
module FtmsParser {

    function u16(v as ByteArray, o as Number) as Number {
        return v[o] | (v[o + 1] << 8);
    }

    function s16(v as ByteArray, o as Number) as Number {
        var x = v[o] | (v[o + 1] << 8);
        return x >= 0x8000 ? x - 0x10000 : x;
    }

    function u24(v as ByteArray, o as Number) as Number {
        return v[o] | (v[o + 1] << 8) | (v[o + 2] << 16);
    }

    //! Parse one notification into d. Fields not present in the packet keep
    //! their previous value (the FTMS "More Data" bit splits records across
    //! several notifications).
    function parseIndoorBikeData(v as ByteArray, d as BikeData) as Void {
        var n = v.size();
        if (n < 2) {
            return;
        }
        var flags = v[0] | (v[1] << 8);
        var o = 2;

        // Bit 0 "More Data": instantaneous speed is present when it is 0.
        if ((flags & 0x0001) == 0) {
            if (o + 2 > n) { return; }
            d.speedKmh = u16(v, o) / 100.0;
            o += 2;
        }
        if ((flags & 0x0002) != 0) {                    // average speed
            if (o + 2 > n) { return; }
            d.avgSpeedKmh = u16(v, o) / 100.0;
            o += 2;
        }
        if ((flags & 0x0004) != 0) {                    // instantaneous cadence
            if (o + 2 > n) { return; }
            d.cadence = u16(v, o) / 2.0;
            o += 2;
        }
        if ((flags & 0x0008) != 0) {                    // average cadence
            if (o + 2 > n) { return; }
            d.avgCadence = u16(v, o) / 2.0;
            o += 2;
        }
        if ((flags & 0x0010) != 0) {                    // total distance
            if (o + 3 > n) { return; }
            d.totalDistanceM = u24(v, o);
            o += 3;
        }
        if ((flags & 0x0020) != 0) {                    // resistance level
            if (o + 2 > n) { return; }
            d.resistance = s16(v, o);
            o += 2;
        }
        if ((flags & 0x0040) != 0) {                    // instantaneous power
            if (o + 2 > n) { return; }
            d.power = s16(v, o);
            o += 2;
        }
        if ((flags & 0x0080) != 0) {                    // average power
            if (o + 2 > n) { return; }
            d.avgPower = s16(v, o);
            o += 2;
        }
        if ((flags & 0x0100) != 0) {                    // expended energy
            if (o + 5 > n) { return; }
            var total = u16(v, o);
            var perHour = u16(v, o + 2);
            var perMin = v[o + 4];
            if (total != 0xFFFF) { d.totalKcal = total; }
            if (perHour != 0xFFFF) { d.kcalPerHour = perHour; }
            if (perMin != 0xFF) { d.kcalPerMin = perMin; }
            o += 5;
        }
        if ((flags & 0x0200) != 0) {                    // heart rate
            if (o + 1 > n) { return; }
            d.heartRate = v[o];
            o += 1;
        }
        if ((flags & 0x0400) != 0) {                    // metabolic equivalent
            if (o + 1 > n) { return; }
            d.met = v[o] / 10.0;
            o += 1;
        }
        if ((flags & 0x0800) != 0) {                    // elapsed time
            if (o + 2 > n) { return; }
            d.elapsedS = u16(v, o);
            o += 2;
        }
        if ((flags & 0x1000) != 0) {                    // remaining time
            if (o + 2 > n) { return; }
            d.remainingS = u16(v, o);
            o += 2;
        }

        d.lastFlags = flags;
        d.packets += 1;
        d.lastPacketMs = System.getTimer();
    }
}
