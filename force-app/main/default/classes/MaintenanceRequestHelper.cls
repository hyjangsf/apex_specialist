public with sharing class MaintenanceRequestHelper {
    public void updateWorkOrders(List<Case> updList) {
        // TODO: Complete the method to update workorders

        // TODO - Required
        // 1. Maintenance Request(Case) 레코드 중 Repair 혹은 Routine Maintenance 타입이
        // Closed될 시, 새 Maintenance Request 레코드를 생성 - 미래의 루틴을 확인하기 위해
        // 2. 새 레코드에 대한 요구 조건
        //   1) 기존 기준이 되는 레코드와 같은 Vehicle과 Equipment(Product2) 레코드를 참조해야 함
        //   2) Type은 Routine Maintenance
        //   3) Subject는 Null이 아니어야 함
        //   4) Report Date 필드는 이 레코드 생성일로 채움 - the request가 기존 request얘기인가?
        //   5) 기존 레코드가 참조하는 Equipment의 Maintenance Cycle중 가장 짧은 Cycle을 이용해 Due Date 산정
        //
        // 3. 모든 과정은 Bulk로 작동하도록 설계

        // *** Setup

        // * Id List to use For WHERE Clause of SOQL
        List<Id> mainReqIdList = new List<Id>();
        List<Id> mainReqVehList = new List<Id>();
        for (Case cs : updList) {
            mainReqIdList.add(cs.Id);
            if (cs.Vehicle__c != null) {
                mainReqVehList.add(cs.Vehicle__c);
            }
        }

        // * Get 'Equipment Maintenance Item' List
        List<Equipment_Maintenance_Item__c> emiList = [
            SELECT Equipment__c, Maintenance_Request__c, Quantity__c
            FROM Equipment_Maintenance_Item__c
            WHERE Maintenance_Request__c IN :mainReqIdList
        ];

        System.debug('# of Related EMI: ' + emiList.size());

        // * 'Equipment' Id List to use For WHERE Clause of SOQL
        List<Id> eqIdList = new List<Id>();
        for (Equipment_Maintenance_Item__c emi : emiList) {
            eqIdList.add(emi.Equipment__c);
        }

        // * Get 'Equipment' List To Get Equip's Maintenance Cycle
        List<Product2> eqList = [SELECT Name, Maintenance_Cycle__c FROM Product2 WHERE Id IN :eqIdList];

        // * Get 'Vehicle' List To Assign to New Maintenance Request
        List<Vehicle__c> vcList = [SELECT Id FROM Vehicle__c WHERE Id IN :mainReqVehList];

        // 새 'Maintenance Request' List
        List<Case> newReqList = new List<Case>();

        // Equipment Maintenance List Related w/ Original Maintenance Request Record
        List<Equipment_Maintenance_Item__c> relatedEmiList = new List<Equipment_Maintenance_Item__c>();

        // * 각 Maintenance Request 별 처리
        for (Case cs : updList) {
            if ((cs.Type == 'Repair' || cs.Type == 'Routine Maintenance') && cs.Status == 'Closed') {
                List<Product2> relatedEqList = new List<Product2>();

                // * To Calculate Due Date of Request
                Integer shortest = 0;

                // * Get related 'Equipment Maintenance Item' List
                for (Equipment_Maintenance_Item__c emi : emiList) {
                    if (emi.Maintenance_Request__c == cs.Id) {
                        relatedEmiList.add(emi);
                        System.debug('Related Equipment Maintenance Item Record Detected');
                    }
                }

                // * Get related 'Equipment' List
                for (Equipment_Maintenance_Item__c emi : relatedEmiList) {
                    for (Product2 eq : eqList) {
                        if (emi.Equipment__c == eq.Id) {
                            System.debug('Related Equipment Detected: ' + eq.Name);
                            relatedEqList.add(eq);
                        }
                    }
                }

                // * Find Shortest Maintenance Cycle(date)
                if (relatedEqList.size() > 0) {
                    for (Product2 eq : relatedEqList) {
                        if (shortest == 0 || eq.Maintenance_Cycle__c < shortest) {
                            shortest = Integer.valueOf(eq.Maintenance_Cycle__c);
                        }
                    }
                }

                // 2. 새 레코드에 대한 요구 조건에 맞추어 생성
                Case newMainReq = new Case(
                    Subject = 'New Maintenance Request by \'' + cs.Subject + '\'',
                    Date_Reported__c = System.today(),
                    Date_Due__c = System.today().addDays(shortest),
                    Type = 'Routine Maintenance',
                    Vehicle__c = cs.Vehicle__c
                );

                newReqList.add(newMainReq);
            }
        } // for문 끝(Trigger에서 받은 Update된 Maintenance Request)

        // * 새 Maintenance Request 생성
        insert newReqList;
        // * insert했으므로 Id값 생성됨

        // * Make Relationship - Equipment Maintenance List (Junction)
        List<Equipment_Maintenance_Item__c> newEmiList = new List<Equipment_Maintenance_Item__c>();

        System.debug('Related EMI List Size: ' + relatedEmiList.size());
        System.debug('New Request List Size: ' + newReqList.size());
        if (relatedEmiList.size() > 0) {
            for (Equipment_Maintenance_Item__c rEmi : relatedEmiList) {
                for (Case newReq : newReqList) {
                    // Maintenance_Request__c, Equipment__c, Quantity__c
                    Equipment_Maintenance_Item__c newEmi = new Equipment_Maintenance_Item__c();
                    newEmi.Maintenance_Request__c = newReq.Id;
                    newEmi.Equipment__c = rEmi.Equipment__c;
                    newEmi.Quantity__c = rEmi.Quantity__c;

                    newEmiList.add(newEmi);
                }
            }
        }
        insert newEmiList;
    } // updateWorkOrders 끝
} // Class 끝
