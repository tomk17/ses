import { LightningElement, wire } from "lwc";
import USER_ID from "@salesforce/user/Id";

import getContactPortalOptions from '@salesforce/apex/B2BStoreController.getContactPortalOptions';

export default class PortalOptionComponent extends LightningElement {

  
    connectedCallback() {
        getContactPortalOptions({userId: USER_ID})
           .then(result => {
              console.log(result);

           })
           .catch(error => {
              console.log(error);
           });
        }
     
}