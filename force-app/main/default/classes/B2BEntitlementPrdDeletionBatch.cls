global class B2BEntitlementPrdDeletionBatch implements Database.Batchable<sObject>, Database.Stateful {

    private Integer entitlementProductTotalCount;
    private Integer entitlementProductDeletedCount;
    private Boolean errors;
    private Set<Id> setIds;
    private boolean schedule;

    global B2BEntitlementPrdDeletionBatch(Set<Id> idAccounts, boolean schedule) {
        this.setIds = idAccounts;
        this.entitlementProductTotalCount = 0;
        this.entitlementProductDeletedCount = 0;
        this.errors = false;
        this.schedule = schedule;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([ 
            SELECT id, Product.MaterialStatus__c  
            FROM CommerceEntitlementProduct 
            WHERE Product.MaterialStatus__c IN ('Blocked for Procurement (05)', 'Blocked for Sales (Z6)', 'Inactive (Z7)')
        ]); 
    }
    global void execute(Database.BatchableContext bc, list<CommerceEntitlementProduct>  commerceEntitlementProducts){
        try {
            this.entitlementProductTotalCount += commerceEntitlementProducts.size();
            delete(commerceEntitlementProducts);
            this.entitlementProductDeletedCount += commerceEntitlementProducts.size();
        } catch (Exception e) {
            System.debug(e);
            this.errors = true;
        }
    }
    global void finish(Database.BatchableContext bc){
        set<Id> setIdsParents = new set<Id>();

        if (this.setIds.size() == 0) {
            Set<String> topParent = new set<String>();
            List<Account> listAccs = [SELECT ID, Top_Parent__c FROM ACCOUNT WHERE TECH_B2B_Store_Account__c != null];
            for(Account acc : listAccs){
                topParent.add(acc.Top_Parent__c);
            }
            List<Account> listTopParent = [SELECT ID, Name FROM ACCOUNT WHERE Name IN:topParent OR AccountNumber IN:topParent];

            for(Account acc2 : listTopParent){
                setIdsParents.add(acc2.Id);
            }
        } else {
            setIdsParents = this.setIds;
        }
        BuyerGroupCreationBatch batch = new BuyerGroupCreationBatch(setIdsParents, this.schedule);
        Database.executeBatch(batch, 100);

    }
}