@isTest
public class CartItemTriggerClassTest {
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
        
                // Insert Product
        Product2 p = new Product2();
        p.Name = 'Test Product';
        p.Description='Test Product Entry 1';
        p.productCode = 'ABC';
        p.isActive = true;
        p.CatalogFamilyDescription__c = 'Software';
        insert p;
        
        // Insert Product
        Product2 p2 = new Product2();
        p2.Name = 'Test Product 2';
        p2.Description='Test Product Entry 2';
        p2.productCode = 'ABCD';
        p2.isActive = true;
        p2.Software__c = p.Id;
        insert p2;
        
        Product2 product2 = new Product2(
            Name = 'Transportation'
            , ProductCode = '6669'
            , Description = 'Test Product'
            , IsActive = true
        );
        insert product2;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        // Insert PricebookEntry
        
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = pricebookId;
        standardPrice.Product2Id = p.Id;
        standardPrice.UnitPrice = 1;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        insert standardPrice ;
        
        // Insert Order
        
        Order o = new Order();
        o.Name = 'Test Order';
        o.Status = 'Draft';
        o.EffectiveDate = system.today();
        o.EndDate = system.today() + 4;
        o.AccountId = account.id;
        o.blng__BillingDayOfMonth__c = '1';
        o.Pricebook2Id =  pricebookId ;
        
        insert o;
        

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
                                  BillToAccount__c = account.Id);
        insert cart;
        
        CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup(
            CartId=cart.Id
            , Name='Default Delivery'
            , DeliverToName ='Detroit IGHQ'
            , DeliverToCountry='France');
        insert cartDeliveryGroup;
                
        CartItem cartItem = new CartItem(
            CartId=cart.Id, 
            Sku='SKU_Test1', 
            Quantity=3.0, 
            Type='Product', 
            Name='TestCI1', 
            Product2Id = p.Id,
            CartDeliveryGroupId=cartDeliveryGroup.Id
            , ListPrice = 50
            , SalesPrice = 50
            , TotalLineAmount = 150
            , TotalPrice = 150
        );
        insert cartItem;
        
        CartItem cartItem2 = new CartItem(
            CartId=cart.Id, 
            Sku='SKU_Test1', 
            Quantity=3.0, 
            Type='Product', 
            Name='TestCI2', 
            Product2Id = p2.Id,
            CartDeliveryGroupId=cartDeliveryGroup.Id
            , ListPrice = 50
            , SalesPrice = 50
            , TotalLineAmount = 150
            , TotalPrice = 150
        );
        insert cartItem2;
    }
    
    // --------------------------------- First Test ---------------------------------
    @isTest
    static void testMethods() {
        Test.startTest();
        CartItem ci = [SELECT Id, Quantity, Product2.CatalogFamilyDescription__c FROM CartItem WHERE Name = 'TestCI1'];
        CartItem ci2 = [SELECT Id, Quantity, Product2.CatalogFamilyDescription__c FROM CartItem WHERE Name = 'TestCI2'];
        //User user = [SELECT Id FROM User WHERE alias = 'Ttest'];
		ci2.Quantity = 10;
        update ci2;
        delete ci;
        Test.stopTest();
    }
}