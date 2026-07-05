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
import Toybox.Weather;

class HAWatchFaceView extends WatchUi.WatchFace {

    hidden var _timeFont as Graphics.FontType;
    hidden var _smallFont as Graphics.FontType;
    hidden var _tinyFont as Graphics.FontType;

    const PRESSURE_TREND_WINDOW_SECONDS = 3 * 60 * 60;
    const PRESSURE_TREND_THRESHOLD_PA = 100.0;

    function initialize() {
        WatchFace.initialize();
        _timeFont = WatchUi.loadResource(Rez.Fonts.GugiLarge) as Graphics.FontType;
        _smallFont = WatchUi.loadResource(Rez.Fonts.GugiSmall) as Graphics.FontType;
        _tinyFont = WatchUi.loadResource(Rez.Fonts.GugiTiny) as Graphics.FontType;
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

        var dateAnchor = drawDate(dc, centerX, centerY, markerRadius, 11);
        drawSteps(dc, centerX, centerY, markerRadius, 1, dateAnchor[1]);
        drawStairs(dc, centerX, centerY, markerRadius, 2);
        drawBluetoothStatus(dc, centerX, centerY, markerRadius, 3);
        drawHeartRate(dc, centerX, centerY, markerRadius, 4);
        var weatherAnchor = drawWeather(dc, centerX, centerY, markerRadius, 5);
        drawPressureTrend(dc, centerX, centerY, markerRadius, 6);
        drawPressure(dc, centerX, centerY, markerRadius, 7, weatherAnchor[1]);
        drawCompass(dc, centerX, centerY, markerRadius, 8);
        drawHomeAssistantStatus(dc, centerX, centerY, markerRadius, 9);
        drawWatchBattery(dc, centerX, centerY, markerRadius, 10);
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

    // ---- Pull a clock-position point inward, if needed, so that a bounding
    // box of [dxMin,dxMax] x [dyMin,dyMax] (pixels, relative to the point)
    // stays entirely within the screen's visible circular bezel. This is used
    // instead of a fixed inset so every element - icons, short labels, and
    // wide icon+text combos alike - is guaranteed to fit regardless of font
    // metrics or string length. ----
    function safePoint(dc as Dc, centerX as Number, centerY as Number, baseRadius as Numeric, hour as Number, dxMin as Numeric, dxMax as Numeric, dyMin as Numeric, dyMax as Numeric) as Array<Number> {
        var screenRadius = (dc.getWidth() < dc.getHeight() ? dc.getWidth() : dc.getHeight()) / 2.0;
        var maxAllowed = screenRadius - 4.0;
        var r = baseRadius;

        while (r > 0) {
            var p = clockPoint(centerX, centerY, r, hour);
            var px = p[0] - centerX;
            var py = p[1] - centerY;
            var corners = [[dxMin, dyMin], [dxMin, dyMax], [dxMax, dyMin], [dxMax, dyMax]];
            var worst = 0.0;
            for (var i = 0; i < corners.size(); i++) {
                var cx = (px + corners[i][0]).toFloat();
                var cy = (py + corners[i][1]).toFloat();
                var dist = Math.sqrt(cx * cx + cy * cy);
                if (dist > worst) {
                    worst = dist;
                }
            }
            if (worst <= maxAllowed) {
                return p;
            }
            r = r - 2;
        }
        return clockPoint(centerX, centerY, 0, hour);
    }

    // ---- Safe point for an icon drawn to the left of the anchor with text
    // drawn (left-justified) to the right of it ----
    function iconTextPoint(dc as Dc, centerX as Number, centerY as Number, baseRadius as Numeric, hour as Number, iconOffset as Numeric, iconRadius as Numeric, textOffset as Numeric, text as String, font as Graphics.FontType) as Array<Number> {
        var textWidth = dc.getTextWidthInPixels(text, font);
        var fontHeight = dc.getFontHeight(font);
        var halfHeight = fontHeight / 2.0;
        if (iconRadius > halfHeight) {
            halfHeight = iconRadius;
        }
        var dxMin = -iconOffset - iconRadius;
        var dxMax = textOffset + textWidth;
        return safePoint(dc, centerX, centerY, baseRadius, hour, dxMin, dxMax, -halfHeight, halfHeight);
    }

    // ---- Safe point for center-justified text ----
    function centeredTextPoint(dc as Dc, centerX as Number, centerY as Number, baseRadius as Numeric, hour as Number, text as String, font as Graphics.FontType) as Array<Number> {
        var textWidth = dc.getTextWidthInPixels(text, font);
        var fontHeight = dc.getFontHeight(font);
        var halfWidth = textWidth / 2.0;
        var halfHeight = fontHeight / 2.0;
        return safePoint(dc, centerX, centerY, baseRadius, hour, -halfWidth, halfWidth, -halfHeight, halfHeight);
    }

    // ---- Safe point for a small icon centered on the anchor ----
    function iconPoint(dc as Dc, centerX as Number, centerY as Number, baseRadius as Numeric, hour as Number, iconRadius as Numeric) as Array<Number> {
        return safePoint(dc, centerX, centerY, baseRadius, hour, -iconRadius, iconRadius, -iconRadius, iconRadius);
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
    function drawWatchBattery(dc as Dc, centerX as Number, centerY as Number, baseRadius as Numeric, hour as Number) as Void {
        var battery = System.getSystemStats().battery;
        var batteryString = battery.format("%d") + "%";

        var p = iconTextPoint(dc, centerX, centerY, baseRadius, hour, 14, 6, 8, batteryString, _smallFont);
        var x = p[0];
        var y = p[1];

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
    // alignY pins this row to the same height as the date at the mirrored
    // 11-position.
    function drawSteps(dc as Dc, centerX as Number, centerY as Number, baseRadius as Numeric, hour as Number, alignY as Number) as Void {
        var info = ActivityMonitor.getInfo();
        var steps = info.steps;
        var stepsString = (steps != null) ? steps.toString() : "--";

        var p = iconTextPoint(dc, centerX, centerY, baseRadius, hour, 14, 8, 8, stepsString, _smallFont);
        var charWidth = dc.getTextWidthInPixels("0", _smallFont);
        var direction = (centerX > p[0]) ? 1 : -1;
        var x = p[0] + (charWidth * direction);
        var y = alignY;

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
    function drawStairs(dc as Dc, centerX as Number, centerY as Number, baseRadius as Numeric, hour as Number) as Void {
        var info = ActivityMonitor.getInfo();
        var floors = info.floorsClimbed;
        var floorsString = (floors != null) ? floors.toString() : "--";

        var p = iconTextPoint(dc, centerX, centerY, baseRadius, hour, 14, 9, 8, floorsString, _smallFont);
        var x = p[0];
        var y = p[1];

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
    function drawCompass(dc as Dc, centerX as Number, centerY as Number, baseRadius as Numeric, hour as Number) as Void {
        var heading = Activity.getActivityInfo().currentHeading;
        var headingString = (heading != null) ? headingToCardinal(heading) : "--";

        var p = centeredTextPoint(dc, centerX, centerY, baseRadius, hour, headingString, _smallFont);

        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(p[0], p[1], _smallFont, headingString,
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
    function drawHeartRate(dc as Dc, centerX as Number, centerY as Number, baseRadius as Numeric, hour as Number) as Void {
        var heartRate = Activity.getActivityInfo().currentHeartRate;
        var heartRateString = (heartRate != null) ? heartRate.toString() : "--";

        var p = iconTextPoint(dc, centerX, centerY, baseRadius, hour, 14, 10, 8, heartRateString, _smallFont);
        var x = p[0];
        var y = p[1];

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

    // ---- Bluetooth connection status to the phone, at the 3-position ----
    function drawBluetoothStatus(dc as Dc, centerX as Number, centerY as Number, baseRadius as Numeric, hour as Number) as Void {
        var connected = System.getDeviceSettings().phoneConnected;
        var p = iconPoint(dc, centerX, centerY, baseRadius, hour, 7);

        if (connected) {
            drawBluetoothIcon(dc, p[0], p[1]);
        } else {
            drawDisconnectedIcon(dc, p[0], p[1]);
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

    // ---- Home Assistant connection status, at the 9-position ----
    // Populated by HAStatusServiceDelegate's periodic background check
    // (Storage["ha_connected"]) - a watch face's foreground code cannot
    // make network requests itself.
    function drawHomeAssistantStatus(dc as Dc, centerX as Number, centerY as Number, baseRadius as Numeric, hour as Number) as Void {
        var connected = Storage.getValue("ha_connected");
        var p = iconPoint(dc, centerX, centerY, baseRadius, hour, 7);

        if (connected == true) {
            drawHouseIcon(dc, p[0], p[1]);
        } else {
            drawDisconnectedIcon(dc, p[0], p[1]);
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

    // ---- Current weather condition icon and temperature (Celsius), at the 5-position ----
    // Returns the anchor point used, so the pressure readout at the mirrored
    // 7-position can align its row to this one.
    function drawWeather(dc as Dc, centerX as Number, centerY as Number, baseRadius as Numeric, hour as Number) as Array<Number> {
        var conditions = Weather.getCurrentConditions();
        var temperature = (conditions != null) ? conditions.temperature : null;
        var condition = (conditions != null) ? conditions.condition : null;
        var tempString = (temperature != null) ? temperature.format("%d") + "°" : "--°";

        var p = iconTextPoint(dc, centerX, centerY, baseRadius, hour, 14, 9, 8, tempString, _smallFont);
        var x = p[0];
        var y = p[1];

        drawWeatherIcon(dc, x - 14, y, condition);

        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + 8, y, _smallFont, tempString,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        return p;
    }

    function drawWeatherIcon(dc as Dc, cx as Numeric, cy as Numeric, condition as Number?) as Void {
        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);

        if (condition == null) {
            dc.drawText(cx, cy, _smallFont, "?", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else if (isRainCondition(condition)) {
            drawCloudShape(dc, cx, cy - 2);
            dc.drawLine(cx - 4, cy + 5, cx - 6, cy + 9);
            dc.drawLine(cx + 1, cy + 5, cx - 1, cy + 9);
            dc.drawLine(cx + 6, cy + 5, cx + 4, cy + 9);
        } else if (isSnowCondition(condition)) {
            drawCloudShape(dc, cx, cy - 2);
            dc.fillCircle(cx - 5, cy + 8, 1);
            dc.fillCircle(cx, cy + 9, 1);
            dc.fillCircle(cx + 5, cy + 8, 1);
        } else if (isStormCondition(condition)) {
            drawCloudShape(dc, cx, cy - 3);
            var bolt = [
                [cx + 1, cy + 3],
                [cx - 3, cy + 9],
                [cx, cy + 9],
                [cx - 2, cy + 13],
                [cx + 4, cy + 6],
                [cx + 1, cy + 6]
            ];
            dc.fillPolygon(bolt);
        } else if (isCloudyCondition(condition)) {
            drawCloudShape(dc, cx, cy);
        } else {
            // Clear / fair / sunny
            dc.fillCircle(cx, cy, 5);
            dc.drawLine(cx, cy - 9, cx, cy - 6);
            dc.drawLine(cx, cy + 6, cx, cy + 9);
            dc.drawLine(cx - 9, cy, cx - 6, cy);
            dc.drawLine(cx + 6, cy, cx + 9, cy);
        }
    }

    function drawCloudShape(dc as Dc, cx as Numeric, cy as Numeric) as Void {
        dc.fillCircle(cx - 4, cy, 4);
        dc.fillCircle(cx + 3, cy - 1, 5);
        dc.fillRectangle(cx - 6, cy, 15, 4);
    }

    function isRainCondition(condition as Number) as Boolean {
        return condition == Weather.CONDITION_RAIN || condition == Weather.CONDITION_LIGHT_RAIN
            || condition == Weather.CONDITION_HEAVY_RAIN || condition == Weather.CONDITION_SHOWERS
            || condition == Weather.CONDITION_LIGHT_SHOWERS || condition == Weather.CONDITION_HEAVY_SHOWERS
            || condition == Weather.CONDITION_SCATTERED_SHOWERS || condition == Weather.CONDITION_DRIZZLE
            || condition == Weather.CONDITION_CHANCE_OF_SHOWERS || condition == Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN
            || condition == Weather.CONDITION_FREEZING_RAIN || condition == Weather.CONDITION_UNKNOWN_PRECIPITATION;
    }

    function isSnowCondition(condition as Number) as Boolean {
        return condition == Weather.CONDITION_SNOW || condition == Weather.CONDITION_LIGHT_SNOW
            || condition == Weather.CONDITION_HEAVY_SNOW || condition == Weather.CONDITION_FLURRIES
            || condition == Weather.CONDITION_CHANCE_OF_SNOW || condition == Weather.CONDITION_CLOUDY_CHANCE_OF_SNOW
            || condition == Weather.CONDITION_ICE_SNOW || condition == Weather.CONDITION_SLEET
            || condition == Weather.CONDITION_WINTRY_MIX || condition == Weather.CONDITION_RAIN_SNOW
            || condition == Weather.CONDITION_LIGHT_RAIN_SNOW || condition == Weather.CONDITION_HEAVY_RAIN_SNOW
            || condition == Weather.CONDITION_CHANCE_OF_RAIN_SNOW || condition == Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN_SNOW;
    }

    function isStormCondition(condition as Number) as Boolean {
        return condition == Weather.CONDITION_THUNDERSTORMS || condition == Weather.CONDITION_SCATTERED_THUNDERSTORMS
            || condition == Weather.CONDITION_CHANCE_OF_THUNDERSTORMS;
    }

    function isCloudyCondition(condition as Number) as Boolean {
        return condition == Weather.CONDITION_PARTLY_CLOUDY || condition == Weather.CONDITION_MOSTLY_CLOUDY
            || condition == Weather.CONDITION_CLOUDY || condition == Weather.CONDITION_THIN_CLOUDS
            || condition == Weather.CONDITION_HAZY || condition == Weather.CONDITION_FOG
            || condition == Weather.CONDITION_MIST || condition == Weather.CONDITION_HAZE
            || condition == Weather.CONDITION_DUST || condition == Weather.CONDITION_SMOKE
            || condition == Weather.CONDITION_VOLCANIC_ASH || condition == Weather.CONDITION_SAND
            || condition == Weather.CONDITION_SANDSTORM || condition == Weather.CONDITION_WINDY
            || condition == Weather.CONDITION_TORNADO || condition == Weather.CONDITION_HURRICANE
            || condition == Weather.CONDITION_TROPICAL_STORM || condition == Weather.CONDITION_SQUALL
            || condition == Weather.CONDITION_HAIL || condition == Weather.CONDITION_ICE
            || condition == Weather.CONDITION_UNKNOWN;
    }

    // Not every device's compiled API includes the CurrentConditions.pressure
    // field (added in API 5.1.0, after this app's declared 5.0.0 minimum), so
    // this must be feature-detected with `has` rather than accessed directly -
    // otherwise it throws a runtime Symbol Not Found error on those devices.
    function getPressurePa(conditions as Weather.CurrentConditions?) as Float? {
        if (conditions != null && (conditions has :pressure)) {
            return conditions.pressure;
        }
        return null;
    }

    // ---- Current atmospheric pressure in kPa, at the 7-position ----
    // alignY pins this row to the same height as the weather indicator at the
    // mirrored 5-position, since the two are meant to read as a pair.
    function drawPressure(dc as Dc, centerX as Number, centerY as Number, baseRadius as Numeric, hour as Number, alignY as Number) as Void {
        var conditions = Weather.getCurrentConditions();
        var pressurePa = getPressurePa(conditions);
        var pressureString = (pressurePa != null) ? (pressurePa / 1000.0).format("%.1f") + "kpa" : "--kpa";

        var p = centeredTextPoint(dc, centerX, centerY, baseRadius, hour, pressureString, _tinyFont);
        var charWidth = dc.getTextWidthInPixels("0", _tinyFont);
        var direction = (centerX > p[0]) ? 1 : -1;
        var x = p[0] + (2 * charWidth * direction);
        var y = alignY;

        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, _tinyFont, pressureString,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // ---- Forecast atmospheric pressure trend arrow, at the 6-position ----
    // Pressure has no forecast trend field in the Weather API, so this tracks
    // a reference reading in Storage and re-derives the trend every
    // PRESSURE_TREND_WINDOW_SECONDS by comparing against the current reading.
    function drawPressureTrend(dc as Dc, centerX as Number, centerY as Number, baseRadius as Numeric, hour as Number) as Void {
        var conditions = Weather.getCurrentConditions();
        var pressurePa = getPressurePa(conditions);
        updatePressureTrend(pressurePa);

        var trend = Storage.getValue("pressure_trend") as String?;
        var p = iconPoint(dc, centerX, centerY, baseRadius, hour, 7);

        drawPressureTrendIcon(dc, p[0], p[1], trend);
    }

    function updatePressureTrend(pressurePa as Float?) as Void {
        if (pressurePa == null) {
            return;
        }

        var now = Time.now().value();
        var refTime = Storage.getValue("pressure_ref_time") as Number?;
        var refValue = Storage.getValue("pressure_ref_value") as Float?;

        if (refTime == null || refValue == null) {
            Storage.setValue("pressure_ref_time", now);
            Storage.setValue("pressure_ref_value", pressurePa);
            return;
        }

        if (now - refTime >= PRESSURE_TREND_WINDOW_SECONDS) {
            var delta = pressurePa - refValue;
            var trend = "flat";
            if (delta > PRESSURE_TREND_THRESHOLD_PA) {
                trend = "up";
            } else if (delta < -PRESSURE_TREND_THRESHOLD_PA) {
                trend = "down";
            }
            Storage.setValue("pressure_trend", trend);
            Storage.setValue("pressure_ref_time", now);
            Storage.setValue("pressure_ref_value", pressurePa);
        }
    }

    function drawPressureTrendIcon(dc as Dc, cx as Numeric, cy as Numeric, trend as String?) as Void {
        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);

        if (trend == null || trend.equals("flat")) {
            dc.drawLine(cx - 6, cy, cx + 6, cy);
        } else if (trend.equals("up")) {
            dc.drawLine(cx, cy - 6, cx, cy + 6);
            dc.drawLine(cx, cy - 6, cx - 4, cy - 2);
            dc.drawLine(cx, cy - 6, cx + 4, cy - 2);
        } else {
            dc.drawLine(cx, cy - 6, cx, cy + 6);
            dc.drawLine(cx, cy + 6, cx - 4, cy + 2);
            dc.drawLine(cx, cy + 6, cx + 4, cy + 2);
        }
    }

    // ---- Date, DD/MM, at the 11-position ----
    // Returns the anchor point used, so the steps counter at the mirrored
    // 1-position can align its row to this one.
    function drawDate(dc as Dc, centerX as Number, centerY as Number, baseRadius as Numeric, hour as Number) as Array<Number> {
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dateString = Lang.format("$1$/$2$", [today.day.format("%02d"), today.month.format("%02d")]);

        var p = centeredTextPoint(dc, centerX, centerY, baseRadius, hour, dateString, _smallFont);

        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(p[0], p[1], _smallFont, dateString,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        return p;
    }

}
