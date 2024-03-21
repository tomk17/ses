@isTest
public class B2BPaymentPOOnlyTest {
	@testSetup
	static void setup() {
        
        // --------------------------------- Create payment terms ---------------------------------

        acCore__PaymentTerms__c pt = new acCore__PaymentTerms__c(
            Name = 'test pt'
        );
        insert pt;
        
		// --------------------------------- Create Account ---------------------------------

		Account account = new Account(
			Name = 'Test Account',
			Description = 'Test Class',
			BillingCountry = 'France',
			ShippingCountry = 'France',
			Incoterms__c = 'FCA',
			Incoterm_Locations__c = 'Local Warehouse',
            acCore__PaymentTerm__c = pt.Id
		);
		insert account;
      
    }
    
    @isTest
	static void testMethods() {
        Test.startTest();
        Account account = [SELECT Id From Account WHERE Name = 'Test Account' LIMIT 1];
		String paymentTerms = B2BPaymentPOOnlyController.returnPaymentTerm(account.Id);
        Test.stopTest();
    }
}