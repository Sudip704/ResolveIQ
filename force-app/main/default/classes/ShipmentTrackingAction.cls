public with sharing class ShipmentTrackingAction {

    private static final Integer MAX_REQUESTS = 20; // stay well under the 100-callout limit

    public class Request {
        @InvocableVariable(label='Tracking Number'
            description='Carrier tracking number from the Shipment record' required=true)
        public String trackingNumber;

        @InvocableVariable(label='Carrier Code'
            description='Carrier code such as UPS, FEDEX or DHL' required=true)
        public String carrierCode;

        @InvocableVariable(label='Shipment Id'
            description='Salesforce Id of the Shipment__c record' required=true)
        public Id shipmentId;
    }

    public class Response {
        @InvocableVariable(label='Success') public Boolean success;
        @InvocableVariable(label='Carrier Status') public String carrierStatus;
        @InvocableVariable(label='Estimated Delivery') public Date estimatedDelivery;
        @InvocableVariable(label='Days Late') public Integer daysLate;
        @InvocableVariable(label='Delay Confirmed') public Boolean delayConfirmed;
        @InvocableVariable(label='Last Event') public String lastEvent;
        @InvocableVariable(label='Error Message') public String errorMessage;
    }

    @InvocableMethod(
        label='Get Shipment Tracking'
        description='Fetches live carrier tracking for a shipment and reports whether it is late versus the promised date. Use before offering any delay credit.'
        category='Logistics'
        callout=true
    )
    public static List<Response> getTracking(List<Request> requests) {
        List<Response> results = new List<Response>();
        if (requests == null || requests.isEmpty()) {
            return results;
        }

        Set<Id> shipmentIds = new Set<Id>();
        for (Request r : requests) {
            if (r.shipmentId != null) {
                shipmentIds.add(r.shipmentId);
            }
        }
        Map<Id, Shipment__c> shipments = new Map<Id, Shipment__c>([
            SELECT Id, Promised_Date__c
            FROM Shipment__c
            WHERE Id IN :shipmentIds
            WITH USER_MODE
        ]);

        List<Shipment__c> toUpdate = new List<Shipment__c>();
        Integer processed = 0;
        for (Request req : requests) {
            if (processed >= MAX_REQUESTS) {
                results.add(failure('Too many tracking requests in one call.'));
                continue;
            }
            processed++;
            results.add(processOne(req, shipments, toUpdate));
        }

        // DML only after all callouts are finished
        if (!toUpdate.isEmpty()) {
            Database.update(toUpdate, false, AccessLevel.USER_MODE);
        }
        return results;
    }

    private static Response processOne(
        Request req, Map<Id, Shipment__c> shipments, List<Shipment__c> toUpdate
    ) {
        if (String.isBlank(req.trackingNumber) || String.isBlank(req.carrierCode)) {
            return failure('Tracking number and carrier code are required.');
        }
        Shipment__c shipment = shipments.get(req.shipmentId);
        if (shipment == null) {
            return failure('Shipment not found or not accessible.');
        }

        try {
            LogisticsClient.TrackingResult tr =
                LogisticsClient.track(req.carrierCode, req.trackingNumber);

            Response res = new Response();
            res.success = true;
            res.carrierStatus = tr.status;
            res.estimatedDelivery = tr.estimatedDelivery;
            res.lastEvent = (tr.events == null || tr.events.isEmpty())
                ? null : tr.events[tr.events.size() - 1].description;

            Integer late = 0;
            if (tr.estimatedDelivery != null && shipment.Promised_Date__c != null) {
                late = shipment.Promised_Date__c.daysBetween(tr.estimatedDelivery);
            }
            res.daysLate = Math.max(late, 0);
            res.delayConfirmed = res.daysLate > 0;

            toUpdate.add(new Shipment__c(
                Id = shipment.Id,
                Carrier_Status__c = tr.status,
                Estimated_Delivery__c = tr.estimatedDelivery,
                Last_Event__c = res.lastEvent,
                Last_Synced__c = Datetime.now()
            ));
            return res;
        } catch (LogisticsClient.LogisticsException e) {
            return failure(e.getMessage()); // already sanitized, safe for the model
        }
    }

    private static Response failure(String message) {
        Response res = new Response();
        res.success = false;
        res.delayConfirmed = false;
        res.errorMessage = message;
        return res;
    }
}
