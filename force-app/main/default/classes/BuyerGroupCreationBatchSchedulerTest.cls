@istest
public class BuyerGroupCreationBatchSchedulerTest {
    static testmethod void test() {
        Test.startTest();
        
        brand__c brand = Test_Utils_EI.createBrand('tst', '125');
        insert brand;
        account acc = Test_Utils_EI.createProspectAccount('customer', 'Brand', brand, 'INDEPENDANT', 'Direct', 'Food');
        acc.AccountNumber = '111';
        acc.ShippingCountry = 'FR';
        acc.acCore__ERPAccountType__c = 'Customer';
        acc.TECH_B2B_Store_Account__c = 'TEST';
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
        
        // Schedule the test job
        String sch = '0 0 7 1/1 * ? *';

        String jobId = System.schedule('test BuyerGroupCreationBatchScheduler',
                                       sch, 
                                       new BuyerGroupCreationBatchScheduler());
        
        // Get the information from the CronTrigger API object
        
        Test.stopTest();

        
    }
}