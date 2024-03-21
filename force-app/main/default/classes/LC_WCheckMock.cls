@isTest
global class LC_WCheckMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        System.debug('************ HttpCalloutMock *************');
        System.debug(request.getEndpoint());
        System.debug(request.getEndpoint().contains('portal.imagotag.com'));

        StaticResource sr = null;
        if(request.getEndpoint().contains('portal.imagotag.com')) {
            sr = [SELECT Id, Body FROM StaticResource WHERE Name = 'WarrantyExample' LIMIT 1];
        }else {
            sr = [SELECT Id, Body FROM StaticResource WHERE Name = 'WarrantyNewApiExample' LIMIT 1];
        }
        response.setBody(sr.Body.toString());
        response.setStatusCode(200);
        response.setStatus('OK');
        System.debug('************ HttpCalloutMock Response*************');
        System.debug(sr.Body.toString());
        return response; 
    }
}