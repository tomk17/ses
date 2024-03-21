/* *******************************************************************************************************
 * Name               :                                                                                  *
 * Description        :                                                                                  *
 * Created Date       : 05.02.2021                                                                       *
 * Created By         : Joao Mota @Waeg                                                                  *
 * -----------------------------------------------------------------------------------------------       *
 * VERSION    AUTHOR                 DATE                                                                *
 *   1.0 -    Joao Mota   @Waeg      05-Feb-2021 Initial version                                         *
 ******************************************************************************************************* */
@isTest
private class B2B_AvalaraWebCallAPITest {
    
    @testSetup static void setup() {
        //Create Account
        Account acc = new Account(Name = 'TestAccount');
        insert acc;
        
        //Create WebStore
        WebStore store = new WebStore(Name = 'SES B2B Commerce');
        insert store;

        //Create new WebCart        
        WebCart cart = new WebCart(Name = 'CartTest',
                            AccountId = acc.Id,
                            WebStoreId = store.id);
        insert cart;
        
        //Create new DeliveryGroup
        CartDeliveryGroup deliveryGrp = new CartDeliveryGroup(CartId = cart.Id,
                                                        Name ='Delivery group test',
                                                        DeliverToName = 'John Doe', 
                                                        //DeliverToAddress, 
                                                        DeliverToStreet = '2000 Main Street', 
                                                        DeliverToCity = 'Irvine',
                                                        DeliverToState = 'CA', 
                                                        DeliverToCountry = 'US', 
                                                        DeliverToPostalCode = '92614');
        insert deliveryGrp;

        Product2 prod = new Product2(Name='productTest');
        insert prod;
        
        Product2 prod2 = new Product2(Name='productTest2', productCode = '6669');
        insert prod2;

        //Create new CartItems
        List<CartItem> cartItems = new List<CartItem>();
        List<String> skuList = new List<String>{'000000000000003684'};
        List<Decimal> amountList = new List<Decimal>{5540};
        List<Integer> quantityList = new List<Integer>{50};

		for(Integer i=0; i < skuList.size(); i++){
            cartItems.add(new CartItem(Name = 'ItemTest' + i,
                                        Type = 'Product',
                                        CartId = cart.Id,
                                        Product2Id = prod.Id,
                                        Quantity = quantityList[i],
                                        TotalPrice = amountList[i],
                                        Sku = skuList[i],
                                        CartDeliveryGroupId = deliveryGrp.Id));
        }
        insert cartItems;        
    }


    @isTest static void calculateAvataxTransationSuccessTest() {
        B2B_AvalaraWebCallAPI.AvalaraTransaction testTransaction = new B2B_AvalaraWebCallAPI.AvalaraTransaction();
        AvalaraHttpCalloutMock unitResponse = new AvalaraHttpCalloutMock(201,'SUCCESS','{"code":"123", "status":"commited", "totalAmount":"10", "totalTax":"2", "statusCode":"201"}','application/json');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class,unitResponse );
        
        WebCart cartTest = [SELECT Id, Name,
                    Account.Id,Account.Name,
                    PoNumber, CurrencyIsoCode, 
                    (SELECT Id, Quantity, TotalAmount, TotalPrice, SKU, Product2.Id, Product2.Name, Product2.ProductGroup__c, Product2.Material_group__c FROM CartItems)                            
                FROM WebCart
                WHERE Name = 'CartTest'];
        testTransaction = B2B_AvalaraWebCallAPI.calculateAvataxTransation(cartTest);
        
        System.assertEquals(testTransaction.status, 'commited');
        System.assertEquals(testTransaction.statusCode, 201);
        System.assertEquals(testTransaction.totalAmount, '10');
        Test.stopTest();
    }

    @isTest static void calculateAvataxTransationErrorTest() {
        B2B_AvalaraWebCallAPI.AvalaraTransaction testTransaction = new B2B_AvalaraWebCallAPI.AvalaraTransaction();
        AvalaraHttpCalloutMock unitResponse = new AvalaraHttpCalloutMock(401,'ERROR','{"error":{"details":[{"code":"", "errorNumber":"", "message":"Not Authorized", "refersTo":"" }]}}','application/json');
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class,unitResponse );
        WebCart cartTest = [SELECT Id, Name,
                    Account.Id,Account.Name,
                    PoNumber, CurrencyIsoCode, 
                    (SELECT Id, Quantity, TotalAmount, TotalPrice, SKU, Product2.Id, Product2.Name, Product2.ProductGroup__c, Product2.Material_group__c FROM CartItems)                            
                FROM WebCart
                WHERE Name = 'CartTest'];
        testTransaction = B2B_AvalaraWebCallAPI.calculateAvataxTransation(cartTest);

        System.assertEquals( 'Error', testTransaction.status);
        System.assertEquals( 401, testTransaction.statusCode );
        System.assertEquals(' Not Authorized', testTransaction.errorMessage );
        Test.stopTest();
    }
    
}