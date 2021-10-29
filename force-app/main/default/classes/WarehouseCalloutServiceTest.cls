@IsTest
private class WarehouseCalloutServiceTest {
    // implement your mock callout test here
    @IsTest
    static void testCallout() {
        Test.setMock(WarehouseCalloutServiceMock.class, new WarehouseCalloutServiceMock());

        Test.startTest();
        WarehouseCalloutService warehouseCallout = new WarehouseCalloutService();
        String sch = '0 0 1 * * ?';
        String jobID = System.enqueueJob(warehouseCallout);
        Test.stopTest();
    }
}
