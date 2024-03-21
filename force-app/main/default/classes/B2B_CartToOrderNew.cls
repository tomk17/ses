/* *******************************************************************************************************
 * Name               :                                                                                  *
 * Description        :                                                                                  *
 * Created Date       : 09.12.2020                                                                       *
 * Created By         : Jakub Holys @Waeg                                                                *
 * -----------------------------------------------------------------------------------------------       *
 * VERSION    AUTHOR                 		DATE                                                                *
 *   1.0 -    Jakub Holys @Waeg      		26-Nov-2018 Initial version
 *   1.1 -    Benjamin Cligny (Icom Cloud)  03-Feb-2023                                                                         *
 ******************************************************************************************************* */

public class B2B_CartToOrderNew {

    public class B2BCartToOrderDraftRequest {

        @InvocableVariable(Required=true)
        public Id checkoutSessionId;

        @InvocableVariable(Required=true)
        public Id cartId;
    }

    /*private static User CurrentUser {
        get {
            if(null == CurrentUser || UserInfo.getUserId() != CurrentUser.Id) {
                CurrentUser = [
                        SELECT  Id,
                                AccountId,
                                ContactId
                        FROM    User
                        WHERE   Id = :UserInfo.getUserId()
                ];
            }
            return CurrentUser;
        }
        set;
    }*/

    /**
     * @description Maps a cart to an order. Activates it, and closes the cart. Returns the resulting order summary id.
     * @param request The checkout session and cart id.
     * @return The OrderId that resulted from this class.
     */
    @InvocableMethod(Label='Map Cart to Order New' Description='Maps the cart and related data to an order' Category='B2B Commerce')
    public static List<Id> cartToOrder(List<B2BCartToOrderDraftRequest> request) {
        // screen flows do not run in bulk
        Id cartId = request[0].cartId;
        Id checkoutSessionId = request[0].checkoutSessionId;

        // load the primary delivery group (only one supported at this time)
        Id cartDeliveryGroupId = [SELECT Id FROM CartDeliveryGroup WHERE CartId = :cartId][0].Id;

        List<Id> orderIds = new List<Id>();
        Id orderId = mapAndInsertCartToOrder(cartId);
        updateCheckoutSession(checkoutSessionId, orderId);
        Id orderDeliveryGroupId = mapAndInsertCartDeliveryGroupToOrderDeliveryGroup(cartDeliveryGroupId, orderId);
        mapAndInsertCartItems(cartDeliveryGroupId, orderId, orderDeliveryGroupId/*, cartId*/);
        orderIds.add(orderId);
        /*try{
            Id orderId = mapAndInsertCartToOrder(cartId);
            updateCheckoutSession(checkoutSessionId, orderId);
            Id orderDeliveryGroupId = mapAndInsertCartDeliveryGroupToOrderDeliveryGroup(cartDeliveryGroupId, orderId);
            mapAndInsertCartItems(cartDeliveryGroupId, orderId, orderDeliveryGroupId);
            orderIds.add(orderId);

            if(!test.isRunningTest()){
            	createOrderSummary(orderId);
            }

        }
        catch(Exception ex){
            System.debug(ex.getMessage());
            B2B_CheckoutUtils.integrationStatusWithCartValidationOutputWarning(
                null, 'An error occured.' + ex.getMessage() , null, cartId, 'Other');
        }*/

        return orderIds;
    }

    /**
     * @description Satisfy the preconditions required to use the following call to Activate the Order
     */
    private static void updateCheckoutSession(Id checkoutSessionId, Id orderId) {
        try {
            CartCheckoutSession checkoutSession = [
                SELECT OrderId, State, NextState 
                FROM CartCheckoutSession
                WHERE Id = :checkoutSessionId
            ];
            checkoutSession.OrderId = orderId;
            update checkoutSession;
        } catch (Exception e) {
            System.debug('An error occurred updating checkout session with the draft order Id');
        }
    }

