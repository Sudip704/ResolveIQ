Account a = new Account(Name='Northwind Fabrication', Tier__c='Gold',
    Annual_Contract_Value__c=1200000, Churn_Risk_Score__c=72, Credits_Issued_90d__c=0);
Account b = new Account(Name='Contoso Metals', Tier__c='Standard',
    Annual_Contract_Value__c=180000, Churn_Risk_Score__c=25, Credits_Issued_90d__c=400);
insert new List<Account>{ a, b };

insert new List<Shipment__c>{
    new Shipment__c(Account__c=a.Id, Order_Number__c='SO-10482', Order_Amount__c=3700,
        Tracking_Number__c='TRK-LATE-1', Carrier_Code__c='UPS', Promised_Date__c=Date.today().addDays(-4)),
    new Shipment__c(Account__c=a.Id, Order_Number__c='SO-10500', Order_Amount__c=2000,
        Tracking_Number__c='TRK-OK-1', Carrier_Code__c='UPS', Promised_Date__c=Date.today().addDays(3)),
    new Shipment__c(Account__c=b.Id, Order_Number__c='SO-10391', Order_Amount__c=12000,
        Tracking_Number__c='TRK-BIG-1', Carrier_Code__c='FEDEX', Promised_Date__c=Date.today().addDays(-7)),
    new Shipment__c(Account__c=b.Id, Order_Number__c='SO-10600', Order_Amount__c=900,
        Tracking_Number__c='TRK-FAIL-1', Carrier_Code__c='DHL', Promised_Date__c=Date.today().addDays(-3))
};

insert new Contact(FirstName='Priya', LastName='Nair', AccountId=a.Id, Email='priya@example.com');
insert new Contact(FirstName='Marco', LastName='Reyes', AccountId=b.Id, Email='marco@example.com');
