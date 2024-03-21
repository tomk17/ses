// Standard Imports
import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Apex Classes
import retrieveShippingAccountCountryAndZone from '@salesforce/apex/B2BCheckoutSummaryAdditionalInfos.retrieveShippingAccountCountryAndZone';
import retrieveContactEmail from '@salesforce/apex/B2BCheckoutSummaryAdditionalInfos.retrieveContactEmail';
import retrieveOptionalEmail from '@salesforce/apex/B2BCheckoutSummaryAdditionalInfos.retrieveOptionalEmail';
import retrieveProduct from '@salesforce/apex/B2BCheckoutSummaryAdditionalInfos.retrieveProduct';
import retrieveSoftware from '@salesforce/apex/B2BCheckoutSummaryAdditionalInfos.retrieveSoftware';
import retrieveCurrency from '@salesforce/apex/B2BCheckoutSummaryAdditionalInfos.retrieveCurrency';

import { CartSummaryAdapter } from "commerce/cartApi";

import ToastMessageServiceChannel from '@salesforce/messageChannel/toastMessageServiceChannel__c';
import CheckoutDeliveryMessageChannel from '@salesforce/messageChannel/checkoutDeliveryMessageChannel__c';
// import TermsAndPONumberMessageChannel from '@salesforce/messageChannel/termsAndPONumberMessageChannel__c';
import { subscribe, unsubscribe, publish, MessageContext, APPLICATION_SCOPE } from 'lightning/messageService';

// Labels
import shippingContact from '@salesforce/label/c.ShippingContact';
import selectedContact from '@salesforce/label/c.B2BStore_Email_address_of_the_selected_contact';
import additionalEmailAddress from '@salesforce/label/c.B2BStore_Additional_email_address';
import noEmail from '@salesforce/label/c.B2BStore_NoEmail';
import productName from '@salesforce/label/c.B2BStore_Product_Name';
import software from '@salesforce/label/c.B2BStore_Software';
import quantity from '@salesforce/label/c.B2BStore_Quantity';
import availablity from '@salesforce/label/c.B2BStore_Availablity';
import price from '@salesforce/label/c.B2BStore_Price';
import monthlyFee from '@salesforce/label/c.B2BStore_Monthly_Fee';
import atp1 from '@salesforce/label/c.B2BStore_ATP1';
import atp2 from '@salesforce/label/c.B2BStore_ATP2';
import atp3 from '@salesforce/label/c.B2BStore_ATP3';
import atp4 from '@salesforce/label/c.B2BStore_ATP4';
import atp5 from '@salesforce/label/c.B2BStore_ATP5';
import deliveryMethod from '@salesforce/label/c.B2BStore_Delivery_Method';
import standardMethod from '@salesforce/label/c.B2BStore_Standard_Delivery';





export default class checkoutSummaryAdditionalInfosB2B extends LightningElement {
    contentReady = false;

    label = {
        shippingContact
        , selectedContact
        , additionalEmailAddress
        , noEmail
        , productName
        , software
        , quantity
        , availablity
        , price
        , monthlyFee
        , atp1
        , atp2
        , atp3
        , atp4
        , atp5
        , deliveryMethod
        , standardMethod
    };
    _cartId;
    _accountId;

    _shippingDone = false;
    _billingDone = false;
    _checkoutMode
    
    _email;
    _optionalEmail;
    _products = [];
    _softwares = [];
    _currency;

    needPayment = false;
    subscription = null;

    get cartId() {
        return !!this._cartId ? this._cartId : false;
    }
    get accountId() {
        return !!this._accountId ? this._accountId : false;
    }
    get email() {
        return !!this._email ? this._email : false;
    }
    get optionalEmail() {
        return !!this._optionalEmail ? this._optionalEmail : false;
    }
    get products() {
        return this._products.length > 0 ? this._products : false;
    }
    get softwares() {
        return this._softwares.length > 0 ? this._softwares : false;
    }
    get currency() {
        return !!this._currency ? this._currency : false;
    }
   

    @api
    get checkoutMode() {
        return this._checkoutMode;
    }

