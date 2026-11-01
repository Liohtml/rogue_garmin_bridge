//
// Activity screens.
//   Page 0: power (big), cadence, heart rate, speed, distance, timer
//   Page 1: averages / maxima, NP, lap power, calories, kcal/h
//

import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class MainView extends WatchUi.View {

    const PAGES = 2;
    var page as Number = 0;

    private var _s as Dictionary<Symbol, String> = {};
    private var _statute as Boolean = false;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
        var ids = {
            :Searching => Rez.Strings.Searching,
            :Connecting => Rez.Strings.Connecting,
            :Subscribing => Rez.Strings.Subscribing,
            :Connected => Rez.Strings.Connected,
            :Reconnecting => Rez.Strings.Reconnecting,
            :NoFtms => Rez.Strings.NoFtms,
            :BleError => Rez.Strings.BleError,
            :PressStart => Rez.Strings.PressStart,
            :Recording => Rez.Strings.Recording,
            :Paused => Rez.Strings.Paused,
            :Power => Rez.Strings.Power,
            :Cadence => Rez.Strings.Cadence,
            :Speed => Rez.Strings.Speed,
            :Distance => Rez.Strings.Distance,
            :HeartRate => Rez.Strings.HeartRate,
            :Calories => Rez.Strings.Calories,
            :AvgPower => Rez.Strings.AvgPower,
            :MaxPower => Rez.Strings.MaxPower,
            :AvgCadence => Rez.Strings.AvgCadence,
            :NormPower => Rez.Strings.NormPower,
            :KcalPerHour => Rez.Strings.KcalPerHour,
            :LapPower => Rez.Strings.LapPower,
            :Lap => Rez.Strings.Lap
        };
        var keys = ids.keys();
        for (var i = 0; i < keys.size(); i++) {
            var k = keys[i] as Symbol;
            _s[k] = WatchUi.loadResource(ids[k] as ResourceId) as String;
        }
    }

    function onShow() as Void {
        _statute = System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE;
    }

    function nextPage() as Void {
        page = (page + 1) % PAGES;
        WatchUi.requestUpdate();
    }

    function previousPage() as Void {
        page = (page + PAGES - 1) % PAGES;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var app = getApp();
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        drawStatus(dc, app, w, h);
        if (page == 0) {
            drawMain(dc, app, w, h);
        } else {
            drawStats(dc, app, w, h);
        }
        drawTimer(dc, app, w, h);
        drawPageDots(dc, w, h);
    }

    // ---------------------------------------------------------------- pages

    private function drawMain(dc as Graphics.Dc, app as EchoBikeApp, w as Number, h as Number) as Void {
        var rec = app.recorder;
        var bike = app.bike;
        var fresh = bike.isFresh();

        // Power (hero metric).
        var powerTxt = fresh ? rec.power.toString() : "--";
        dc.setColor(powerColor(rec.power, fresh), Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, (h * 0.30).toNumber(), Graphics.FONT_NUMBER_MEDIUM, powerTxt,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        label(dc, w / 2, (h * 0.43).toNumber(), _s[:Power] + " W");

        // Cadence | heart rate.
        var hr = heartRate(app);
        cell(dc, (w * 0.30).toNumber(), (h * 0.53).toNumber(), fresh ? rec.cadence.toString() : "--", _s[:Cadence]);
        cell(dc, (w * 0.70).toNumber(), (h * 0.53).toNumber(), hr != null ? hr.toString() : "--", _s[:HeartRate]);

        // Speed | distance.
        var speed = rec.speedMps * (_statute ? 2.236936 : 3.6);
        var dist = rec.hasSession() ? rec.distanceM : 0.0;
        var distTxt = (dist / (_statute ? 1609.344 : 1000.0)).format("%.2f");
        cell(dc, (w * 0.30).toNumber(), (h * 0.71).toNumber(), fresh ? speed.format("%.1f") : "--",
            _s[:Speed] + (_statute ? " mph" : " km/h"));
        cell(dc, (w * 0.70).toNumber(), (h * 0.71).toNumber(), distTxt,
            _s[:Distance] + (_statute ? " mi" : " km"));
    }

    private function drawStats(dc as Graphics.Dc, app as EchoBikeApp, w as Number, h as Number) as Void {
        var rec = app.recorder;
        var bike = app.bike;
        var kh = bike.kcalPerHour;

        cell(dc, (w * 0.30).toNumber(), (h * 0.30).toNumber(), rec.avgPower.toString(), _s[:AvgPower]);
        cell(dc, (w * 0.70).toNumber(), (h * 0.30).toNumber(), rec.maxPower.toString(), _s[:MaxPower]);
        cell(dc, (w * 0.30).toNumber(), (h * 0.49).toNumber(), rec.np.toString(), _s[:NormPower]);
        cell(dc, (w * 0.70).toNumber(), (h * 0.49).toNumber(), rec.lapAvgPower.toString(),
            _s[:LapPower] + " " + rec.laps.toString());
        cell(dc, (w * 0.30).toNumber(), (h * 0.68).toNumber(), rec.avgCadence.toString(), _s[:AvgCadence]);
        cell(dc, (w * 0.70).toNumber(), (h * 0.68).toNumber(), calories(app).toString(), _s[:Calories]);

        var info = (kh != null && bike.isFresh()) ? kh.toString() + " " + _s[:KcalPerHour] : "";
        var met = bike.met;
        if (met != null) {
            info += (info.length() > 0 ? "  " : "") + met.format("%.1f") + " MET";
        }
        if (info.length() > 0) {
            label(dc, w / 2, (h * 0.80).toNumber(), info);
        }
    }

    // -------------------------------------------------------------- pieces

    private function drawStatus(dc as Graphics.Dc, app as EchoBikeApp, w as Number, h as Number) as Void {
        var ble = app.ble;
        var txt;
        var color = Graphics.COLOR_ORANGE;

        if (app.statusMessage != null && System.getTimer() < app.statusUntilMs) {
            txt = app.statusMessage as String;
            color = Graphics.COLOR_WHITE;
        } else {
            switch (ble.state) {
                case BLE_CONNECTED:
                    var n = ble.deviceName;
                    txt = n != null ? n : _s[:Connected];
                    color = Graphics.COLOR_GREEN;
                    break;
                case BLE_CONNECTING:
                    txt = _s[:Connecting];
                    break;
                case BLE_SUBSCRIBING:
                    txt = _s[:Subscribing];
                    break;
                case BLE_RECONNECTING:
                    txt = _s[:Reconnecting];
                    color = Graphics.COLOR_RED;
                    break;
                case BLE_ERROR:
                    txt = _s[:BleError];
                    color = Graphics.COLOR_RED;
                    break;
                default:
                    txt = ble.lastMessage == :NoFtms ? _s[:NoFtms] : _s[:Searching];
                    break;
            }
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, (h * 0.13).toNumber(), Graphics.FONT_XTINY, txt as String,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawTimer(dc as Graphics.Dc, app as EchoBikeApp, w as Number, h as Number) as Void {
        var rec = app.recorder;
        var y = (h * 0.87).toNumber();
        if (rec.state == REC_IDLE) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, y, Graphics.FONT_SMALL, _s[:PressStart] as String,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }
        var ms = 0;
        var info = Activity.getActivityInfo();
        if (info != null && info.timerTime != null) {
            ms = info.timerTime as Number;
        }
        var t = ms / 1000;
        var txt = (t / 3600) > 0
            ? (t / 3600).format("%d") + ":" + ((t / 60) % 60).format("%02d") + ":" + (t % 60).format("%02d")
            : (t / 60).format("%d") + ":" + (t % 60).format("%02d");
        if (rec.state == REC_PAUSED) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            txt = _s[:Paused] + " " + txt;
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(w / 2, y, Graphics.FONT_SMALL, txt,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        if (rec.state == REC_RECORDING) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(w / 2, (h * 0.95).toNumber(), (h / 80) + 2);
        }
    }

    private function drawPageDots(dc as Graphics.Dc, w as Number, h as Number) as Void {
        var r = (h / 100) + 2;
        var x = (w * 0.94).toNumber();
        for (var i = 0; i < PAGES; i++) {
            var y = h / 2 + (i * 2 - (PAGES - 1)) * r * 2;
            dc.setColor(i == page ? Graphics.COLOR_WHITE : Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(x, y, r);
        }
    }

    private function cell(dc as Graphics.Dc, x as Number, y as Number, value as String, name as String?) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, Graphics.FONT_MEDIUM, value,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        var fh = dc.getFontHeight(Graphics.FONT_MEDIUM);
        label(dc, x, y + (fh * 0.62).toNumber(), name);
    }

    private function label(dc as Graphics.Dc, x as Number, y as Number, text as String?) as Void {
        if (text == null) {
            return;
        }
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, Graphics.FONT_XTINY, text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function heartRate(app as EchoBikeApp) as Number? {
        var info = Activity.getActivityInfo();
        if (info != null && info.currentHeartRate != null) {
            return info.currentHeartRate;
        }
        var bhr = app.bike.heartRate;
        return (bhr != null && bhr > 0 && app.bike.isFresh()) ? bhr : null;
    }

    private function calories(app as EchoBikeApp) as Number {
        var rec = app.recorder;
        if (rec.kcal > 0) {
            return rec.kcal.toNumber();
        }
        var info = Activity.getActivityInfo();
        if (info != null && info.calories != null && rec.hasSession()) {
            return info.calories as Number;
        }
        return 0;
    }

    private function powerColor(p as Number, fresh as Boolean) as Graphics.ColorType {
        if (!fresh) {
            return Graphics.COLOR_DK_GRAY;
        }
        return p > 0 ? Graphics.COLOR_WHITE : Graphics.COLOR_LT_GRAY;
    }
}