    /**
     * @description Maps the cart entity to an order entity and returns the id of the order entity that was created.
     * @param cartId The cart id to map to an order.
     * @return The id of the order that was created.
     */
    private static Id mapAndInsertCartToOrder(Id cartId) {
        // Get the cart data needed to populate the order
        List<WebCart> carts = [SELECT Id,
                AccountId,
                OwnerId,
                WebStoreId,
                PoNumber,
                BillingStreet,
                BillingCity,
                BillingState,
                BillingPostalCode,
                BillingCountry,
                BillingLatitude,
                BillingLongitude,
                CurrencyIsoCode,
                ShipToAccount__c,
                ShipToContact__c,
                Ship_To_Email__c
                /*BillToAccount__c,
                BillToContact__c,
                ShipToAccount__c,
                ShipToContact__c*/
        FROM WebCart WHERE Id = :cartId];
        WebCart cart = carts[0];
           
        User userFromCart = [SELECT Id, ContactId FROM User WHERE Id =:cart.OwnerId];
        Contact contactFromCart = [SELECT id FROM Contact WHERE Id =:userFromCart.ContactId];

        CartDeliveryGroup cdg = [SELECT Id, DeliverToCity, DeliverToCountry, DeliverToLatitude, DeliverToLongitude, DeliverToPostalCode, DeliverToState, DeliverToStreet, TECH_isPickingAddress__c FROM CartDeliveryGroup WHERE CartId = :cartId][0];
        Account acc = [SELECT Id, Incoterms__c FROM Account WHERE Id =:cart.AccountId];
        List<Account_Salesorg__c> aso = [SELECT Id, Sales_Org__c FROM Account_Salesorg__c WHERE Account__c = :acc.Id AND Primary__c = true LIMIT 1];
        List<Sales_Org__c> listSo = new List<Sales_Org__c>();
        if(aso.size() > 0){
            listSo = [SELECT Id, Code__c FROM Sales_Org__c WHERE Id = :aso[0].Sales_Org__c LIMIT 1];
        }
        
        // Create the order
        Date now = Date.today();
        
        Order order = new Order(
            AccountId = cart.AccountId,
            OwnerId = cart.OwnerId,
            PoNumber = cart.PoNumber,
            BillingStreet = cart.BillingStreet,
            BillingCity = cart.BillingCity,
            BillingState = cart.BillingState,
            BillingPostalCode = cart.BillingPostalCode,
            BillingCountry = cart.BillingCountry,
            BillingLatitude = cart.BillingLatitude,
            BillingLongitude = cart.BillingLongitude,
            ShippingStreet = cdg.DeliverToStreet,
            ShippingCity = cdg.DeliverToCity,
            ShippingState = cdg.DeliverToState,
            ShippingPostalCode = cdg.DeliverToPostalCode,
            ShippingCountry = cdg.DeliverToCountry,
            ShippingLatitude = cdg.DeliverToLatitude,
            ShippingLongitude = cdg.DeliverToLongitude,
            TECH_isPickingOrder__c = cdg.TECH_isPickingAddress__c,
            blng__BillingDayOfMonth__c = '1',
            CurrencyIsoCode = cart.CurrencyIsoCode,
            EffectiveDate = now,
            ShipToAccount__c = cart.ShipToAccount__c,
            OrderContact__c = contactFromCart.Id,
            ShipToContactId = cart.ShipToContact__c,
            TECH_Additional_Ship_to_Email__c = cart.Ship_To_Email__c,
            Order_date__c = System.today(), 
            Status = 'Draft',
            SAP_Order_Type__c = 'ZOR',
            Order_Origin__c = 'B2B Commerce',
            Incoterms__c = acc.Incoterms__c,
            InFullDelivery__c = true,
            EligibleToSync__c = false
            /*BillToContactId = cart.BillToContact__c,
            Bill_To_Account__c = cart.BillToAccount__c,
            SoldToAccount__c = cart.AccountId*/
        );
        
        if(listSo.size()>0){
            Order.SalesOrg__c = listSo[0].Id;
        }

        /**
         * @4C : Try to add a pricebook on test ONLY
         */
        if(Test.isRunningTest()){
            order.Pricebook2Id = Test.getStandardPricebookId();
        }

        //SBQQ.TriggerControl.disable();
        insert(order);
        //SBQQ.TriggerControl.enable();

        /*ConnectApi.OrderSummaryInputRepresentation orderSummaryInput = new ConnectApi.OrderSummaryInputRepresentation();
        orderSummaryInput.OrderId =order.Id;
        orderSummaryInput.OrderLifecycleType ='UNMANAGED';
        ConnectApi.OrderSummaryCreation.createOrderSummary(orderSummaryInput);*/

        return order.Id;
    }

