//
// Records a native Garmin "Indoor Cycling" activity and writes the Echo Bike
// metrics into the FIT file.
//
// Power, cadence, speed and distance are written with :nativeNum so Garmin
// Connect / Strava treat them as the regular FIT fields (record power,
// cadence, speed, distance; lap/session averages, maxima, distance, work,
// normalized power). Bike-only values (console calories, kcal/h, console
// heart rate, MET, resistance) are written as Connect IQ developer fields.
// Heart rate and calories from the watch itself are recorded natively by the
// firmware as in every other activity.
//

import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Attention;
import Toybox.FitContributor;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

enum RecState {
    REC_IDLE,
    REC_RECORDING,
    REC_PAUSED
}

class Recorder {

    // FIT profile field numbers (FIT SDK Profile.xlsx).
    private const REC_CADENCE = 4;     // record.cadence        rpm
    private const REC_DISTANCE = 5;    // record.distance       m * 100
    private const REC_SPEED = 6;       // record.speed          m/s * 1000
    private const REC_POWER = 7;       // record.power          W
    private const LAP_DISTANCE = 9;    // lap.total_distance    m * 100
    private const LAP_AVG_SPEED = 13;  // lap.avg_speed         m/s * 1000
    private const LAP_MAX_SPEED = 14;  // lap.max_speed         m/s * 1000
    private const LAP_AVG_CAD = 17;    // lap.avg_cadence       rpm
    private const LAP_MAX_CAD = 18;    // lap.max_cadence       rpm
    private const LAP_AVG_POWER = 19;  // lap.avg_power         W
    private const LAP_MAX_POWER = 20;  // lap.max_power         W
    private const LAP_NP = 33;         // lap.normalized_power  W
    private const SES_DISTANCE = 9;    // session.total_distance
    private const SES_AVG_SPEED = 14;  // session.avg_speed
    private const SES_MAX_SPEED = 15;  // session.max_speed
    private const SES_AVG_CAD = 18;    // session.avg_cadence
    private const SES_MAX_CAD = 19;    // session.max_cadence
    private const SES_AVG_POWER = 20;  // session.avg_power
    private const SES_MAX_POWER = 21;  // session.max_power
    private const SES_NP = 34;         // session.normalized_power
    private const SES_WORK = 48;       // session.total_work    J

    var state as RecState = REC_IDLE;

    // Live values (also used by the UI).
    var power as Number = 0;
    var cadence as Number = 0;
    var speedMps as Float = 0.0;

    // Session totals.
    var distanceM as Float = 0.0;
    var kcal as Float = 0.0;
    var seconds as Number = 0;
    var avgPower as Number = 0;
    var maxPower as Number = 0;
    var avgCadence as Number = 0;
    var maxCadence as Number = 0;
    var maxSpeedMps as Float = 0.0;
    var workJ as Float = 0.0;
    var np as Number = 0;
    var laps as Number = 1;

    // Current lap.
    var lapDistanceM as Float = 0.0;
    var lapKcal as Float = 0.0;
    var lapSeconds as Number = 0;
    var lapAvgPower as Number = 0;

    private var _session as ActivityRecording.Session?;
    private var _powerSum as Number = 0;
    private var _cadSum as Number = 0;
    private var _cadCount as Number = 0;
    private var _lapPowerSum as Number = 0;
    private var _lapMaxPower as Number = 0;
    private var _lapCadSum as Number = 0;
    private var _lapCadCount as Number = 0;
    private var _lapMaxCad as Number = 0;
    private var _lapMaxSpeed as Float = 0.0;

    // Normalized power: 30 s rolling average, 4th power mean.
    private var _npBuf as Array<Number> = new Array<Number>[30];
    private var _npIdx as Number = 0;
    private var _npFill as Number = 0;
    private var _npRolling as Number = 0;
    private var _np4Sum as Float = 0.0;
    private var _np4Count as Number = 0;
    private var _lapNp4Sum as Float = 0.0;
    private var _lapNp4Count as Number = 0;

    // Console counters (to turn totals into per-second deltas).
    private var _lastConsoleDist as Number?;
    private var _lastConsoleDistMs as Number = 0;
    private var _hasConsoleDist as Boolean = false;
    private var _lastConsoleKcal as Number?;
    private var _lastConsoleKcalMs as Number = 0;
    private var _hasConsoleKcal as Boolean = false;

