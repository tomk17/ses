public class BuyerGroupCreationBatchController {
	@AuraEnabled
    public static Id executeBatchJob(Id accountId){
        Set<Id> setIds = new Set<Id>();
        setIds.add(accountId);
        //Id batchJobId = Database.executeBatch(new BuyerGroupCreationBatch(setIds, true), 5);
        Id batchJobId = Database.executeBatch(new B2BEntitlementPrdDeletionBatch(setIds, true), 5);
        return batchJobId;
    }

    @AuraEnabled
    public static AsyncApexJob getBatchJobStatus(Id jobID){
        AsyncApexJob jobInfo = [SELECT Status, NumberOfErrors,JobItemsProcessed,TotalJobItems FROM AsyncApexJob WHERE Id = :jobID];
        return jobInfo;
    }
}