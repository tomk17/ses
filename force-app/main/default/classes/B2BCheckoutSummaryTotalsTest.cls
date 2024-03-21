@IsTest
public class B2BCheckoutSummaryTotalsTest {
    @testSetup 
    static void setup() {
        
        Account acc = new Account(Name = 'TestAccount');
        insert acc;
        
        WebStore store = new WebStore(Name = 'TestWebStore');
        insert store;
        //Create new WebCart
        WebCart cart = new WebCart(Name = 'cartName',
                                   AccountId = acc.Id,
                                   WebStoreId = store.Id,
                                   CurrencyIsoCode = 'USD');
        insert cart;
        
        //Create new DeliveryGroup
        CartDeliveryGroup deliveryGrp = new CartDeliveryGroup(CartId = cart.Id,
                                                              Name = 'Delivery group test',
                                                              DeliverToName = 'John Doe',
                                                              //DeliverToAddress,
                                                              DeliverToStreet = '2000 Main Street',
                                                              DeliverToCity = 'Irvine',
                                                              DeliverToState = 'CA',
                                                              DeliverToCountry = 'Canada',
                                                              DeliverToPostalCode = '92614');
        insert deliveryGrp;
    }
    
    @isTest
    static void testRetrieveDeliverToCountry() {
        Test.startTest();
        WebCart cart = [SELECT Id FROM WebCart WHERE Name = 'cartName'];
		String DeliverToCountry = B2BCheckoutSummaryTotals.retrieveDeliverToCountry(cart.Id);
        Test.stopTest();
    }
}