@isTest
private class MaintenanceRequestHelperTest {
    private static final Integer TESTQUANTITY = 3;

    // implement scheduled code here
    @isTest
    private static void testPositive() {
        // positive

        // Test data setup
        Map<Integer, Case> testReqMap = new Map<Integer, Case>();

        for (Integer i = 0; i < TESTQUANTITY; i++) {
            testReqMap.put(
                i,
                new Case(
                    Status = 'New',
                    Subject = 'Test Record ' + i,
                    Type = 'Repair',
                    Origin = 'Phone',
                    Vehicle__c = 'a025j000001LeIZAA0',
                    Date_Due__c = System.today()
                )
            );
        }

        insert testReqMap.values();

        Product2 testEq = new Product2(Name = 'TestEquipment', Replacement_Part__c = true, Maintenance_Cycle__c = 30);
        insert testEq;

        Map<Integer, List<Equipment_Maintenance_Item__c>> testEmiMap = new Map<Integer, List<Equipment_Maintenance_Item__c>>();
        List<Equipment_Maintenance_Item__c> emiList = new List<Equipment_Maintenance_Item__c>();
        for (Integer i = 0; i < TESTQUANTITY; i++) {
            emiList.add(
                new Equipment_Maintenance_Item__c(Maintenance_Request__c = testReqMap.get(i).Id, Equipment__c = testEq.Id)
            );
            testEmiMap.put(i, new List<Equipment_Maintenance_Item__c>{ emiList.get(i) });
            testReqMap.get(i).status = 'Closed';
        }
        insert emiList;

        Test.startTest();
        update testReqMap.values();
        Test.stopTest();

        Date tday = System.today();
        List<Case> newReq = [
            SELECT Id, Vehicle__c, Date_Due__c
            FROM Case
            WHERE Subject LIKE 'New Maintenance Request For Test Record%'
        ];
        // Assertion Loop
        for (Integer i = 0; i < newReq.size() - 1; i++) {
            System.assertEquals('a025j000001LeIZAA0', newReq.get(i).Vehicle__c, 'Vehicle is not Equal_' + i);
            System.assertEquals(System.today() + 30, newReq.get(i).Date_Due__c, 'Due Date is not Equal_' + i);
            for (Integer j = 0; j < testEmiMap.get(i).size() - 1; j++) {
                if (testEmiMap.get(i).get(j) != null) {
                    System.assertEquals(
                        testEq.Id,
                        testEmiMap.get(i).get(j).Equipment__c,
                        'Referenced Equipment is not Equal_' + i
                    );
                }
            }
        }
    }
    @isTest
    private static void testNegative() {
        // neg - no work orders were created
        // Test data setup
        Map<Integer, Case> testReqMap = new Map<Integer, Case>();

        for (Integer i = 0; i < TESTQUANTITY; i++) {
            testReqMap.put(
                i,
                new Case(
                    Status = 'New',
                    Subject = 'Test Record ' + i,
                    Type = 'Eloctronic',
                    Origin = 'Phone',
                    Vehicle__c = 'a025j000001LeIZAA0',
                    Date_Due__c = System.today()
                )
            );
        }

        insert testReqMap.values();

        for (Integer i = 0; i < TESTQUANTITY; i++) {
            testReqMap.get(i).status = 'Closed';
        }
        Test.startTest();
        update testReqMap.values();
        Test.stopTest();
    }
}
