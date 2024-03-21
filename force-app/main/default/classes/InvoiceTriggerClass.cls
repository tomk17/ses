public class InvoiceTriggerClass {

    public static PaymentAuthorization GetPaymentAutorization(SAPInvoice__c invoice) {
        // Get authorization of the invoice.
        // Only process B2B Commmerce invoices
        // should only have one payment authorization for order and invoice.
        if(invoice.order__c == null) return null;
        Order order = [SELECT Id, Order_Origin__c FROM Order WHERE Id = :invoice.order__c LIMIT 1]; 
        if(order.Order_Origin__c != 'B2B Commerce' || order == null) return null;

        List<PaymentAuthorization> paymentAuthorizations = [SELECT id FROM PaymentAuthorization WHERE order__c =:order.Id ORDER BY CreatedDate DESC LIMIT 1] ;
        if(paymentAuthorizations.size() == 0) return null;

        return paymentAuthorizations[0];
    }
}