    // FIT fields.
    private var _fPower as FitContributor.Field?;
    private var _fCadence as FitContributor.Field?;
    private var _fSpeed as FitContributor.Field?;
    private var _fDistance as FitContributor.Field?;
    private var _fKcal as FitContributor.Field?;
    private var _fKcalH as FitContributor.Field?;
    private var _fBikeHr as FitContributor.Field?;
    private var _fMet as FitContributor.Field?;
    private var _fResistance as FitContributor.Field?;
    private var _fLapAvgPower as FitContributor.Field?;
    private var _fLapMaxPower as FitContributor.Field?;
    private var _fLapAvgCad as FitContributor.Field?;
    private var _fLapMaxCad as FitContributor.Field?;
    private var _fLapDistance as FitContributor.Field?;
    private var _fLapAvgSpeed as FitContributor.Field?;
    private var _fLapMaxSpeed as FitContributor.Field?;
    private var _fLapNp as FitContributor.Field?;
    private var _fLapKcal as FitContributor.Field?;
    private var _fSesAvgPower as FitContributor.Field?;
    private var _fSesMaxPower as FitContributor.Field?;
    private var _fSesAvgCad as FitContributor.Field?;
    private var _fSesMaxCad as FitContributor.Field?;
    private var _fSesDistance as FitContributor.Field?;
    private var _fSesAvgSpeed as FitContributor.Field?;
    private var _fSesMaxSpeed as FitContributor.Field?;
    private var _fSesNp as FitContributor.Field?;
    private var _fSesWork as FitContributor.Field?;
    private var _fSesKcal as FitContributor.Field?;

    function initialize() {
        resetStats();
    }

    function hasSession() as Boolean {
        return _session != null;
    }

    // ------------------------------------------------------------ control

    function start() as Void {
        if (_session == null) {
            resetStats();
            var s = ActivityRecording.createSession({
                :name => "Echo Bike",
                :sport => Activity.SPORT_CYCLING,
                :subSport => Activity.SUB_SPORT_INDOOR_CYCLING
            });
            _session = s;
            createFields(s);
        }
        var session = _session as ActivityRecording.Session;
        session.start();
        state = REC_RECORDING;
        signal(Attention has :TONE_START ? Attention.TONE_START : null);
    }

    function pause() as Void {
        var s = _session;
        if (s != null && s.isRecording()) {
            s.stop();
        }
        state = REC_PAUSED;
        signal(Attention has :TONE_STOP ? Attention.TONE_STOP : null);
    }

    function resume() as Void {
        start();
    }

    function lap() as Void {
        var s = _session;
        if (s == null || state != REC_RECORDING) {
            return;
        }
        writeLapFields();
        s.addLap();
        laps += 1;
        resetLap();
        signal(Attention has :TONE_LAP ? Attention.TONE_LAP : null);
    }

    function save() as Boolean {
        var s = _session;
        if (s == null) {
            return false;
        }
        writeLapFields();
        writeSessionFields();
        if (s.isRecording()) {
            s.stop();
        }
        var ok = s.save();
        _session = null;
        state = REC_IDLE;
        clearFields();
        signal(Attention has :TONE_SUCCESS ? Attention.TONE_SUCCESS : null);
        return ok;
    }

    function discard() as Void {
        var s = _session;
        if (s != null) {
            if (s.isRecording()) {
                s.stop();
            }
            s.discard();
        }
        _session = null;
        state = REC_IDLE;
        clearFields();
    }

    // --------------------------------------------------------------- tick

