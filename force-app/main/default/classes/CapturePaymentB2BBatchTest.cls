@IsTest(SeeAllData=true)
public class CapturePaymentB2BBatchTest {
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
        p.Name = ' Test Product 1 ';
        p.Description='Test Product Entry 1';
        p.productCode = 'ABC';
        p.isActive = true;
        insert p;
        
        // upsert Product
       
        Product2 p2 = [SELECT Name, ProductCode, Description, IsActive FROM product2 WHERE Name = 'Transportation' AND ProductCode = '6669' LIMIT 1];
        if(p2 == null) {
            p2 = new Product2(
                Name = 'Transportation'
                , ProductCode = '6669'
                , Description = 'Test Product'
                , IsActive = true
            );
        } else {
            p2.IsActive = true;
        }
        upsert p2;

        Id pricebookId = Test.getStandardPricebookId();
        
        // Insert PricebookEntry
        
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = pricebookId;
        standardPrice.Product2Id = p.Id;
        standardPrice.UnitPrice = 1;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        insert standardPrice ;
        
        
        // Create Contact
        
        Contact contact = new Contact(AccountId = account.Id, FirstName = 'capture', LastName = 'test', Email = 'b2bc_test@test.com');
        insert contact;
        
        // Search Profile 
        Profile profile = [SELECT Id, Name FROM Profile WHERE Name = 'Customer Community Login User SES-imagotag' LIMIT 1];
        
        User user = new User(
            username = System.now().millisecond() + 'test12345@test.com'
            , contactId = contact.Id
            , profileId = profile.Id
            , alias = 'B2BTtest'
            , email = 'b2bc_test@test.com'
            , emailEncodingKey = 'UTF-8'
            , isActive = true
            , lastName = 'B2BcTtest'
            , timeZoneSidKey = 'Europe/Paris'
            , localeSidKey = 'en_US'
            , languageLocaleKey = 'en_US'
        );
        insert user;
		// Insert Order
        Order o = new Order();
        o.Name = 'B2B Test Order';
        o.Status = 'Draft';
        o.EffectiveDate = system.today();
        o.EndDate = system.today() + 4;
        o.AccountId = account.id;
        o.blng__BillingDayOfMonth__c = '1';
        o.Pricebook2Id =  pricebookId ;
        o.Order_Origin__c = 'B2B Commerce';
        o.OwnerId = User.Id;
        
        insert o;
        // Insert Order Item
        
        OrderItem oi = new OrderItem();
        oi.OrderId = o.id;
        oi.Quantity = 1;
        oi.UnitPrice = 10;
        oi.Product2id = p.id;
        oi.PricebookEntryId=standardPrice.id;
        oi.Type = 'Order Product';
        SBQQ.TriggerControl.disable();
        insert oi;
        SBQQ.TriggerControl.enable();
        

        
        Order order = [SELECT Id, Bill_To_Account__c, SalesOrg__c, ShipToAccount__c , OwnerId, Tax_Amount__c, TotalAmount FROM Order WHERE Id = :o.Id];
        OrderItem orderItem = [SELECT Id, product2Id, Quantity, unitPrice, TotalPrice FROM OrderItem WHERE Id = :oi.Id];
        System.debug('********** order *********');
        System.debug(order);
        System.debug('********** order Item *********');
        System.debug(orderItem); 
        
        PaymentAuthorization pa = new PaymentAuthorization(
            AccountId = order.Bill_To_Account__c
            , Amount = 10
            , order__c = order.Id
            , Status = 'Processed'
            , ProcessingMode = 'External'
            , GatewayRefNumber = '6886308888276241503008'
        );
        insert pa;
        
        SAPInvoice__c i = new SAPInvoice__c(
            Order__c = order.Id
            , Open_Amount__c = order.TotalAmount
            , Bill_To__c = order.Bill_To_Account__c
            , Sales_Org__c = order.SalesOrg__c
            , OwnerId = order.OwnerId
            , Tax_Amount__c = order.Tax_Amount__c
            , TECH_Invoice_Number__c = 'test_capture_invoice'
            , Name = 'test_capture_invoice'
        );
        insert i;
        
        SAPInvoice__c invoice = [SELECT Id, Open_Amount__c, Bill_To__c, Sales_Org__c, OwnerId, Tax_Amount__c, Name FROM SAPInvoice__c WHERE Id = :i.Id];
        System.debug('********** Invoice *********');
        System.debug(invoice);

        SAPInvoice_Line__c invoiceline = new SAPInvoice_Line__c(
            Invoice__c = invoice.Id
            , Product__c= orderItem.product2Id
            , Quantity__c = orderItem.Quantity
            , Gross_Price__c = orderItem.unitPrice
            , Net_Value__c = orderItem.TotalPrice
        );
        
        insert invoiceline;
        System.debug('********* invoiceline');
        System.debug(invoiceline);

