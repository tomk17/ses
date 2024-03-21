@isTest
global class CybersourceCalloutMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
       	// Create a fake response
     	String body = '{"_links":{"void":{"method":"POST","href":"/pts/v2/captures/6951118066626005204953/voids"},"self":{"method":"GET","href":"/pts/v2/captures/6951118066626005204953"}},"clientReferenceInformation":{"code":"test_22"},"id":"6951118066626005204953","orderInformation":{"amountDetails":{"totalAmount":"10.00","currency":"USD"}},"reconciliationId":"76433322HM4PARIP","status":"PENDING","submitTimeUtc":"2023-09-19T08:23:26Z"}';

        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody(body);
        response.setStatusCode(201);
        return response; 
    }
}