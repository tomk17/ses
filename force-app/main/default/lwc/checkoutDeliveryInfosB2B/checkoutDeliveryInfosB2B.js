import { LightningElement, wire, api, track } from 'lwc';
import { CartSummaryAdapter } from "commerce/cartApi";
import { getRecord } from "lightning/uiRecordApi";

import returnAccountSelected from '@salesforce/apex/B2BPicklistForFlowScreenController.returnAccountSelected';
import returnListAccount from '@salesforce/apex/B2BPicklistForFlowScreenController.returnListAccount';
import returnPickingAccountSelected from '@salesforce/apex/B2BPicklistForFlowScreenController.returnPickingAccountSelected';
import returnContacts from '@salesforce/apex/B2BPicklistForFlowScreenController.returnContacts';
import returnContactSelected from '@salesforce/apex/B2BPicklistForFlowScreenController.returnContactSelected';


// import startCartProcessAsync from '@salesforce/apex/B2BCheckInventorySample.startCartProcessAsync';
import updateShippingDeliveryInfo from '@salesforce/apex/B2BCheckoutUtilsLWR.updateShippingDeliveryInfo';
import updateBillingDeliveryInfo from '@salesforce/apex/B2BCheckoutUtilsLWR.updateBillingDeliveryInfo';
import processShippingCostsAction from '@salesforce/apex/B2BDeliveryLWR.processShippingCostsAction';
import processCartTaxesCalculationAction from '@salesforce/apex/B2BDeliveryLWR.processCartTaxesCalculationAction';

import cartToOrder from '@salesforce/apex/B2B_CartToOrderNewLWR.cartToOrder';
import deleteOrderFromCart from '@salesforce/apex/B2B_CartToOrderNewLWR.deleteOrderFromCart';
// Labels
import labelCardAccount from '@salesforce/label/c.B2BStore_ShippingAddress';
import labelCardContact from '@salesforce/label/c.ShippingContact';
import labelSelect from '@salesforce/label/c.B2BStore_Select_Account';
import labelContactSelect from '@salesforce/label/c.B2BStore_Notify_the_receiver';
import labelRadioGroup from '@salesforce/label/c.B2BStore_AdditionalEmailTrackingNotification';
import labelWarning from '@salesforce/label/c.B2BStore_NoShipToContact';

import labelBillingContact from '@salesforce/label/c.B2BStore_Billing_Contact';
import labelSelectBillingAccount from '@salesforce/label/c.B2BStore_Select_billing_account';
import labelShippingAddress from '@salesforce/label/c.B2BStore_ShippingAddress';
import labelPickingAddress from '@salesforce/label/c.B2BStore_Picking_Address';
import labelBillingAddress from '@salesforce/label/c.B2BStore_BillingAddress';
import labelContact from '@salesforce/label/c.B2BStore_Contact';
import labelSelectedContactEmail from '@salesforce/label/c.B2BStore_Email_address_of_the_selected_contact';
import labelEnterEmailAddress from '@salesforce/label/c.B2BStore_Please_enter_the_email_address_below';
import labelEnterConfirmingOrderEmailAddress from '@salesforce/label/c.B2BStore_Enter_the_email_that_will_receive_the_order_confirmation';

import labelBillingRadioGroup from '@salesforce/label/c.B2BStore_You_will_receive_a_copy_of_the_order_confirmation';
import labelNoBillToContact from '@salesforce/label/c.B2BStore_NoBillToContact';

import yes from '@salesforce/label/c.B2BStore_Yes';
import no from '@salesforce/label/c.B2BStore_No';

import WEBCART_OWNER_ID_FIELD from '@salesforce/schema/WebCart.OwnerId';
import WEBCART_ACCOUNT_ID_FIELD from '@salesforce/schema/WebCart.AccountId';


import { publish, subscribe, unsubscribe, MessageContext, APPLICATION_SCOPE } from 'lightning/messageService';
import CheckoutDeliveryMessageChannel from '@salesforce/messageChannel/checkoutDeliveryMessageChannel__c';
import ToastMessageServiceChannel from '@salesforce/messageChannel/toastMessageServiceChannel__c';


const SHIPPING_MODE = 'Shipping';
const BILLING_MODE = 'Billing';


export default class CheckoutDeliveryInfosB2B extends LightningElement {