    //! Called once per second with the latest bike values.
    function tick(bike as BikeData) as Void {
        var now = System.getTimer();
        var fresh = bike.isFresh();

        var p = bike.power;
        var c = bike.cadence;
        var sp = bike.speedKmh;
        power = (fresh && p != null && p > 0) ? p : 0;
        cadence = (fresh && c != null && c > 0) ? c.toNumber() : 0;
        speedMps = (fresh && sp != null && sp > 0) ? (sp / 3.6).toFloat() : 0.0;

        // Distance: use the console odometer when available, otherwise
        // integrate speed.
        var dDist = 0.0;
        var cd = bike.totalDistanceM;
        if (cd != null) {
            _hasConsoleDist = true;
            if (fresh) {
                var last = _lastConsoleDist;
                if (last != null) {
                    var gapS = (now - _lastConsoleDistMs) / 1000.0 + 1.0;
                    var d = cd - last;
                    if (d < 0) {
                        d = cd;                 // console was reset
                    }
                    if (d <= 25.0 * gapS) {     // ignore implausible jumps
                        dDist = d.toFloat();
                    }
                }
                _lastConsoleDist = cd;
                _lastConsoleDistMs = now;
            }
        } else if (!_hasConsoleDist) {
            dDist = speedMps;
        }

        // Calories from the console (kcal counter).
        var dKcal = 0.0;
        var ck = bike.totalKcal;
        if (ck != null) {
            _hasConsoleKcal = true;
            if (fresh) {
                var lastK = _lastConsoleKcal;
                if (lastK != null) {
                    var gapK = (now - _lastConsoleKcalMs) / 1000.0 + 1.0;
                    var k = ck - lastK;
                    if (k < 0) {
                        k = ck;
                    }
                    if (k <= 5.0 * gapK) {
                        dKcal = k.toFloat();
                    }
                }
                _lastConsoleKcal = ck;
                _lastConsoleKcalMs = now;
            }
        } else if (!_hasConsoleKcal) {
            var kh = bike.kcalPerHour;
            if (fresh && kh != null) {
                dKcal = kh / 3600.0;
            }
        }

        var s = _session;
        if (state == REC_RECORDING && s != null && s.isRecording()) {
            seconds += 1;
            lapSeconds += 1;
            distanceM += dDist;
            lapDistanceM += dDist;
            kcal += dKcal;
            lapKcal += dKcal;
            workJ += power;

            _powerSum += power;
            _lapPowerSum += power;
            if (power > maxPower) { maxPower = power; }
            if (power > _lapMaxPower) { _lapMaxPower = power; }
            avgPower = _powerSum / seconds;
            lapAvgPower = _lapPowerSum / lapSeconds;

            if (cadence > 0) {
                _cadSum += cadence;
                _cadCount += 1;
                _lapCadSum += cadence;
                _lapCadCount += 1;
                if (cadence > maxCadence) { maxCadence = cadence; }
                if (cadence > _lapMaxCad) { _lapMaxCad = cadence; }
                avgCadence = _cadSum / _cadCount;
            }
            if (speedMps > maxSpeedMps) { maxSpeedMps = speedMps; }
            if (speedMps > _lapMaxSpeed) { _lapMaxSpeed = speedMps; }

            updateNp(power);
        }

        writeRecordFields(bike, fresh);
        if (s != null) {
            writeLapFields();
            writeSessionFields();
        }
    }

    // ---------------------------------------------------------- FIT fields

