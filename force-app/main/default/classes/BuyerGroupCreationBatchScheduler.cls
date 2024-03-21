global class BuyerGroupCreationBatchScheduler implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        // Set<String> topParent = new set<String>();
        // List<Account> listAccs = [SELECT ID, Top_Parent__c FROM ACCOUNT WHERE TECH_B2B_Store_Account__c != null];
        // for(Account acc : listAccs){
        //     topParent.add(acc.Top_Parent__c);
        // }
        // List<Account> listTopParent = [SELECT ID, Name FROM ACCOUNT WHERE Name IN:topParent OR AccountNumber IN:topParent];
        // set<Id> setIdsParents = new set<Id>();
        // for(Account acc2 : listTopParent){
        //     setIdsParents.add(acc2.Id);
        // }
        // BuyerGroupCreationBatch batch = new BuyerGroupCreationBatch(setIdsParents, true);
        // Database.executeBatch(batch, 100);
        Set<Id> setIds = new Set<Id>();
        B2BEntitlementPrdDeletionBatch batch = new B2BEntitlementPrdDeletionBatch(setIds, true);
        Database.executeBatch(batch, 100);
    }
    
}