import Toybox.Application.Properties;
import Toybox.Background;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.System;

// Runs periodically (see HAWatchFaceApp's temporal event registration) to
// check whether Home Assistant is reachable. Only background execution
// contexts are allowed to make network requests - a watch face's normal
// foreground code cannot call Communications directly.
(:background)
class HAStatusServiceDelegate extends System.ServiceDelegate {

    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
        var url = Properties.getValue("ha_url") as String?;
        var token = Properties.getValue("ha_token") as String?;

        if (url == null || url.equals("") || token == null || token.equals("")) {
            Background.exit(false);
            return;
        }

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Authorization" => "Bearer " + token
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url + "/api/", {}, options, method(:onReceive));
    }

    function onReceive(responseCode as Number, data as Dictionary?) as Void {
        Background.exit(responseCode == 200);
    }

}
