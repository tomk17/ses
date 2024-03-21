import { LightningElement, api, wire } from 'lwc';
import { CartSummaryAdapter } from "commerce/cartApi";
import { getRecord } from "lightning/uiRecordApi";

import returnPaymentTerm from '@salesforce/apex/B2BPaymentPOOnlyController.returnPaymentTerm';
import Id from '@salesforce/user/Id';

import ACCOUNT_SHIPPING_COUNTRY_FIELD from '@salesforce/schema/Account.ShippingCountry';
import USER_LANGUAGE_FIELD from '@salesforce/schema/User.LanguageLocaleKey';

import updateCatPoNumber from '@salesforce/apex/B2BCheckoutUtilsLWR.updateCatPoNumber';

import labelConfirmThat from '@salesforce/label/c.B2BStore_I_Confirm_That';
import labelConfirmReadThe from '@salesforce/label/c.B2BStore_I_have_read_and_agreed_to_the';
import labelTermsAndCondition from '@salesforce/label/c.B2BStore_Terms_and_Conditions';
import labelAknowledgePaymentTherms from '@salesforce/label/c.B2BStore_I_acknowledge_that_the_payment_terms_are';
import labelPurchaseIOTDevice from '@salesforce/label/c.B2BStore_I_acknowledge_that_the_purchase_of_additional_IOT_devices';
import labelPurchaseOrderNumber from '@salesforce/label/c.B2BStore_Enter_a_PO_number';
import labelPurchaseOrderNumberInfo from '@salesforce/label/c.B2BStore_Adding_a_purchase_order_number';

//import { publish, subscribe, unsubscribe, MessageContext, APPLICATION_SCOPE } from 'lightning/messageService';
// import CheckoutDeliveryMessageChannel from '@salesforce/messageChannel/checkoutDeliveryMessageChannel__c';
// import TermsAndPONumberMessageChannel from '@salesforce/messageChannel/termsAndPONumberMessageChannel__c';
// import ToastMessageServiceChannel from '@salesforce/messageChannel/toastMessageServiceChannel__c';

export default class CheckoutTermsAndPONumberB2B extends LightningElement {
    
    contentReady = false;
    showIOTcheckbox  =false;
    _cartId;
    _accountId;
    _userLanguageKey;
    _poNumber;
    _paymentTerms;

    _termsAndconditionsChecked;
    _paymentTermsChecked;
    _purchaseIOTDeviceChecked;

    @api caFrTermsAndConditionLink;
    @api caEnTermsAndConditionLink;
    @api usTermsAndConditionLink;
    @api frTermsAndConditionLink;
    @api itTermsAndConditionLink;
    @api deTermsAndConditionLink;
    @api enTermsAndConditionLink;

    @api get isWarning() {
        return this._isWarnng;
    }

    set isWarning(value){
        console.log(`iswarning set: ${value}`);
        this._isWarnng = value;
        console.log(this.template.querySelector(".terms-and-conditions"));
        if(this._isWarnng){
            this.template.querySelector(".terms-and-conditions").classList.add('warning');
        }

    }

    get label() {
        const label = {
            labelConfirmThat
            , labelConfirmReadThe
            , labelTermsAndCondition
            , labelAknowledgePaymentTherms
            , labelPurchaseIOTDevice
            , labelPurchaseOrderNumber
            , labelPurchaseOrderNumberInfo
        };
        return label;
    }


    get termsAndConditions() {
        let terms = '';
        switch (this._shippingCountry) {
            case 'Canada':
                if(this._userLanguageKey == 'fr') {
                    terms = this.caFrTermsAndConditionLink;
                } else { 
                    terms = this.caEnTermsAndConditionLink;
                }
                break;
            case 'United States':
                terms = this.usTermsAndConditionLink;
                break;
            case 'France':
                terms = this.frTermsAndConditionLink;
                break;
            case 'Italy':
                terms = this.itTermsAndConditionLink;
                break;
            case 'Germany':
                terms = this.deTermsAndConditionLink;
                break;
            default:
                terms = this.enTermsAndConditionLink;
        }
        return terms;
    }



    get paymentTerms() {
        return this._paymentTerms;
    }
    get poNumber() {
        return this._poNumber;
    }


    @wire(CartSummaryAdapter)
    cartSummaryHandler(response) {
        if (response.data) {
            console.log("cartSummaryHandler");
            console.log(response.data);
            this._cartId = response.data.cartId;
            this._accountId = response.data.accountId;
        }
    }

    @wire(getRecord, { recordId: "$_accountId", fields: [ACCOUNT_SHIPPING_COUNTRY_FIELD] })
    accountHandler( { data, error }){
        if(data) {
            console.log("accountHandler");
            console.log(data);
            this._shippingCountry = data.fields.ShippingCountry.value;
            this.showIOTcheckbox = this._shippingCountry == 'Canada' || this._shippingCountry == 'United States';
            this.getPaymentTerms();
        }

        if(error) {
            this.handleError(error, 'Could not get the Shipping country');
        }
    };

    @wire(getRecord, { recordId: Id, fields: [USER_LANGUAGE_FIELD] })
    userHandler({ error, data }) {
        if(data) {
            console.log("userHandler");
            console.log(data.fields.LanguageLocaleKey.value);
            this._userLanguageKey = data.fields.LanguageLocaleKey.value;
        }

        if(error) {
            this.handleError(error, 'Could not get the user lang');
        }
    }

    getPaymentTerms() {
        console.log(`getPaymentTerms account ID :  ${this._accountId}`)
        returnPaymentTerm({idAcc: this._accountId})
        .then((response) => {
            console.log('returnPaymentTerm response');
            console.log(JSON.parse(JSON.stringify(response)));

            this._paymentTerms = response.data;
        })
        .catch(error => {
            this.handleError(error, 'Error on getting payments terms')
        })
    }


    handleChangeCheckbox1(event) {
        this._termsAndconditionsChecked = event.detail.checked;
        this.sendEvent();
    }

    handleChangeCheckbox2(event) {
        this._paymentTermsChecked = event.detail.checked;
        this.sendEvent();
    }

    handleChangeCheckbox3(event) {
        this._purchaseIOTDeviceChecked = event.detail.checked;
        this.sendEvent();
    }
    handleChangePoNumber(event) {
        this._poNumber = event.detail.value;
        this.sendEvent();
    }

    handleError(error, subject) {
        console.log(error);
        console.log(`error in ${subject}`);
    }
    sendEvent(){
        console.log(`this._shippingCountry ${this._shippingCountry}`);
        let isValid = !!this._termsAndconditionsChecked && !!this._paymentTermsChecked;
        if (this._shippingCountry == 'Canada' || this._shippingCountry == 'United States') {
            isValid = !!this._purchaseIOTDeviceChecked && isValid;
        }
        
        const message = new CustomEvent(
            "terms", { 
                detail: {
                    termsValid: isValid,
                    poNumber: !!this._poNumber ? '' : this._poNumber
                }
            }
        );
        this.dispatchEvent(message);
    }


}