public without sharing class B2BCheckoutSummaryAdditionalInfos {

    @AuraEnabled
    public static Account retrieveShippingAccountCountryAndZone(Id cartId) {
        Account acc = new Account();
        WebCart cart = [SELECT Id, AccountId FROM WebCart WHERE Id=:cartId];
        if(cart == null){
            return acc;
        } 
        acc = [SELECT Id, ShippingCountry, pw_cc__ShippingCountryLookup__r.Zone__c FROM Account WHERE Id =:cart.AccountId];
        return acc;
    }

    @AuraEnabled
    public static String retrieveContactEmail(String cartId) {
        WebCart cart = [SELECT Id, Ship_To_Email__c, ShipToContact__c FROM WebCart WHERE Id=:cartId];
        Contact con = [SELECT Id, email FROM Contact WHERE Id = :cart.ShipToContact__c];
        return con.email;
    }

    @AuraEnabled
    public static String retrieveOptionalEmail(String cartId) {
        WebCart cart = [SELECT Id, Ship_To_Email__c FROM WebCart WHERE Id=:cartId];
        return cart.Ship_To_Email__c;
    }
    
    @AuraEnabled
    public static String retrieveCurrency(String cartId) {
        WebCart cart = [SELECT Id, AccountId FROM WebCart WHERE Id=:cartId];
        Account acc = [SELECT Id, CurrencyIsoCode FROM Account WHERE Id =:cart.AccountId];
        return acc.CurrencyIsoCode;
    }

    @AuraEnabled
    public static List<CartItem> retrieveProduct(String cartId) {
        List<CartItem> cis = [SELECT Id, Product2.Name, Quantity, TotalPrice, Product2.CatalogFamilyDescription__c, Availability_Result__c FROM CartItem WHERE CartId=:cartId AND Type = 'Product' AND Product2.CatalogFamilyDescription__c != 'Software'];
        return cis;
    }

    @AuraEnabled
    public static List<CartItem> retrieveSoftware(String cartId) {
        List<CartItem> cis = [SELECT Id, Product2.Name, Quantity, TotalPrice, Product2.CatalogFamilyDescription__c FROM CartItem WHERE CartId=:cartId AND Type = 'Product' AND Product2.CatalogFamilyDescription__c = 'Software'];
        return cis;
    }
    
    @AuraEnabled
    public static String retrieveDeliverToCountry(String cartId) {
        System.debug('cartId ' + cartId);
        String deliverToCountry = [SELECT deliverToCountry FROM CartDeliveryGroup WHERE CartId=:cartId].deliverToCountry;
        return deliverToCountry;
    }

    @AuraEnabled
    public static WebCart retrieveCart(String cartId) {
        WebCart cart = [SELECT TotalProductAmount, TotalAmount, TotalChargeAmount, CanadianTaxGSTHST__c, CanadianTaxPSTQST__c, TotalTaxAmount, GrandTotalAmount FROM WebCart WHERE Id=:cartId];
        return cart;
    }

    @AuraEnabled
    public static Decimal softwareAmount(String cartId) {
        List<CartItem> listCis = [SELECT Id, SalesPrice, ListPrice, Quantity, Product2.CatalogFamilyDescription__c, Availability_Result__c FROM CartItem WHERE CartId =:cartId AND Product2.CatalogFamilyDescription__c = 'Software' ];
            
        Decimal amountSoftware = 0;
        for(CartItem ci : listCis){
            amountSoftware += ci.SalesPrice * ci.Quantity;
        }

        return amountSoftware;
    }
    
    @AuraEnabled
    public static void calculateAvailability(String cartId) {
        WebCart cart = [SELECT Id, AccountId FROM WebCart WHERE Id=:cartId];
        Account acc = [SELECT Id, CurrencyIsoCode FROM Account WHERE Id =:cart.AccountId];
        List<CartItem> cis = [SELECT Id, Product2.ProductCode, Quantity, TotalPrice, Product2.CatalogFamilyDescription__c FROM CartItem WHERE CartId=:cartId AND Type = 'Product' AND Product2.CatalogFamilyDescription__c != 'Software'];
        List<Account_Salesorg__c> aso = [SELECT Id, Sales_Org__c FROM Account_Salesorg__c WHERE Account__c = :acc.Id AND Primary__c = true LIMIT 1];
        List<Sales_Org__c> listSo = new List<Sales_Org__c>();
        if(aso.size()>0){
            listSo = [SELECT Id, Code__c FROM Sales_Org__c WHERE Id = :aso[0].Sales_Org__c LIMIT 1];
        }
        String strCode = '';
        if(listSo.size()>0){
            strCode = String.ValueOf(listSo[0].Code__c);
        }
        if(String.isNotBlank(strCode)){
            for(CartItem ci : cis){
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                Organization org = [SELECT InstanceName,Name, IsSandbox, OrganizationType FROM Organization];
                String endpoint = '';
                if(org.IsSandbox == true){
                    APITalenDev__c devapi = [SELECT Id, url__c, token__c FROM APITalenDev__c LIMIT 1];
                    endpoint = devapi.url__c + '/atp/DetermineAvailabilityOf?ATPCheckingRule=\'A\'&Material=\''+ ci.Product2.ProductCode +'\'&SupplyingPlant=\''+ strCode +'\'&RequestedQuantityInBaseUnit='+ ci.Quantity +'.0M&subscription-key=' + devapi.token__c;
                }else{
                    APITalenProd__c prodapi = [SELECT Id, url__c, token__c FROM APITalenProd__c LIMIT 1];
                    endpoint = prodapi.url__c + '/atp/DetermineAvailabilityOf?ATPCheckingRule=\'A\'&Material=\''+ ci.Product2.ProductCode +'\'&SupplyingPlant=\''+ strCode +'\'&RequestedQuantityInBaseUnit='+ ci.Quantity +'.0M&subscription-key=' + prodapi.token__c;
                }                
                request.setEndpoint(endpoint);
                request.setMethod('GET');
                request.setHeader('Content-Type', 'application/json');
                HttpResponse response = http.send(request);
                // Parse the JSON response
                if(response.getStatusCode() == 200) {
                    ci.Availability_Result__c = 'En stock';
                }else if(response.getStatusCode() == 404) {
                    Map<String, Object> deserializedResponse = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                    Map<String, Object> getError = new Map<String, Object>();
                    Map<String, Object> getMessage = new Map<String, Object>();
					String getValue = '';
                    if(deserializedResponse != null && !deserializedResponse.isEmpty()){
                        getError = (Map<String, Object>) deserializedResponse.get('error');
                    }
                    if(getError != null && !getError.isEmpty()){getMessage = (Map<String, Object>) getError.get('message');}
                    if(getMessage != null && !getMessage.isEmpty()){getValue = (String) getMessage.get('value');}
                    if(getValue == 'Requested quantity is not available.'){
                        ci.Availability_Result__c = 'En cours de réapprovisionnement';
                    }else{ci.Availability_Result__c = 'Information non disponible actuellement';}
                }else {ci.Availability_Result__c = 'Information non disponible actuellement';}
            }
        }
        update cis;
    }

}