    /**
     * @description Maps the cart delivery group entity to an order delivery group entity and returns the id of the
     *              order delivery group entity that was created.
     * @param cartDeliveryGroupId The cartDeliveryGroup id to map.
     * @param orderId The orderDeliveryGroup is linked to the original order.
     * @return The id of the order delivery group that was created.
     */
    private static Id mapAndInsertCartDeliveryGroupToOrderDeliveryGroup(Id cartDeliveryGroupId, Id orderId) {
        // Get the cart delivery group data needed to populate the order delivery group
        List<CartDeliveryGroup> cartDeliveryGroups = [SELECT
                DesiredDeliveryDate,
                DeliverToName,
                ShippingInstructions,
                DeliverToStreet,
                DeliverToCity,
                DeliverToState,
                DeliverToPostalCode,
                DeliverToCountry,
                DeliverToLatitude,
                DeliverToLongitude,
                DeliveryMethodId
        FROM CartDeliveryGroup WHERE Id = :cartDeliveryGroupId];

        // Retrieving DeliveryMethod Id to be put on OrderDelivery Method id
        List<CartDeliveryGroupMethod> cartDeliveryGroupMethod = [SELECT DeliveryMethodId FROM CartDeliveryGroupMethod WHERE CartDeliveryGroupId  = :cartDeliveryGroupId];


        CartDeliveryGroup cartDeliveryGroup = cartDeliveryGroups[0];
        CartDeliveryGroupMethod resultcartDeliveryGroupMethod = cartDeliveryGroupMethod[0];

        // Create the order delivery group
        Date desiredDeliveryDate = toDate(cartDeliveryGroup.DesiredDeliveryDate);
        OrderDeliveryGroup orderDeliveryGroup = new OrderDeliveryGroup(
                DesiredDeliveryDate = desiredDeliveryDate,
                DeliverToName = cartDeliveryGroup.DeliverToName,
                DeliveryInstructions = cartDeliveryGroup.ShippingInstructions,
                DeliverToStreet = cartDeliveryGroup.DeliverToStreet,
                DeliverToCity = cartDeliveryGroup.DeliverToCity,
                DeliverToState = cartDeliveryGroup.DeliverToState,
                DeliverToPostalCode = cartDeliveryGroup.DeliverToPostalCode,
                DeliverToCountry = cartDeliveryGroup.DeliverToCountry,
                DeliverToLatitude = cartDeliveryGroup.DeliverToLatitude,
                DeliverToLongitude = cartDeliveryGroup.DeliverToLongitude,
                OrderDeliveryMethodId = resultcartDeliveryGroupMethod.DeliveryMethodId,
                OrderId = orderId
        );

        insert orderDeliveryGroup;
        return orderDeliveryGroup.Id;
    }


    /**
     * @description Create the order summary object to display it for end user on B2B store
     * @param orderId The items are linked to the original order.
     */
    /*private static void createOrderSummary (Id orderId){
        try {        
            Order orderToUpdate = [SELECT id, Status FROM Order WHERE Id =:orderId LIMIT 1];
            orderToUpdate.Status = 'Picking';
            update orderToUpdate;

            ConnectApi.OrderSummaryInputRepresentation orderSummaryInput = new ConnectApi.OrderSummaryInputRepresentation();
            orderSummaryInput.OrderId = orderId;
            orderSummaryInput.OrderLifecycleType ='UNMANAGED';
            ConnectApi.OrderSummaryCreation.createOrderSummary(orderSummaryInput);

            orderToUpdate.Status = 'Draft';
            update orderToUpdate;
        } catch (Exception e) {
            System.debug('An error occurred creating the order summary : Error message'+e.getMessage());
        }
    }*/

