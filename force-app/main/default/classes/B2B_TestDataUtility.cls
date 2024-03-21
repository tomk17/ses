/* *******************************************************************************************************
 * Name               :                                                                                  *
 * Description        :                                                                                  *
 * Created Date       : 05.02.2021                                                                       *
 * Created By         : Joao Mota @Waeg                                                                  *
 * -----------------------------------------------------------------------------------------------       *
 * VERSION    AUTHOR                 DATE                                                                *
 *   1.0 -    Joao Mota   @Waeg      05-Feb-2021 Initial version                                         *
 ******************************************************************************************************* */

@IsTest
public class B2B_TestDataUtility {
    static String STORE_NAME = 'SES B2B Commerce';

    public class B2B_TestContext {
        public Id cartId;
        public Id storeId;
        public Id accountId;
    }
    
    public static B2B_TestContext createWebCartContext(String communityUsername, String cartName, List<String> cartItemsSkuList, List<Decimal> cartItemsAmountList, List<Decimal> cartItemsQuantityList) {
        User communityUser;

        System.runAs(new User(Id = UserInfo.getUserId())) {
            //Create User
            UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
            Profile profile1 = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
            User portalAccountOwner1 = new User(
                    UserRoleId = portalRole.Id,
                    ProfileId = profile1.Id,
                    Username = System.now().millisecond() + 'test2@test.com',
                    Alias = 'batman',
                    Email = 'bruce.wayne@sesimagotagtest.com',
                    EmailEncodingKey = 'UTF-8',
                    FirstName = 'Bruce',
                    LastName = 'Wayne',
                    LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US',
                    TimeZoneSidKey = 'America/Chicago',
                    acCore__SalesRepCode__c = 'DUMMY',
                    Street = 'Street of no name',
                    City = 'Irvine',
                    Country = 'United States',
                    PostalCode = '10002',
                    State = 'CA'
            );
            Database.insert(portalAccountOwner1);
            
            //Create Account
            Id recordTypeActivePartner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Active Partner').getRecordTypeId();
            Account ac = new Account(recordTypeId = recordTypeActivePartner,
                                                    NotCustomerAnymore__c = false,
                                                    Name = 'TestAccount', OwnerId=portalAccountOwner1.Id,
                                                    ShippingStreet = 'Street of no name',
                                                    ShippingCity = 'Irvine',
                                                    ShippingCountry = 'United States',
                                                    ShippingPostalCode = '10002',
                                                    ShippingState = 'CA',
                                                    BillingStreet = 'Street of no name',
                                                    BillingCity = 'Irvine',
                                                    BillingCountry = 'United States',
                                                    BillingPostalCode = '10002',
                                                    BillingState = 'CA');
            Database.insert(ac);

            //Create Contact
            Contact con = new Contact(FirstName = 'John', LastName = 'Doe', AccountId = ac.Id, Email = 'test@example.com.invalid');
            Database.insert(con);

            //Create user
            //Profile portalProfile = [SELECT Id FROM Profile WHERE Name LIKE '%Customer Community Plus%' Limit 1];
            Profile portalProfile = [SELECT Id FROM Profile WHERE Name LIKE 'Customer Community Plus User' LIMIT 1];
                        
            communityUser = new User(
                    Username = communityUsername,
                    ContactId = con.Id,
                    ProfileId = portalProfile.Id,
                    Alias = 'test123',
                    Email = 'test12345@test.com',
                    EmailEncodingKey = 'UTF-8',
                    LastName = 'McTesty',
                    CommunityNickname = 'test12345',
                    TimeZoneSidKey = 'America/Los_Angeles',
                    LocaleSidKey = 'en_US',
                    LanguageLocaleKey = 'en_US',
                    acCore__SalesRepCode__c = 'DUMMY2',
                    Street = 'Street of no name',
                    City = 'Irvine',
                    Country = 'United States',
                    PostalCode = '10002',
                    State = 'CA'
            );
            Database.insert(communityUser);

            PermissionSet testPS = [
                    SELECT Name
                    FROM PermissionSet
                    WHERE Name = 'B2B_Commerce_Buyer'];
            PermissionSetAssignment testPSA = new PermissionSetAssignment();
            testPSA.PermissionSetId = testPS.Id;
            testPSA.AssigneeId = communityUser.Id;
            insert testPSA;
        }

        Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccount'];
        //Create WebStore
        WebStore store = new WebStore(Name = 'TestWebStore');
        insert store;


        //Create new WebCart
        WebCart cart = new WebCart(Name = cartName,
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

        OrderDeliveryMethod deliveryMethod = new OrderDeliveryMethod( Name = 'Standard Delivery' );
        insert deliveryMethod;

        List<Product2> prodList = new List<Product2>{new Product2(Name = 'Transportation', ProductCode = '6669'),
                                                    new Product2(Name = 'productTest')};
        insert prodList;

        //Create new CartItems
        List<CartItem> cartItems = new List<CartItem>();
        
		for(Integer i=0; i < cartItemsSkuList.size(); i++){
            cartItems.add(new CartItem(Name = 'ItemTest' + i,
                                        Type = 'Product',
                                        CartId = cart.Id,
                                        Product2Id = prodList[1].Id,
                                        Quantity = cartItemsQuantityList[i],
                                        TotalPrice = cartItemsAmountList[i],
                                        ListPrice = cartItemsAmountList[i],
                                        Sku = cartItemsSkuList[i],
                                        CartDeliveryGroupId = deliveryGrp.Id));
        }
        insert cartItems; 

        B2B_TestContext testDataContext = new B2B_TestContext();
        testDataContext.cartId = cart.Id;
        testDataContext.storeId = store.Id;
        testDataContext.accountId = acc.Id;

        return testDataContext;
    }

    public static B2B_TestContext createWebCartContext2(String communityUsername, String cartName, List<String> cartItemsSkuList, List<Decimal> cartItemsAmountList, List<Decimal> cartItemsQuantityList) {
        User communityUser;
        B2B_TestContext testDataContext = new B2B_TestContext();
        WebStore store;
        List<Product2> prodList;

        System.runAs(new User(Id = UserInfo.getUserId())) {
            //Create User
            UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
            Profile profile1 = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
            User portalAccountOwner1 = new User(
                    UserRoleId = portalRole.Id,
                    ProfileId = profile1.Id,
                    Username = System.now().millisecond() + 'test4@test.com',
                    Alias = 'batman',
                    Email = 'bruce.wayne2@sesimagotagtest.com',
                    EmailEncodingKey = 'UTF-8',
                    FirstName = 'Brucee',
                    LastName = 'Waynee',
                    LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US',
                    TimeZoneSidKey = 'America/Chicago',
                    acCore__SalesRepCode__c = 'DUMMY',
                    Street = 'Street of no name',
                    City = 'Irvine',
                    Country = 'United States',
                    PostalCode = '10002',
                    State = 'CA'
            );
            Database.insert(portalAccountOwner1);
            
            //Create Account
            Id recordTypeActivePartner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Active Partner').getRecordTypeId();
            Account ac = new Account(recordTypeId = recordTypeActivePartner,
                                                    NotCustomerAnymore__c = false,
                                                    Name = 'TestAccount', OwnerId=portalAccountOwner1.Id,
                                                    ShippingStreet = 'Street of no name',
                                                    ShippingCity = 'Irvine',
                                                    ShippingCountry = 'United States',
                                                    ShippingPostalCode = '10002',
                                                    ShippingState = 'CA',
                                                    BillingStreet = 'Street of no name',
                                                    BillingCity = 'Irvine',
                                                    BillingCountry = 'United States',
                                                    BillingPostalCode = '10002',
                                                    BillingState = 'CA');
            Database.insert(ac);

            //Create Contact
            Contact con = new Contact(FirstName = 'John', LastName = 'Doe', AccountId = ac.Id, Email = 'test@example.com.invalid');
            Database.insert(con);

            //Create user
            //Profile portalProfile = [SELECT Id FROM Profile WHERE Name LIKE '%Customer Community Plus%' Limit 1];
            Profile portalProfile = [SELECT Id FROM Profile WHERE Name LIKE 'Customer Community Login User SES-imagotag' LIMIT 1];
                        
            communityUser = new User(
                    Username = communityUsername,
                    ContactId = con.Id,
                    ProfileId = portalProfile.Id,
                    Alias = 'test123',
                    Email = 'test12345@test.com',
                    EmailEncodingKey = 'UTF-8',
                    LastName = 'McTesty',
                    CommunityNickname = 'test12345',
                    TimeZoneSidKey = 'America/Los_Angeles',
                    LocaleSidKey = 'en_US',
                    LanguageLocaleKey = 'en_US',
                    acCore__SalesRepCode__c = 'DUMMY2',
                    Street = 'Street of no name',
                    City = 'Irvine',
                    Country = 'United States',
                    PostalCode = '10002',
                    State = 'CA'
            );
            Database.insert(communityUser);

            PermissionSet testPS = [
                    SELECT Name
                    FROM PermissionSet
                    WHERE Name = 'B2BBuyer'];
            PermissionSetAssignment testPSA = new PermissionSetAssignment();
            testPSA.PermissionSetId = testPS.Id;
            testPSA.AssigneeId = communityUser.Id;
            insert testPSA;

            store = new WebStore(Name = 'SES B2B Commerce');
            insert store;

            Pricebook2 testPricebook = new Pricebook2(
                    Name = 'Test Pricebook'
            );
            insert testPricebook;

            WebStorePricebook testWSP = new WebStorePricebook(
                    Pricebook2Id = testPricebook.Id,
                    WebStoreId = store.Id
            );
            insert testWSP;

            prodList = new List<Product2>{new Product2(Name = 'Transportation', ProductCode = '6669'),
                    new Product2(Name='Softwares Licenseee',ProductCode = '8096'),
                    new Product2(Name = 'productTest',ProductCode = '8097')};
            insert prodList;
            Set<String> skus = new Set<String>{'6669','8096','8097'};
            List<product2> prodlistinsert = [SELECT Id, Name FROM Product2 WHERE StockKeepingUnit IN :skus];
            System.debug('BEN prodlistinsert : ' + prodlistinsert);

            List<PricebookEntry> prdEntries = new List<PricebookEntry>();
            for(Product2 prd : prodList){
                PricebookEntry testEntry = new PricebookEntry(
                        Pricebook2Id = Test.getStandardPricebookId(),
                        Product2Id = prd.Id,
                        UnitPrice = 190
                );
                prdEntries.add(testEntry);
            }
            for(Product2 prd : prodList){
                PricebookEntry testEntry = new PricebookEntry(
                        Pricebook2Id = testPricebook.Id,
                        Product2Id = prd.Id,
                        UnitPrice = 190
                );
                prdEntries.add(testEntry);
            }
            insert prdEntries;
        }

        System.runAs(communityUser) {
            Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccount'];
            //Create WebStore

            //Create new WebCart
            WebCart cart = new WebCart(Name = cartName,
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

            OrderDeliveryMethod deliveryMethod = new OrderDeliveryMethod( Name = 'Standard Delivery' );
            insert deliveryMethod;

            CartDeliveryGroupMethod deliveryGrpMethod = new CartDeliveryGroupMethod(Name='Test delivery group',
            CartDeliveryGroupId= deliveryGrp.Id,
            WebCartId = cart.Id,
            CurrencyIsoCode = 'USD',                                                                        
            DeliveryMethodId  = deliveryMethod.Id,
            ShippingFee=0);
            insert deliveryGrpMethod;
            //Create new CartItems
            List<CartItem> cartItems = new List<CartItem>();
            
            for(Integer i=0; i < cartItemsSkuList.size(); i++){
                cartItems.add(new CartItem(Name = 'ItemTest' + i,
                                            Type = 'Product',
                                            CartId = cart.Id,
                                            Product2Id = prodList[1].Id,
                                            Quantity = cartItemsQuantityList[i],
                                            TotalPrice = cartItemsAmountList[i],
                                            ListPrice = cartItemsAmountList[i],
                                            Sku = prodList[1].StockKeepingUnit,
                                            CurrencyIsoCode = 'USD',
                                            CartDeliveryGroupId = deliveryGrp.Id));
            }
            insert cartItems; 

            
            testDataContext.cartId = cart.Id;
            testDataContext.storeId = store.Id;
            testDataContext.accountId = acc.Id;
        }       

        return testDataContext;
    }

    public static B2B_TestContext createTestData_SeeAllData(String communityUsername, String cartName) {
        Account testAcccount;
        Contact testContact;
        User communityUser;
        WebStore store;
        WebCart cart;

        //Create Account
        testAcccount = new Account(
                //RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Client').getRecordTypeId(),
                Name = 'TestAccount4',
                ShippingStreet = 'Street of no name1',
                ShippingCity = 'Irvine1',
                ShippingCountry = 'United States',
                ShippingPostalCode = '10002',
                ShippingState = 'CA',
                BillingStreet = 'Street of no name',
                BillingCity = 'Irvine',
                BillingCountry = 'United States',
                BillingPostalCode = '10002',
                BillingState = 'CA'
        );
        Database.insert(testAcccount);

        BuyerAccount testBA = new BuyerAccount(
                IsActive = true,
                BuyerId = testAcccount.Id,
                Name = testAcccount.Name
        );
        insert testBA;

        //Create Contact
        testContact = new Contact(
                FirstName = 'Johnny',
                LastName = 'Doenny',
                AccountId = testAcccount.Id,
                Email = 'tes2t@example.com.invalid',
                Is_Customer_Portal_User__c = true
        );
        Database.insert(testContact);

        //Create user
        Profile portalProfile = [SELECT Id FROM Profile WHERE Name LIKE 'Customer Community Plus User' LIMIT 1];

        communityUser = new User(
                Username = communityUsername,
                ContactId = testContact.Id,
                ProfileId = portalProfile.Id,
                Alias = 'test143',
                Email = 'test12445@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'MacTesty',
                CommunityNickname = 'test14345',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                acCore__SalesRepCode__c = 'DUMMY2',
                Street = 'Street of no name',
                City = 'Irvine',
                Country = 'United States',
                PostalCode = '10002',
                State = 'CA'
        );
        Database.insert(communityUser);

        WebStoreBuyerGroup wsbg = [
                SELECT  Id,
                        Name,
                        BuyerGroupId
                FROM WebStoreBuyerGroup
                WHERE WebStore.Name = 'SES B2B Commerce'
                LIMIT 1
        ];
        BuyerGroupMember bgm = new BuyerGroupMember();
        bgm.BuyerGroupId = wsbg.BuyerGroupId;
        bgm.BuyerId = testAcccount.Id;
        insert bgm;

        //Get WebStore
        store = [SELECT Id FROM WebStore WHERE Name = :STORE_NAME];

        //Create new WebCart
        cart = new WebCart(
                Name = cartName,
                AccountId = testAcccount.Id,
                WebStoreId = store.Id,
                CurrencyIsoCode = 'USD',
                OwnerId = communityUser.Id,
                Status = 'Active'
        );
        insert cart;

        System.runAs(new User(Id = UserInfo.getUserId())) {
            PermissionSet testPS = [
                    SELECT Name
                    FROM PermissionSet
                    WHERE Name = 'B2B_Commerce_Buyer'];
            PermissionSetAssignment testPSA = new PermissionSetAssignment();
            testPSA.PermissionSetId = testPS.Id;
            testPSA.AssigneeId = communityUser.Id;
            insert testPSA;
        }

        //Create new DeliveryGroup
        CartDeliveryGroup deliveryGrp = new CartDeliveryGroup(
                CartId = cart.Id,
                Name = 'Delivery group test',
                DeliverToName = 'Johnny Doenny',
                DeliverToStreet = '2000 Main Streeet',
                DeliverToCity = 'Irvine2',
                DeliverToState = 'CA',
                DeliverToCountry = 'Canada',
                DeliverToPostalCode = '92614');
        insert deliveryGrp;

        OrderDeliveryMethod deliveryMethod = new OrderDeliveryMethod( Name = 'Standard Delivery' );
        insert deliveryMethod;

        B2B_TestContext testDataContext = new B2B_TestContext();
        testDataContext.cartId = cart.Id;
        testDataContext.storeId = store.Id;
        testDataContext.accountId = testAcccount.Id;

        return testDataContext;
    }
}