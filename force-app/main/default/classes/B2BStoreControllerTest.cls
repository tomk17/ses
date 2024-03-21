@isTest(SeeAllData=true)
public class B2BStoreControllerTest {
    public static String effectiveAccountId = null;
    public static String contactId = null;

    // cannot use test setup annotation in a see all data context
    static void setup() {
        
        pw_cc__CountryObject__c FR = [SELECT Id, Zone__c FROM pw_cc__CountryObject__c WHERE pw_cc__IsoCode_2__c = 'FR'];
        
        Account account = new Account(Name='TestAccount',pw_cc__ShippingCountryLookup__c = FR.Id, ShippingCountry='France');
        insert account;
        effectiveAccountId = account.Id;
        
        Contact contact = new Contact(LastName='TestAccount', AccountId=account.Id, Email='test@example.com');
        insert contact;
        contactId = contact.Id;
        
        WebStore store = [SELECT Id FROM WebStore WHERE Name = 'SES B2B Commerce'];
                
        //Create new WebCart        
        WebCart cart = new WebCart(Name = 'CartTestinB2BStoreControllerTest',
                                   AccountId = account.Id,
                                  WebStoreId = store.Id);
        insert cart;
        
        Order order = new Order(AccountId = account.Id, Status = 'Open', EffectiveDate = Date.today(), blng__BillingDayOfMonth__c = '1');
        insert order;

    }
    
    @IsTest
    static void TestMethods() {

        setup();
    
        Network community = [SELECT Id FROM Network WHERE Name = 'SES B2B Commerce'];
        
        map<String,Id> mapIdNameCate = B2BStoreController.getCategories(community.Id);
        
        Order ord = [SELECT Id, Account.pw_cc__ShippingCountryLookup__c FROM Order LIMIT 1];
        
        Boolean isEurope = B2BStoreController.isEuropeAccountFunction(ord.Id);
        
        WebCart cart = [SELECT Id, AccountId FROM WebCart WHERE name = 'CartTestinB2BStoreControllerTest' LIMIT 1];
        
        Boolean isUS = B2BStoreController.isUSAccount(cart.Id);

    }
}