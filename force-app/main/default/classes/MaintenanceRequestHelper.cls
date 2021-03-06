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
        //   4) Report Date 필드는 이 레코드 생성일로 채움
        //   5) 기존 레코드가 참조하는 Equipment의 Maintenance Cycle중 가장 짧은 Cycle을 이용해 Due Date 산정
        //
        // 3. 모든 과정은 Bulk로 작동하도록 설계

        // *** Setup

        // * Id List to use For WHERE Clause of SOQL
        List<Id> mainReqIdList = new List<Id>();
        for (Case cs : updList) {
            mainReqIdList.add(cs.Id);
        }
        System.debug('updList(Trigger.New) Size: ' + updList.size());

        // ** SOQL Queries
        // * Get 'Equipment Maintenance Item' List
        List<Equipment_Maintenance_Item__c> emiList = [
            SELECT Equipment__c, Maintenance_Request__c
            FROM Equipment_Maintenance_Item__c
            WHERE Maintenance_Request__c IN :mainReqIdList
        ];
        System.debug('emiList ' + emiList.size());

        // * 'Equipment' Id List to use For WHERE Clause of SOQL
        List<Id> eqIdList = new List<Id>();
        for (Equipment_Maintenance_Item__c emi : emiList) {
            eqIdList.add(emi.Equipment__c);
        }

        // * Get 'Equipment' List To Get Equip's Maintenance Cycle
        List<Product2> eqList = [SELECT Name, Maintenance_Cycle__c FROM Product2 WHERE Id IN :eqIdList];

        // * Created 'Maintenance Request' List
        List<Case> newReqList = new List<Case>();

        // * Created 'Equipment Maintenance Item' List (Make Relationship)
        List<Equipment_Maintenance_Item__c> newEmiList = new List<Equipment_Maintenance_Item__c>();

        // for Map EMIs to New Maintenance Requests
        Map<Integer, List<Equipment_Maintenance_Item__c>> emiToReq = new Map<Integer, List<Equipment_Maintenance_Item__c>>();
        Integer idxOfUpd = 0;

        System.debug('Start Processing Each Requests');
        // * 각 Maintenance Request 별 처리
        for (Case cs : updList) {
            if ((cs.Type == 'Repair' || cs.Type == 'Routine Maintenance') && cs.Status == 'Closed') {
                List<Equipment_Maintenance_Item__c> relatedEmiList = new List<Equipment_Maintenance_Item__c>();
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
                    Subject = 'New Maintenance Request For \'' + cs.Subject + '\'',
                    Date_Reported__c = System.today(),
                    Date_Due__c = System.today().addDays(shortest),
                    Type = 'Routine Maintenance',
                    Vehicle__c = cs.Vehicle__c
                );
                emiToReq.put(idxOfUpd++, relatedEmiList.deepClone());
                newReqList.add(newMainReq);
            }
        } // for문 끝(Trigger에서 받은 Update된 Maintenance Request)

        // * 새 Maintenance Request 생성
        insert newReqList;

        idxOfUpd = 0;

        for (Case newReq : newReqList) {
            if (emiToReq.get(idxOfUpd) != null) {
                for (Equipment_Maintenance_Item__c rEmi : emiToReq.get(idxOfUpd)) {
                    // Maintenance_Request__c, Equipment__c
                    Equipment_Maintenance_Item__c newEmi = new Equipment_Maintenance_Item__c();
                    newEmi.Maintenance_Request__c = newReq.Id;
                    newEmi.Equipment__c = rEmi.Equipment__c;

                    newEmiList.add(newEmi);
                }
            }
            idxOfUpd++;
        }
        insert newEmiList;
    } // updateWorkOrders 끝
} // Class 끝

/*
// Best Case From Github
public class MaintenanceRequestHelper {
    
    public static void createNewRequest(Map<Id, Case> validCaseMap){
        List<Case> newCases = new List<Case>();
        Map<Id, Integer> productMaintenanceCycleMap = new Map<Id, Integer>();
        Map<Id, Integer> workPartMaintenanceCycleMap = new Map<Id, Integer>();
        
		for (Product2 productHere : [select Id, Maintenance_Cycle__c from Product2]) {
            if (productHere.Maintenance_Cycle__c != null) {
                productMaintenanceCycleMap.put(productHere.Id, Integer.valueOf(productHere.Maintenance_Cycle__c));               
            }
        }
        
        for (Work_Part__c workPart : [select Id, Equipment__c, Maintenance_Request__c from Work_Part__c where Maintenance_Request__c in :validCaseMap.keySet()]) {
            if (workPart.Equipment__c != null) {
                if(!workPartMaintenanceCycleMap.containsKey(workPart.Maintenance_Request__c)){
                    workPartMaintenanceCycleMap.put(workPart.Maintenance_Request__c, productMaintenanceCycleMap.get(workPart.Equipment__c));   
                }
                else if(productMaintenanceCycleMap.get(workPart.Equipment__c) < workPartMaintenanceCycleMap.get(workPart.Maintenance_Request__c)){
                    workPartMaintenanceCycleMap.put(workPart.Maintenance_Request__c, productMaintenanceCycleMap.get(workPart.Equipment__c));  
                }             
            }
        }
        
        for(Case caseHere: validCaseMap.values()){
            Case newCase = new Case();
            newCase.Vehicle__c = caseHere.Vehicle__c;
            newCase.Equipment__c = caseHere.Equipment__c;
            newCase.Type = 'Routine Maintenance';
            newCase.Subject = String.isBlank(caseHere.Subject) ? 'Routine Maintenance Request' : caseHere.Subject + ' New';
            newCase.Date_Reported__c = Date.today();
            newCase.Date_Due__c = workPartMaintenanceCycleMap.containsKey(caseHere.Product__c) ? Date.today().addDays(workPartMaintenanceCycleMap.get(caseHere.Product__c)) : Date.today();
            newCase.Status = 'New';
            newCase.Product__c = caseHere.Product__c;
            newCase.AccountId = caseHere.AccountId;
            newCase.ContactId = caseHere.ContactId;
            newCase.AssetId = caseHere.AssetId;
            newCase.Origin = caseHere.Origin;
            newCase.Reason = caseHere.Reason;
          	
            newCases.add(newCase);
        }
        
        if(newCases.size() > 0){
            insert newCases;
        }
    }

}
*/

