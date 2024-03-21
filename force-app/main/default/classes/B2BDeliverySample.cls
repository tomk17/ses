// This must implement the sfdc_checkout.CartShippingCharges interface
// in order to be processed by the checkout flow for the "Shipping" integration
global without sharing class B2BDeliverySample implements sfdc_checkout.CartShippingCharges {
    
    public Boolean triggerError = false;
    
    global sfdc_checkout.IntegrationStatus startCartProcessAsync(sfdc_checkout.IntegrationInfo jobInfo, Id cartId) {
        sfdc_checkout.IntegrationStatus integStatus = new sfdc_checkout.IntegrationStatus();
        try {
            // We need to get the ID of the cart delivery group in order to create the order delivery groups.
            Id cartDeliveryGroupId = [SELECT Id FROM CartDeliveryGroup WHERE CartId = :cartId WITH SECURITY_ENFORCED][0].Id;
            
            // Used to increase the cost by a multiple of the number of items in the cart (useful for testing but should not be done in the final code)
            Integer numberOfUniqueItems = [SELECT count() from cartItem WHERE CartId = :cartId WITH SECURITY_ENFORCED];

            // Get shipping options, including aspects like rates and carriers, from the external service. 
            ShippingOptionsAndRatesFromExternalService[] shippingOptionsAndRatesFromExternalService = getShippingOptionsAndRates(numberOfUniqueItems, cartId);

            // On re-entry of the checkout flow delete all previous CartDeliveryGroupMethods for the given cartDeliveryGroupId
            delete [SELECT Id FROM CartDeliveryGroupMethod WHERE CartDeliveryGroupId = :cartDeliveryGroupId WITH SECURITY_ENFORCED];

            // Create orderDeliveryMethods given your shipping options or fetch existing ones. 2 should be returned.
            List<Id> orderDeliveryMethodIds = getOrderDeliveryMethods(shippingOptionsAndRatesFromExternalService);

            // Create a CartDeliveryGroupMethod record for every shipping option returned from the external service
            Integer i = 0;
            for (Id orderDeliveryMethodId: orderDeliveryMethodIds) {
               populateCartDeliveryGroupMethodWithShippingOptions(shippingOptionsAndRatesFromExternalService[i],
                                                                  cartDeliveryGroupId,
                                                                  orderDeliveryMethodId,
                                                                  cartId);
                i+=1;
            }
            
            // If everything works well, the charge is added to the cart and our integration has been successfully completed.
            /*
            CartDeliveryGroupMethod cdgm = [SELECT WebcartId, Shippingfee, CartDeliveryGroupId from CartDeliveryGroupMethod where WebCartId =:cartDeliveryGroupId limit 100];
            Product2 product = [SELECT id FROM Product2 Where productCode = '6669'];
            CartItem ci = new CartItem();
            ci.CartId = cdgm.WebcartId;
            ci.Product2Id = product.Id;
            ci.TotalPrice = cdgm.ShippingFee;
            ci.CurrencyIsoCode = 'USD';
            ci.CartDeliveryGroupId = cdgm.CartDeliveryGroupId;
            ci.Name = 'Transportation';
            ci.Type = 'Charge';
            ci.ListPrice = cdgm.ShippingFee;
            ci.Quantity = 1;
            insert ci;*/
            // A enlever pour LWR
            integStatus.status = sfdc_checkout.IntegrationStatus.Status.SUCCESS;
                        
            if(triggerError){
                throw new handledException('errorTest');
            }

        // For testing purposes, this example treats exceptions as user errors, which means they are displayed to the buyer user.
        // In production you probably want this to be an admin-type error. In that case, throw the exception here
        // and make sure that a notification system is in place to let the admin know that the error occurred.
        // See the readme section about error handling for details about how to create that notification.
        } catch (DmlException de) {
            // Catch any exceptions thrown when trying to insert the shipping charge to the CartItems
            Integer numErrors = de.getNumDml();
            String errorMessage = 'There were ' + numErrors + ' errors when trying to insert the charge in the CartItem: ';
            for(Integer errorIdx = 0; errorIdx < numErrors; errorIdx++) {
                errorMessage += 'Field Names = ' + de.getDmlFieldNames(errorIdx);
                errorMessage += 'Message = ' + de.getDmlMessage(errorIdx);
                errorMessage += ' , ';
            }

            return integrationStatusFailedWithCartValidationOutputError(
                integStatus,
                errorMessage,
                jobInfo,
                cartId
            );
        } catch(Exception e) {
            return integrationStatusFailedWithCartValidationOutputError(
                integStatus,
                'An exception of type ' + e.getTypeName() + ' has occurred: ' + e.getMessage(),
                jobInfo,
                cartId
            );
        }
        return integStatus;
    }

    public ShippingOptionsAndRatesFromExternalService[] getShippingOptionsAndRates (Integer numberOfUniqueItems, Id cartId) {
        final Integer SuccessfulHttpRequest = 200;

        ShippingOptionsAndRatesFromExternalService[] shippingOptions = new List<ShippingOptionsAndRatesFromExternalService>();
        
        Boolean cartDeliveryGroupIsPicking = [SELECT Id, TECH_isPickingAddress__c FROM CartDeliveryGroup WHERE CartId = :cartId WITH SECURITY_ENFORCED][0].TECH_isPickingAddress__c;

        /*Http http = new Http();
        HttpRequest request = new HttpRequest();
        // To access the service below, you may need to add endpoint = https://b2b-commerce-test.herokuapp.com in Setup | Security | Remote site settings.
        request.setEndpoint('https://b2b-commerce-test.herokuapp.com/calculate-shipping-rates-winter-21');
        request.setMethod('GET');
        HttpResponse response = http.send(request);

        // If the request is successful, parse the JSON response.
        // The response looks like this:
        // [{"status":"calculated","rate":{"name":"Delivery Method 1","serviceName":"Test Carrier 1","serviceCode":"SNC9600","shipmentCost":11.99,"otherCost":5.99}},
        // {"status":"calculated","rate":{"name":"Delivery Method 2","serviceName":"Test Carrier 2","serviceCode":"SNC9600","shipmentCost":15.99,"otherCost":6.99}}]
        if (response.getStatusCode() == SuccessfulHttpRequest) {
           List<Object> results = (List<Object>) JSON.deserializeUntyped(response.getBody());
           for (Object result: results) {
                Map<String, Object> subresult = (Map<String, Object>) result;
                Map<String, Object> providerAndRate = (Map<String, Object>) subresult.get('rate');
                shippingOptions.add( new ShippingOptionsAndRatesFromExternalService(
                    (String) providerAndRate.get('name'),
                    (String) providerAndRate.get('serviceCode'),
                    (Decimal) providerAndRate.get('shipmentCost') * numberOfUniqueItems, // Multiply so shipping costs can change; remove when using a real shipping provider
                    (Decimal) providerAndRate.get('otherCost'),
                    (String) providerAndRate.get('serviceName')
                ));
            }
            return shippingOptions;
        }
        else {
            throw new CalloutException ('There was a problem with the request. Error: ' + response.getStatusCode());
        }*/
        
        Decimal shippingCharge = 0;
        if(!cartDeliveryGroupIsPicking){
            WebCart wcart = [SELECT Id, TotalProductAmount, AccountId, ShipToAccount__c FROM WebCart WHERE Id =:cartId];
            
            Account acc = [SELECT Id, pw_cc__ShippingCountryLookup__r.Zone__c, pw_cc__ShippingCountryLookup__r.pw_cc__IsoCode_2__c, ShippingPostalCode, Brand__r.Name FROM Account WHERE Id =:wcart.AccountId];
                        
            if(acc.pw_cc__ShippingCountryLookup__r.Zone__c == 'CEE' || acc.pw_cc__ShippingCountryLookup__r.Zone__c == 'France' || acc.pw_cc__ShippingCountryLookup__r.Zone__c == 'EMEA'){
                Double weight = 0;
                Double quantityofESLAndFixing = 0;
                //TRANSPORTATION EMEA
                List<CartItem> listCisNS = [SELECT Id, SalesPrice, ListPrice, Quantity, Product2.Unit_Gross_Weight_kg__c, Product2.Family FROM CartItem WHERE CartId =:cartId AND Product2.CatalogFamilyDescription__c != 'Software' ];
                
                for(CartItem ci : listCisNS){
                    System.debug(ci);
                    if(ci.Product2.Unit_Gross_Weight_kg__c != null){
                        System.debug(ci.Product2.Unit_Gross_Weight_kg__c);
                        weight += ci.Quantity * ci.Product2.Unit_Gross_Weight_kg__c;
                    }
                    if(ci.Product2.Family == 'ESLs' || ci.Product2.Family == 'Fixings'){
                        quantityofESLAndFixing += ci.Quantity;
                    }
                }
                
                String uuidTransport = B2BTransportationPrice.createKey(acc, weight);
                
                TransportationPriceList__c priceTransport = [SELECT Unit_Price__c, UUID__c FROM TransportationPriceList__c WHERE UUID__c =: uuidTransport LIMIT 1];
                
                //marge 30% + palettes 5%
                if(weight >  80){
                    shippingCharge = priceTransport.Unit_Price__c * 1.35;
                } else {
                    shippingCharge = priceTransport.Unit_Price__c * 1.30;
                }
                
                
                //negociate price FNAC
                if(acc.Brand__r.Name == 'FNAC'){
                    if(quantityofESLAndFixing <= 100){
                        shippingCharge = 67.5;
                    }
                    else {
                        shippingCharge = 135;
                    }
                }
               
                //negociate price Super U
                if(acc.Brand__r.Name == 'SUPER U'){
                    if(wcart.TotalProductAmount <= 600){
                        shippingCharge = 20.45;
                    }
                    else if(wcart.TotalProductAmount >= 601 && wcart.TotalProductAmount <= 3500) {
                        shippingCharge = 45;
                    } 
                    else {
                        shippingCharge = 84;
                    }
                }
                
            }else{
                List<CartItem> listCis = [SELECT Id, SalesPrice, ListPrice, Quantity, Product2.CatalogFamilyDescription__c FROM CartItem WHERE CartId =:cartId AND Product2.CatalogFamilyDescription__c = 'Software' ];
                
                Decimal amountSoftware = 0;
                for(CartItem ci : listCis){
                    amountSoftware += ci.SalesPrice * ci.Quantity;
                }
                
                shippingCharge = (wcart.TotalProductAmount-amountSoftware) * 0.03;
                if(shippingCharge < 10){
                    shippingCharge = 10;
                } 
            }
            System.debug('shippingCharge: ' + shippingCharge);
        }

        shippingOptions.add( new ShippingOptionsAndRatesFromExternalService(
            Label.B2BStore_Standard_Delivery,
            'Standard',
            //(Decimal) 0 * numberOfUniqueItems, // Multiply so shipping costs can change; remove when using a real shipping provider
            (Decimal) shippingCharge.setScale(2),
            (Decimal) 0,
            'Delivery Method'
        ));
        
        return shippingOptions;
    }

    // Structure to store the shipping options retrieved from external service.
    Class ShippingOptionsAndRatesFromExternalService {
        private String name;
        private String provider;
        private Decimal rate;
        private Decimal otherCost;
        private String serviceName;

        public ShippingOptionsAndRatesFromExternalService(String someName, String someProvider, Decimal someRate, Decimal someOtherCost, String someServiceName) {
            name = someName;
            provider = someProvider;
            rate = someRate;
            otherCost = someOtherCost;
            serviceName = someServiceName;
        }

        public String getProvider() {
            return provider;
        }

        public Decimal getRate() {
            return rate;
        }

        public Decimal getOtherCost() {
            return otherCost;
        }

        public String getServiceName() {
            return serviceName;
        }

        public String getName() {
            return name;
        }
    }

    // Create a CartDeliveryGroupMethod record for every shipping option returned from the external service
    private void populateCartDeliveryGroupMethodWithShippingOptions(ShippingOptionsAndRatesFromExternalService shippingOption,
                                                                  Id cartDeliveryGroupId,
                                                                  Id deliveryMethodId,
                                                                  Id webCartId){
        // When inserting a new CartDeliveryGroupMethod, the following fields have to be populated:
        // CartDeliveryGroupId: Id of the delivery group of this shipping option
        // DeliveryMethodId: Id of the delivery method for this shipping option
        // ExternalProvider: Unique identifier of shipping provider
        // Name: Name of the CartDeliveryGroupMethod record
        // ShippingFee: The cost of shipping for the delivery group
        // WebCartId: Id if the cart that the delivery group belongs to
        WebCart wcart = [SELECT Id, CurrencyIsoCode, AccountId FROM WebCart WHERE Id =:webCartId];
        //String currencyFromAccount = [SELECT CurrencyIsoCode FROM Account WHERE Id =:wcart.AccountId].CurrencyIsoCode;
        CartDeliveryGroupMethod cartDeliveryGroupMethod = new CartDeliveryGroupMethod(
            CartDeliveryGroupId = cartDeliveryGroupId,
            DeliveryMethodId = deliveryMethodId,
            ExternalProvider = shippingOption.getProvider(),
            Name = shippingOption.getName(),
            ShippingFee = shippingOption.getRate(),
            CurrencyIsoCode = wcart.CurrencyIsoCode,
            WebCartId = webCartId
        );
        insert(cartDeliveryGroupMethod);
    }

    private sfdc_checkout.IntegrationStatus integrationStatusFailedWithCartValidationOutputError(
        sfdc_checkout.IntegrationStatus integrationStatus, String errorMessage, sfdc_checkout.IntegrationInfo jobInfo, Id cartId) {
            integrationStatus.status = sfdc_checkout.IntegrationStatus.Status.FAILED;
            // In order for the error to be propagated to the user, we need to add a new CartValidationOutput record.
            // The following fields must be populated:
            // BackgroundOperationId: Foreign Key to the BackgroundOperation
            // CartId: Foreign key to the WebCart that this validation line is for
            // Level (required): One of the following - Info, Error, or Warning
            // Message (optional): Message displayed to the user
            // Name (required): The name of this CartValidationOutput record. For example CartId:BackgroundOperationId
            // RelatedEntityId (required): Foreign key to WebCart, CartItem, CartDeliveryGroup
            // Type (required): One of the following - SystemError, Inventory, Taxes, Pricing, Shipping, Entitlement, Other
            CartValidationOutput cartValidationError = new CartValidationOutput(
                BackgroundOperationId = jobInfo.jobId,
                CartId = cartId,
                Level = 'Error',
                Message = errorMessage.left(255),
                Name = (String)cartId + ':' + jobInfo.jobId,
                RelatedEntityId = cartId,
                Type = 'Shipping'
            );
            insert(cartValidationError);

            return integrationStatus;
    }

    private Id getShippingChargeProduct2Id(Id orderDeliveryMethodId) {
        // The Order Delivery Method should have a Product2 associated with it, because we added that in getDefaultOrderDeliveryMethod if it didn't exist.
        List<OrderDeliveryMethod> orderDeliveryMethods = [SELECT ProductId FROM OrderDeliveryMethod WHERE Id = :orderDeliveryMethodId WITH SECURITY_ENFORCED];
        return orderDeliveryMethods[0].ProductId;
    }

    private List<Id> getOrderDeliveryMethods(List<ShippingOptionsAndRatesFromExternalService> shippingOptions) {
        String defaultDeliveryMethodName = 'Order Delivery Method';
        Id product2IdForThisDeliveryMethod = getDefaultShippingChargeProduct2Id();

        // Check to see if a default OrderDeliveryMethod already exists.
        // If it doesn't exist, create one.
        List<Id> orderDeliveryMethodIds = new List<Id>();
        List<OrderDeliveryMethod> orderDeliveryMethods = new List<OrderDeliveryMethod>();
        Integer i = 1;
        for (ShippingOptionsAndRatesFromExternalService shippingOption : shippingOptions) {
            String shippingOptionNumber = String.valueOf(i);
            String name = 'Standard Delivery';
            List<OrderDeliveryMethod> odms = [SELECT Id, ProductId, Carrier, ClassOfService FROM OrderDeliveryMethod WHERE Name = :name];
            // This is the case in which an Order Delivery method does not exist.
            if (odms.isEmpty()) {
                OrderDeliveryMethod defaultOrderDeliveryMethod = new OrderDeliveryMethod(
                    Name = name,
                    Carrier = shippingOption.serviceName,
                    isActive = true,
                    ProductId = product2IdForThisDeliveryMethod,
                    ClassOfService = shippingOption.provider
                );
                insert(defaultOrderDeliveryMethod);
                orderDeliveryMethodIds.add(defaultOrderDeliveryMethod.Id);
            }
            else {
                // This is the case in which an Order Delivery method exists.
                // If the OrderDeliveryMethod doesn't have a Product2 associated with it, assign one
                // We can always pick the 0th orderDeliveryMethod since we queried based off the name.
                OrderDeliveryMethod existingodm = odms[0];
                // This is for reference implementation purposes only.
                // This is the if statement that checks to make sure that there is a product carrier and class of service
                // associated to the order delivery method.
                if (existingodm.ProductId == null || existingodm.Carrier == null || existingodm.ClassOfService == null) {
                    existingodm.ProductId = product2IdForThisDeliveryMethod;
                    existingodm.Carrier = shippingOption.serviceName;
                    existingodm.ClassOfService = shippingOption.provider;
                    update(existingodm);
                }
                orderDeliveryMethodIds.add(existingodm.Id);
            }
            i+=1;
        }
        return orderDeliveryMethodIds;
    }

    private Id getDefaultShippingChargeProduct2Id() {
        // In this example we will name the product representing shipping charges 'Shipping Charge for this delivery method'.
        // Check to see if a Product2 with that name already exists.
        // If it doesn't exist, create one.
        /*String shippingChargeProduct2Name = 'Shipping Costs';
        List<Product2> shippingChargeProducts = [SELECT Id FROM Product2 WHERE Name = :shippingChargeProduct2Name];
        System.debug('Debug product : ' + shippingChargeProducts);
        if (shippingChargeProducts.isEmpty()) {
            Product2 shippingChargeProduct = new Product2(
                isActive = true,
                Name = shippingChargeProduct2Name
                //CurrencyIsoCode = 'USD'
            );
            insert(shippingChargeProduct);
            return shippingChargeProduct.Id;
        }
        else {
            return shippingChargeProducts[0].Id;
        }*/
        String idTransportation = [SELECT Id FROM Product2 WHERE ProductCode = '6669'].Id;
        return idTransportation;
    }
}