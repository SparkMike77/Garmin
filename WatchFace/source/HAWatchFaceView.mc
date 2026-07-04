import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class HAWatchFaceView extends WatchUi.WatchFace {

    hidden var _timeFont as Graphics.FontType;
    hidden var _smallFont as Graphics.FontType;

    function initialize() {
        WatchFace.initialize();
        _timeFont = WatchUi.loadResource(Rez.Fonts.GugiLarge) as Graphics.FontType;
        _smallFont = WatchUi.loadResource(Rez.Fonts.GugiSmall) as Graphics.FontType;
    }

    function onLayout(dc as Dc) as Void {
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;
        var markerRadius = width * 0.40;

        drawTime(dc, centerX, centerY);

        var p1 = clockPoint(centerX, centerY, markerRadius, 1);
        var p2 = clockPoint(centerX, centerY, markerRadius, 2);
        var p4 = clockPoint(centerX, centerY, markerRadius, 4);
        var p6 = clockPoint(centerX, centerY, markerRadius, 6);
        var p7 = clockPoint(centerX, centerY, markerRadius, 7);
        var p8 = clockPoint(centerX, centerY, markerRadius, 8);
        var p10 = clockPoint(centerX, centerY, markerRadius, 10);
        var p11 = clockPoint(centerX, centerY, markerRadius, 11);

        drawWatchBattery(dc, p10[0], p10[1]);
        drawSteps(dc, p1[0], p1[1]);
        drawStairs(dc, p2[0], p2[1]);
        drawCompass(dc, p8[0], p8[1]);
        drawHeartRate(dc, p4[0], p4[1]);
        drawBluetoothStatus(dc, p6[0], p6[1]);
        drawHomeAssistantStatus(dc, p7[0], p7[1]);
        drawDate(dc, p11[0], p11[1]);
    }

    function onHide() as Void {
    }

    function onExitSleep() as Void {
    }

    function onEnterSleep() as Void {
    }

    // ---- Convert a clock hour (1-12) to a screen point at the given radius ----
    function clockPoint(centerX as Number, centerY as Number, radius as Numeric, hour as Number) as Array<Number> {
        var degrees = (hour % 12) * 30.0;
        var radians = degrees * Math.PI / 180.0;
        var x = centerX + radius * Math.sin(radians);
        var y = centerY - radius * Math.cos(radians);
        return [x.toNumber(), y.toNumber()];
    }

    // ---- Time, centered, always 24-hour ----
    function drawTime(dc as Dc, centerX as Number, centerY as Number) as Void {
        var clockTime = System.getClockTime();
        var timeString = Lang.format("$1$:$2$", [clockTime.hour.format("%02d"), clockTime.min.format("%02d")]);
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY, _timeFont, timeString,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // ---- Watch battery, at the 10-position, clock icon left of the percentage ----
    function drawWatchBattery(dc as Dc, x as Numeric, y as Numeric) as Void {
        var battery = System.getSystemStats().battery;
        var batteryString = battery.format("%d") + "%";

        drawClockIcon(dc, x - 14, y);

        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + 8, y, _smallFont, batteryString,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function drawClockIcon(dc as Dc, cx as Numeric, cy as Numeric) as Void {
        var r = 6;
        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, r);
        dc.drawLine(cx, cy, cx, cy - r + 1);
        dc.drawLine(cx, cy, cx + r - 2, cy);
    }

    // ---- Step count with a footprints icon, at the 1-position ----
    function drawSteps(dc as Dc, x as Numeric, y as Numeric) as Void {
        var info = ActivityMonitor.getInfo();
        var steps = info.steps;
        var stepsString = (steps != null) ? steps.toString() : "--";

        drawFootprintsIcon(dc, x - 14, y);

        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + 8, y, _smallFont, stepsString,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function drawFootprintsIcon(dc as Dc, cx as Numeric, cy as Numeric) as Void {
        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.fillEllipse(cx - 3, cy - 3, 3, 5);
        dc.fillEllipse(cx + 3, cy + 3, 3, 5);
    }

    // ---- Stair (floors climbed) count with a stair icon, at the 2-position ----
    function drawStairs(dc as Dc, x as Numeric, y as Numeric) as Void {
        var info = ActivityMonitor.getInfo();
        var floors = info.floorsClimbed;
        var floorsString = (floors != null) ? floors.toString() : "--";

        drawStairIcon(dc, x - 14, y);

        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + 8, y, _smallFont, floorsString,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function drawStairIcon(dc as Dc, cx as Numeric, cy as Numeric) as Void {
        var baseline = cy + 6;
        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(cx - 9, baseline - 4, 5, 4);
        dc.fillRectangle(cx - 4, baseline - 8, 5, 8);
        dc.fillRectangle(cx + 1, baseline - 12, 5, 12);
    }

    // ---- Compass heading as a cardinal direction, at the 8-position ----
    function drawCompass(dc as Dc, x as Numeric, y as Numeric) as Void {
        var heading = Activity.getActivityInfo().currentHeading;
        var headingString = (heading != null) ? headingToCardinal(heading) : "--";

        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, _smallFont, headingString,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function headingToCardinal(headingRadians as Float) as String {
        var degrees = headingRadians * 180.0 / Math.PI;
        while (degrees < 0.0) {
            degrees += 360.0;
        }
        while (degrees >= 360.0) {
            degrees -= 360.0;
        }

        var directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"];
        var index = ((degrees + 22.5) / 45.0).toNumber();
        if (index >= 8) {
            index = 0;
        }
        return directions[index];
    }

    // ---- Heart rate with a simple drawn heart icon, at the 4-position ----
    function drawHeartRate(dc as Dc, x as Numeric, y as Numeric) as Void {
        var heartRate = Activity.getActivityInfo().currentHeartRate;
        var heartRateString = (heartRate != null) ? heartRate.toString() : "--";

        drawHeartIcon(dc, x - 14, y);

        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + 8, y, _smallFont, heartRateString,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function drawHeartIcon(dc as Dc, cx as Numeric, cy as Numeric) as Void {
        var r = 5;
        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx - r, cy - (r / 2), r);
        dc.fillCircle(cx + r, cy - (r / 2), r);
        var points = [
            [cx - (r * 2), cy - (r / 2)],
            [cx + (r * 2), cy - (r / 2)],
            [cx, cy + (r * 2)]
        ];
        dc.fillPolygon(points);
    }

    // ---- Bluetooth connection status to the phone, at the 6-position ----
    function drawBluetoothStatus(dc as Dc, x as Numeric, y as Numeric) as Void {
        var connected = System.getDeviceSettings().phoneConnected;
        if (connected) {
            drawBluetoothIcon(dc, x, y);
        } else {
            drawDisconnectedIcon(dc, x, y);
        }
    }

    function drawBluetoothIcon(dc as Dc, cx as Numeric, cy as Numeric) as Void {
        var r = 6;
        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx, cy - r, cx, cy + r);
        dc.drawLine(cx, cy - r, cx + (r * 0.7).toNumber(), cy - (r * 0.5).toNumber());
        dc.drawLine(cx + (r * 0.7).toNumber(), cy - (r * 0.5).toNumber(), cx, cy);
        dc.drawLine(cx, cy, cx + (r * 0.7).toNumber(), cy + (r * 0.5).toNumber());
        dc.drawLine(cx + (r * 0.7).toNumber(), cy + (r * 0.5).toNumber(), cx, cy + r);
    }

    // ---- Home Assistant connection status, at the 7-position ----
    // Populated by HAStatusServiceDelegate's periodic background check
    // (Storage["ha_connected"]) - a watch face's foreground code cannot
    // make network requests itself.
    function drawHomeAssistantStatus(dc as Dc, x as Numeric, y as Numeric) as Void {
        var connected = Storage.getValue("ha_connected");
        if (connected == true) {
            drawHouseIcon(dc, x, y);
        } else {
            drawDisconnectedIcon(dc, x, y);
        }
    }

    function drawHouseIcon(dc as Dc, cx as Numeric, cy as Numeric) as Void {
        var r = 7;
        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
        var roof = [
            [cx - r, cy - (r * 0.1).toNumber()],
            [cx + r, cy - (r * 0.1).toNumber()],
            [cx, cy - r]
        ];
        dc.fillPolygon(roof);
        dc.fillRectangle(cx - (r * 0.7).toNumber(), cy - (r * 0.1).toNumber(), (r * 1.4).toNumber(), (r * 1.1).toNumber());
    }

    // ---- Shared "unavailable" indicator: a circle with a diagonal slash ----
    function drawDisconnectedIcon(dc as Dc, cx as Numeric, cy as Numeric) as Void {
        var r = 7;
        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, r);
        var offset = (r * 0.7).toNumber();
        dc.drawLine(cx - offset, cy - offset, cx + offset, cy + offset);
    }

    // ---- Date, DD/MM, at the 11-position ----
    function drawDate(dc as Dc, x as Numeric, y as Numeric) as Void {
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dateString = Lang.format("$1$/$2$", [today.day.format("%02d"), today.month.format("%02d")]);
        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, _smallFont, dateString,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

}