    /**
     * @description Maps the cart items to a set of order items. This also creates order item adjustments.
     *              Tax adjustments could probably also be done here, but are not part of the example.
     * @param cartDeliveryGroupId the cartDeliveryGroup id for this set of cart items.
     * @param orderId The items are linked to the original order.
     * @param orderDeliveryGroupId The items are linked to the order delivery group.
     */
    private static void mapAndInsertCartItems(Id cartDeliveryGroupId, Id orderId, Id orderDeliveryGroupId/*, Id cartId*/) {
        // Get the cart items needed to populate the order items and adjustments
        List<CartItem> cartItems = [SELECT Id,
                AdjustmentAmount,
                Product2Id,
                //Product2.Lot_size__c,
                Type,
                Product2.SBQQ__ChargeType__c,
                Product2.ProductCode,
                Product2.CatalogFamilyDescription__c,
                Quantity,
                ListPrice,
                SalesPrice,
                CurrencyIsoCode,
                TotalLineAmount
        FROM CartItem WHERE CartDeliveryGroupId = :cartDeliveryGroupId];
        
        /*Boolean Software = false;
        
        //Order ord = [SELECT Id, AccountId FROM Order WHERE Id =:orderId];
        WebCart cart = [SELECT Id, ShipToAccount__c, AccountId FROM WebCart WHERE Id =:cartId];
        
        for(CartItem ci : cartItems){
            if(ci.Product2.CatalogFamilyDescription__c == 'Software'){
                Software = true;
            }
        }
        
        Contract cont = new Contract();
        
        if(Software){
            cont.AccountId = cart.AccountId;
            cont.AltShipTo_Account__c = cart.ShipToAccount__c;
            cont.Contract_Origin__c = 'Subscription';
            cont.InstallationDate__c = Date.today();
            cont.Periodicity__c = 'Calendar (Annual)';
            cont.SBQQ__Order__c = orderId;
            cont.Status = 'InProgress';
            cont.Type__c = 'CLOUD SUB.- ESAS';
            insert cont;
        }*/

        //List<OrderItem> orderItems = new List<OrderItem>();
        Map<Id,OrderItem> orderItemsMap = new Map<Id,OrderItem>();
        // For each item, map it to an order, then add adjustments
        for (CartItem cartItem : cartItems) {
            //orderItems.add(mapCartItemToOrderItem(cartItem, orderId, orderDeliveryGroupId));
            if(cartItem.Product2.CatalogFamilyDescription__c != 'Software'){
                orderItemsMap.put(cartItem.Id,mapCartItemToOrderItem(cartItem, orderId, orderDeliveryGroupId));
            }
            /*if(cartItem.Product2.CatalogFamilyDescription__c == 'Software'){
                Decimal price = getUnitPrice(cartItem);
                SBQQ__Subscription__c sub = new SBQQ__Subscription__c();
                //sub.Name = cont.ContractNumber + ' ' + cartItem.Product2.ProductCode;
                sub.SBQQ__Contract__c = cont.Id;
                sub.SBQQ__Product__c = cartItem.Product2Id;
                sub.SBQQ__Quantity__c = cartItem.Quantity;
				sub.CurrencyIsoCode = cartItem.CurrencyIsoCode;
                sub.SBQQ__SubscriptionEndDate__c = date.Today().addYears(50);
                sub.SBQQ__UnitCost__c = price;
                sub.SBQQ__Account__c = cart.ShipToAccount__c;
                sub.startDate__c = Date.today();
                SBQQ.TriggerControl.disable();
                insert sub;
                SBQQ.TriggerControl.enable();
            }*/
        }

        // If there are no items to insert, we can't do anything
        if (orderItemsMap.size() == 0 /*|| cartItems.size() != orderItemsMap.size()*/) {
            return;
        }
                
        SBQQ.TriggerControl.disable();
        insert orderItemsMap.values();
        SBQQ.TriggerControl.enable();
        
        //create new Order Item Tax Line Items according to Cart Taxes
        List<CartTax> cartTaxes = [SELECT
                                    CartItemId,
                                    Name,
                                    TaxCalculationDate,
                                    Amount,
                                    TaxRate,
                                    TaxType
                                    FROM CartTax WHERE CartItemId IN:orderItemsMap.keySet()];

        List<OrderItemTaxLineItem> orderTaxes = new List<OrderItemTaxLineItem>();
        // For each item, map it to an order, then add adjustments
        for (CartTax cartTax : cartTaxes) {
            orderTaxes.add(mapCartTaxToOrderItemTaxLineItem(cartTax, orderId, orderItemsMap.get(cartTax.CartItemId)));
        }

        // If there are no items to insert, we can't do anything
        if (orderTaxes.size() == 0 || cartTaxes.size() != orderTaxes.size()) {
            return;
        }
        
        SBQQ.TriggerControl.disable();
        insert orderTaxes;
        SBQQ.TriggerControl.enable();
    }

