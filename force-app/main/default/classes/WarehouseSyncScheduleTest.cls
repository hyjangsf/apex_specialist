@isTest
private with sharing class WarehouseSyncScheduleTest {
    // implement scheduled code here
    public static String CRON_EXP = '0 0 1 * * ?';
    static testMethod void testScheduledJob() {
        WarehouseCalloutService wcs = new WarehouseCalloutService();
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock());
        Test.startTest();
        Id schId = System.schedule('WarehouseSyncSchedule', CRON_EXP, new WarehouseSyncSchedule());
        Test.stopTest();
        System.assert(schId != null);
    }
}
