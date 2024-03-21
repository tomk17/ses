public with sharing class B2BDeliveryLWR {

    @AuraEnabled(cacheable=false)
    public static void processShippingCostsAction(Id cartId) {
        try {
            System.debug('**** processShippingCostsAction ****');
            // We need to get the ID of the cart delivery group in order to create the order delivery groups.
            Id cartDeliveryGroupId = [SELECT Id FROM CartDeliveryGroup WHERE CartId = :cartId WITH SECURITY_ENFORCED][0].Id;
            

            // Get shipping options, including aspects like rates and carriers, from the external service. 
            ShippingOptions[] shippingOptions = getShippingOptionsAndRates(cartId);

            // On re-entry of the checkout flow delete all previous CartDeliveryGroupMethods for the given cartDeliveryGroupId
            delete [SELECT Id FROM CartDeliveryGroupMethod WHERE CartDeliveryGroupId = :cartDeliveryGroupId WITH SECURITY_ENFORCED];
            // remove transportation cartItem to avoid duplicates
            // TODO
            delete [SELECT Id FROM CartItem WHERE CartId =: cartId and Name= 'Transportation' WITH SECURITY_ENFORCED];

            // Create orderDeliveryMethods given your shipping options or fetch existing ones. 2 should be returned.
            List<Id> orderDeliveryMethodIds = getOrderDeliveryMethods(shippingOptions);
            System.debug('>>>>>>>>>>>>>>>>>>>>>       orderDeliveryMethodIds');
            System.debug(orderDeliveryMethodIds);
            // Create a CartDeliveryGroupMethod record for every shipping option returned from the external service
            Integer i = 0;
            for (Id orderDeliveryMethodId: orderDeliveryMethodIds) {
               populateCartDeliveryGroupMethodWithShippingOptions(shippingOptions[i],
                                                                  cartDeliveryGroupId,
                                                                  orderDeliveryMethodId,
                                                                  cartId);
                i+=1;
            }
            System.debug('**** AFTER populateCartDeliveryGroupMethodWithShippingOptions ****');
            System.debug('>>>>>>>>>>>>>>>>>>>>>       cartDeliveryGroupId');
            System.debug(cartDeliveryGroupId);

            // If everything works well, the charge is added to the cart and our integration has been successfully completed.
            CartDeliveryGroupMethod cdgm = [SELECT WebcartId, Shippingfee, CartDeliveryGroupId from CartDeliveryGroupMethod where CartDeliveryGroupId =:cartDeliveryGroupId limit 100];
            System.debug('cdgm:');
            System.debug(cdgm);

            Product2 product = [SELECT id FROM Product2 Where productCode = '6669'];
            System.debug('product:');
            System.debug(product);

           
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
            insert ci;
                        

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
            throw handledException(errorMessage);

        } catch(Exception e) {
            throw handledException(e.getMessage());
        }
    }

    public static ShippingOptions[] getShippingOptionsAndRates (Id cartId) {
        System.debug('**** getShippingOptionsAndRates ****');

        ShippingOptions[] shippingOptions = new List<ShippingOptions>();
        
        Boolean cartDeliveryGroupIsPicking = [SELECT Id, TECH_isPickingAddress__c FROM CartDeliveryGroup WHERE CartId = :cartId WITH SECURITY_ENFORCED][0].TECH_isPickingAddress__c;
      
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

        shippingOptions.add( new ShippingOptions(
            Label.B2BStore_Standard_Delivery,
            'Standard',
            (Decimal) shippingCharge.setScale(2),
            (Decimal) 0,
            'Delivery Method'
        ));
        
        return shippingOptions;
    }

    // Structure to store the shipping options retrieved from external service.
    Class ShippingOptions {
        private String name;
        private String provider;
        private Decimal rate;
        private Decimal otherCost;
        private String serviceName;

        public ShippingOptions(String someName, String someProvider, Decimal someRate, Decimal someOtherCost, String someServiceName) {
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
    public static void populateCartDeliveryGroupMethodWithShippingOptions(ShippingOptions shippingOption,
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


    public Id getShippingChargeProduct2Id(Id orderDeliveryMethodId) {
        // The Order Delivery Method should have a Product2 associated with it, because we added that in getDefaultOrderDeliveryMethod if it didn't exist.
        List<OrderDeliveryMethod> orderDeliveryMethods = [SELECT ProductId FROM OrderDeliveryMethod WHERE Id = :orderDeliveryMethodId WITH SECURITY_ENFORCED];
        return orderDeliveryMethods[0].ProductId;
    }

    public static List<Id> getOrderDeliveryMethods(List<ShippingOptions> shippingOptions) {
        
        System.debug('**** getOrderDeliveryMethods ****');
        String defaultDeliveryMethodName = 'Order Delivery Method';
        Id product2IdForThisDeliveryMethod = getDefaultShippingChargeProduct2Id();

        // Check to see if a default OrderDeliveryMethod already exists.
        // If it doesn't exist, create one.
        List<Id> orderDeliveryMethodIds = new List<Id>();
        List<OrderDeliveryMethod> orderDeliveryMethods = new List<OrderDeliveryMethod>();
        Integer i = 1;
        for (ShippingOptions shippingOption : shippingOptions) {
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

    public static Id getDefaultShippingChargeProduct2Id() {
        System.debug('**** getDefaultShippingChargeProduct2Id ****');

        String idTransportation = [SELECT Id FROM Product2 WHERE ProductCode = '6669'].Id;
        return idTransportation;
    }

    /*
    * Calculate cart Taxes 
    * No taxes on CEE countries
    * Uses Avatax API to calculate taxes on non CEE countries
    */
    @AuraEnabled(cacheable=false)
    public static void processCartTaxesCalculationAction(Id cartId) {
        System.debug('**** processCartTaxesCalculationAction ****');
        WebCart cart = [SELECT Id, Name,
                        Account.Id,Account.Name,
                        PoNumber, CurrencyIsoCode, 
                        CanadianTaxPSTQST__c, CanadianTaxGSTHST__c,
                        (SELECT Id, Quantity, CurrencyIsoCode, TotalAmount, TotalPrice, SKU, Product2.Id, Product2.Name, Product2.ProductGroup__c, Product2.Material_group__c FROM CartItems)                            
                        FROM WebCart
                        WHERE Id =:cartId];
        
        String deliverToCountry = [SELECT Id, DeliverToCountry FROM CartDeliveryGroup  WHERE CartId =:cartId].DeliverToCountry;
        
        List<CartTax> cartTaxes = new List<CartTax>();
        
        Account acc = [SELECT Id, pw_cc__ShippingCountryLookup__r.Zone__c FROM Account WHERE Id =:cart.Account.Id];
        
        if(acc.pw_cc__ShippingCountryLookup__r.Zone__c == 'CEE' || acc.pw_cc__ShippingCountryLookup__r.Zone__c == 'France' || acc.pw_cc__ShippingCountryLookup__r.Zone__c == 'EMEA'){
            return ;
        }
        
        B2B_AvalaraWebCallAPI.AvalaraTransaction avalaraTransactionResponse = B2B_AvalaraWebCallAPI.calculateAvataxTransation(cart);
        System.debug('avalaraTransactionResponse : ' + avalaraTransactionResponse);
        
        if(avalaraTransactionResponse.Status == 'Error'){

            throw handledException('Avalara Transaction error: ' + avalaraTransactionResponse.errorMessage);
        }

        cartTaxes = new List<CartTax>();
                        
        for(B2B_AvalaraWebCallAPI.AvalaraLineItem lineItem : avalaraTransactionResponse.lines){
            System.debug('lineItem : ' + lineItem);
            for(B2B_AvalaraWebCallAPI.AvalaraTaxDetail lineItemDetail : lineItem.details){
                System.debug('lineItemDetail : ' + lineItemDetail);
                cartTaxes.add(new CartTax(
                    CartItemId = lineItem.ref1,
                    Name = lineItemDetail.taxName,
                    TaxCalculationDate = Date.Today(),
                    CurrencyIsoCode = cart.CurrencyIsoCode,
                    Amount = String.isBlank(lineItemDetail.taxCalculated) ? 0 : decimal.valueOf(lineItemDetail.taxCalculated),
                    TaxRate = String.isBlank(lineItemDetail.rate) ? 0 : decimal.valueOf(lineItemDetail.rate),
                    TaxType = 'Estimated'
                ));
            }
        }
        
        
        
        try {

            List<CartItem> cartItems = cart.CartItems;
            List<CartTax> oldSessionTaxes = [SELECT Id FROM CartTax WHERE CartItemId IN :cartItems];
            if (!oldSessionTaxes.isEmpty()) {
                delete oldSessionTaxes;
            }
            if(!cartTaxes.isEmpty()){
                System.debug('cartTaxes : ' + cartTaxes);
                if(DeliverToCountry == 'Canada'){
                    Decimal amountGSTHST = 0;
                    Decimal amountPSTQST = 0;
                    for(CartTax ct : cartTaxes){
                        if(ct.Name.contains('GST') || ct.Name.contains('HST')){
                            amountGSTHST += ct.Amount;
                        }else if(ct.Name.contains('PST') || ct.Name.contains('QST')){
                            amountPSTQST += ct.Amount;
                        }
                    }
                    cart.CanadianTaxGSTHST__c = amountGSTHST;
                    cart.CanadianTaxPSTQST__c = amountPSTQST;
                    update cart;
                }
                //IF CartDeliveryGroup DeliverToCountry = Canada
                //Viens remplir les deux champs créé
                //Dans mon composant j'ai que le cart à envoyer, j'affiche juste les champs et je reprends le style avec l'inspecteur
                insert cartTaxes;
            }
        } catch (Exception e) {
            throw handledException(e.getMessage());
        }
    }
    
    private static AuraHandledException handledException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }
    
}