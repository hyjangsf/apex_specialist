@isTest
private class WarehouseCalloutServiceTest {
    // implement your mock callout test here
    @isTest
    static void testCallout() {
        WarehouseCalloutService wcs = new WarehouseCalloutService();
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock());

        Test.startTest();
        System.enqueueJob(wcs);
        Test.stopTest();

        Product2 testEq = [SELECT Id, Name FROM Product2 WHERE ExternalId = '1234567'];
        System.assertEquals('Test Equipment', testEq.Name);
    }
}