    /**
     * @description Maps the cart item to an order item.
     * @param cartItem The cartItem to map to an order item.
     * @param orderId The item is linked to the original order.
     * @param orderDeliveryGroupId The item is linked to the order delivery group.
     * @return The order item to be inserted.
     */
    private static OrderItem mapCartItemToOrderItem(CartItem cartItem, Id orderId, Id orderDeliveryGroupId) {
        String orderItemType = getOrderItemType(cartItem.Type);
        Decimal unitPrice = getUnitPrice(cartItem);
        Decimal listPrice = cartItem.ListPrice==null?0:cartItem.ListPrice;
        String blgRule = [SELECT Id FROM blng__BillingRule__c WHERE Name = 'Default Billing Rule'].Id;
        String blgRRR = [SELECT Id FROM blng__RevenueRecognitionRule__c WHERE Name = 'Default Rev Rec Rue'].Id;
        String blgTR = [SELECT Id FROM blng__TaxRule__c WHERE Name = 'Default Tax Rules'].Id;
        
        /*String frequency = '';
        String billingType = '';
        Double defaultSubTerm;
        Date endDate;
        if(cartItem.Product2.SBQQ__ChargeType__c == 'Recurring'){
            frequency = 'Monthly';
            billingType = 'Advance';
            defaultSubTerm = 1;
            endDate = date.Today().addYears(50);
        }*/
        
        OrderItem orderItem = new OrderItem(
            Product2Id = cartItem.Product2Id,
            Type = orderItemType,
            Quantity = cartItem.Quantity,
            ListPrice = listPrice,
            UnitPrice = unitPrice,
            OrderId = orderId,
            SBQQ__ChargeType__c = 'One-Time',
            /*endDate = endDate,
            SBQQ__ChargeType__c = cartItem.Product2.SBQQ__ChargeType__c,
            SBQQ__BillingFrequency__c = frequency,
            SBQQ__DefaultSubscriptionTerm__c = defaultSubTerm,
            SBQQ__BillingType__c = billingType,*/
            blng__BillableUnitPrice__c = unitPrice,
            blng__RevenueRecognitionRule__c = blgRRR,
            blng__BillingRule__c = blgRule,
            blng__TaxRule__c = blgTR,
            ServiceDate = date.today(),
            OrderDeliveryGroupId = orderDeliveryGroupId,
            TotalLineAmount = cartItem.TotalLineAmount
            
            //Quantity_Lot__c	= (cartItem.product2.Lot_size__c == null ? cartItem.Quantity : cartItem.Quantity / cartItem.product2.Lot_size__c)
        );
        
        /*
         *  @4C : Add a pricebook entry for the order product TEST ONLY
         */
        if(Test.isRunningTest()){
            Order parentOrder = [SELECT Id, CurrencyIsoCode FROM Order WHERE Id =: orderItem.OrderId];
           
            PricebookEntry testPricebookEntry = [SELECT id,Pricebook2Id,Product2Id FROM PricebookEntry WHERE Product2Id =:cartItem.Product2Id 
                                                 and Pricebook2Id =:Test.getStandardPricebookId() LIMIT 1][0];
            
            orderItem.PricebookEntryId = testPricebookEntry.Id;
        }

        return orderItem;
    }

    /**
     * @description Maps the cart tax to an order tax.
     * @param cartTax The cartItem to map to an order item.
     * @param orderId The item is linked to the original order.
     * @param orderItem The item is linked to the new orderItem.
     * @return The order tax to be inserted.
     */
    private static OrderItemTaxLineItem mapCartTaxToOrderItemTaxLineItem(CartTax cartTax, Id orderId, OrderItem orderItem) {
        //String orderItemType = getOrderItemType(cartItem.Type);
        //Decimal unitPrice = getUnitPrice(cartItem);

        OrderItemTaxLineItem orderTaxItem = new OrderItemTaxLineItem(
            Amount = cartTax.Amount,
            Rate = cartTax.TaxRate,
            Name = cartTax.Name,
            OrderItemId = orderItem.Id,
            //OrderItemAdjustmentLineItemId = ,
            TaxEffectiveDate = cartTax.TaxCalculationDate,
            Type = 'Actual' 
        );

        return orderTaxItem;
    }

    

    /**
     * @description Gets the order item type from the sales item type. This maps the cart item type to the order item type.
     * @param cartItemType The cart item's type.
     * @return The order Item Type or null if the type doesn't map.
     */
    private static String getOrderItemType(String cartItemType) {
        if (cartItemType == 'Product') {
            return 'Order Product';
        }
        if (cartItemType == 'Charge') {
            return 'Delivery Charge';
        }

        return null;
    }

    /**
     * @description Gets the unit price from the cart item. This tries to use the sales price but will default to the list price
     *              if there is no sales price.
     * @param cartItem The item that has the prices.
     * @return The unit price.
     */
    private static Decimal getUnitPrice(CartItem cartItem) {
        if (cartItem.SalesPrice != null) {
            return cartItem.SalesPrice;
        }

        return cartItem.ListPrice;
    }

    /**
     * @description Converts a DateTime object to a Date object.
     * @param dt The datetime to convert.
     * @return The new Date.
     */
    private static Date toDate(Datetime dt) {
        if (dt != null) {
            return Date.newInstance(dt.year(), dt.month(), dt.day());
        }

        return null;
    }
}