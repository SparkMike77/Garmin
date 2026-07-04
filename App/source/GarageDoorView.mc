import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

class GarageDoorView extends WatchUi.View {

    hidden var _doorState as String;
    hidden var _refreshTimer as Timer.Timer?;

    function initialize() {
        View.initialize();
        _doorState = "--";
        _refreshTimer = null;
    }

    function onLayout(dc as Dc) as Void {
    }

    function onShow() as Void {
        refreshState();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var centerX = dc.getWidth() / 2;
        var height = dc.getHeight();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 0.18, Graphics.FONT_SMALL, "Garage Door",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 0.30, Graphics.FONT_MEDIUM, _doorState,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        drawButton(dc, GarageDoorView.getUpButtonRect(), "UP");
        drawButton(dc, GarageDoorView.getDownButtonRect(), "DOWN");
    }

    function onHide() as Void {
        if (_refreshTimer != null) {
            _refreshTimer.stop();
            _refreshTimer = null;
        }
    }

    // Pulls the entity's actual state from Home Assistant.
    function refreshState() as Void {
        var entityId = Properties.getValue("ha_garage_entity") as String;
        HomeAssistantClient.getState(entityId, method(:onStateResult));
    }

    function onStateResult(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode == -1) {
            _doorState = "Not configured";
        } else if (responseCode == 200 && data != null) {
            _doorState = formatState(data["state"] as String?);
        } else {
            _doorState = "Error (" + responseCode.toString() + ")";
        }
        WatchUi.requestUpdate();
    }

    // Sends an open/close command, shows an optimistic in-progress label,
    // then re-polls the real state a few seconds later once the door has
    // had time to actually move.
    function sendCommand(service as String, inProgressLabel as String) as Void {
        var entityId = Properties.getValue("ha_garage_entity") as String;
        _doorState = inProgressLabel;
        WatchUi.requestUpdate();

        HomeAssistantClient.callService("cover", service, entityId, method(:onCommandResult));
    }

    function onCommandResult(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode != 200) {
            _doorState = "Error (" + responseCode.toString() + ")";
            WatchUi.requestUpdate();
            return;
        }

        if (_refreshTimer == null) {
            _refreshTimer = new Timer.Timer();
        }
        _refreshTimer.start(method(:refreshState), 6000, false);
    }

    function formatState(state as String?) as String {
        if (state == null) {
            return "Unknown";
        }
        if (state.equals("open")) {
            return "Open";
        }
        if (state.equals("closed")) {
            return "Closed";
        }
        if (state.equals("opening")) {
            return "Opening...";
        }
        if (state.equals("closing")) {
            return "Closing...";
        }
        return state;
    }

    function drawButton(dc as Dc, rect as Array<Number>, label as String) as Void {
        var x = rect[0];
        var y = rect[1];
        var w = rect[2];
        var h = rect[3];

        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(x, y, w, h, 8);
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + (w / 2), y + (h / 2), Graphics.FONT_SMALL, label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Static so the delegate can hit-test taps without holding a view reference.
    static function getUpButtonRect() as Array<Number> {
        var settings = System.getDeviceSettings();
        var width = settings.screenWidth;
        var height = settings.screenHeight;
        return [(width * 0.20).toNumber(), (height * 0.42).toNumber(), (width * 0.60).toNumber(), (height * 0.16).toNumber()];
    }

    static function getDownButtonRect() as Array<Number> {
        var settings = System.getDeviceSettings();
        var width = settings.screenWidth;
        var height = settings.screenHeight;
        return [(width * 0.20).toNumber(), (height * 0.64).toNumber(), (width * 0.60).toNumber(), (height * 0.16).toNumber()];
    }

    static function isPointInRect(x as Number, y as Number, rect as Array<Number>) as Boolean {
        return x >= rect[0] && x <= rect[0] + rect[2] && y >= rect[1] && y <= rect[1] + rect[3];
    }

}
