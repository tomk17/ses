@isTest
global class CybersourceCalloutErrorMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
       	// Create a fake response
     	String body = '{"submitTimeUtc": "2023-09-28T10:05:14Z","status": "404","errorInformation": {"reason": "NOT_FOUND","message": "The requested resource does not exist."}}';
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody(body);
        response.setStatusCode(404);
        return response; 
    }
}