public without sharing class B2BCheckoutUtilsLWR {

    @AuraEnabled(cacheable=false)  
    public static void updateShippingDeliveryInfo(ID cartId, Map<string,string> shippingData) {
        try {
            system.debug(cartId);
            system.debug(shippingData);
            ID accountId = shippingData.get('accountId');
            ID contactId = shippingData.get('contactId');
            String email = shippingData.get('email');
            String shippingInstructions = shippingData.get('shippingInstructions');
            Boolean isPickingAddress = false;
            WebCart cart = [
                SELECT 
                        Id, 
                        ShipToAccount__c, 
                        ShipToContact__c, 
                        Ship_To_Email__c,
                        GuestEmailAddress 
                    FROM WebCart 
                    WHERE Id =: cartId];

            if(cart == null) {
                throw new AuraHandledException('Error: No cart found');
            }
            cart.ShipToAccount__c = accountId;
            cart.ShipToContact__c = contactId;
            cart.Ship_To_Email__c = email;

            Account acc = [
                SELECT 
                    Id, 
                    Name, 
                    Incoterms__c, 
                    ShippingCity, 
                    ShippingCountry, 
                    ShippingGeocodeAccuracy, 
                    ShippingLongitude, 
                    ShippingLatitude, 
                    ShippingPostalCode, 
                    ShippingState, 
                    ShippingStreet 
                FROM Account 
                WHERE Id =: accountId
            ];
            if(acc == null) {
                throw new AuraHandledException('Error: No account found');
            }
            if( acc.Incoterms__c == 'FCA' || acc.Incoterms__c  == 'EXW') {

                Account_Salesorg__c accSO = null;
                Sales_Org__c sO = null;
                Account pickingAccount = null;
                CartDeliveryGroup cartDG = null;
                String strSOCode;

                isPickingAddress = true;

                accSO = [SELECT Id FROM Account_Salesorg__c WHERE Account__c =: acc.Id LIMIT 1];
                if(accSO != null) {
                    sO = [SELECT Id, Code__c FROM Sales_Org__c WHERE Id =: accSO.Id LIMIT 1];
                    strSOCode =  String.valueOf(sO.Code__c);
                }

                if(sO != null && strSOCode != '') {

                    acc = [
                        SELECT 
                            Id, 
                            Name, 
                            ShippingCity, 
                            ShippingCountry, 
                            ShippingGeocodeAccuracy, 
                            ShippingLongitude, 
                            ShippingLatitude, 
                            ShippingPostalCode, 
                            ShippingState, 
                            ShippingStreet 
                        FROM Account 
                        WHERE AccountNumber =: strSOCode 
                        LIMIT 1
                        ];
                }
                if(acc == null) {
                    throw new AuraHandledException('Error: No picking account found');
                }
            }
        

            CartDeliveryGroup cartDG = 
            [
                SELECT 
                    Id, 
                    DeliverToCity, 
                    DeliverToCountry,
                    DeliverToGeocodeAccuracy, 
                    DeliverToLatitude, 
                    DeliverToLongitude,
                    DeliverToName,
                    DeliverToPostalCode,
                    DeliverToState,
                    DeliverToStreet,
                    ShippingInstructions,
                    TECH_isPickingAddress__c
                FROM CartDeliveryGroup
                WHERE CartId =: cartId
            ];
            if(cartDG == null) {
                throw new AuraHandledException('Error: No Cart delivery group found');
            }

            cartDG.DeliverToCity = acc.ShippingCity;
            cartDG.DeliverToCountry = acc.ShippingCountry;
            cartDG.DeliverToGeocodeAccuracy = acc.ShippingGeocodeAccuracy;
            cartDG.DeliverToLatitude = acc.ShippingLatitude;
            cartDG.DeliverToLongitude = acc.ShippingLongitude;
            cartDG.DeliverToName = acc.Name;
            cartDG.DeliverToPostalCode = acc.ShippingPostalCode;
            cartDG.DeliverToState = acc.ShippingState;
            cartDG.DeliverToStreet = acc.ShippingStreet;
            cartDG.ShippingInstructions = shippingInstructions;
            cartDG.TECH_isPickingAddress__c = isPickingAddress;
        
            update cartDG;       
            update cart;

        } catch(Exception e) {
            throw handledException(e.getMessage());
        }
    }
    @AuraEnabled(cacheable=false)  
    public static void updateBillingDeliveryInfo(ID cartId, Map<string,string> billingData) {
        try {
            system.debug(cartId);
            system.debug(billingData);
            ID accountId = billingData.get('accountId');
            String email = billingData.get('email');
            Account acc = [
                SELECT 
                    Id,
                    BillingCity, 
                    BillingCountry, 
                    BillingGeocodeAccuracy,
                    BillingLatitude,
                    BillingLongitude,
                    BillingPostalCode,
                    BillingState,
                    BillingStreet
                FROM Account
                WHERE Id =: accountId
            ];
            if(acc == null) {
                throw new AuraHandledException('Error: No picking account found');
            }
            WebCart cart = [
                SELECT 
                    Id, 
                    BillToAccount__c, 
                    BillingCity, 
                    BillingCountry, 
                    BillingGeocodeAccuracy,
                    BillingLatitude,
                    BillingLongitude,
                    BillingPostalCode,
                    BillingState,
                    BillingStreet
                FROM WebCart 
                WHERE Id =: cartId
            ];

            if(cart == null) {
                throw new AuraHandledException('Error: No cart found');
            }
            cart.BillToAccount__c = acc.Id;
            cart.BillingCity = acc.BillingCity;
            cart.BillingCountry = acc.BillingCountry;
            cart.BillingGeocodeAccuracy = acc.BillingGeocodeAccuracy;
            cart.BillingLatitude = acc.BillingLatitude;
            cart.BillingLongitude = acc.BillingLongitude;
            cart.BillingPostalCode = acc.BillingPostalCode;
            cart.BillingState = acc.BillingState;
            cart.BillingStreet = acc.BillingStreet;

            update cart;

        } catch(Exception e) {
            throw handledException(e.getMessage());
        }
    }

    
    @AuraEnabled(cacheable=false)  
    public static Account getAccountData(ID accountId) {
        Account acc = [SELECT Id, ShippingCountry From Account WHERE Id =: accountId];
        return acc;
    }

    @AuraEnabled(cacheable=false)  
    public static void updateCatPoNumber(ID cartId, String poNumber) {
        try {
            WebCart cart = [SELECT Id, PoNumber FROM WebCart WHERE Id =:cartId];
            cart.PoNumber = poNumber;
            update cart;
        } catch(Exception e) {
            throw handledException(e.getMessage());
        }
       
    }
    private static AuraHandledException handledException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }
    
}