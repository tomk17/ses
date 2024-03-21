/* *******************************************************************************************************
 * Name               :                                                                                  *
 * Description        :                                                                                  *
 * Created Date       : 07.02.2023                                                                       *
 * Created By         : Benjamin Cligny @Icom                                                                  *
 * -----------------------------------------------------------------------------------------------       *
 * VERSION    AUTHOR                 DATE                                                                *
 *   1.0 -    Benjamin Cligny   @Icom      07-Feb-2023 Initial version                                         *
 ******************************************************************************************************* */
@IsTest
public class B2B_CartToOrderNewTest {
    
    public static String effectiveAccountId = null;
    public static String shipToContactPointAddressId = null;
    public static Id cartId = null;
    public static String webstoreId = null;
    public static String deliveryMethodId = null;
    public static String cartDeliveryGroupId = null;
    public static String cartDeliveryGroupMethodId = null;
    public static Id pricebookId = null;
    
    private static void setup() {

        System.debug('begin setup()');

        Product2 product1 = new Product2(
            Name = 'TestProduct'
            , StockKeepingUnit = 'SKU_Test1'
            , Description = 'Test Product'
            , IsActive = true
        );

        insert product1;
        
        Product2 product2 = new Product2(
            Name = 'Transportation'
            , ProductCode = '6669'
            , Description = 'Test Product'
            , IsActive = true
        );
        
        insert product2;
        
        Contact con = new Contact(
            LastName = 'test',
            FirstName = 'Contact',
            Email = 'test@test.com'
        );
        insert con;

        pricebookId = Test.getStandardPricebookId();

        PricebookEntry pbe = new PricebookEntry(
            IsActive = true
            , UnitPrice = 50
            , Pricebook2Id = pricebookId
            , Product2Id = product1.Id
            , UseStandardPrice = false
        );

        insert pbe;
        Account account = new Account(
            Name='TestAccount',
            ShippingCountry='France'  
        );
        insert account;
        effectiveAccountId = account.Id;
        
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

        WebStore webStore = new WebStore(Name='SES B2B Commerce', SupportedLanguages='en_US', DefaultLanguage='en_US');
        insert webStore;
        webstoreId = webStore.Id;

        WebCart cart = new WebCart(
            Name='Cart'
            , WebStoreId=webStore.Id
            , AccountId=account.Id
            , OwnerId=user.Id
            , PONumber = '24601'
            , Status = 'Active'
            , Type = 'Cart'
            , BillingStreet = '2100 Woodward Ave'
            , BillingCity = 'Detroit'
            , BillingPostalCode = '48201'
            , BillingCountry = 'France'
            );
        insert cart;
        cartId = cart.Id;

        System.debug('cartId: ' + cartId);

        CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup(
            CartId=cart.Id
            , Name='Default Delivery'
            , DeliverToName ='Detroit IGHQ'
            , DeliverToCountry='France');
        insert cartDeliveryGroup;

        cartDeliveryGroupId = cartDeliveryGroup.Id;
        
        CartItem cartItem = new CartItem(
            CartId=cart.Id, 
            Sku='SKU_Test1', 
            Quantity=3.0, 
            Type='Product', 
            Name='TestProduct', 
            CartDeliveryGroupId=cartDeliveryGroup.Id
            , ListPrice = 50
            , SalesPrice = 50
            , TotalLineAmount = 150
            , TotalPrice = 150
            , Product2Id = product1.Id
        );
        insert cartItem;

        CartTax tax = new CartTax( 
                    Amount = 9,
                    CartItemId = cartItem.Id,
                    Name = 'GST',
                    TaxCalculationDate = Date.today(),
                    TaxRate = .06,
                    TaxType = 'Actual'
                );

        insert tax;

        List<ContactPointAddress> cpaList = new List<ContactPointAddress>();
        ContactPointAddress billingAddr = new ContactPointAddress(
            AddressType = 'Billing'
            , Street = '2100 Woodward Ave'
            , ParentId = effectiveAccountId
            , Name ='Detroit IGHQ'
            , City = 'Detroit'
            , PostalCode = '48201'
            , Country = 'France'
            , IsDefault = true
            , IsPrimary = true
        );
        cpaList.add(billingAddr);

        ContactPointAddress shippingAddr = new ContactPointAddress(
            AddressType = 'Shipping'
            , Street = '2100 Woodward Ave'
            , ParentId = effectiveAccountId
            , Name ='Detroit IGHQ'
            , City = 'Detroit'
            , PostalCode = '48201'
            , Country = 'France'
            , IsDefault = true
            , IsPrimary = true
        );
        cpaList.add(shippingAddr);

        insert(cpaList);

        shipToContactPointAddressId = cpaList.get(1).Id;

    }

