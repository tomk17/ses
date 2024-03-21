public with sharing class B2BPaymentController {

    /**
    * Tokenizes the payment information, returns a paymentMethod that is then saved to the current WebCart.
    * It also updates the WebCart with the selected billing address.
    **/
    @AuraEnabled
    public static void setPayment(//String paymentType,
                                  String cartId,
                                  //Map<String, Object> billingAddress,
                                  Map<String, Object> paymentInfo) {
        try {
            system.debug('Tom setPayment');
            String queryFields = 'PONumber, PaymentMethodId, WebStoreId, BillingAddress, BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode';

            String soqlQuery = 'SELECT ' + queryFields + ' FROM WebCart WHERE Id=:cartId LIMIT 1';
            WebCart cart = Database.query(soqlQuery);

            String webStoreId = cart.WebStoreId;

            cart.PONumber = null;
            // Let's first check that paymentGateway has been setup
            String paymentGatewayId = getPaymentGatewayId(webStoreId);

            // Cannot proceed if paymentGatewayId does not exist
            if (paymentGatewayId == null || paymentGatewayId.equals('')) {
                throw new AuraHandledException('This store is not authorized to process payments.');
            }

            // Tokenize the paymentInfo
            ConnectApi.PaymentMethodTokenizationRequest tokenizeRequest = new ConnectApi.PaymentMethodTokenizationRequest();
            tokenizeRequest.paymentGatewayId = paymentGatewayId;
            tokenizeRequest.cardPaymentMethod = getCardPaymentMethod(paymentInfo);
            /*if (billAddressSet) {
                tokenizeRequest.address = getAddress(billingAddress);                    
            }*/
            
            ConnectApi.AddressRequest address = new ConnectApi.AddressRequest();
            address.street = (String) cart.BillingStreet;
            address.city = (String) cart.BillingCity;
            address.state = (String) cart.BillingState;
            address.country = (String) cart.BillingCountry;
            address.postalCode = (String) cart.BillingPostalCode;

            tokenizeRequest.address = address;

            if(!test.isRunningTest()){
                system.debug('Tom Tokenize Response');
                ConnectApi.PaymentMethodTokenizationResponse tokenizeResponse = ConnectApi.Payments.tokenizePaymentMethod(tokenizeRequest); 
                system.debug(tokenizeResponse);
                if (tokenizeResponse.error != null) {System.debug('TokenizeResponse has an error: ' + tokenizeResponse.error.message);throw new AuraHandledException('There are issues finalizing your payment. Try contacting your account rep.');}
                
                // Tokenize was successful, assign the new payment method to the cart.
                System.debug('BEN tokenizeResponse' + tokenizeResponse);
                
                cart.paymentMethodId = tokenizeResponse.paymentMethod.Id;
                //}
                
                // Now update the webCart
                if(Schema.sObjectType.WebCart.isAccessible()) {update cart;}
            }

        // } catch (AuraHandledException e) {throw e;} catch (DmlException e) {throw new AuraHandledException('Unexpected error occurred while updating the cart: ' + e.getMessage());} catch (ConnectApi.ConnectApiException e) {throw new AuraHandledException('Unexpected error occurred while processing payment: ' + e.getMessage());} catch (Exception e) {throw new AuraHandledException(e.getMessage());}
        } catch (AuraHandledException e) {system.debug(e.getMessage()); throw e;} catch (DmlException e) {system.debug(e.getMessage());throw new AuraHandledException(e.getMessage());} catch (ConnectApi.ConnectApiException e) { system.debug(e.getMessage()); throw new AuraHandledException(System.Label.B2BStore_CardGatewayError);} catch (Exception e) {system.debug(e.getMessage());throw new AuraHandledException(e.getMessage());}}

    private static String getPaymentGatewayId(String webStoreId) {
        String paymentGatewayId = null;
        try {
            paymentGatewayId = [SELECT Integration FROM StoreIntegratedService WHERE ServiceProviderType='Payment' AND StoreId=:webStoreId].Integration;
        } catch (Exception e) {
            // For debug logs
            System.debug('Error querying the payment integration from StoreIntegratedService: ' + e.getMessage());
        }
        return paymentGatewayId;
    }
    
    private static ConnectApi.CardPaymentMethodRequest getCardPaymentMethod(Map<String, Object> paymentInfo) {
        system.debug('Tom getCardPaymentMethod');        
        ConnectApi.CardPaymentMethodRequest paymentMethod = new ConnectApi.CardPaymentMethodRequest();
        paymentMethod.cardCategory = ConnectApi.CardCategory.CreditCard;
        paymentMethod.cardHolderFirstName = (String) paymentInfo.get('cardHolderName');
        paymentMethod.cardHolderLastName = (String) paymentInfo.get('cardHolderLastName');
        paymentMethod.cardNumber = (String) paymentInfo.get('cardNumber');
        paymentMethod.cardType = (String) paymentInfo.get('cardType');
        if (paymentInfo.get('cvv') != null) { //throws special error if this is missing
            paymentMethod.cvv = (String) paymentInfo.get('cvv');            
        }
        paymentMethod.expiryMonth = Integer.valueOf(paymentInfo.get('expiryMonth'));
        paymentMethod.expiryYear = Integer.valueOf(paymentInfo.get('expiryYear'));
        system.debug(paymentMethod);      
        return paymentMethod;
    }

}