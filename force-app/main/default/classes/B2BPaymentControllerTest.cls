@IsTest(SeeAllData=true)
public class B2BPaymentControllerTest {
    static void setup() {
        // Account and Contact are related
        Account account = new Account(Name='TestAccount');
        insert account;
        Contact contact = new Contact(LastName='TestContact', AccountId=account.Id);
        insert contact;

        WebStore webStore = [SELECT Id FROM WebStore WHERE Name = 'SES B2B Commerce']; 
        //new WebStore(Name='SES B2B Commerce', DefaultLanguage='en_US');
        //insert webStore;

        WebCart cart = new WebCart(Name='B2BcommerceCart', WebStoreId=webStore.Id, AccountId=account.Id);
        insert cart;
        
                // Insert Product
        Product2 p = new Product2();
        p.Name = ' Test Product ';
        p.Description='Test Product Entry 1';
        p.productCode = 'ABC';
        p.isActive = true;
        p.CatalogFamilyDescription__c = 'Software';
        insert p;
        Product2 product2 = [SELECT Name, ProductCode, Description, IsActive FROM product2 WHERE Name = 'Transportation' AND ProductCode = '6669' LIMIT 1];
        if(product2 == null) {
            product2 = new Product2(
                Name = 'Transportation'
                , ProductCode = '6669'
                , Description = 'Test Product'
                , IsActive = true
            );
        }else{
            product2.IsActive = true;
        }

        upsert product2;
        
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
            
        CartCheckoutSession ccs = new CartCheckoutSession();
        ccs.OrderId = o.Id;
        ccs.WebCartId = cart.Id;
        ccs.Name = 'testCCS';
        ccs.State = 'Payment And Billing Address';
        
        insert ccs;
        
        CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup(CartId=cart.Id, Name='Default Delivery');
        insert cartDeliveryGroup;
        
        insertCartItem(cart.Id, cartDeliveryGroup.Id, p.Id);
    }
    
    
    @isTest static void testCreditWithPaymentGateway() {
        setup();
        WebCart webCart = [SELECT Id FROM WebCart WHERE Name='B2BcommerceCart' LIMIT 1];
        
        String paymentType = 'CreditCard';
        String cartId = webCart.Id;
        //Map<String, Object> billingAddress = createBillingMapFromAddress(cpa1.Address);
        Map<String, Object> paymentInfo = new Map<String, Object>();
        //PaymentGateway pg = [SELECT Id FROM PaymentGateway WHERE PaymentGatewayName = 'CybersourceWithChargent'];
        
        
        Test.startTest();
        //Test.setMock(HttpCalloutMock.class, new B2BAtpProductsHttpCalloutMock()); 

        B2BPaymentController.setPayment(cartId, paymentInfo);
   
        Test.stopTest();

    }
    
    @isTest static void testAuthorize() {
        setup();
        WebCart webCart = [SELECT Id FROM WebCart WHERE Name='B2BcommerceCart' LIMIT 1];
        
        String cartId = webCart.Id;
        
        B2BAuthorizeTokenizedPayment.B2BAuthorizeTokenizedPaymentRequest request = new B2BAuthorizeTokenizedPayment.B2BAuthorizeTokenizedPaymentRequest();
        request.cartId = cartId;
        List<B2BAuthorizeTokenizedPayment.B2BAuthorizeTokenizedPaymentRequest> requestList = new List<B2BAuthorizeTokenizedPayment.B2BAuthorizeTokenizedPaymentRequest>();
        requestList.add(request);
        
        Test.startTest();
        //Test.setMock(HttpCalloutMock.class, new B2BAtpProductsHttpCalloutMock()); 

        List<String> errors = B2BAuthorizeTokenizedPayment.authorizePaymentInfo(requestList);
   
        Test.stopTest();

    }
    
    // Inserts a cart item that matches the cart and cart delivery group
    static void insertCartItem(String cartId, String cartDeliveryGroupId, String pId) {
       
        CartItem cartItem = new CartItem(
            CartId=cartId, 
            Product2Id=pId,
            Sku='SKU_Test1', 
            Quantity=3.0, 
            Type='Product', 
            Name='TestProduct', 
            CartDeliveryGroupId=cartDeliveryGroupId
        );
        insert cartItem;
    }

}