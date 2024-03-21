@isTest
global class AvalaraHttpCalloutMock implements HttpCalloutMock {
    public Integer code;
    public String status;
    public String body;
    public String header;

    global AvalaraHttpCalloutMock(Integer code, String status, String body, String header) {
        this.code = code;
        this.status = status;
        this.body = body;
        this.header = header;
    }

    global AvalaraHttpCalloutMock() {

    }

    global HTTPResponse respond(HTTPRequest req) {

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', this.header);
        res.setBody(this.body);
        res.setStatusCode(this.code);
        res.setStatus(this.status);
        return res;
    }
}