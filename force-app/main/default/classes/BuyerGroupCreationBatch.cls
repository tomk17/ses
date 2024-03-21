global class BuyerGroupCreationBatch implements Database.Batchable<sObject>, Database.Stateful {

    //BuyerGroupCreationController bgcc;
    private Set<Id> childrenIds;
    private String query;
    private Set<Id> setIds;
    private Integer scope;
    private Boolean schedule;
    //variable globale scope
    
    global BuyerGroupCreationBatch(Set<Id> idAccounts, boolean schedule){
        this.setIds = idAccounts;
        this.childrenIds = new Set<Id>();
        query = 'SELECT Id, ParentId, Name, AccountNumber, CurrencyIsoCode FROM Account WHERE ID IN :setIds AND CurrencyIsoCode != \'BRL\' AND CurrencyIsoCode != \'ARS\'';
        scope = 50;
        this.schedule = schedule;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query); 
    }
    
    global void execute(Database.BatchableContext bc, List<Account> accounts){
        System.debug('execute scope : ' + accounts);
        BuyerGroupCreationController bgcc = new BuyerGroupCreationController(accounts);
        bgcc.clearAllExistingObjects();
   		bgcc.setChildren();
        bgcc.buyerAccountsCreation();
        bgcc.buyerGroupCreation();
        //childrenIds = bgcc.getChildren();
        for(Id anId : bgcc.getChildren()){
            childrenIds.add(anId);
        }
        System.debug('debug execute children ' + childrenIds.size());
    }    
    global void finish(Database.BatchableContext bc){
        System.debug('debug finish children ' + childrenIds.size());
        if(childrenIds.size() > 0){
            BuyerGroupCreationBatch batch = new BuyerGroupCreationBatch(childrenIds, false);
            Database.executeBatch(batch, scope);
        }
        
        if(schedule){
            BuildIndexScheduler bis = new BuildIndexScheduler();
			Datetime dt = Datetime.now() + (0.064);            
            String timeForScheduler = dt.format('s m H d M \'?\' yyyy');
            System.schedule('Build Index in BGs Creation Batch ' + timeForScheduler, timeForScheduler, bis);
        }    
    }
}