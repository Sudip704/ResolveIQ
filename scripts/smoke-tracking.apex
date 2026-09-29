Shipment__c s = [SELECT Id FROM Shipment__c WHERE Tracking_Number__c = 'TRK-LATE-1' LIMIT 1];
ShipmentTrackingAction.Request r = new ShipmentTrackingAction.Request();
r.trackingNumber = 'TRK-LATE-1';
r.carrierCode = 'UPS';
r.shipmentId = s.Id;
System.debug(JSON.serializePretty(ShipmentTrackingAction.getTracking(
    new List<ShipmentTrackingAction.Request>{ r })));
