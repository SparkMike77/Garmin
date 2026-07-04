import Toybox.Application;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class HAControlMenuDelegate extends WatchUi.MenuInputDelegate {

    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :item_garage_door) {
            var view = new GarageDoorView();
            WatchUi.pushView(view, new GarageDoorDelegate(view), WatchUi.SLIDE_LEFT);
        } else if (item == :item_lights) {
            var entityId = Properties.getValue("ha_light_entity") as String;
            HomeAssistantClient.callService("light", "toggle", entityId, method(:onLightToggleResult));
        }
    }

    function onLightToggleResult(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode == -1) {
            System.println("Lights: ha_url/ha_token not configured");
        } else if (responseCode == 200) {
            System.println("Lights toggled");
        } else {
            System.println("Lights toggle failed: " + responseCode.toString());
        }
    }

}