    set checkoutMode(value) {
        console.log(`Checkout summary : ${value}`);
        this._checkoutMode = value;
    } 

    @api
    checkoutSave() {
       console.log('save summary');
    }    
    @api
    reportValidity() {
       
        return true;
    }

    //Use commerce API to fetch cartId and accountId from current cart  
    @wire(CartSummaryAdapter)
    cartSummaryHandler(response) {
        if (response.data) {
            this._cartId = response.data.cartId;
            this._accountId = response.data.accountId;
        }
    }

    // Initialize messageContext for Message Service
    @wire(MessageContext)
    messageContext;
    // Subscribes to the checkout delivery component's message channel
    subscribeToDeliveryMessageChannel() {

        if (this.deliveryMessageSubscription) {
            return;
        }
        this._billingDone = false;
        // Subscribe to the message channel to retrieve the recordId and explicitly assign it to boatId.
        this.deliveryMessageSubscription = subscribe(
            this.messageContext,
            CheckoutDeliveryMessageChannel,
            (message) => {
                console.log("Cart Summary recieved a message");
                console.log(message);
                if (!!message.billingDone){
                    console.log(`message.billingDone ${!!message.billingDone}`);
                    this._billingDone = true;
                }
               
                this.displayCheckoutSummary();
            },
            {
                scope: APPLICATION_SCOPE
            }
        );
    }
    

    unsubscribeToMessageChannel() {
        unsubscribe(this.deliveryMessageSubscription);
        this.deliveryMessageSubscription = null;
    }

    connectedCallback() {
        this.subscribeToDeliveryMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    async displayCheckoutSummary() {
        console.log(`this._cartId ${this._cartId}`);
        console.log(`this._billingDone ${this._billingDone}`);

        if(!this._cartId || !this._billingDone) return;


        try {
            
            /// Update Order Info
            const emailResult = await retrieveContactEmail({ cartId: this._cartId });
            const optionalEmail = await retrieveOptionalEmail({ cartId: this._cartId });
            const products = await  retrieveProduct({ cartId: this._cartId });
            const softwares = await  retrieveSoftware({ cartId: this._cartId });
            const currency = await  retrieveCurrency({ cartId: this._cartId });
            const accountCountryAndZone = await retrieveShippingAccountCountryAndZone({ cartId: this._cartId });
            console.log('accountCountryAndZone');
            console.log(JSON.parse(JSON.stringify(accountCountryAndZone)));
            console.log(`zone ${accountCountryAndZone.pw_cc__ShippingCountryLookup__r.Zone__c}`);
            console.log(`country ${accountCountryAndZone.ShippingCountry}`);

            if(accountCountryAndZone.ShippingCountry == 'United States' && accountCountryAndZone.pw_cc__ShippingCountryLookup__r.Zone__c == 'Americas'){
                this.needPayment = true;
            }
            this._email = emailResult;
            this._optionalEmail = optionalEmail;
            this._products = products.map( (product) => {
                product.isReplenishment = false;
                product.isInStock = false;
                product.isUndefinedStock = false;
                console.log('product');
                console.log(JSON.parse(JSON.stringify(product)));
                switch( product.Availability_Result__c) {
                    case 'En cours de réapprovisionnement':
                        product.isReplenishment = true;
                        break;
                    case 'En stock':
                        product.isInStock = true;
                    break;
                    default:
                        product.isUndefinedStock = true;
                    break;
                }
                return product;
            });
            this._softwares = softwares;
            
            this._currency = currency;
            console.log('displayCheckoutSummary contant ready');
            this.contentReady = true;
            console.log(JSON.parse(JSON.stringify(products)));
        } catch (error) {
            this.handleError(error, 'displayCheckoutSummary');
            console.log(JSON.parse(JSON.stringify(error)));
            this.showToast('Error : could not fetch summary informations', error.message, 'error');
        }
    }


    handleError(error, subject) {
        console.log(`error in ${subject}`);
        console.log(error);
    }
    
    showToast(title, content, variant) {
        const message = {
            title: title,
            message: content,
            variant: variant,
        };
        console.log(message);
        publish(this.messageContext, ToastMessageServiceChannel, message);
    }

}