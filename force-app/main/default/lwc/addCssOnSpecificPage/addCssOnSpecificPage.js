import { LightningElement, api } from 'lwc';

export default class AddCssOnSpecificPage extends LightningElement {

    @api css

    renderedCallback() {
        if (this.hasRendered) return;
        this.hasRendered = true;
    
        const style = document.createElement('style');
        style.innerHTML = this.css;
        this.template.querySelector('div').appendChild(style);;

    }

}