    @api componentMode; //shipping or billing mode

    @api caFrTermsAndConditionLink;
    @api caEnTermsAndConditionLink;
    @api usTermsAndConditionLink;
    @api frTermsAndConditionLink;
    @api itTermsAndConditionLink;
    @api deTermsAndConditionLink;
    @api enTermsAndConditionLink;

    selectedShipTo;
    selectedContactTo;
    accountSelected;
    idAccountSelected;
    selectedContactId;
   
    selectAccountsOption;
    selectContactsOption;

    pickingAccountSelected;
    _shippingInstructions;

    isEditMode = true;
    contentReady = true;
    _checkoutMode = 1;

    _cart;
    _cartId;
    _contactFound;
    _contactSelected;
    _isAdditionalRatioSelected;
    _additionalEmailValue;
    _isShipping;
    _isBilling;
    _termsValid = false;
    _termsAndPoError;
    _poNumber;

    subscription = null;
    _shippingDone;
    _billingDone;

    get formatOptions() {
        return  [
            { label: yes, value: 'yes' }, 
            { label: no, value:'no' }
        ];
    }

    get label() {
        let label = {
            labelCardAccount
            , labelCardContact
            , labelSelect
            , labelContactSelect
            , labelRadioGroup
            , labelWarning
            , labelShippingAddress
            , labelPickingAddress
            , labelBillingAddress
            , labelContact
            , labelSelectedContactEmail
            , labelEnterEmailAddress
            , labelEnterConfirmingOrderEmailAddress
        };
        if(this.isShipping) {
            label.labelDeliveryInstructions = "Delivery instructions";
        }
        if(this.isBilling) {
            label.labelCardContact = labelBillingContact;
            label.labelCardAccount = labelBillingAddress;
            label.labelSelect = labelSelectBillingAccount;
            label.labelRadioGroup = labelBillingRadioGroup;
            label.labelWarning = labelNoBillToContact;
        }
        return label;
    }
    
    get hasAdditionalEmail(){
        return this._isAdditionalRatioSelected;
    }
    get additionalEmailValue(){
        return this._additionalEmailValue; 
    }

    get cart() {
        return this._cart || false;
    }
    get cartId() {
        return this.cart ? this._cart.Id : false;
    }

    get isShipping() {
        return this.componentMode == SHIPPING_MODE;
    }

    get isBilling() {
        return  this.componentMode == BILLING_MODE;
    }
    get isPicking() {
        if(this.accountSelected){
            return this.accountSelected.Incoterms__c == 'FCA' || this.accountSelected.Incoterms__c == 'EXW';
        }
        return '';
    }
    get selectAccountOptions() {
        return []
    }
    get cardAccountLabel() {
        return this.componentMode == BILLING_MODE && (this.accountSelected.Incoterms__c == 'FCA' || this.accountSelected.Incoterms__c == 'EXW')
        ? "Picking Address" 
        : labelCardAccount;
    }
    get iconName () {
        return this.componentMode == BILLING_MODE ? "utility:tour_check" : "utility:tour"; 
    }
    get findContact() {
        return this._contactFound || false;
    }
    get isContactSelected() {
        return this._contactSelected || false;
    }
    get selectedContacToEmail() {
        return this._contactSelected ? this._contactSelected.Email : '';
    }

    get additionalEmailRadioValue() {
        return this._isAdditionalRatioSelected ? 'yes' : 'no';
    }
    get shippingInstructions() {
        return this._shippingInstructions;
    }
    get isTermsWarning() {
        return !!this._termsAndPoError;
    }

    /**
     * Required by checkout to register as a checkout component
     * 0 = FUTURE
     * 1 = EDIT mode
     * 2 = DISABLED
     * 3 = SUMMARY
     * 4 = STENCIL
     */
    @api
    get checkoutMode() {
        return this._checkoutMode;
    }

