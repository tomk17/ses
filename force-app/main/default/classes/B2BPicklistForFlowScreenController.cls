public without sharing class B2BPicklistForFlowScreenController {
    @AuraEnabled  
    public static List<Account> returnListAccount(Account acc, Boolean boolShip, Boolean boolBill) {
        List<AccountFunction__c> accFuncs = new List<AccountFunction__c>();
        if(boolShip) {
        	accFuncs = [SELECT Id, FunctionAccount__c FROM AccountFunction__c WHERE CurrentAccount__c =:acc.Id AND Function__c = 'Ship-To Party'];
        }else if(boolBill) {
            accFuncs = [SELECT Id, FunctionAccount__c FROM AccountFunction__c WHERE CurrentAccount__c =:acc.Id AND Function__c = 'Bill-To Party'];
        }
        Set<Id> idAccs = new Set<Id>();
        for(AccountFunction__c accFunc : accFuncs){
            idAccs.add(accFunc.FunctionAccount__c);
        }
        List<Account> listAccs = [SELECT Id, ShippingAddress, Name, Incoterms__c FROM Account WHERE Id IN :idAccs AND NotCustomerAnymore__c = false];
        return listAccs;
    }
    
    @AuraEnabled  
    public static Account returnAccountSelected(String idAcc) {
        Account acc = [SELECT Id, ShippingAddress, BillingAddress, Incoterms__c, Name FROM Account WHERE Id =:idAcc];
        return acc;
    }
    
    @AuraEnabled  
    public static Account returnPickingAccountSelected(String idAcc) {
        List<Account_Salesorg__c> aso = [SELECT Id, Sales_Org__c FROM Account_Salesorg__c WHERE Account__c = :idAcc AND Primary__c = true LIMIT 1];
        List<Sales_Org__c> listSo = new List<Sales_Org__c>();
        if(aso.size()>0){
            listSo = [SELECT Id, Code__c FROM Sales_Org__c WHERE Id = :aso[0].Sales_Org__c LIMIT 1];
        }
        String strCode = '';
        if(listSo.size()>0){
            strCode = String.ValueOf(listSo[0].Code__c);
        }
        List<Account> acc = [SELECT Id, ShippingAddress, BillingAddress, Incoterms__c, Name FROM Account WHERE AccountNumber =:strCode LIMIT 1];
        return acc[0];
    }
    
    @AuraEnabled  
    public static Contact returnContactSelected(String idCon) {
        Contact con = [SELECT Id, Name, Email FROM Contact WHERE Id =:idCon];
        return con;
    }
    
    @AuraEnabled  
    public static List<Contact> returnContacts(WebCart cart, String accId, Boolean boolShip, Boolean boolBill) {
        System.debug(cart);
        User userFromCart = [SELECT Id, ContactId FROM User WHERE Id =:cart.OwnerId];
        Contact contactFromCart = [SELECT Id, Name, Email FROM Contact WHERE Id =:userFromCart.ContactId];
        
        List<AccountContactRelation> accConRels = new List<AccountContactRelation>();
        if(boolShip) {
            accConRels = [SELECT Id, ContactId FROM AccountContactRelation WHERE AccountId =:accId AND Function__c INCLUDES('Ship-to contact')];
        }else if(boolBill){
            accConRels = [SELECT Id, ContactId FROM AccountContactRelation WHERE AccountId =:accId AND Function__c INCLUDES('Bill-to contact')];
        }
        Set<Id> idCons = new Set<Id>();
        for(AccountContactRelation accConRel : accConRels){
            idCons.add(accConRel.ContactId);
        }
        List<Contact> listCons = [SELECT Id, Name, Email FROM Contact WHERE Id IN :idCons];
        System.debug(listCons);
        System.debug(contactFromCart);

        if(listCons.contains(contactFromCart) && listCons.size() > 1){
            Integer itemPos = listCons.indexOf(contactFromCart);
            listCons.remove(itemPos);
            listCons.add(0, contactFromCart );
        }
        return listCons;
    }
}