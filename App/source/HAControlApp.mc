import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class HAControlApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new Rez.Menus.DeviceMenu(), new HAControlMenuDelegate() ];
    }

}

function getApp() as HAControlApp {
    return Application.getApp() as HAControlApp;
}