        CybersourceSettings__c cybersourceSettings = new CybersourceSettings__c(
        	host__c = 'http://apitest.cybersource.com'
            , chatter_group__c = ''
            , payment_endpoint__c = '/pts/v2/payments'
            , organization_Id__c = 'ses_imagotag_smb_us'
            , private_key__c = 'sZMRZkqqWL7LEivo8j9dYElIh0t6KwaLTnnX7bb0bGQ='
            , public_key__c = '26948455-8add-4917-a642-854b41cb8b50'
            , producion_env__c = false
        );
        insert cybersourceSettings;
            
    }
    
    @isTest static void TestCapturePayment() {
        System.debug('********** TestCapturePayment *********');
        setup();
        Test.setMock(HttpCalloutMock.class, new CybersourceCalloutMock()); 
      	
		SAPInvoice__c invoice = [
            SELECT Id, Invoice_Amount__c, Tax_Amount__c, Name, Payment_Authorization__r.GatewayRefNumber, Capture_id__c, Capture_request_date__c
            FROM SAPInvoice__c 
            WHERE Name = 'test_capture_invoice'
            LIMIT 1
        ];
        System.debug('********** Invoice *********');
        System.debug(invoice);
        CybersourceSettings__c credentials =  [
            SELECT id, host__c, payment_endpoint__c,  organization_Id__c, private_key__c, public_key__c
            FROM CybersourceSettings__c 
            WHERE producion_env__c = false 
            LIMIT 1
        ];
        System.debug('********** credentials *********');
        System.debug(invoice);
        
        Test.startTest();
        CapturePaymentB2B.CapturePayment(JSON.serialize(invoice), JSON.serialize(credentials));
        Test.stopTest();
        
        SAPInvoice__c updatedInvoice = [SELECT Capture_id__c, Capture_request_date__c FROM  SAPInvoice__c WHERE Id = :invoice.Id];
        System.debug('********** updatedInvoice *********');
        System.debug(updatedInvoice);
        
        Assert.isNotNull(updatedInvoice.Capture_id__c, 'Field SAPInvoice__c.Capture_id__c should not be null');
        Assert.isNotNull(updatedInvoice.Capture_request_date__c, 'Field SAPInvoice__c.Capture_request_date__c should not be null');
    }
    
    @isTest static void TestCapturePaymentError() {
        System.debug('********** TestCapturePayment *********');
        setup();
        Test.setMock(HttpCalloutMock.class, new CybersourceCalloutErrorMock()); 
      	
		SAPInvoice__c invoice = [
            SELECT Id, Invoice_Amount__c, Tax_Amount__c, Name, Payment_Authorization__r.GatewayRefNumber, Capture_id__c, Capture_request_date__c
            FROM SAPInvoice__c 
            WHERE Name = 'test_capture_invoice'
            LIMIT 1
        ];
        System.debug('********** Invoice *********');
        System.debug(invoice);
        CybersourceSettings__c credentials =  [
            SELECT id, host__c, payment_endpoint__c,  organization_Id__c, private_key__c, public_key__c
            FROM CybersourceSettings__c 
            WHERE producion_env__c = false 
            LIMIT 1
        ];
        System.debug('********** credentials *********');
        System.debug(invoice);
        
        Test.startTest();
        CapturePaymentB2B.CapturePayment(JSON.serialize(invoice), JSON.serialize(credentials));
        Test.stopTest();
        
        SAPInvoice__c updatedInvoice = [SELECT Capture_id__c, Capture_request_date__c FROM  SAPInvoice__c WHERE Id = :invoice.Id];
        System.debug('********** updatedInvoice *********');
        System.debug(updatedInvoice);
        
        Assert.isNull(updatedInvoice.Capture_id__c, 'Field SAPInvoice__c.Capture_id__c should not be null');
        Assert.isNull(updatedInvoice.Capture_request_date__c, 'Field SAPInvoice__c.Capture_request_date__c should not be null');
    } 
    @isTest static void TestCapturePaymentBatch() {
        setup();
        Test.setMock(HttpCalloutMock.class, new CybersourceCalloutMock()); 
        Test.startTest();
        CapturePaymentB2BBatch cpb = new CapturePaymentB2BBatch();
        Id batchId = Database.executeBatch(cpb, 100);
                
        Test.stopTest();  
        Assert.IsNotNull(batchId, 'Batch should not be null');

    }
     
    @isTest static void TestCapturePaymentScheduler() {
        setup();
        String CRON_EXP = '20 30 8 10 2 ?';
        Test.setMock(HttpCalloutMock.class, new CybersourceCalloutMock()); 
        SchedulableContext sc = null;
        Test.startTest();
		String jobId =  System.schedule('CapturePaymentJob', CRON_EXP, new CapturePaymentB2BScheduler());
        Integer ct = [
            SELECT count()
            FROM CronTrigger 
            WHERE id = :jobId
        ];
        Test.stopTest();
        System.assertEquals(1, ct, 'No cron job where scheduled');
  
    }
}