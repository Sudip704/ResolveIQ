@IsTest
private class ShipmentTrackingActionTest {

    private class MockLogistics implements HttpCalloutMock {
        private Integer code;
        private String body;
        private Boolean throwError;
        MockLogistics(Integer code, String body, Boolean throwError) {
            this.code = code; this.body = body; this.throwError = throwError;
        }
        public HttpResponse respond(HttpRequest req) {
            if (throwError) {
                throw new CalloutException('Read timed out');
            }
            HttpResponse res = new HttpResponse();
            res.setStatusCode(code);
            res.setBody(body);
            return res;
        }
    }

    private static String bodyWithEta(Date eta) {
        return JSON.serialize(new Map<String, Object>{
            'trackingNumber' => 'TRK1',
            'status' => 'IN_TRANSIT',
            'estimatedDelivery' => eta,
            'events' => new List<Object>{
                new Map<String, Object>{
                    'timestamp' => Datetime.now(),
                    'description' => 'Held at regional hub'
                }
            }
        });
    }

    @TestSetup
    static void setup() {
        Account a = new Account(Name = 'Test Account');
        insert a;
        insert new Shipment__c(
            Account__c = a.Id,
            Tracking_Number__c = 'TRK1',
            Carrier_Code__c = 'UPS',
            Promised_Date__c = Date.today().addDays(-2)
        );
    }

    private static ShipmentTrackingAction.Request buildRequest() {
        Shipment__c s = [SELECT Id FROM Shipment__c LIMIT 1];
        ShipmentTrackingAction.Request r = new ShipmentTrackingAction.Request();
        r.trackingNumber = 'TRK1';
        r.carrierCode = 'UPS';
        r.shipmentId = s.Id;
        return r;
    }

    @IsTest
    static void confirmsDelayWhenEtaAfterPromise() {
        Test.setMock(HttpCalloutMock.class,
            new MockLogistics(200, bodyWithEta(Date.today().addDays(3)), false));
        Test.startTest();
        List<ShipmentTrackingAction.Response> out =
            ShipmentTrackingAction.getTracking(new List<ShipmentTrackingAction.Request>{ buildRequest() });
        Test.stopTest();

        System.assertEquals(true, out[0].success);
        System.assertEquals(true, out[0].delayConfirmed);
        System.assertEquals(5, out[0].daysLate);
        Shipment__c s = [SELECT Carrier_Status__c, Last_Synced__c FROM Shipment__c LIMIT 1];
        System.assertEquals('IN_TRANSIT', s.Carrier_Status__c);
        System.assertNotEquals(null, s.Last_Synced__c);
    }

    @IsTest
    static void noDelayWhenEtaOnOrBeforePromise() {
        Test.setMock(HttpCalloutMock.class,
            new MockLogistics(200, bodyWithEta(Date.today().addDays(-2)), false));
        Test.startTest();
        List<ShipmentTrackingAction.Response> out =
            ShipmentTrackingAction.getTracking(new List<ShipmentTrackingAction.Request>{ buildRequest() });
        Test.stopTest();

        System.assertEquals(true, out[0].success);
        System.assertEquals(false, out[0].delayConfirmed);
        System.assertEquals(0, out[0].daysLate);
    }

    @IsTest
    static void returnsSafeErrorOnNotFound() {
        Test.setMock(HttpCalloutMock.class, new MockLogistics(404, '{}', false));
        Test.startTest();
        List<ShipmentTrackingAction.Response> out =
            ShipmentTrackingAction.getTracking(new List<ShipmentTrackingAction.Request>{ buildRequest() });
        Test.stopTest();

        System.assertEquals(false, out[0].success);
        System.assertEquals(false, out[0].delayConfirmed);
        System.assert(out[0].errorMessage.contains('not found'));
    }

    @IsTest
    static void returnsSafeErrorOnServerFailure() {
        Test.setMock(HttpCalloutMock.class, new MockLogistics(500, 'boom', false));
        Test.startTest();
        List<ShipmentTrackingAction.Response> out =
            ShipmentTrackingAction.getTracking(new List<ShipmentTrackingAction.Request>{ buildRequest() });
        Test.stopTest();

        System.assertEquals(false, out[0].success);
        System.assert(out[0].errorMessage.contains('500'));
    }

    @IsTest
    static void handlesTimeoutWithoutThrowing() {
        Test.setMock(HttpCalloutMock.class, new MockLogistics(0, '', true));
        Test.startTest();
        List<ShipmentTrackingAction.Response> out =
            ShipmentTrackingAction.getTracking(new List<ShipmentTrackingAction.Request>{ buildRequest() });
        Test.stopTest();

        System.assertEquals(false, out[0].success);
        System.assert(out[0].errorMessage.contains('unavailable'));
    }

    @IsTest
    static void rejectsBlankInputs() {
        ShipmentTrackingAction.Request r = buildRequest();
        r.trackingNumber = null;
        Test.startTest();
        List<ShipmentTrackingAction.Response> out =
            ShipmentTrackingAction.getTracking(new List<ShipmentTrackingAction.Request>{ r });
        Test.stopTest();

        System.assertEquals(false, out[0].success);
    }

    @IsTest
    static void handlesBulkRequests() {
        Test.setMock(HttpCalloutMock.class,
            new MockLogistics(200, bodyWithEta(Date.today().addDays(1)), false));
        List<ShipmentTrackingAction.Request> reqs = new List<ShipmentTrackingAction.Request>();
        for (Integer i = 0; i < 3; i++) {
            reqs.add(buildRequest());
        }
        Test.startTest();
        List<ShipmentTrackingAction.Response> out = ShipmentTrackingAction.getTracking(reqs);
        Test.stopTest();

        System.assertEquals(3, out.size());
        for (ShipmentTrackingAction.Response r : out) {
            System.assertEquals(true, r.success);
        }
    }
}
