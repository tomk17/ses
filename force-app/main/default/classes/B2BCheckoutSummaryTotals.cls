public without sharing class B2BCheckoutSummaryTotals {
    @AuraEnabled
    public static String retrieveDeliverToCountry(String cartId) {
        System.debug('cartId ' + cartId);
        String deliverToCountry = [SELECT deliverToCountry FROM CartDeliveryGroup WHERE CartId=:cartId].deliverToCountry;
        return deliverToCountry;
    }
}