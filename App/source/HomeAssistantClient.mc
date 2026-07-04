import Toybox.Application;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.System;

// Thin wrapper around the Home Assistant REST API.
// Requires the "ha_url" and "ha_token" properties to be set via the
// app's settings screen in Garmin Connect Mobile (Settings > Home Assistant URL /
// Long-Lived Access Token). Never hardcode real values here - they're
// read from Properties so they stay out of source control.
class HomeAssistantClient {

    // Call a Home Assistant service, e.g. callService("cover", "open_cover", "cover.garage_door", callback)
    // callback receives (responseCode as Number, data as Dictionary or Null).
    // responseCode -1 means the client isn't configured yet (no URL/token set).
    static function callService(domain as String, service as String, entityId as String, callback as Method) as Void {
        var base = baseUrl();
        var token = Properties.getValue("ha_token") as String?;

        if (base == null || base.equals("") || token == null || token.equals("")) {
            System.println("HomeAssistantClient: ha_url/ha_token not configured");
            callback.invoke(-1, null);
            return;
        }

        var url = base + "/api/services/" + domain + "/" + service;
        var params = { "entity_id" => entityId };
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
                "Authorization" => "Bearer " + token
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, params, options, callback);
    }

    // Fetch the current state of an entity, e.g. getState("cover.garage_door", callback)
    // callback receives (responseCode as Number, data as Dictionary or Null).
    // On success, data["state"] holds the state string (e.g. "open", "closed", "on", "off").
    static function getState(entityId as String, callback as Method) as Void {
        var base = baseUrl();
        var token = Properties.getValue("ha_token") as String?;

        if (base == null || base.equals("") || token == null || token.equals("")) {
            System.println("HomeAssistantClient: ha_url/ha_token not configured");
            callback.invoke(-1, null);
            return;
        }

        var url = base + "/api/states/" + entityId;
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Authorization" => "Bearer " + token
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    // Strips a trailing slash so "/api/..." concatenation never double-slashes.
    private static function baseUrl() as String? {
        var url = Properties.getValue("ha_url") as String?;
        if (url == null || url.equals("")) {
            return null;
        }
        if (url.substring(url.length() - 1, url.length()).equals("/")) {
            return url.substring(0, url.length() - 1);
        }
        return url;
    }

}
