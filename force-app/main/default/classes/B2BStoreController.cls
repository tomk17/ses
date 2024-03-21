public without sharing class B2BStoreController {
    @AuraEnabled (cacheable=true)
    public static map<String, Id> getCategories(String communityId){
        String storeId = [SELECT WebStoreId FROM WebStoreNetwork WHERE NetworkId =:communityId LIMIT 1].WebStoreId;
        map<String, Id> mapIdNomCate = new map<String, Id>();
        WebStoreCatalog catalog = [SELECT Id, ProductCatalogId, SalesStoreId FROM WebStoreCatalog WHERE SalesStoreId =:storeId LIMIT 1];
        for(ProductCategory cat : [SELECT Id, Name FROM ProductCategory WHERE CatalogId =:catalog.ProductCatalogId]){
            mapIdNomCate.put(cat.Name, cat.Id);
        }
        return mapIdNomCate;
    }

    @AuraEnabled (cacheable=true)
    public static Boolean isEuropeAccountFunction(String orderId){
        Order ord = [SELECT Id, Account.pw_cc__ShippingCountryLookup__c FROM Order WHERE Id =:orderId];
        String zone = [SELECT Id, Zone__c FROM 	pw_cc__CountryObject__c WHERE Id =:ord.Account.pw_cc__ShippingCountryLookup__c].Zone__c;
        Boolean isEurope = false;
        if(zone == 'France' || zone == 'CEE' || zone == 'EMEA'){
            isEurope = true;
        }
        return isEurope;
    }
    
    @AuraEnabled (cacheable=true)
    public static Boolean isUSAccount(String cartId){
        WebCart cart = [SELECT Id, AccountId FROM WebCart WHERE Id =:cartId];
        Account acc = [SELECT Id, ShippingCountry FROM Account WHERE Id =:cart.AccountId];
        Boolean isUS = false;
        if(acc.ShippingCountry == 'United States'){
            isUS = true;
        }
        return isUS;
    }
    @AuraEnabled (cacheable=true) 
    public static String getContactPortalOptions(String userId) {
        User u =  [SELECT Id, Contact.Portal_Options__c from User WHERE id = :userId];
        return u.Contact.Portal_Options__c;
    }
}