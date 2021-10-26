trigger MaintenanceRequest on Case (before update, after update) {
    // ToDo: Call MaintenanceRequestHelper.updateWorkOrders
    if(Trigger.isBefore && Trigger.isUpdate){
        // Id List to use For WHERE Clause of SOQL
        List<Id> mainReqIdList = new List<Id>();
        List<Id> mainReqVehList = new List<Id>();
        for(Case cs:Trigger.New){
            mainReqIdList.add(cs.Id);
            if(cs.Vehicle__c!=null){
                mainReqVehList.add(cs.Vehicle__c);
            }
        }
        
        // Get 'Equipment Maintenance Item' List To Get Equip's Maintenance Cycle
        List<Equipment_Maintenance_Item__c> emiList = [SELECT Equipment__c, Maintenance_Request__c, Quantity__c 
        FROM Equipment_Maintenance_Item__c
        WHERE Maintenance_Request__c IN :mainReqIdList];

        // Id List to use For WHERE Clause of SOQL
        List<Id> eqIdList = new List<Id>();
        for(Equipment_Maintenance_Item__c emi : emiList){
            eqIdList.add(emi.Equipment__c);
        }

        // Get 'Equipment' List To Get Equip's Maintenance Cycle
        List<Product2> eqList = [SELECT Name, Maintenance_Cycle__c FROM Product2 WHERE Id IN :eqIdList];
        // Get 'Vehicle' List To Assign to New Maintenance Request
        List<Vehicle__c> vcList = [SELECT Id FROM Vehicle__c WHERE Id IN :mainReqVehList];

        for(Case cs:Trigger.New){
            if((cs.Type=='Repair' || cs.Type=='Routine Maintenance') &&
            cs.Status == 'Closed'){
                List<Equipment_Maintenance_Item__c> relatedEmiList = new List<Equipment_Maintenance_Item__c>();
                List<Equipment_Maintenance_Item__c> newEmiList = new List<Equipment_Maintenance_Item__c>();
                List<Product2> relatedEqList = new List<Product2>();
                Integer shortest = 0;

                // Get related 'Equipment Maintenance Item' List
                for(Equipment_Maintenance_Item__c emi : emiList){
                    if(emi.Maintenance_Request__c == cs.Id){
                        relatedEmiList.add(emi);
                        System.debug('Related Equipment Maintenance Item Record Detected');
                    }
                }
                
                // Get related 'Equipment' List
                for(Equipment_Maintenance_Item__c emi : relatedEmiList){
                    for(Product2 eq : eqList){
                        if(emi.Equipment__c == eq.Id){
                            System.debug('Related Equipment Detected: '+eq.Name);
                            relatedEqList.add(eq);
                        }
                    }
                }
                
                // Find Shortest Maintenance Cycle(date)
                if(relatedEqList.size() > 0){
                    for(Product2 eq : relatedEqList){
                        if(shortest == 0 || eq.Maintenance_Cycle__c < shortest){
                            shortest = Integer.valueOf(eq.Maintenance_Cycle__c);
                        }
                    }
                }

                Case newMainReq = new Case(
                    Subject = 'New Maintenance Request by \'' + cs.Subject + '\'',
                    Date_Reported__c = System.today(),
                    Date_Due__c = System.today().addDays(shortest),
                    Type='Routine Maintenance',
                    Vehicle__c = cs.Vehicle__c);
                

                insert newMainReq;

                // Create Related Equipment Maintenance Items
                for(Equipment_Maintenance_Item__c emi : relatedEmiList){
                    Equipment_Maintenance_Item__c newEmi = new Equipment_Maintenance_Item__c(
                        Maintenance_Request__c = newMainReq.Id,
                        Equipment__c = emi.Equipment__c,
                        Quantity__c = emi.Quantity__c
                    );
                    newEmiList.add(newEmi);
                }

                insert newEmiList;
            }
        }
    }
}