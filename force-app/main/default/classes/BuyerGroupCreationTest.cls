@isTest
public class BuyerGroupCreationTest {
    
    @testSetup
    static void setup() {
        brand__c brand = Test_Utils_EI.createBrand('tst', '125');
        insert brand;
        account acc = Test_Utils_EI.createProspectAccount('customer', 'Brand', brand, 'INDEPENDANT', 'Direct', 'Food');
        acc.AccountNumber = '111';
        acc.ShippingCountry = 'FR';
        acc.acCore__ERPAccountType__c = 'Customer';
        insert acc;
        Product2 product = new Product2(
            CanUseQuantitySchedule=true,
            CanUseRevenueSchedule =true,
            //CurrencyIsoCode="EUR",
            isActive=true,
            Name='core appliance bundle incl. usa/canada power supply');
        insert product;
        WebStore ws = new WebStore(name = 'SES B2B Commerce');
        insert ws;
		SBQQ__ContractedPrice__c cp = new SBQQ__ContractedPrice__c(SBQQ__Account__c = acc.Id, Restock_MROPrice__c = 9, SBQQ__Product__c = product.Id);
        insert cp;
    }
    
    @isTest 
    static void test() {
        Test.startTest();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Id jobId = BuyerGroupCreationBatchController.executeBatchJob(acc.Id);
        BuyerGroupCreationBatchController.getBatchJobStatus(jobId);
        Test.stopTest();
    }

    @isTest 
	static void TestBuyerGroupCreationAndEntitlementPrdDeletionBatch() {
        List<Account> accounts = new List<Account>();
        Set<Id> childrenIds;
        
        Account acc = [SELECT Id, Name, AccountNumber, CurrencyIsoCode, ParentId FROM Account LIMIT 1];
        accounts.add(acc);    
        BuyerGroupCreationController bgcc = new BuyerGroupCreationController(accounts);
        bgcc.clearAllExistingObjects();
   		bgcc.setChildren();
        bgcc.buyerAccountsCreation();
        bgcc.buyerGroupCreation();
        for(Id anId : bgcc.getChildren()){
            childrenIds.add(anId);
        }
        Test.startTest();
       	Product2 p = [SELECT Id, Name, MaterialStatus__c FROM Product2 WHERE Name = 'core appliance bundle incl. usa/canada power supply' LIMIT 1];
       	p.MaterialStatus__c = 'Blocked for Procurement (05)';
       	update p;
        Set<Id> setIds = new Set<Id>();
        setIds.add(acc.Id);
        id jobId = Database.executeBatch(new B2BEntitlementPrdDeletionBatch(setIds, true), 50);
       	Test.stopTest();
       	
    }
    
    @isTest 
	static void TestBuyerGroupCreationAndEntitlementPrdDeletionBatchEmptySetOfAccount() {
        List<Account> accounts = new List<Account>();
        Set<Id> childrenIds;
        
        Account acc = [SELECT Id, Name, AccountNumber, CurrencyIsoCode, ParentId FROM Account LIMIT 1];
        accounts.add(acc);    
        BuyerGroupCreationController bgcc = new BuyerGroupCreationController(accounts);
        bgcc.clearAllExistingObjects();
   		bgcc.setChildren();
        bgcc.buyerAccountsCreation();
        bgcc.buyerGroupCreation();
        for(Id anId : bgcc.getChildren()){
            childrenIds.add(anId);
        }
        Test.startTest();

       	Product2 p = [SELECT Id, Name, MaterialStatus__c FROM Product2 WHERE Name = 'core appliance bundle incl. usa/canada power supply' LIMIT 1];
       	p.MaterialStatus__c = 'Blocked for Procurement (05)';
       	update p;
        Set<Id> setIds = new Set<Id>();
        id jobId = Database.executeBatch(new B2BEntitlementPrdDeletionBatch(setIds, true), 50);
       	Test.stopTest();
       	
    }
}