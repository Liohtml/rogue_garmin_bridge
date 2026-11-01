// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Liohtml
//
// Unit tests for the FTMS Indoor Bike Data parser.
// Build: scripts/build.sh --test fenix7   Run: monkeydo bin/EchoBike-test-fenix7.prg fenix7 -t

import Toybox.Lang;
import Toybox.Test;

//! Assert that a nullable parser value is set and equals the expected value.
//! (:debug) keeps the helper out of release builds.
(:debug)
function expect(actual as Object?, expected as Object, what as String) as Void {
    Test.assertMessage(actual != null, what + " is null");
    Test.assertEqualMessage(actual as Object, expected, what);
}

(:test)
function testSpeedCadencePower(logger as Test.Logger) as Boolean {
    // flags 0x0044: speed (bit0 clear), cadence, power
    var d = new BikeData();
    FtmsParser.parseIndoorBikeData([0x44, 0x00, 0x54, 0x0B, 0xA0, 0x00, 0xFA, 0x00]b, d);
    expect(d.speedKmh, 29.0, "speed");
    expect(d.cadence, 80.0, "cadence");
    expect(d.power, 250, "power");
    expect(d.packets, 1, "packets");
    Test.assert(d.totalDistanceM == null);
    return true;
}

(:test)
function testAllFields(logger as Test.Logger) as Boolean {
    // flags 0x1FFE: every optional field, instantaneous speed present
    var d = new BikeData();
    FtmsParser.parseIndoorBikeData([
        0xFE, 0x1F,
        0xD0, 0x07,             // speed       20.00 km/h
        0xB0, 0x04,             // avg speed   12.00 km/h
        0x78, 0x00,             // cadence     60 rpm
        0x64, 0x00,             // avg cadence 50 rpm
        0x10, 0x27, 0x00,       // distance    10000 m
        0xFB, 0xFF,             // resistance  -5
        0x2C, 0x01,             // power       300 W
        0xC8, 0x00,             // avg power   200 W
        0x7B, 0x00,             // total kcal  123
        0x84, 0x03,             // kcal/h      900
        0x0F,                   // kcal/min    15
        0x96,                   // heart rate  150
        0x55,                   // MET         8.5
        0x2C, 0x01,             // elapsed     300 s
        0x3C, 0x00              // remaining   60 s
    ]b, d);
    expect(d.speedKmh, 20.0, "speed");
    expect(d.avgSpeedKmh, 12.0, "avg speed");
    expect(d.cadence, 60.0, "cadence");
    expect(d.avgCadence, 50.0, "avg cadence");
    expect(d.totalDistanceM, 10000, "distance");
    expect(d.resistance, -5, "resistance");
    expect(d.power, 300, "power");
    expect(d.avgPower, 200, "avg power");
    expect(d.totalKcal, 123, "kcal");
    expect(d.kcalPerHour, 900, "kcal/h");
    expect(d.kcalPerMin, 15, "kcal/min");
    expect(d.heartRate, 150, "hr");
    expect(d.met, 8.5, "met");
    expect(d.elapsedS, 300, "elapsed");
    expect(d.remainingS, 60, "remaining");
    return true;
}

(:test)
function testMoreDataKeepsPreviousValues(logger as Test.Logger) as Boolean {
    var d = new BikeData();
    FtmsParser.parseIndoorBikeData([0x44, 0x00, 0x54, 0x0B, 0xA0, 0x00, 0xFA, 0x00]b, d);
    // flags 0x0041: "more data" (no speed) + power only, power = 0
    FtmsParser.parseIndoorBikeData([0x41, 0x00, 0x00, 0x00]b, d);
    expect(d.speedKmh, 29.0, "speed kept");
    expect(d.cadence, 80.0, "cadence kept");
    expect(d.power, 0, "power updated");
    expect(d.packets, 2, "packets");
    return true;
}

(:test)
function testEnergyNotAvailable(logger as Test.Logger) as Boolean {
    // flags 0x0101: more data + expended energy, all "not available"
    var d = new BikeData();
    FtmsParser.parseIndoorBikeData([0x01, 0x01, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]b, d);
    Test.assert(d.totalKcal == null);
    Test.assert(d.kcalPerHour == null);
    Test.assert(d.kcalPerMin == null);
    return true;
}

(:test)
function testTruncatedPacketIgnored(logger as Test.Logger) as Boolean {
    var d = new BikeData();
    // power flag set but only one byte of payload
    FtmsParser.parseIndoorBikeData([0x41, 0x00, 0x2C]b, d);
    FtmsParser.parseIndoorBikeData([0x44]b, d);
    Test.assert(d.power == null);
    expect(d.packets, 0, "no packet counted");
    Test.assert(!d.isFresh());
    return true;
}
