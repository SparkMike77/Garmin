import Toybox.Lang;
import Toybox.WatchUi;

class GarageDoorDelegate extends WatchUi.BehaviorDelegate {

    hidden var _view as GarageDoorView;

    function initialize(view as GarageDoorView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onTap(clickEvent as ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();
        var x = coords[0];
        var y = coords[1];

        if (GarageDoorView.isPointInRect(x, y, GarageDoorView.getUpButtonRect())) {
            _view.sendCommand("open_cover", "Opening...");
            return true;
        }

        if (GarageDoorView.isPointInRect(x, y, GarageDoorView.getDownButtonRect())) {
            _view.sendCommand("close_cover", "Closing...");
            return true;
        }

        return false;
    }

}
