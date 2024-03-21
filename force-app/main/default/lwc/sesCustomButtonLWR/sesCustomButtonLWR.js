import {
    LightningElement,
    api,
    wire
} from 'lwc';
import {
    NavigationMixin
} from 'lightning/navigation';
import Id from '@salesforce/community/Id';
import getMapIdNomCate from '@salesforce/apex/B2BStoreController.getCategories';

export default class SesCustomButtonLWR extends NavigationMixin(LightningElement) {

    @api pageName
    @api buttonLabel
    @api backgroundColor
    @api textColor
    @api reload = false;
    @api viewCatalog;

    @wire(getMapIdNomCate, { communityId: Id})
    mapIdNomCate;

    navigateTo() {
        console.log('navigateTo - start')
        console.log('navigateTo - pageName', this.pageName)
        console.log('navigateTo - pageName', this.buttonLabel)
        console.log('navigateTo - pageName', this.backgroundColor)
        console.log('navigateTo - pageName', this.textColor)

        if(this.pageName == 'Category Detail'){

            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.mapIdNomCate.data['My Catalog'],
                    objectApiName: 'ProductCategory',
                    actionName: 'view'
                },
            });
        }
        else if (this.pageName.includes('results_layout') || this.pageName.includes('/orders') || this.pageName.includes('/my-catalog') || this.pageName.includes('/knowledge-base')) {
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__webPage',
                attributes: {
                    url: ''
                }
            }).then(url => {
                window.open(this.pageName, "_self");
            });
        } else if (this.pageName.includes('https://') || this.pageName.includes('http://' || this.pageName.includes('www.'))) {
            // navigate to the external link
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: this.pageName
                }
            });
        } else {
            // navigate to specific Community page
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: this.pageName
                }
            });
        }

        console.log('navigateTo - end')
    }

    get divClassWrapper() {
        return this.viewCatalog ? 'custom-btn-wrapper wrapperClass' : 'custom-btn-wrapper';
    }

    get divClassButton() {
        return this.viewCatalog ? 'custom-btn buttonClass' : 'custom-btn';
    }

    renderedCallback() {
        /**/
        //
        const btn = this.template.querySelector('.custom-btn');
        btn.style.background = this.backgroundColor;
        btn.style.color = this.textColor;

        // change hover button text color if background is black
        if (this.backgroundColor.includes('000000') || this.backgroundColor.includes('0,0,0')) {
            btn.classList.add('special-hover-button');
        }

    }

}