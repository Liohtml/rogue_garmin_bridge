//
// Bluetooth LE central that finds the Rogue Echo Bike, connects to it and
// subscribes to the FTMS Indoor Bike Data characteristic.
//

import Toybox.BluetoothLowEnergy;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

enum BleState {
    BLE_IDLE,
    BLE_REGISTERING,
    BLE_SCANNING,
    BLE_CONNECTING,
    BLE_SUBSCRIBING,
    BLE_CONNECTED,
    BLE_RECONNECTING,
    BLE_ERROR
}

class FtmsBleManager extends BluetoothLowEnergy.BleDelegate {

    // Fitness Machine Service and Indoor Bike Data (Bluetooth SIG base UUID).
    private var _ftmsService as BluetoothLowEnergy.Uuid;
    private var _indoorBikeData as BluetoothLowEnergy.Uuid;

    // If no device with "Echo" in its name shows up, connect to the first
    // FTMS device seen after this many milliseconds of scanning.
    private const FALLBACK_AFTER_MS = 8000;
    // Give up on a connection attempt / subscription after this long.
    private const CONNECT_TIMEOUT_MS = 20000;
    // Rescan when an automatic reconnect did not succeed within this time.
    private const RECONNECT_TIMEOUT_MS = 45000;

    var state as BleState = BLE_IDLE;
    var deviceName as String?;
    var lastMessage as Symbol?;

    private var _bike as BikeData;
    private var _device as BluetoothLowEnergy.Device?;
    private var _candidate as BluetoothLowEnergy.ScanResult?;
    private var _stateSinceMs as Number = 0;
    private var _subscribeRetries as Number = 0;

    function initialize(bike as BikeData) {
        BleDelegate.initialize();
        _bike = bike;
        _ftmsService = BluetoothLowEnergy.longToUuid(0x0000182600001000l, 0x800000805F9B34FBl);
        _indoorBikeData = BluetoothLowEnergy.longToUuid(0x00002AD200001000l, 0x800000805F9B34FBl);
    }

    //! Register the FTMS profile; scanning starts once registration completes.
    function start() as Void {
        setState(BLE_REGISTERING);
        try {
            BluetoothLowEnergy.registerProfile({
                :uuid => _ftmsService,
                :characteristics => [{
                    :uuid => _indoorBikeData,
                    :descriptors => [BluetoothLowEnergy.cccdUuid()]
                }]
            });
        } catch (e) {
            System.println("registerProfile failed: " + e.getErrorMessage());
            // Profile may already be registered (e.g. app restarted) - scan anyway.
            startScan();
        }
    }

    //! Stop scanning and release the bike.
    function stop() as Void {
        try {
            BluetoothLowEnergy.setScanState(BluetoothLowEnergy.SCAN_STATE_OFF);
        } catch (e) {
        }
        var dev = _device;
        if (dev != null) {
            try {
                BluetoothLowEnergy.unpairDevice(dev);
            } catch (e) {
            }
        }
        _device = null;
        setState(BLE_IDLE);
    }

    //! Called once per second by the app to drive timeouts.
    function tick() as Void {
        var age = System.getTimer() - _stateSinceMs;
        if (state == BLE_SCANNING) {
            var c = _candidate;
            if (c != null && age > FALLBACK_AFTER_MS) {
                connect(c);
            }
        } else if (state == BLE_CONNECTING || state == BLE_SUBSCRIBING) {
            if (age > CONNECT_TIMEOUT_MS) {
                System.println("connect/subscribe timeout - rescanning");
                restartScan();
            }
        } else if (state == BLE_RECONNECTING) {
            // The system reconnects paired devices by itself; if the console
            // stays away (switched off / restarted), scan for it again.
            if (age > RECONNECT_TIMEOUT_MS) {
                restartScan();
            }
        } else if (state == BLE_CONNECTED) {
            // Connected but the bike stopped talking: re-enable notifications.
            var t = _bike.lastPacketMs;
            if (t != null && System.getTimer() - t > 10000 && age > 10000) {
                enableNotifications();
            }
        }
    }

    function isConnected() as Boolean {
        return state == BLE_CONNECTED;
    }

    // ---------------------------------------------------------------- BLE

    function onProfileRegister(uuid as BluetoothLowEnergy.Uuid, status as BluetoothLowEnergy.Status) as Void {
        System.println("onProfileRegister status=" + status);
        startScan();
    }

    function onScanResults(scanResults as BluetoothLowEnergy.Iterator) as Void {
        if (state != BLE_SCANNING) {
            return;
        }
        for (var r = scanResults.next(); r != null; r = scanResults.next()) {
            if (!(r instanceof BluetoothLowEnergy.ScanResult)) {
                continue;
            }
            var result = r as BluetoothLowEnergy.ScanResult;
            var name = result.getDeviceName();
            var isFtms = advertisesFtms(result);
            var isEcho = false;
            if (name != null) {
                var lower = name.toLower();
                // "Echo Bike ..." - but not the Echo Rower.
                isEcho = lower.find("echo") != null && lower.find("row") == null;
            }
            if (isEcho) {
                connect(result);
                return;
            }
            if (isFtms && _candidate == null) {
                _candidate = result;
            }
        }
    }

