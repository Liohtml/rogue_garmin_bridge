// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Liohtml
//
// Rogue Echo Bike for Garmin fenix / epix.
//
// Connects to the Echo Bike console over Bluetooth LE (FTMS), shows the
// live metrics and records them into a native indoor cycling activity.
//

import Toybox.Application;
import Toybox.BluetoothLowEnergy;
import Toybox.Lang;
import Toybox.Sensor;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

class EchoBikeApp extends Application.AppBase {

    var bike as BikeData;
    var ble as FtmsBleManager;
    var recorder as Recorder;
    var statusMessage as String?;
    var statusUntilMs as Number = 0;

    private var _timer as Timer.Timer?;

    function initialize() {
        AppBase.initialize();
        bike = new BikeData();
        ble = new FtmsBleManager(bike);
        recorder = new Recorder();
    }

    function onStart(state as Dictionary?) as Void {
        // Wrist heart rate (and any paired HR strap) is recorded natively.
        try {
            Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
        } catch (e) {
        }

        BluetoothLowEnergy.setDelegate(ble);
        ble.start();

        var t = new Timer.Timer();
        t.start(method(:onTick), 1000, true);
        _timer = t;
    }

    function onStop(state as Dictionary?) as Void {
        var t = _timer;
        if (t != null) {
            t.stop();
        }
        // Never lose a workout: save if the app is closed while recording.
        if (recorder.hasSession()) {
            recorder.save();
        }
        ble.stop();
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var view = new MainView();
        return [view, new MainDelegate(view)];
    }

    function onTick() as Void {
        ble.tick();
        recorder.tick(bike);
        WatchUi.requestUpdate();
    }

    //! Show a short message in the status line for a few seconds.
    function flash(msg as ResourceId) as Void {
        statusMessage = WatchUi.loadResource(msg) as String;
        statusUntilMs = System.getTimer() + 4000;
        WatchUi.requestUpdate();
    }
}

function getApp() as EchoBikeApp {
    return Application.getApp() as EchoBikeApp;
}
