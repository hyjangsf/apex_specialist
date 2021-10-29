@isTest
private class MaintenanceRequestHelperTest {
    // implement scheduled code here

    // <<Test automation logic>>
    // Build tests for all cases (positive, negative, and bulk) specified in the business requirements

    //
    // 100% test coverage Required
    // assert values to prove
    // Choose Run All Tests in the Developer Console at least once
    @isTest
    private static void testPositive() {
        // positive

        // prepare test records
        Map<Integer, Case> testReqMap = new Map<Integer, Case>();
        for (Integer i = 0; i < 3; i++) {
            Case mReq = new Case(Status = 'New', Subject = 'Test Record ' + i, Type = 'Repair', Origin = 'Phone');
            testReqMap.put(i, mReq);
        }
        insert testReqMap.values();

        Map<Integer, List<Equipment_Maintenance_Item__c>> testEmiMap = new Map<Integer, List<Equipment_Maintenance_Item__c>>();
        List<Equipment_Maintenance_Item__c> emiList = new List<Equipment_Maintenance_Item__c>();
        for (Integer i = 0; i < 300; i++) {
            emiList.add(
                new Equipment_Maintenance_Item__c(
                    Maintenance_Request__c = testReqMap.get(i).Id,
                    Equipment__c = '01t5j000001hzyuAAA'
                )
            );

            emiList.add(
                new Equipment_Maintenance_Item__c(
                    Maintenance_Request__c = testReqMap.get(i).Id,
                    Equipment__c = '01t5j000000dF62AAE'
                )
            );

            testReqMap.get(i).status = 'Closed';
        }
        insert emiList;
        update testReqMap.values();

        List<Case> newReqs = [
            SELECT Id, Vehicle__c, Date_Due__c
            FROM Case
            WHERE Subject LIKE 'New Maintenance Request For%'
        ];
        Id[] newReqIds = null;
        for (Case nReq : newReqs) {
            newReqIds.add(nReq.Id);
        }
        // EMI Required Fields : Maintenance_Request__c, Equipment__c
        List<Equipment_Maintenance_Item__c> newEmis = [
            SELECT Id, Maintenance_Request__c, Equipment__c
            FROM Equipment_Maintenance_Item__c
            WHERE Maintenance_Request__c IN :newReqIds
        ];

        for (Integer i = 0; i < newReqs.size() - 1; i++) {
            String findKey = 'Test Record ' + i;
            Case nReq = null;
            String strEmiList = '';
            String strEmiListComp = '';

            for (Case req : newReqs) {
                nReq = req.Subject.contains(findKey) ? req : null;
            }
            // Assertion : vehicle ,equipment relationship, due date
            System.assertEquals(testReqMap.get(i).Vehicle__c, nReq.Vehicle__c, 'Vehicle is not Equal_' + i);
            System.assertEquals(testReqMap.get(i).Date_Due__c, nReq.Date_Due__c, 'Due Date is not Equal_' + i);

            for (Integer j = 0; j < testEmiMap.get(i).size() - 1; j++) {
                if (newEmis.get(j).Maintenance_Request__c == findKey) {
                    System.assertEquals(
                        testEmiMap.get(i).get(j).Equipment__c,
                        newEmis.get(j).Equipment__c,
                        'Referenced Equipment is not Equal_' + i
                    );
                }
            }
        }

        // neg - no work orders were created
    }
}
