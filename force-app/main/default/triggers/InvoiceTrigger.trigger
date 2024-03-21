trigger InvoiceTrigger on SAPInvoice__c (before insert) {
    system.debug('**** Invoice Before insert trigger');
    if(!PAD.canTrigger('CanTriggerB2BInvoice')) return;
    system.debug('**** Invoice trigger running...');
    SAPInvoice__c invoice =  Trigger.new[0];
    system.debug('***** invoice data');
    system.debug(invoice);

    PaymentAuthorization paymentAuthorization = InvoiceTriggerClass.GetPaymentAutorization(invoice);
    system.debug('**** Payment authorization result');
    system.debug(paymentAuthorization);
    
    if(paymentAuthorization != null){
        invoice.Payment_Authorization__c =  paymentAuthorization.Id;
    }
    system.debug('**** Invoice trigger END');
}