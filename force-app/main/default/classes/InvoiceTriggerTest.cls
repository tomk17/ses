@IsTest(SeeAllData=true)
public class InvoiceTriggerTest {
    
    static void setup() {
        Account testAccount = new Account(Name='TestAccount');
        insert testAccount;
        WebStore testWebStore = new WebStore(Name='SES B2B Commerce', DefaultLanguage='en_US');
        insert testWebStore;
      
        Account account = [SELECT Id FROM Account WHERE Name='TestAccount' LIMIT 1];
        WebStore webStore = [SELECT Id FROM WebStore WHERE Name='SES B2B Commerce' LIMIT 1];
        WebCart cart = new WebCart(Name='Cart', WebStoreId=webStore.Id, AccountId=account.Id, status = 'active');
        insert cart;
        
        // Insert Product
        Product2 p = new Product2();
        p.Name = ' Test Product ';
        p.Description='Test Product Entry 1';
        p.productCode = 'ABC';
        p.isActive = true;
        insert p;
        
        // Insert Product
        Product2 p2 = new Product2();
        p2.Name = ' Test Product ';
        p2.Description='Test Product Entry 2';
        p2.productCode = '6669';
        p2.isActive = true;
        insert p2;
        
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
        o.Order_Origin__c = 'B2B Commerce';
        
        insert o;
        // Insert Order Item
        
        OrderItem i = new OrderItem();
        i.OrderId = o.id;
        i.Quantity = 1;
        i.UnitPrice = 10;
        i.Product2id = p.id;
        i.PricebookEntryId=standardPrice.id;
        i.Type = 'Order Product';
        SBQQ.TriggerControl.disable();
        insert i;
        SBQQ.TriggerControl.enable();
        

        

    }
     
     @isTest static void TestInsertInvoicePopulatingPaymentAuthorizationField() {
         setup();

         System.debug('************** order *****************');
         Order order = [SELECT Id,TotalAmount, Bill_To_Account__c, SalesOrg__c, OwnerId FROM Order where Name = 'Test Order' LIMIT 1];
         System.debug(order);
         PaymentAuthorization pa = new PaymentAuthorization(
             AccountId = order.Bill_To_Account__c
             , Amount = 10
             , order__c = order.Id
             , Status = 'Processed'
             , ProcessingMode = 'External'
         );
         insert pa;
         SAPInvoice__c invoice = new SAPInvoice__c(
             Order__c = order.Id
             , Open_Amount__c = order.TotalAmount
             , Bill_To__c = order.Bill_To_Account__c
             , Sales_Org__c = order.SalesOrg__c
             , OwnerId = order.OwnerId
             , TECH_Invoice_Number__c = '9999999999'
             , Name = '9999999999'
         );
         Test.startTest();  
         insert invoice;
         Test.stopTest();

         SAPInvoice__c sapInvoice = [SELECT Payment_Authorization__c FROM SAPInvoice__c WHERE Id = :invoice.Id];
         PaymentAuthorization paymentAuthorization =  [SELECT Id, order__c FROM PaymentAuthorization WHERE order__c = :order.Id LIMIT 1];
         
         Assert.isNotNull(sapInvoice.Payment_Authorization__c, 'Invoice PaymentAuthorization field should not be null');
         System.assertEquals(sapInvoice.Payment_Authorization__c, paymentAuthorization.Id, 'Invoice PaymentAuthorization__c field value does match with PaymentAuthorization Id');
    }
    @isTest static void TestInsertInvoiceNullPaymentAuthorizationField() {
         setup();

         System.debug('************** order *****************');
         Order order = [SELECT Id,TotalAmount, Bill_To_Account__c, SalesOrg__c, OwnerId FROM Order where Name = 'Test Order' LIMIT 1];
         System.debug(order);

         SAPInvoice__c invoice = new SAPInvoice__c(
             Order__c = order.Id
             , Open_Amount__c = order.TotalAmount
             , Bill_To__c = order.Bill_To_Account__c
             , Sales_Org__c = order.SalesOrg__c
             , OwnerId = order.OwnerId
             , TECH_Invoice_Number__c = '9999999999'
             , Name = '9999999999'
         );
         Test.startTest();  
         insert invoice;
         Test.stopTest();

         SAPInvoice__c sapInvoice = [SELECT Payment_Authorization__c FROM SAPInvoice__c WHERE Id = :invoice.Id];
         
         Assert.isNull(sapInvoice.Payment_Authorization__c, 'Invoice PaymentAuthorization field should  be null');
    }
}