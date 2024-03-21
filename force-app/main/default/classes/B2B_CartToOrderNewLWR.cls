public without sharing class B2B_CartToOrderNewLWR {

    /**
     * @description Maps a cart to an order. Activates it, and closes the cart. Returns the resulting order summary id.
     * @param request The checkout session and cart id.
     * @return The OrderId that resulted from this class.
     */
    @AuraEnabled(cacheable=false)
    public static void cartToOrder(Id cartId, Map<string,string> billingData) {
        try {
             // load the primary delivery group (only one supported at this time)
            Id cartDeliveryGroupId = [SELECT Id FROM CartDeliveryGroup WHERE CartId = :cartId][0].Id;
            System.debug('******************** call  mapAndUpsertOrderFromCart');
            Id orderId = mapAndInsertOrderFromCart(cartId, billingData);
            System.debug('******************** call  mapAndInsertCartDeliveryGroupToOrderDeliveryGroup');
            Id orderDeliveryGroupId = mapAndInsertCartDeliveryGroupToOrderDeliveryGroup(cartDeliveryGroupId, orderId);
            mapAndInsertCartItems(cartDeliveryGroupId, orderId, orderDeliveryGroupId/*, cartId*/);

        } catch(Exception e) {
            throw handledException(e.getMessage());
        }

    }

    @AuraEnabled(cacheable=false)
    public static void deleteOrderFromCart(Id cartId) {
        try {
            WebCart cart = [SELECT order__c FROM WebCart WHERE Id = :cartId];
            if(cart.order__c == null){
                return;
            }
            Order order = [SELECT Id FROM Order WHERE Id = :cart.order__c];
            if(order == null){
                return;
            }
            List<OrderItem> orderItems = [SELECT Id From OrderItem WHERE OrderId = :cart.order__c];
            System.debug('***********************   orderItems for deletion     ************************');
            System.debug(orderItems);
            SBQQ.TriggerControl.disable();
            delete orderItems;
            SBQQ.TriggerControl.enable();
            List<OrderItemTaxLineItem> orderTaxeLineItems = [SELECT Id FROM OrderItemTaxLineItem  WHERE OrderId = :cart.order__c];
            System.debug('***********************   orderTaxeLineItems for deletion    ************************');
            System.debug(orderTaxeLineItems);
            SBQQ.TriggerControl.disable();
            delete orderTaxeLineItems;
            SBQQ.TriggerControl.enable();
            SBQQ.TriggerControl.disable();
            delete order;
            SBQQ.TriggerControl.enable();
        } catch(Exception e) {
            throw handledException(e.getMessage());
        }
    }
    /**
     * @description Maps the cart entity to an order entity and returns the id of the order entity that was created.
     * @param cartId The cart id to map to an order.
     * @return The id of the order that was created.
     */
    private static Id mapAndInsertOrderFromCart(Id cartId, Map<string,string> billingData) {

        ID billToAccountId = billingData.get('accountId');
        ID billToContactId = billingData.get('contactId');
        String billToEmail = billingData.get('email');
        // Get the cart data needed to populate the order
        WebCart cart = [
            SELECT 
                Id,
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
                Ship_To_Email__c,
                BillToAccount__c,
                order__c
            FROM WebCart 
            WHERE Id = :cartId
        ];

        User userFromCart = [SELECT Id, ContactId FROM User WHERE Id =:cart.OwnerId];
        Contact contactFromCart = [SELECT id FROM Contact WHERE Id =:userFromCart.ContactId];

        CartDeliveryGroup cdg = [
            SELECT 
                Id, 
                DeliverToCity, 
                DeliverToCountry, 
                DeliverToLatitude, 
                DeliverToLongitude, 
                DeliverToPostalCode, 
                DeliverToState, 
                DeliverToStreet, 
                TECH_isPickingAddress__c
            FROM CartDeliveryGroup 
            WHERE CartId =:cartId
        ][0];

        Account acc = [SELECT Id, Incoterms__c FROM Account WHERE Id =:cart.AccountId];
        List<Account_Salesorg__c> aso = [SELECT Id, Sales_Org__c FROM Account_Salesorg__c WHERE Account__c = :acc.Id AND Primary__c = true LIMIT 1];
        List<Sales_Org__c> listSo = new List<Sales_Org__c>();
        if(aso.size() > 0){
            listSo = [SELECT Id, Code__c FROM Sales_Org__c WHERE Id = :aso[0].Sales_Org__c LIMIT 1];
        }
        
        // Create the order
        Date now = Date.today();
        dateTime nowDateTime = system.now();
        System.debug('***********************   CART    ************************');
        System.debug(cart);
        Order order = new Order();
        // if(cart.order__c != null){
        //     Id orderId = cart.order__c;
        //     List<OrderItem> orderItems = [SELECT Id From OrderItem WHERE OrderId =:orderId];
        //     System.debug('***********************   orderItems for deletion     ************************');
        //     System.debug(orderItems);
        //     SBQQ.TriggerControl.disable();
        //     delete orderItems;
        //     SBQQ.TriggerControl.enable();
        //     List<OrderItemTaxLineItem> orderTaxeLineItems = [SELECT Id FROM OrderItemTaxLineItem  WHERE OrderId =:orderId];
        //     System.debug('***********************   orderTaxeLineItems for deletion    ************************');
        //     System.debug(orderTaxeLineItems);
        //     SBQQ.TriggerControl.disable();
        //     delete orderTaxeLineItems;
        //     SBQQ.TriggerControl.enable();
        //     order = [ 
        //         SELECT 
        //             Id,
        //             AccountId, 
        //             OwnerId,
        //             PoNumber,
        //             Bill_To_Account__c,
        //             BillToContactId,
        //             BillingStreet,
        //             BillingCity,
        //             BillingState,
        //             BillingPostalCode,
        //             BillingCountry,
        //             BillingLatitude,
        //             BillingLongitude,
        //             ShippingStreet,
        //             ShippingCity,
        //             ShippingState,
        //             ShippingPostalCode,
        //             ShippingCountry,
        //             ShippingLatitude,
        //             ShippingLongitude,
        //             TECH_isPickingOrder__c,
        //             blng__BillingDayOfMonth__c,
        //             CurrencyIsoCode,
        //             EffectiveDate,
        //             OrderedDate,
        //             ShipToAccount__c,
        //             OrderContact__c,
        //             ShipToContactId,
        //             TECH_Additional_Ship_to_Email__c,
        //             Order_date__c, 
        //             Status,
        //             SAP_Order_Type__c,
        //             Order_Origin__c,
        //             Incoterms__c,
        //             InFullDelivery__c,
        //             EligibleToSync__c,
        //             SalesOrg__c,
        //             Pricebook2Id
        //         FROM Order
        //         WHERE Id =:cart.order__c
        //     ];    
        // }
        order.AccountId = cart.AccountId;
        order.OwnerId = cart.OwnerId;
        order.PoNumber = cart.PoNumber;
        order.BillToContactId = billToContactId;
        order.Bill_To_Account__c = billToAccountId;
        order.BillingStreet = cart.BillingStreet;
        order.BillingCity = cart.BillingCity;
        order.BillingState = cart.BillingState;
        order.BillingPostalCode = cart.BillingPostalCode;
        order.BillingCountry = cart.BillingCountry;
        order.BillingLatitude = cart.BillingLatitude;
        order.BillingLongitude = cart.BillingLongitude;
        order.ShippingStreet = cdg.DeliverToStreet;
        order.ShippingCity = cdg.DeliverToCity;
        order.ShippingState = cdg.DeliverToState;
        order.ShippingPostalCode = cdg.DeliverToPostalCode;
        order.ShippingCountry = cdg.DeliverToCountry;
        order.ShippingLatitude = cdg.DeliverToLatitude;
        order.ShippingLongitude = cdg.DeliverToLongitude;
        order.blng__BillingDayOfMonth__c = '1';
        order.CurrencyIsoCode = cart.CurrencyIsoCode;
        order.EffectiveDate = now;
        order.OrderedDate = nowDateTime;
        order.ShipToAccount__c = cart.ShipToAccount__c;
        order.OrderContact__c = contactFromCart.Id;
        order.ShipToContactId = cart.ShipToContact__c;
        order.TECH_isPickingOrder__c = cdg.TECH_isPickingAddress__c;
        order.TECH_Additional_Bill_to_Email__c = billToEmail;
        order.TECH_Additional_Ship_to_Email__c = cart.Ship_To_Email__c;
        order.TECH_B2B_Payment_Terms_Accepted__c = true;
        order.TECH_B2B_Terms_And_Conditions_Accepted__c = true;
        order.Order_date__c = System.today();
        order.Status = 'Draft';
        order.SAP_Order_Type__c = 'ZOR';
        order.Order_Origin__c = 'B2B Commerce';
        order.Incoterms__c = acc.Incoterms__c;
        order.InFullDelivery__c = true;
        order.EligibleToSync__c = false;    
       
        if(listSo.size()>0){
            order.SalesOrg__c = listSo[0].Id;
        }

        /**
         * @4C : Try to add a pricebook on test ONLY
         */
        if(Test.isRunningTest()){
            order.Pricebook2Id = Test.getStandardPricebookId();
        }
        System.debug('***********************   ORDER    ************************');
        System.debug(order);
        SBQQ.TriggerControl.disable();
        insert(order);
        SBQQ.TriggerControl.enable();
        cart.order__c = order.Id;
        SBQQ.TriggerControl.disable();
        update cart;
        SBQQ.TriggerControl.enable();
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

        // delete order delivery group if exist for the order
        List<OrderDeliveryGroup> odgs = [SELECT Id FROM OrderDeliveryGroup WHERE OrderId  = :orderId];
        if(odgs.size() > 0) {
            delete odgs;
        }

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
     * @description Maps the cart items to a set of order items. This also creates order item adjustments.
     *              Tax adjustments could probably also be done here, but are not part of the example.
     * @param cartDeliveryGroupId the cartDeliveryGroup id for this set of cart items.
     * @param orderId The items are linked to the original order.
     * @param orderDeliveryGroupId The items are linked to the order delivery group.
     */
    private static void mapAndInsertCartItems(Id cartDeliveryGroupId, Id orderId, Id orderDeliveryGroupId/*, Id cartId*/) {
        System.debug('***********************   mapAndInsertCartItems    ************************');
        System.debug('cartDeliveryGroupId' + cartDeliveryGroupId);
        System.debug('orderId' + orderId);
        System.debug('orderDeliveryGroupId' + orderDeliveryGroupId);
        // Order is upserted orderItems and OrderTaxeLineItems are deleted before insert items   
        List<OrderItem> orderItems = [SELECT Id From OrderItem WHERE OrderId =:orderId];
        System.debug('***********************   orderItems    ************************');
        System.debug(orderItems);
        List<OrderItemTaxLineItem> orderTaxeLineItems = [SELECT Id FROM OrderItemTaxLineItem  WHERE OrderId =:orderId];
        System.debug('***********************   orderTaxeLineItems    ************************');
        System.debug(orderTaxeLineItems);




        // Get the cart items needed to populate the order items and adjustments
        List<CartItem> cartItems = [
            SELECT 
                Id,
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
            FROM CartItem 
            WHERE CartDeliveryGroupId = :cartDeliveryGroupId
        ];
        System.debug('***********************   CartItems    ************************');
        System.debug(cartItems);

        Map<Id,OrderItem> orderItemsMap = new Map<Id,OrderItem>();
        // For each item, map it to an order, then add adjustments
        for (CartItem cartItem : cartItems) {

            if(cartItem.Product2.CatalogFamilyDescription__c != 'Software'){
                orderItemsMap.put(cartItem.Id,mapCartItemToOrderItem(cartItem, orderId, orderDeliveryGroupId));
            }
        }

        // If there are no items to insert, we can't do anything
        if (orderItemsMap.size() == 0 /*|| cartItems.size() != orderItemsMap.size()*/) {
            return;
        }
                
        SBQQ.TriggerControl.disable();
        insert orderItemsMap.values();
        SBQQ.TriggerControl.enable();

        //create new Order Item Tax Line Items according to Cart Taxes
        List<CartTax> cartTaxes = [
            SELECT
                    CartItemId,
                    Name,
                    TaxCalculationDate,
                    Amount,
                    TaxRate,
                    TaxType
            FROM CartTax 
            WHERE CartItemId IN:orderItemsMap.keySet()];

        System.debug('***********************   CartTaxes    ************************');
        System.debug(cartTaxes);
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
        System.debug('***********************   mapCartItemToOrderItem    ************************');
        System.debug('***********************  cartItem ' + cartItem);
        System.debug('***********************  orderId ' + orderId);
        System.debug('***********************  orderDeliveryGroupId ' + orderDeliveryGroupId);

        String orderItemType = getOrderItemType(cartItem.Type);
        System.debug('***********************  orderItemType ' + orderItemType);

        Decimal unitPrice = getUnitPrice(cartItem);
        System.debug('***********************  unitPrice ' + unitPrice);
        System.debug('***********************  listPrice >' );
        System.debug(cartItem.ListPrice);
        Decimal listPrice = cartItem.ListPrice==null?0:cartItem.ListPrice;
        System.debug('***********************  listPrice :' + listPrice );

        System.debug('***********************  blgRule  > ');
        String blgRule = [SELECT Id FROM blng__BillingRule__c WHERE Name = 'Default Billing Rule'].Id;
        System.debug('***********************  blgRule OBJ ********** ');
        // System.debug(blgRuleObj);
        // ID blgRule = blgRuleObj.Id;
        System.debug('***********************  blgRule ' + blgRule);

        System.debug('***********************  blgRRR  > ');
        String blgRRR = [SELECT Id FROM blng__RevenueRecognitionRule__c WHERE Name = 'Default Rev Rec Rue'].Id;
        System.debug('***********************  blgRRR ' + blgRRR);

        System.debug('***********************  blgTR  > ');
        String blgTR = [SELECT Id FROM blng__TaxRule__c WHERE Name = 'Default Tax Rules'].Id;
        System.debug('***********************  blgTR ' + blgTR);
        
        OrderItem orderItem = new OrderItem(
            Product2Id = cartItem.Product2Id,
            Type = orderItemType,
            Quantity = cartItem.Quantity,
            ListPrice = listPrice,
            UnitPrice = unitPrice,
            OrderId = orderId,
            SBQQ__ChargeType__c = 'One-Time',
            blng__BillableUnitPrice__c = unitPrice,
            blng__RevenueRecognitionRule__c = blgRRR,
            blng__BillingRule__c = blgRule,
            blng__TaxRule__c = blgTR,
            ServiceDate = date.today(),
            OrderDeliveryGroupId = orderDeliveryGroupId,
            TotalLineAmount = cartItem.TotalLineAmount
            
        );
        System.debug('***********************   orderItem    ************************');
        System.debug(orderItem);
        
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

    private static AuraHandledException handledException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }
}