    set checkoutMode(value) {
        console.log(`set  checkoutMode : ${value}`);
        this._checkoutMode = value;
        this.isEditMode = this._checkoutMode == 1;
        if(this.componentMode == SHIPPING_MODE && this.isEditMode){
            console.log('shipping mode');
            this._shippingDone = false;
            this.sendMessageService();
        }
        if(this.componentMode == BILLING_MODE && this.isEditMode){
            console.log('billing mode');
            this._billingDone = false;
            this.sendMessageService();
        }

    }     
    /**
    * Works in Accordion when terms component before payment component.
    * 
    * Works in One Page when terms component placed anywhere.
    * 
    * Can be in same step/section as payment component as long as it is placed 
    * before payment info.
    *
    * (In this case this method is redundant and optional but shows as an 
    * example of how checkoutSave can also throw an error to temporarily halt 
    * checkout on the ui)
    */
    @api
    checkoutSave() {
        console.log('checkoutSave DeliveryInfo');
        console.log(`(this._isShipping ${this._isShipping}`);
        console.log(`(this._isBilling ${this._isBilling}`);
        let data = {
            'accountId': this.selectedShipTo,
            'contactId': this.selectedContactTo,
            'email': this._additionalEmailValue,
            
        };
        if(this._isShipping) {
            console.log('updateShippingProcess');
            data.shippingInstructions = this._shippingInstructions,
            this.updateShippingProcess(data);
        }
        if(this._isBilling) {
            console.log('updateBillingProcess');
            this.updateBillingProcess(data);
        }

    }
    
    async updateShippingProcess(shippingData) {
        deleteOrderFromCart({cartId: this._cartId})
        .then(() => {
            console.log('order deleted');
        })
        .catch(e => {
            this.handleError(e, '');
            this.showToast('Error encountered on shipping update', error.message, 'error');
        });
        try{
            console.log('****** updateShippingDeliveryInfo >>>>>>');
            await updateShippingDeliveryInfo({
                cartId: this._cartId,
                shippingData: shippingData
            });
            console.log('<<<<<<< updateShippingDeliveryInfo ******');
            console.log('****** processShippingCostsAction >>>>>>');
            await processShippingCostsAction({
                cartId: this._cartId,
            });
            console.log('<<<<<<< processShippingCostsAction ******');
            console.log('****** processCartTaxesCalculationAction >>>>>>');
            await processCartTaxesCalculationAction({
                cartId: this._cartId,
            });
            console.log('<<<<<<< processCartTaxesCalculationAction ******');
            console.log(`this._shippingDone result ${this._shippingDone}`);
            this._shippingDone = true;
        }catch (error) {
            this._shippingDone = false;
            this.handleError(error, '', false);
            this.showToast('Error encountered on shipping update', error.message, 'error');
        } finally {
            this.sendMessageService();
        }
    }

    async updateBillingProcess(billingData) {
        try{
            await updateBillingDeliveryInfo({cartId: this._cartId, billingData: billingData});
            console.log('billig data updated');
            await cartToOrder({cartId: this._cartId, billingData: billingData});
            console.log('order created');
            this._billingDone = true;
        }catch (error) {
            this._billingDone = false;
            this.handleError(error, '', false);
            this.showToast('Error encountered on billing update', error.message, 'error');
        } finally {
            this.sendMessageService();
        }
    }

    /**
     * 
     * One-page Layout: reportValidity is triggered clicking place order.
     * 
     * Accordion Layout: reportValidity is triggered clicking each section's 
     * proceed button.
     *
     * @returns boolean
     */
    @api
    reportValidity() {
        console.log(`checkoutDeliveryInfo report validity`);
        let isValid = false;
        let selectedShipTo = !!this.selectedShipTo;
        let contactSelected = !!this._contactSelected;
        let additionalEmailValue = !!this._additionalEmailValue;
        let isAdditionalRatioSelected = !!this._isAdditionalRatioSelected;

        isValid = (selectedShipTo && contactSelected) || (!selectedShipTo && additionalEmailValue)
        isValid = isValid && ( (isAdditionalRatioSelected && additionalEmailValue) || !isAdditionalRatioSelected) ;
        if(this.isBilling){
            console.log(`billing this._termsValid ${this._termsValid}`);
            this._termsAndPoError = !this._termsValid;
            isValid = isValid && this._termsValid;
        }

        console.log(`checkoutDeliveryInfo is valid ${isValid}`);
        return isValid;
    }