    private function createFields(s as ActivityRecording.Session) as Void {
        var R = FitContributor.MESG_TYPE_RECORD;
        var L = FitContributor.MESG_TYPE_LAP;
        var S = FitContributor.MESG_TYPE_SESSION;
        var U8 = FitContributor.DATA_TYPE_UINT8;
        var U16 = FitContributor.DATA_TYPE_UINT16;
        var S16 = FitContributor.DATA_TYPE_SINT16;
        var U32 = FitContributor.DATA_TYPE_UINT32;
        var F = FitContributor.DATA_TYPE_FLOAT;

        // Record (1 Hz) - native equivalents.
        _fPower = s.createField("power", 0, U16, { :mesgType => R, :units => "W", :nativeNum => REC_POWER });
        _fCadence = s.createField("cadence", 1, U8, { :mesgType => R, :units => "rpm", :nativeNum => REC_CADENCE });
        _fSpeed = s.createField("speed", 2, U16, { :mesgType => R, :units => "m/s", :nativeNum => REC_SPEED });
        _fDistance = s.createField("distance", 3, U32, { :mesgType => R, :units => "m", :nativeNum => REC_DISTANCE });
        // Record - Echo-only values.
        _fKcal = s.createField("echo_calories", 4, U16, { :mesgType => R, :units => "kcal" });
        _fKcalH = s.createField("echo_kcal_per_hour", 5, U16, { :mesgType => R, :units => "kcal/h" });
        _fBikeHr = s.createField("echo_heart_rate", 6, U8, { :mesgType => R, :units => "bpm" });
        _fMet = s.createField("echo_met", 7, F, { :mesgType => R, :units => "MET" });
        _fResistance = s.createField("echo_resistance", 8, S16, { :mesgType => R, :units => "" });

        // Lap.
        _fLapAvgPower = s.createField("lap_avg_power", 20, U16, { :mesgType => L, :units => "W", :nativeNum => LAP_AVG_POWER });
        _fLapMaxPower = s.createField("lap_max_power", 21, U16, { :mesgType => L, :units => "W", :nativeNum => LAP_MAX_POWER });
        _fLapAvgCad = s.createField("lap_avg_cadence", 22, U8, { :mesgType => L, :units => "rpm", :nativeNum => LAP_AVG_CAD });
        _fLapMaxCad = s.createField("lap_max_cadence", 23, U8, { :mesgType => L, :units => "rpm", :nativeNum => LAP_MAX_CAD });
        _fLapDistance = s.createField("lap_distance", 24, U32, { :mesgType => L, :units => "m", :nativeNum => LAP_DISTANCE });
        _fLapAvgSpeed = s.createField("lap_avg_speed", 25, U16, { :mesgType => L, :units => "m/s", :nativeNum => LAP_AVG_SPEED });
        _fLapMaxSpeed = s.createField("lap_max_speed", 26, U16, { :mesgType => L, :units => "m/s", :nativeNum => LAP_MAX_SPEED });
        _fLapNp = s.createField("lap_normalized_power", 27, U16, { :mesgType => L, :units => "W", :nativeNum => LAP_NP });
        _fLapKcal = s.createField("lap_echo_calories", 28, U16, { :mesgType => L, :units => "kcal" });

        // Session.
        _fSesAvgPower = s.createField("avg_power", 40, U16, { :mesgType => S, :units => "W", :nativeNum => SES_AVG_POWER });
        _fSesMaxPower = s.createField("max_power", 41, U16, { :mesgType => S, :units => "W", :nativeNum => SES_MAX_POWER });
        _fSesAvgCad = s.createField("avg_cadence", 42, U8, { :mesgType => S, :units => "rpm", :nativeNum => SES_AVG_CAD });
        _fSesMaxCad = s.createField("max_cadence", 43, U8, { :mesgType => S, :units => "rpm", :nativeNum => SES_MAX_CAD });
        _fSesDistance = s.createField("total_distance", 44, U32, { :mesgType => S, :units => "m", :nativeNum => SES_DISTANCE });
        _fSesAvgSpeed = s.createField("avg_speed", 45, U16, { :mesgType => S, :units => "m/s", :nativeNum => SES_AVG_SPEED });
        _fSesMaxSpeed = s.createField("max_speed", 46, U16, { :mesgType => S, :units => "m/s", :nativeNum => SES_MAX_SPEED });
        _fSesNp = s.createField("normalized_power", 47, U16, { :mesgType => S, :units => "W", :nativeNum => SES_NP });
        _fSesWork = s.createField("total_work", 48, U32, { :mesgType => S, :units => "J", :nativeNum => SES_WORK });
        _fSesKcal = s.createField("echo_total_calories", 49, U16, { :mesgType => S, :units => "kcal" });
    }

    private function clearFields() as Void {
        _fPower = null; _fCadence = null; _fSpeed = null; _fDistance = null;
        _fKcal = null; _fKcalH = null; _fBikeHr = null; _fMet = null; _fResistance = null;
        _fLapAvgPower = null; _fLapMaxPower = null; _fLapAvgCad = null; _fLapMaxCad = null;
        _fLapDistance = null; _fLapAvgSpeed = null; _fLapMaxSpeed = null; _fLapNp = null; _fLapKcal = null;
        _fSesAvgPower = null; _fSesMaxPower = null; _fSesAvgCad = null; _fSesMaxCad = null;
        _fSesDistance = null; _fSesAvgSpeed = null; _fSesMaxSpeed = null; _fSesNp = null;
        _fSesWork = null; _fSesKcal = null;
    }

    private function set(f as FitContributor.Field?, v as Numeric) as Void {
        if (f != null) {
            f.setData(v);
        }
    }

    private function writeRecordFields(bike as BikeData, fresh as Boolean) as Void {
        set(_fPower, clamp(power, 0, 65534));
        set(_fCadence, clamp(cadence, 0, 254));
        set(_fSpeed, clamp((speedMps * 1000).toNumber(), 0, 65534));
        set(_fDistance, (distanceM * 100).toNumber());
        set(_fKcal, clamp(kcal.toNumber(), 0, 65534));
        var kh = bike.kcalPerHour;
        set(_fKcalH, (fresh && kh != null) ? clamp(kh, 0, 65534) : 0);
        var hr = bike.heartRate;
        if (hr != null && fresh) {
            set(_fBikeHr, clamp(hr, 0, 254));
        }
        var met = bike.met;
        if (met != null) {
            set(_fMet, met);
        }
        var res = bike.resistance;
        if (res != null) {
            set(_fResistance, res);
        }
    }