    private static void setup2() {

        System.debug('begin setup2()');

        Product2 productA = new Product2(
            Name = 'Shipping Charge for this delivery method'
            , IsActive = true
        );

        insert productA;

        Id pricebookId = Test.getStandardPricebookId();

        PricebookEntry pbe = new PricebookEntry(
            IsActive = true
            , UnitPrice = 39.99
            , Pricebook2Id = pricebookId
            , Product2Id = productA.Id
            , UseStandardPrice = false
        );

        insert pbe;

        CartItem cartItem = new CartItem(
            CartId = cartId, 
            Quantity = 1.0
            , Type='Product'
            , Name='Shipping Cost'
            , CartDeliveryGroupId = cartDeliveryGroupId
            , ListPrice = 39.99
            , SalesPrice = 39.99
            , TotalLineAmount = 39.99
            , TotalPrice = 39.99
            , Product2Id = productA.Id
        );
        insert cartItem;

        CartTax tax = new CartTax( 
                    Amount = 2.40,
                    CartItemId = cartItem.Id,
                    Name = 'GST',
                    TaxCalculationDate = Date.today(),
                    TaxRate = .06,
                    TaxType = 'Actual'
                );

        insert tax;

        OrderDeliveryMethod defaultOrderDeliveryMethod = new OrderDeliveryMethod(
                    Name = 'Order Delivery Method1',
                    Carrier = 'DHL',
                    isActive = true,
                    ProductId = productA.Id,
                    ClassOfService = 'DHLND9'
                );
        insert(defaultOrderDeliveryMethod);

        deliveryMethodId = defaultOrderDeliveryMethod.Id;

        String shippingOptionProvider = 'DHLND9';
        String shippingOptionName = 'Next day 9am';
        Decimal shippingOptionRate = 39.99;


        CartDeliveryGroupMethod cartDeliveryGroupMethod = new CartDeliveryGroupMethod(
            CartDeliveryGroupId = cartDeliveryGroupId,
            DeliveryMethodId = deliveryMethodId,
            ExternalProvider = shippingOptionProvider,
            Name = shippingOptionName,
            ShippingFee = shippingOptionRate,
            WebCartId = cartId
        );
        insert(cartDeliveryGroupMethod);

        cartDeliveryGroupMethodId = cartDeliveryGroupMethod.Id;

        CartDeliveryGroup cartDeliveryGroup = [SELECT Id, DeliveryMethodId FROM CartDeliveryGroup WHERE Id= :cartDeliveryGroupId][0];
        cartDeliveryGroup.DeliveryMethodId = deliveryMethodId;
        update cartDeliveryGroup;
        
        // --------------------------------- Add Billing Rule ---------------------------------
        
        blng__BillingRule__c billingRule = new blng__BillingRule__c( 
            Name = 'Default Billing Rule',
            CurrencyIsoCode = 'EUR',
            blng__Active__c = true,
            blng__GenerateInvoices__c = 'No',
            blng__InitialBillingTrigger__c = 'Order Product Activation Date'
        );
        insert billingRule;
        
        // --------------------------------- Add Revenue Recognition Rule ---------------------------------
        
        blng__RevenueRecognitionRule__c revenueRecognitionRule = new blng__RevenueRecognitionRule__c(
            Name = 'Default Rev Rec Rue',
            blng__CreateRevenueSchedule__c = 'No'
        );
        insert revenueRecognitionRule;
        
        // --------------------------------- Add Tax Rule ---------------------------------
        
        blng__TaxRule__c taxRule = new blng__TaxRule__c(
            Name = 'Default Tax Rules'
        );
        insert taxRule;

    }

    /*
        Test getting the cart summary, where a delivery method has been selected.
    */
    @isTest static void testCode1() {

        setup();

        // Additional setup to associate a cart delivery group method with the cart delivery group.
        setup2();
        
        B2B_CartToOrderNew.B2BCartToOrderDraftRequest request = new B2B_CartToOrderNew.B2BCartToOrderDraftRequest();
        request.cartId = cartId;

        List<B2B_CartToOrderNew.B2BCartToOrderDraftRequest> requestList = new List<B2B_CartToOrderNew.B2BCartToOrderDraftRequest>();
        requestList.add(request);

        Test.startTest();

        List<ID> orderIds = B2B_CartToOrderNew.cartToOrder(requestList);      
        
        Test.stopTest();
    }

}