    // Initialize messageContext for Message Service
    @wire(MessageContext)
    messageContext;
    // Subscribes to the checkout delivery component's message channel
    subscribeToMessageChannel() {
        if (this.subscription) return;
        if(this.componentMode == SHIPPING_MODE) return;
        console.log('billing recieved massage')
        this.subscription = subscribe(
            this.messageContext,
            CheckoutDeliveryMessageChannel,
            (message) => {
                this._shippingDone = !!message.shippingDone;
                this.contentReady = this._shippingDone;
                console.log(`billing content ready ${this.contentReady}`);
            },
            {
                scope: APPLICATION_SCOPE
            }
        );

    }
    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }


    connectedCallback() {
        console.log(`checkoutMode ${this.checkoutMode}`);
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    // wired message context
    @wire(MessageContext) 
    messageContext;

    @wire(CartSummaryAdapter)
    cartSummaryHandler(response) {
        if (response.data) {
            console.log(JSON.parse(JSON.stringify(response.data)));
            this._cartId = response.data.cartId;
            this._idAccountSelected = response.data.accountId;
        }
    }
    @wire(getRecord, { recordId: "$_cartId", fields: [WEBCART_OWNER_ID_FIELD, WEBCART_ACCOUNT_ID_FIELD]})
    getCart( { data, error }){
        console.log('cartwire result ');
        if(data) {
            this._cart = data;
            this._isShipping = this.componentMode == SHIPPING_MODE;
            this._isBilling = this.componentMode == BILLING_MODE;
            console.log('CART LOADED');
            console.log(this._cart);
            this.init();
        }
        if(error) {
            this.handleError(error, 'Could not get cart data');
        }

    };

    init() {
        this._idAccountSelected = this._cart.fields.AccountId.value;
        returnAccountSelected({idAcc: this._idAccountSelected})
        .then(selectedAccountResult => {
            console.log(`selectedAccountResult `);
            console.log(JSON.parse(JSON.stringify(selectedAccountResult)));
            this.accountSelected = selectedAccountResult;
            console.log('returnListAccount ' + this._idAccountSelected );
            console.log('returnListAccount _isShipping' + this._isShipping );
            console.log('returnListAccount _isBilling ' + this._isBilling );
            returnListAccount({
                acc: this.accountSelected,
                boolShip: this._isShipping,
                boolBill: this._isBilling,
            })
            .then((returnListAccountResult) => {
                console.log('returnListAccount result');
                console.log(JSON.parse(JSON.stringify(returnListAccountResult)));
                this.selectAccountsOption = returnListAccountResult.map(item => {
                    console.log(item);
                    return {label: item.Name, value: item.Id};
                });
                this.selectedShipTo = returnListAccountResult.length > 0 ?  returnListAccountResult[0].Id : false;
                if( this.accountSelected.Incoterms__c == 'FCA' || this.accountSelected.Incoterms__c == 'EXW') {
                    returnPickingAccountSelected({idAcc: this._idAccountSelected})
                    .then((pickingAccountSelected) => {
                        console.log('pickingAccountSelected');
                        console.log(pickingAccountSelected);
                        this.pickingAccountSelected = pickingAccountSelected; 
                    })
                    .catch(error => {
                        this.handleError(error, 'returnPickingAccountSelected');
                    });
                }

            })
            .then(() => {
                console.log('returncontact...')
                console.log(JSON.parse(JSON.stringify(this.accountSelected)));
                if(this.selectedShipTo) {
                    let cart = this.getSObject(this._cart);
                    returnContacts({  
                        accId: this.accountSelected.Id,
                        boolShip: this._isShipping,
                        boolBill: this._isBilling,
                        cart: cart
                    }).then((contactsFromController) => {
                        
                        console.log('contactsFromController');
                        if(contactsFromController.length) {
                            this._contactFound = true;
                            this.selectContactsOption = contactsFromController.map(item => {
                                console.log(item);
                                return {label: item.Email, value: item.Id};
                            });
                            
                            this._contactSelected = contactsFromController[0];
                            this.selectedContactTo = this._contactSelected.Id;
                            
                        }
                    }).catch(error => {
                        this.handleError(error, 'returnContacts');
                    });
                }
            })
            
        })
        .then(() => {
            console.log('then ...');
        })
        .catch(error => {
            this.handleError(error, 'returnAccountSelected');
        }).finally(()=>{
            this.contentReady  =  this._isBilling ? this._shippingDone : true;
            console.log(`Init contentready : ${this.contentReady}`)
        });
    }

    updateData() {
        returnAccountSelected({idAcc: this._idAccountSelected})
        .then(selectedAccountResult => {
            console.log(`selectedAccountResult `);
            console.log(JSON.parse(JSON.stringify(selectedAccountResult)));
            this.accountSelectedId = selectedAccountResult.Id;
            this.accountSelected = selectedAccountResult;
            if( this.accountSelected.Incoterms__c == 'FCA' || this.accountSelected.Incoterms__c == 'EXW') {
                returnPickingAccountSelected({idAcc: this.accountSelectedId})
                .then((pickingAccountSelected) => {
                    console.log('pickingAccountSelected');
                    console.log(pickingAccountSelected);
                    this.pickingAccountSelected = pickingAccountSelected; 
                })
                .catch(error => {
                    this.handleError(error, 'returnPickingAccountSelected');
                });
            }
        })
        .then(() => {
            if(this.selectedShipTo) {
                console.log('selectedShipTo ' + this.selectedShipTo);
                console.log('before returnContacts');
                console.log('cart ');
                console.log(JSON.parse(JSON.stringify(this._cart)));
                console.log('this.accountSelectedId ' + this.accountSelectedId );
                console.log('returnListAccount _isShippin ' + this._isShipping );
                console.log('returnListAccount _isBilling ' + this._isBilling );
                let cart = this.getSObject(this._cart);
                console.log('cart');                
                console.log(cart);                
                returnContacts({  
                    cart: cart,
                    accId: this.accountSelectedId,
                    boolShip: this._isShipping,
                    boolBill: this._isBilling
                }).then((contactsFromController) => {
                    console.log('contactsFromController');
                    console.log(JSON.parse(JSON.stringify(contactsFromController)));
                    if(contactsFromController.length) {
                        this._contactFound = true;
                        this.selectContactsOption = contactsFromController.map(item => {
                            console.log(item);
                            return {label: item.Email, value: item.Id};
                        });
                        this._contactSelected = contactsFromController[0];
                        this.selectedContactTo = this._contactSelected.Id;
                    }
                }).catch(error => {
                    this.handleError(error, 'returnContacts');
                });
            }
        }).then(() => {

        })
        .catch(error => {
            this.handleError(error, 'returnAccountSelected');
        }).finally(()=>{
            this.contentReady  =  this._isBilling ? this._shippingDone : true;
            
            console.log(`updateData contentready : ${this.contentReady}`)
        });
    }

    getSObject(data) {
        let sObject = {
            sobjectTtype : data.apiName,
            Id: data.Id
        };
        Object.keys(data.fields).map(fieldPath => {
            sObject[fieldPath] = data.fields[fieldPath].value;
        });
        return sObject;
    }
    handleSelectAccountChange(event) {
        console.log(`handleSelectAccountChange ${event.detail.value}`);
        this.selectedShipTo = event.detail.value;
        this.updateData();
    }
    handleSelectContactChange(event) {
        this.selectedContactId = event.detail.value;
        returnContactSelected({idCon: this.selectedContactId})
        .then(contactSelectedResult => {
            console.log('contactSelectedResult');
            console.log(JSON.parse(JSON.stringify(contactSelectedResult)));
            this._contactSelected = contactSelectedResult;
            this.selectedContactTo = this._contactSelected.Id;

        })
    }
    handleInputChange(event) {
        this._additionalEmailValue = event.detail.value;
        
    }
    handleRadioGroupChange(event){
         console.log(event.detail.value);
        this._isAdditionalRatioSelected = event.detail.value === 'yes'; 
    }

    handleChangeShippingInstructions(event) {
        console.log(event.detail.value);
        this._shippingInstructions = event.detail.value;
    }
    handleError(error, subject) {
        console.log(error);
        console.log(`error in ${subject}`);
    }
    handelTermAndPoChanged(event){
        console.log('terms an po event');
        console.log(event);
        this._termsValid = event.detail.termsValid;
        this._poNumber = event.detail.poNumber; 
    }

    sendMessageService() {
        const message = {
            shippingDone: this._shippingDone,
            billingDone: this._billingDone,

        };
        console.log(`${this.componentMode} send message`);
        console.log(message);
        publish(this.messageContext, CheckoutDeliveryMessageChannel, message);
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