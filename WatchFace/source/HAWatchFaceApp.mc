import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

class HAWatchFaceApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        if (Background.getTemporalEventRegisteredTime() == null) {
            Background.registerForTemporalEvent(new Time.Duration(5 * 60));
        }
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new HAWatchFaceView() ];
    }

    function getServiceDelegate() as [System.ServiceDelegate] {
        return [ new HAStatusServiceDelegate() ];
    }

    // Called with the Boolean result from HAStatusServiceDelegate.onTemporalEvent
    // once the background network check completes.
    function onBackgroundData(data as Application.PersistableType) as Void {
        Storage.setValue("ha_connected", data);
        WatchUi.requestUpdate();
    }

}

function getApp() as HAWatchFaceApp {
    return Application.getApp() as HAWatchFaceApp;
}
