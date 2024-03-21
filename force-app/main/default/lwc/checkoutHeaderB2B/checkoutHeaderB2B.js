import { LightningElement, api } from 'lwc';
import Shipping from '@salesforce/label/c.Shipping';
import OrderSummary from '@salesforce/label/c.OrderSummary';
import BillingAndPayment from '@salesforce/label/c.BillingAndPayment';

import Billing from '@salesforce/label/c.B2BStore_Billing';
import Payment from '@salesforce/label/c.B2BStore_Payment';

import isUSAccount from '@salesforce/apex/B2BStoreController.isUSAccount';

export default class CheckoutHeaderB2B extends LightningElement {
   
   labels = {
      Shipping,
      OrderSummary,
      BillingAndPayment,
      Billing,
      Payment
   };
   
    @api stepOne;
    @api stepTwo;
    @api stepThree;
    @api stepFourth;
    @api cartId;
    @api isUS;


    get isStepOne() {
        return this.stepOne ? 'currentStep step' : 'step';
     }

     get isStepTwo() {
        return this.stepTwo ? 'currentStep step' : 'step';
     }

     get isStepThree() {
        return this.stepThree ? 'currentStep step' : 'step';
     }

     get isStepFourth() {
      return this.stepFourth ? 'currentStep step' : 'step';
   }

connectedCallback() {
   isUSAccount({cartId: this.cartId})
      .then(result => {
         this.isUS = result;
      })
      .catch(error => {
         console.log(error);
      });
   }

}