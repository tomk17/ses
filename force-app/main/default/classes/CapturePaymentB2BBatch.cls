global class CapturePaymentB2BBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {

    private Boolean schedule;
    
    private CybersourceSettings__c credentials;
    private Integer capturedInvoicesCount;
    private Integer errorsCount;
    
    global CapturePaymentB2BBatch() {


        Organization org = [SELECT IsSandbox FROM Organization];
        boolean productionEnv = false;

        if(org.IsSandbox != true && !Test.isRunningTest()){
            productionEnv = true;
        }

        this.credentials  = [
            SELECT id, chatter_group__c, host__c, organization_Id__c, payment_endpoint__c, private_key__c, public_key__c
            FROM CybersourceSettings__c 
            WHERE producion_env__c =:productionEnv 
            LIMIT 1
        ];

        this.capturedInvoicesCount = 0;
        this.errorsCount = 0;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([ 
            SELECT Id, Invoice_Amount__c, Tax_Amount__c, Name, Payment_Authorization__r.GatewayRefNumber, Payment_Authorization__r.CurrencyIsoCode, Capture_id__c, Capture_request_date__c
            FROM SAPInvoice__c 
            WHERE Payment_Authorization__c != ''
            AND Capture_request_date__c = null
            AND Capture_id__c = null
        ]); 


    }
  
    global void execute(Database.BatchableContext bc, List<SAPInvoice__c> invoices) {
        try {

            for (SAPInvoice__c invoice : invoices) {
                CapturePaymentB2B.CapturePayment(JSON.serialize(invoice), JSON.serialize(this.credentials));
            }


        } catch (Exception e) {
            System.debug(e);
        }
    } 
    global void finish(Database.BatchableContext bc) {
        System.debug('Capture finished');
        System.debug('Captured invoices :' + this.capturedInvoicesCount);
        System.debug('Error count :' + this.errorsCount);
    }   

}