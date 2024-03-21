import { LightningElement, api, wire, track } from 'lwc';


/*import { getRecord, getFieldValue } from "lightning/uiRecordApi";

import { refreshApex } from '@salesforce/apex';

import GRAND_TOTAL_AMOUNT from '@salesforce/schema/WebCart.GrandTotalAmount';
import TOTAL_CHARGE_AMOUNT from '@salesforce/schema/WebCart.TotalChargeAmount';
import TOTAL_PRODUCT_AMOUNT from '@salesforce/schema/WebCart.TotalProductAmount';
import TOTAL_TAX_AMOUNT from '@salesforce/schema/WebCart.TotalTaxAmount';
import TOTAL_AMOUNT from '@salesforce/schema/WebCart.TotalAmount';
import CANADIAN_TAX_PSTQST from '@salesforce/schema/WebCart.CanadianTaxPSTQST__c';
import CANADIAN_TAX_GSTHST from '@salesforce/schema/WebCart.CanadianTaxGSTHST__c';*/

import DeliverToCountry from '@salesforce/apex/B2BCheckoutSummaryAdditionalInfos.retrieveDeliverToCountry';
import CurrencyFromCart from '@salesforce/apex/B2BCheckoutSummaryAdditionalInfos.retrieveCurrency';
import retrieveCart from '@salesforce/apex/B2BCheckoutSummaryAdditionalInfos.retrieveCart';
import softwareAmountMethod from '@salesforce/apex/B2BCheckoutSummaryAdditionalInfos.softwareAmount';
import 	B2BStore_Checkout_Summary from '@salesforce/label/c.B2BStore_Checkout_Summary';
import 	B2BStore_Subtotal from '@salesforce/label/c.B2BStore_Subtotal';
import 	Shipping from '@salesforce/label/c.Shipping';
import 	B2BStore_Total_Before_Tax from '@salesforce/label/c.B2BStore_Total_Before_Tax';
import 	B2BStore_Estimated_GST_HST from '@salesforce/label/c.B2BStore_Estimated_GST_HST';
import 	B2BStore_Estimated_PST_QST from '@salesforce/label/c.B2BStore_Estimated_PST_QST';
import 	B2BStore_without_Tax from '@salesforce/label/c.B2BStore_without_Tax';
import 	B2BStore_Tax from '@salesforce/label/c.B2BStore_Tax';
import 	B2BStore_Order_Total from '@salesforce/label/c.B2BStore_Order_Total';	


//const fields = [GRAND_TOTAL_AMOUNT, TOTAL_CHARGE_AMOUNT, TOTAL_PRODUCT_AMOUNT, TOTAL_TAX_AMOUNT, CANADIAN_TAX_PSTQST, CANADIAN_TAX_GSTHST, TOTAL_AMOUNT];

export default class CheckoutSummaryB2BTotals extends LightningElement {
    @api cartId;
    @api canadaCountry;
    @api usCountry;
    @api currencySymbol;
    @api htMention;
    //@api shipping;
    //@track cart;
    softwareAmount;
    cart;

    labels = {
        B2BStore_Checkout_Summary,
        B2BStore_Subtotal,
        Shipping,
        B2BStore_Total_Before_Tax,
        B2BStore_Estimated_GST_HST,
        B2BStore_Estimated_PST_QST,
        B2BStore_without_Tax,
        B2BStore_Tax,
        B2BStore_Order_Total
     };

    //fields = [GRAND_TOTAL_AMOUNT, TOTAL_CHARGE_AMOUNT, TOTAL_PRODUCT_AMOUNT, TOTAL_TAX_AMOUNT, CANADIAN_TAX_PSTQST, CANADIAN_TAX_GSTHST, TOTAL_AMOUNT];

    /*@wire(getRecord, {recordId: '$cartId', fields: '$fields'})
    fetchCart(response) {
        console.log('Cart => ', JSON.stringify(response));
        this.cart = response;
    }

    refreshWire() {
        refreshApex(this.cart);
    }*/

    /*@wire(getRecord, {recordId: '$cartId', fields: '$fields'})
    cart*/

    connectedCallback() {
		DeliverToCountry({cartId: this.cartId})
        .then(result => {
			console.log(result);
			if(result == 'Canada'){
				this.canadaCountry = true;
			}else if(result == 'United States'){
                this.usCountry = true;
            }
            /*if(result == 'France'){
                this.htMention = 'HT';
            }else if(result != 'Canada' && result != 'United States' && result != 'France'){
                this.htMention = 'without Tax'
            }*/
            if(result != 'Canada' && result != 'United States'){
                this.htMention = this.labels.B2BStore_without_Tax
            }
        })
        .catch(error => {
            console.log(error);
        });

        CurrencyFromCart({cartId: this.cartId})
        .then(result => {
			console.log(result);
			if(result == 'USD'){
				this.currencySymbol = '$';
			}else if(result == 'CAD'){
				this.currencySymbol = 'CA$';
            }else if(result == 'EUR'){
				this.currencySymbol = '€';
            }
        })
        .catch(error => {
            console.log(error);
        });

        softwareAmountMethod({cartId: this.cartId})
        .then(result => {
            this.softwareAmount = result;
            retrieveCart({cartId: this.cartId})
            .then(result => {
                this.cart = result;
                this.cart.TotalProductAmount = this.cart.TotalProductAmount-this.softwareAmount;
                this.cart.TotalAmount = this.cart.TotalAmount-this.softwareAmount;
                this.cart.GrandTotalAmount = this.cart.GrandTotalAmount-this.softwareAmount;
            })
            .catch(error => {
                console.log(error);
            });
        })
        .catch(error => {
            console.log(error);
        });


	}   
}