public without sharing class B2BPaymentPOOnlyController {
    @AuraEnabled  
    public static String returnPaymentTerm(String idAcc) {
        Account acc = [SELECT Id, acCore__PaymentTerm__c FROM Account WHERE Id =:idAcc];
        if(acc.acCore__PaymentTerm__c == null){
            return '';
        }
        acCore__PaymentTerms__c pt = [SELECT Id, Name FROM acCore__PaymentTerms__c WHERE Id =:acc.acCore__PaymentTerm__c];
        String idUser = UserInfo.getUserId();
        String language = [SELECT LanguageLocaleKey FROM User WHERE Id =:idUser].LanguageLocaleKey;
        if(language == 'fr'){
            if(pt.Name == '30 DAYS NET'){pt.Name = '30 jours net';}else if(pt.Name == '30 DAYS END OF MONTH'){pt.Name = '30 jours fin de mois';}else if(pt.Name == '45 DAYS END OF MONTH'){pt.Name = '45 jours fin de mois';}else if(pt.Name == '45 DAYS NET'){pt.Name = '45 jours net';}else if(pt.Name == '60 DAYS NET'){pt.Name = '60 jours net';}
        }
        return pt.Name;
    }
}