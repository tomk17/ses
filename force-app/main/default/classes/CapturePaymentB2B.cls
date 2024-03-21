public with sharing class CapturePaymentB2B {

 
    public static void CapturePayment(string invoiceData, string credentialsData) {
      if(System.isFuture() || System.isBatch()) {
        excuteCaptureCallout(invoiceData,credentialsData);
      }else{
        futureCallout(invoiceData, credentialsData);
      }
    }

    @future(callout=true)
    private static void futureCallout(string invoiceData, string credentialsData) {
      excuteCaptureCallout(invoiceData,credentialsData);
    }  

    private static void excuteCaptureCallout(string invoiceData, string credentialsData) {

        SAPInvoice__c invoice = (SAPInvoice__c)JSON.deserializeStrict(invoiceData, SAPInvoice__c.class);
        system.debug('CapturePaymentB2B  invoiceData');
        system.debug(invoiceData);
        CybersourceSettings__c cybersourceSettings = (CybersourceSettings__c)JSON.deserializeStrict(credentialsData, CybersourceSettings__c.class);

        system.debug('CapturePaymentB2B cybersourceSettings');
        system.debug(cybersourceSettings);
        Map<string,string> credentials = new Map <String, String>();
        credentials.put('host', cybersourceSettings.host__c);
        credentials.put('merchant_id', cybersourceSettings.organization_Id__c);
        credentials.put('key_id', cybersourceSettings.public_key__c);
        credentials.put('shared_secret_key', cybersourceSettings.private_key__c);
        credentials.put('target', cybersourceSettings.payment_endpoint__c + '/' +  invoice.Payment_Authorization__r.GatewayRefNumber + '/captures');
        credentials.put('method', 'POST');
        credentials.put('date', setDateTimeString());
        credentials.put('currency_code', invoice.Payment_Authorization__r.CurrencyIsoCode);
        credentials.put('is_sandbox', 'true');
        credentials.put('chatter_group_id', cybersourceSettings.chatter_group__c);
        system.debug('CapturePaymentB2B  Credentials');
        system.debug(credentials);

        string body = generateCaptureBody(credentials, invoice);
        
        system.debug('body');
        system.debug(body);

        HttpRequest request = generatePostRequest(credentials, body);

        Http http = new Http();
        HttpResponse response = http.send(request);
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        string chatterMessage = '';
        if(response.getStatusCode() == 201) {
            invoice.Capture_id__c = (string)result.get('id');
            String captureDateTime = (string)result.get('submitTimeUtc');
            invoice.Capture_request_date__c = DateTime.valueOf(captureDateTime.replace('T',' '));
            update invoice; 
            chatterMessage = 'B2B Captutre Initiated for SAP invoice :' + invoice.Id +  '\n' + 
                                    'Cybersource capture Id :' + (string)result.get('id') + '\n' ;
        } else {
            system.debug('B2B Captutre payment error');
            system.debug('STATUS : ' + result.get('status'));
            system.debug('REASON : ' + result.get('reason'));
            system.debug('MESSAGE : ' + result.get('message'));
            chatterMessage = 'B2B Captutre payment error\n' + 
                                    'Reason :' + result.get('reason') + '\n' +
                                    'Message :' + result.get('message') + '\n';
            
        }
        String chatterGroupId = credentials.get('chatter_group_id');
        if(!Test.isRunningTest() && chatterGroupId != '') ConnectApi.FeedElement fi = ConnectAPI.ChatterFeeds.postFeedElement(null, chatterGroupId, ConnectApi.FeedElementType.FeedItem, chatterMessage);
    }

    private static string generateCaptureBody(Map<string,string> credentials, SAPInvoice__c invoice) {
      system.debug('CapturePaymentB2B  generateCaptureBody');
      system.debug('>>>>>> Invoice');
      system.debug(invoice);
      decimal amount = invoice.Invoice_Amount__c;
      if (invoice.Tax_Amount__c != null) {
        amount += invoice.Tax_Amount__c;
      }
      system.debug('>>>>>> Amount');
      system.debug(amount);

      string body = '{';
      body += '"clientReferenceInformation": {';
      body += '"code": "'+ invoice.Name + '"';
      body +='},';
      body += '"orderInformation": {';
      body += '"amountDetails": {';
      body += '"totalAmount": ' + amount +',';
      body += '"currency": "'+ credentials.get('currency_code') + '"';
      body += '}';
      body += '}';
      body += '}';
      return body;
    }

    private static HttpRequest generatePostRequest(Map<string,string> credentials, String reqBody) {

      HttpRequest request = generateRequestBase(credentials);
        
      //POST requests
      String digestString = generateDigest(reqBody);
      String signatureString = generateSignature(credentials, digestString); 
      system.debug('signatureString');
      system.debug(signatureString);

      request.setHeader('Digest', digestString);
      request.setHeader('Signature', signatureString);
      request.setBody(reqBody);
      return request; 
    }
    //Generates a base HTTP Request with common headers set (basic structure for GET and POST methods)
    private static HttpRequest generateRequestBase(Map<string,string> credentials) {

      HttpRequest request = new HttpRequest();
      request.setEndpoint('https://' + credentials.get('host') + credentials.get('target'));
      request.setMethod(credentials.get('method'));
      request.setHeader('Host', credentials.get('host'));
      request.setHeader('v-c-merchant-id', credentials.get('merchant_id'));
      request.setHeader('Content-Type', 'application/json');
      request.setHeader('Date', credentials.get('date'));
      
      return request;
  }

    private static string generateSignature(Map<string,string> credentials, String digestString) {
      String signatureHeaders = generateSignatureHeaders(credentials, digestString);
      System.debug('signatureHeaders');
      System.debug(signatureHeaders);

      String signatureHash = generateSignatureHash(credentials, signatureHeaders);
      return generateSignatureString(credentials, signatureHash);

    }
    private static String generateSignatureHeaders(Map<string,string> credentials , String digestString) {
      String headerFields = '';
      String reqType = credentials.get('method').toLowerCase();
      
      //Add host
      headerFields += ('host: ' + credentials.get('host') + '\n');
      
      //Add date (for POST requests only)
      if(reqType == 'post') {
          headerFields += 'date: ' + credentials.get('date') + '\n';
      }
      
      //Add (request-target)
      headerFields += ('(request-target): ' + reqType + ' ' + credentials.get('target') + '\n');
      
      //Add digest (for POST requests only)
      if(reqType == 'post') {
          headerFields += ('digest: ' + digestString + '\n');
      } 
      
      //Add v-c-merchant-id
      headerFields += ('v-c-merchant-id: ' + credentials.get('merchant_id'));
      System.debug(headerFields);
      
      return headerFields;
  }

  private static String generateSignatureString(Map<string,string> credentials, String signatureHash) {
    String signatureString = '';
    String reqType = credentials.get('method').toLowerCase();
    signatureString += 'keyid="' + credentials.get('key_id') + '", ';
    signatureString += 'algorithm="HmacSHA256", ';
    signatureString += 'headers="host';
        
    //Add in 'date' for POST requests (seems to break GET requests)
    if(reqType == 'post') {
        signatureString += ' date';
    }
    
    signatureString += ' (request-target)';

    //Add in 'digest' for POST requests        
    if(reqType == 'post') {
        signatureString += ' digest';
    }
    
    signatureString += ' v-c-merchant-id", ';
    signatureString += 'signature="' + signatureHash + '"';
    
    return signatureString;
  }  
  private static String generateSignatureHash(Map<string,string> credentials, String signatureHeaders) {
    Blob hash = Crypto.generateMac('HmacSHA256', Blob.valueOf(signatureHeaders), EncodingUtil.base64Decode(credentials.get('shared_secret_key')));

    return EncodingUtil.base64Encode(hash);
  }
  //Generates a Hash of the request body (Digest header)
  private static String generateDigest(String reqBody) {
    Blob digestHash = Crypto.generateDigest('SHA-256', Blob.valueOf(reqBody)); 
    String digestString = 'SHA-256=' + EncodingUtil.base64Encode(digestHash);
    
    return digestString;
  }
  private static String setDateTimeString() {
    return DateTime.now().formatGMT('EEE, d MMM  yyyy HH:mm:ss') + ' GMT';
  }

}