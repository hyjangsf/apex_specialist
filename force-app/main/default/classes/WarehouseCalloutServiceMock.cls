@isTest
global class WarehouseCalloutServiceMock implements HttpCalloutMock {
    // implement http mock callout
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody(
            '[{"_id":"55d66226726b611100aaf741","replacement":true,"quantity":5,"name":"Test Equipment","maintenanceperiod":365,"lifespan":120,"cost":5000,"sku":"1234567"}]'
        );
        response.setStatusCode(200);
        return response;
    }
}
