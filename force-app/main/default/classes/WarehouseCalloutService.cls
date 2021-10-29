public class WarehouseCalloutService implements Queueable, Database.AllowsCallouts {
    private static final String WAREHOUSE_URL = 'https://th-superbadge-apex.herokuapp.com/equipment';

    public void execute(QueueableContext context) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();

        request.setEndpoint(WAREHOUSE_URL);
        request.setMethod('GET');

        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            String resJson = response.getBody();
            // resJson = resJson.replace('_id', 'Id');
            resJson = resJson.replace('replacement', 'Replacement_Part__c');
            resJson = resJson.replace('quantity', 'QuantityUnitOfMeasure');
            resJson = resJson.replace('name', 'Name');
            resJson = resJson.replace('maintenanceperiod', 'Maintenance_Cycle__c');
            resJson = resJson.replace('lifespan', 'Lifespan_Months__c');
            resJson = resJson.replace('cost', 'Cost__c');
            resJson = resJson.replace('sku', 'ExternalId');

            List<Product2> res = (List<Product2>) JSON.deserialize(resJson, List<Product2>.class);

            for (Product2 eq : res) {
                eq.Replacement_Part__c = true;
            }

            upsert res;
        }
    }
}
