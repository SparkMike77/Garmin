import Toybox.Lang;
import Toybox.WatchUi;

class HAControlDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() as Boolean {
        WatchUi.pushView(new Rez.Menus.DeviceMenu(), new HAControlMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    function onMenu() as Boolean {
        return onSelect();
    }

}
