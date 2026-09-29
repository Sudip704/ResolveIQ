public with sharing class LogisticsClient {

    public class LogisticsException extends Exception {}

    public class TrackingEvent {
        public Datetime timestamp;
        public String description;
    }

    public class TrackingResult {
        public String trackingNumber;
        public String status;
        public Date estimatedDelivery;
        public List<TrackingEvent> events;
    }

    private static final Integer TIMEOUT_MS = 10000;

    public static TrackingResult track(String carrierCode, String trackingNumber) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Logistics_API/v1/track/'
            + EncodingUtil.urlEncode(carrierCode, 'UTF-8') + '/'
            + EncodingUtil.urlEncode(trackingNumber, 'UTF-8'));
        req.setMethod('GET');
        req.setHeader('Accept', 'application/json');
        req.setTimeout(TIMEOUT_MS);

        HttpResponse res;
        try {
            res = new Http().send(req);
        } catch (CalloutException e) {
            throw new LogisticsException('Carrier service is unavailable or timed out.');
        }

        if (res.getStatusCode() == 404) {
            throw new LogisticsException('Tracking number not found with the carrier.');
        }
        if (res.getStatusCode() < 200 || res.getStatusCode() > 299) {
            throw new LogisticsException(
                'Carrier service returned an error (' + res.getStatusCode() + ').');
        }

        try {
            return (TrackingResult) JSON.deserialize(res.getBody(), TrackingResult.class);
        } catch (JSONException e) {
            throw new LogisticsException('Carrier response could not be read.');
        }
    }
}
