// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Liohtml
//
// Button mapping (same as native Garmin activities):
//   START/STOP  start / pause (opens Resume / Save / Discard menu)
//   BACK/LAP    lap while recording, menu while paused, exit when idle
//   UP / DOWN   switch data page (swipe / tap on touch models)
//

import Toybox.Lang;
import Toybox.WatchUi;

class MainDelegate extends WatchUi.BehaviorDelegate {

    private var _view as MainView;

    function initialize(view as MainView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        if (keyEvent.getKey() == WatchUi.KEY_ENTER) {
            startStop();
            return true;
        }
        return false;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        // Touch only changes pages - start/stop is reserved for the button.
        _view.nextPage();
        return true;
    }

    function onNextPage() as Boolean {
        _view.nextPage();
        return true;
    }

    function onPreviousPage() as Boolean {
        _view.previousPage();
        return true;
    }

    function onMenu() as Boolean {
        var rec = getApp().recorder;
        if (rec.hasSession()) {
            if (rec.state == REC_RECORDING) {
                rec.pause();
            }
            showPauseMenu();
            return true;
        }
        return false;
    }

    function onBack() as Boolean {
        var app = getApp();
        var rec = app.recorder;
        if (rec.state == REC_RECORDING) {
            rec.lap();
            app.flash(Rez.Strings.Lap);
            return true;
        }
        if (rec.state == REC_PAUSED) {
            showPauseMenu();
            return true;
        }
        return false;   // idle: leave the app
    }

    private function startStop() as Void {
        var rec = getApp().recorder;
        if (rec.state == REC_IDLE) {
            rec.start();
        } else if (rec.state == REC_RECORDING) {
            rec.pause();
            showPauseMenu();
        } else {
            rec.resume();
        }
        WatchUi.requestUpdate();
    }

    private function showPauseMenu() as Void {
        var menu = new WatchUi.Menu2({ :title => Rez.Strings.Paused });
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.Resume, null, :resume, null));
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.Save, null, :save, null));
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.Discard, null, :discard, null));
        WatchUi.pushView(menu, new PauseMenuDelegate(), WatchUi.SLIDE_UP);
    }
}

class PauseMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var app = getApp();
        var id = item.getId();
        if (id == :resume) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            app.recorder.resume();
        } else if (id == :save) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            app.recorder.save();
            app.flash(Rez.Strings.Saved);
        } else if (id == :discard) {
            WatchUi.pushView(
                new WatchUi.Confirmation(WatchUi.loadResource(Rez.Strings.DiscardConfirm) as String),
                new DiscardConfirmDelegate(),
                WatchUi.SLIDE_LEFT);
        }
    }

    function onBack() as Void {
        // Stay paused on the data screen.
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class DiscardConfirmDelegate extends WatchUi.ConfirmationDelegate {

    function initialize() {
        ConfirmationDelegate.initialize();
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            var app = getApp();
            app.recorder.discard();
            app.flash(Rez.Strings.Discarded);
            // Close the pause menu underneath the confirmation as well.
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }
        return true;
    }
}