    private function writeLapFields() as Void {
        var lapAvgSpeed = lapSeconds > 0 ? lapDistanceM / lapSeconds : 0.0;
        var lapAvgCad = _lapCadCount > 0 ? _lapCadSum / _lapCadCount : 0;
        set(_fLapAvgPower, clamp(lapAvgPower, 0, 65534));
        set(_fLapMaxPower, clamp(_lapMaxPower, 0, 65534));
        set(_fLapAvgCad, clamp(lapAvgCad, 0, 254));
        set(_fLapMaxCad, clamp(_lapMaxCad, 0, 254));
        set(_fLapDistance, (lapDistanceM * 100).toNumber());
        set(_fLapAvgSpeed, clamp((lapAvgSpeed * 1000).toNumber(), 0, 65534));
        set(_fLapMaxSpeed, clamp((_lapMaxSpeed * 1000).toNumber(), 0, 65534));
        set(_fLapNp, clamp(npFrom(_lapNp4Sum, _lapNp4Count), 0, 65534));
        set(_fLapKcal, clamp(lapKcal.toNumber(), 0, 65534));
    }

    private function writeSessionFields() as Void {
        var avgSpeed = seconds > 0 ? distanceM / seconds : 0.0;
        set(_fSesAvgPower, clamp(avgPower, 0, 65534));
        set(_fSesMaxPower, clamp(maxPower, 0, 65534));
        set(_fSesAvgCad, clamp(avgCadence, 0, 254));
        set(_fSesMaxCad, clamp(maxCadence, 0, 254));
        set(_fSesDistance, (distanceM * 100).toNumber());
        set(_fSesAvgSpeed, clamp((avgSpeed * 1000).toNumber(), 0, 65534));
        set(_fSesMaxSpeed, clamp((maxSpeedMps * 1000).toNumber(), 0, 65534));
        set(_fSesNp, clamp(np, 0, 65534));
        set(_fSesWork, workJ.toNumber());
        set(_fSesKcal, clamp(kcal.toNumber(), 0, 65534));
    }

    // -------------------------------------------------------------- stats

    private function updateNp(p as Number) as Void {
        if (_npFill == 30) {
            _npRolling -= _npBuf[_npIdx];
        } else {
            _npFill += 1;
        }
        _npBuf[_npIdx] = p;
        _npRolling += p;
        _npIdx = (_npIdx + 1) % 30;
        if (_npFill == 30) {
            var avg = _npRolling / 30.0;
            var a4 = avg * avg * avg * avg;
            _np4Sum += a4;
            _np4Count += 1;
            _lapNp4Sum += a4;
            _lapNp4Count += 1;
            np = npFrom(_np4Sum, _np4Count);
        }
    }

    private function npFrom(sum as Float, count as Number) as Number {
        if (count == 0) {
            return 0;
        }
        return Math.pow(sum / count, 0.25).toNumber();
    }

    private function resetLap() as Void {
        lapDistanceM = 0.0;
        lapKcal = 0.0;
        lapSeconds = 0;
        lapAvgPower = 0;
        _lapPowerSum = 0;
        _lapMaxPower = 0;
        _lapCadSum = 0;
        _lapCadCount = 0;
        _lapMaxCad = 0;
        _lapMaxSpeed = 0.0;
        _lapNp4Sum = 0.0;
        _lapNp4Count = 0;
    }

    private function resetStats() as Void {
        distanceM = 0.0;
        kcal = 0.0;
        seconds = 0;
        avgPower = 0;
        maxPower = 0;
        avgCadence = 0;
        maxCadence = 0;
        maxSpeedMps = 0.0;
        workJ = 0.0;
        np = 0;
        laps = 1;
        _powerSum = 0;
        _cadSum = 0;
        _cadCount = 0;
        _npIdx = 0;
        _npFill = 0;
        _npRolling = 0;
        _np4Sum = 0.0;
        _np4Count = 0;
        for (var i = 0; i < 30; i++) {
            _npBuf[i] = 0;
        }
        _lastConsoleDist = null;
        _lastConsoleKcal = null;
        resetLap();
    }

    private function clamp(v as Number, lo as Number, hi as Number) as Number {
        return v < lo ? lo : (v > hi ? hi : v);
    }

    private function signal(tone as Attention.Tone?) as Void {
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(60, 250)]);
        }
        if (tone != null && Attention has :playTone) {
            Attention.playTone(tone);
        }
    }
}
