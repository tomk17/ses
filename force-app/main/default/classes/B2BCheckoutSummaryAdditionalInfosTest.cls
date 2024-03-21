@isTest
public class B2BCheckoutSummaryAdditionalInfosTest {
	@testSetup
	static void setup() {
		// --------------------------------- Create Account ---------------------------------

		Account account = new Account(
			Name = 'Test Account',
			Description = 'Test Class',
			BillingCountry = 'France',
			ShippingCountry = 'France',
			Incoterms__c = 'FCA',
			Incoterm_Locations__c = 'Local Warehouse'
		);
		insert account;
        
        // --------------------------------- Create Sales Org---------------------------------
        
        Sales_Org__c so = new Sales_Org__c(
            Name = 'SES-imagotag Inc.',
            Corresponding_User_HR_Companies__c = 'SES-imagotag Inc.',
            Code__c = 1710
        );
        insert so;
        
        // --------------------------------- Create Account Sales Org---------------------------------
        
        Account_Salesorg__c aso = new Account_Salesorg__c(
            Account__c = account.Id,
            Primary__c = true,
            Sales_Org__c = so.Id
        );
        insert aso;

		// --------------------------------- Create Contact ---------------------------------

		Contact contact = new Contact(AccountId = account.Id, FirstName = 'John', LastName = 'Doe', Email = 'test@test.com');
		insert contact;
        
        // --------------------------------- Search Profile ---------------------------------
        
        Profile profile = [SELECT Id, Name FROM Profile WHERE Name = 'Customer Community Login User SES-imagotag' LIMIT 1];
        
        // --------------------------------- Create User ---------------------------------
        
        User user = new User(
            username = System.now().millisecond() + 'test12345@test.com',
            contactId = contact.Id,
            profileId = profile.Id,
            alias = 'Ttest',
            email = 'test@test.com',
            emailEncodingKey = 'UTF-8',
            isActive = true,
            lastName = 'McTesty',
            timeZoneSidKey = 'America/Los_Angeles',
            localeSidKey = 'en_US',
            languageLocaleKey = 'en_US'
        );
        insert user;
        
        //Create WebStore
        WebStore store = new WebStore(Name = 'SES B2B Commerce');
        insert store;

        //Create new WebCart        
        WebCart cart = new WebCart(Name = 'CartTest',
                                   AccountId = account.Id,
                                   WebStoreId = store.Id,
                                   OwnerId = user.Id,
                                   ShipToContact__c = contact.Id);
        insert cart;
        
        CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup(
            CartId=cart.Id
            , Name='Default Delivery'
            , DeliverToName ='Detroit IGHQ'
            , DeliverToCountry='France');
        insert cartDeliveryGroup;
        
        // Insert Product
        Product2 p2 = new Product2();
        p2.Name = 'Test Product 2';
        p2.Description='Test Product Entry 2';
        p2.productCode = 'ABCD';
        p2.isActive = true;
        insert p2;
        
        Product2 product2 = new Product2(
            Name = 'Transportation'
            , ProductCode = '6669'
            , Description = 'Test Product'
            , IsActive = true
        );
        insert product2;
        
        CartItem cartItem = new CartItem(
            CartId=cart.Id, 
            Sku='SKU_Test1', 
            Quantity=3.0, 
            Type='Product', 
            Name='TestCI1', 
            Product2Id = p2.Id,
            CartDeliveryGroupId=cartDeliveryGroup.Id
            , ListPrice = 50
            , SalesPrice = 50
            , TotalLineAmount = 150
            , TotalPrice = 150
        );
        insert cartItem;
        
        APITalenDev__c talendev = new APITalenDev__c(url__c = 'testdev', token__c = 'tokendev');
        APITalenProd__c talenprod = new APITalenProd__c(url__c = 'testprod', token__c = 'tokenprod');
        insert talendev;
        insert talenprod;
    }
    
    @isTest
	static void testMethods() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new B2BAtpProductsHttpCalloutMock()); 
        WebCart cart = [SELECT Id, OwnerId From WebCart LIMIT 1];
        String email = B2BCheckoutSummaryAdditionalInfos.retrieveContactEmail(cart.Id);
        String currencyFromAcc = B2BCheckoutSummaryAdditionalInfos.retrieveCurrency(cart.Id);
        String optEmail = B2BCheckoutSummaryAdditionalInfos.retrieveOptionalEmail(cart.Id);
        List<CartItem> cis = B2BCheckoutSummaryAdditionalInfos.retrieveProduct(cart.Id);
        List<CartItem> cis2 = B2BCheckoutSummaryAdditionalInfos.retrieveSoftware(cart.Id);
        String deliverToCountry = B2BCheckoutSummaryAdditionalInfos.retrieveDeliverToCountry(cart.Id);
        WebCart retrieveFields = B2BCheckoutSummaryAdditionalInfos.retrieveCart(cart.Id);
        Decimal softwareAmount = B2BCheckoutSummaryAdditionalInfos.softwareAmount(cart.Id);
        B2BCheckoutSummaryAdditionalInfos.calculateAvailability(cart.Id);
        Test.stopTest();
    }
}