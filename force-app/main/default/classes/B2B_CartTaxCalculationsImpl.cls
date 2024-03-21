/* *******************************************************************************************************
 * Name               :                                                                                  *
 * Description        :                                                                                  *
 * Created Date       : 08.12.2020                                                                       *
 * Created By         : Jakub Holys @Waeg                                                                *
 * -----------------------------------------------------------------------------------------------       *
 * VERSION    AUTHOR                 DATE                                                                *
 *   1.0 -    Jakub Holys @Waeg      26-Nov-2018 Initial version                                         *
 *   1.1 -    Joao Mota @Waeg        19-Jan-2021 Integrate with Avalara to calculate taxes   
 *   1.2 -    Benjamin Cligny @Icom  03-Feb-2023  
 *   1.3 -    Tom KOUAME @Icom       04-Jan-2024 get Only State Taxe entries from AVALARA response       *
 ******************************************************************************************************* */

public with sharing class B2B_CartTaxCalculationsImpl implements sfdc_checkout.CartTaxCalculations {
    
    public sfdc_checkout.IntegrationStatus startCartProcessAsync(sfdc_checkout.IntegrationInfo integrationInfo, Id cartId) {
        sfdc_checkout.IntegrationStatus outcome = new sfdc_checkout.IntegrationStatus();
        outcome.status = sfdc_checkout.IntegrationStatus.Status.SUCCESS;
        
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
        
        if(acc.pw_cc__ShippingCountryLookup__r.Zone__c != 'CEE' && acc.pw_cc__ShippingCountryLookup__r.Zone__c != 'France' && acc.pw_cc__ShippingCountryLookup__r.Zone__c != 'EMEA'){
        
            B2B_AvalaraWebCallAPI.AvalaraTransaction avalaraTransactionResponse = B2B_AvalaraWebCallAPI.calculateAvataxTransation(cart);
            System.debug('avalaraTransactionResponse : ' + avalaraTransactionResponse);
            
            
            if(avalaraTransactionResponse.Status == 'Error'){
                B2B_CheckoutUtils.integrationStatusWithCartValidationOutputWarning(
                    outcome, 'An error occured. Please Review the Shipping Address.', integrationInfo, cartId, 'Taxes');
            } else{
                cartTaxes = new List<CartTax>();
                                
                for(B2B_AvalaraWebCallAPI.AvalaraLineItem lineItem : avalaraTransactionResponse.lines){
                    System.debug('lineItem : ' + lineItem);
                    for(B2B_AvalaraWebCallAPI.AvalaraTaxDetail lineItemDetail : lineItem.details){
                        System.debug('lineItemDetail : ' + lineItemDetail);
                        // only take STATE TAX 
                        if(lineItemDetail.taxName == 'IL STATE TAX') {
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
                }
            }
        }
        
        try {
            //List<CartItem> cartItems = [SELECT Id, TotalPrice FROM CartItem WHERE CartId = :cartId];

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
        } catch (Exception exc) {
            outcome.status = sfdc_checkout.IntegrationStatus.Status.FAILED;
        }

        return outcome;
    }
}