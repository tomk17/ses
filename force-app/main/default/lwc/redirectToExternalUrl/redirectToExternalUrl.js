import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import Id from "@salesforce/user/Id";

export default class RedirectToExternalUrl extends NavigationMixin(LightningElement) {

    @api targetUrl;
    @api active;
    renderedCallback() {
        if (Id != undefined) return; 
        if (this.active && this.targetUrl !== '' ) {
            const alink = this.template.querySelector('.redirect');
            alink.click();
        }

    }
}