    function onConnectedStateChanged(device as BluetoothLowEnergy.Device, connState as BluetoothLowEnergy.ConnectionState) as Void {
        System.println("onConnectedStateChanged " + connState);
        if (connState == BluetoothLowEnergy.CONNECTION_STATE_CONNECTED) {
            _device = device;
            var n = device.getName();
            if (n != null) {
                deviceName = n;
            }
            _subscribeRetries = 0;
            enableNotifications();
        } else {
            // The system keeps the pairing and reconnects automatically.
            _bike.clearInstant();
            if (_device != null) {
                setState(BLE_RECONNECTING);
            }
        }
        WatchUi.requestUpdate();
    }

    function onDescriptorWrite(descriptor as BluetoothLowEnergy.Descriptor, status as BluetoothLowEnergy.Status) as Void {
        System.println("onDescriptorWrite status=" + status);
        if (status == BluetoothLowEnergy.STATUS_SUCCESS) {
            setState(BLE_CONNECTED);
        } else if (_subscribeRetries < 3) {
            _subscribeRetries += 1;
            enableNotifications();
        } else {
            lastMessage = :NoFtms;
            restartScan();
        }
        WatchUi.requestUpdate();
    }

    function onCharacteristicChanged(characteristic as BluetoothLowEnergy.Characteristic, value as ByteArray) as Void {
        if (characteristic.getUuid().equals(_indoorBikeData)) {
            FtmsParser.parseIndoorBikeData(value, _bike);
            if (state != BLE_CONNECTED) {
                setState(BLE_CONNECTED);
            }
        }
    }

    // ---------------------------------------------------------- internals

    private function setState(s as BleState) as Void {
        state = s;
        _stateSinceMs = System.getTimer();
    }

    private function startScan() as Void {
        _candidate = null;
        setState(BLE_SCANNING);
        try {
            BluetoothLowEnergy.setScanState(BluetoothLowEnergy.SCAN_STATE_SCANNING);
        } catch (e) {
            System.println("setScanState failed: " + e.getErrorMessage());
            setState(BLE_ERROR);
        }
        WatchUi.requestUpdate();
    }

    private function restartScan() as Void {
        var dev = _device;
        if (dev != null) {
            try {
                BluetoothLowEnergy.unpairDevice(dev);
            } catch (e) {
            }
        }
        _device = null;
        _bike.clearInstant();
        startScan();
    }

    private function connect(result as BluetoothLowEnergy.ScanResult) as Void {
        try {
            BluetoothLowEnergy.setScanState(BluetoothLowEnergy.SCAN_STATE_OFF);
        } catch (e) {
        }
        deviceName = result.getDeviceName();
        setState(BLE_CONNECTING);
        try {
            var dev = BluetoothLowEnergy.pairDevice(result);
            if (dev == null) {
                startScan();
                return;
            }
            _device = dev;
            // Already connected (e.g. bond kept by the system)?
            if (dev.isConnected()) {
                enableNotifications();
            }
        } catch (e) {
            System.println("pairDevice failed: " + e.getErrorMessage());
            startScan();
        }
        WatchUi.requestUpdate();
    }

    private function enableNotifications() as Void {
        var dev = _device;
        if (dev == null) {
            return;
        }
        setState(BLE_SUBSCRIBING);
        var service = dev.getService(_ftmsService);
        if (service == null) {
            System.println("FTMS service not found");
            lastMessage = :NoFtms;
            restartScan();
            return;
        }
        var ch = service.getCharacteristic(_indoorBikeData);
        if (ch == null) {
            System.println("Indoor Bike Data characteristic not found");
            lastMessage = :NoFtms;
            restartScan();
            return;
        }
        var cccd = ch.getDescriptor(BluetoothLowEnergy.cccdUuid());
        if (cccd == null) {
            lastMessage = :NoFtms;
            restartScan();
            return;
        }
        try {
            cccd.requestWrite([0x01, 0x00]b);
        } catch (e) {
            // Another GATT operation may still be pending; tick() retries.
            System.println("CCCD write failed: " + e.getErrorMessage());
        }
    }

    private function advertisesFtms(result as BluetoothLowEnergy.ScanResult) as Boolean {
        var it = result.getServiceUuids();
        for (var u = it.next(); u != null; u = it.next()) {
            if ((u as BluetoothLowEnergy.Uuid).equals(_ftmsService)) {
                return true;
            }
        }
        return false;
    }
}
