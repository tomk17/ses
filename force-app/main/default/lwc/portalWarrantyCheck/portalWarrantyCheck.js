/**
 * @author          Bernier Corentin - iCom Cloud
 * Release          Portal 1.5 Lot 3.2
 * Created Date     2022-06-03
 * Used in          portal/warranty-check-on-line-tool-rma, flow/CaseFlowPortal
 * 
 *  Date      | Author							| Version | Changes
 * ---------- | ------------------------------- |-------- | -----------------------------------------
 * 2022-06-03 | Corentin Bernier - iCom Cloud	|  1.0.0  | Initial version.
 * 2022-07-01 | Corentin Bernier - iCom Cloud	|  1.0.1  | Added radioGroupChanged, slight changes for the Recette Lot 3.2
 */
import { LightningElement } from 'lwc';

import checkHFWarrantyWebService from '@salesforce/apex/LC_WCheckController.checkHFWarrantyWebService';
import checkHFWarrantyWithLabel from '@salesforce/apex/LC_WCheckController.checkHFWarrantyWithLabel';
import checkLFWarranty from '@salesforce/apex/LC_WCheckController.checkLFWarranty';

import STATIC_RESOURCE_VusionTag from '@salesforce/resourceUrl/community_Vusion_Tag';
import STATIC_RESOURCE_GTag from '@salesforce/resourceUrl/community_G_Tag';
import STATIC_RESOURCE_STag from '@salesforce/resourceUrl/community_S_Tag';
import STATIC_RESOURCE_Formats from '@salesforce/resourceUrl/Formats';
import STATIC_RESOURCE_DouchetteScan from '@salesforce/resourceUrl/DouchetteScan';

import CUSTOM_LABEL_VusionLabels from '@salesforce/label/c.Z_VusionLabels';
import CUSTOM_LABEL_GTagAndSTagLabels from '@salesforce/label/c.Labels';
import CUSTOM_LABEL_InputHelpVusionTag from '@salesforce/label/c.Warranty_HelpVusion';
import CUSTOM_LABEL_InputHelpGSTag from '@salesforce/label/c.Z_RMA_HelpLF';
import CUSTOM_LABEL_ProductTitle from '@salesforce/label/c.Warranty_ProductTitle';
import CUSTOM_LABEL_VusionTitle from '@salesforce/label/c.Warranty_VusionTitle';
import CUSTOM_LABEL_GSTagsTitle from '@salesforce/label/c.Warranty_GSTagsTitle';
import CUSTOM_LABEL_VusionInputLabel from '@salesforce/label/c.Warranty_VusionInputLabel';
import CUSTOM_LABEL_GSTagsInputLabel from '@salesforce/label/c.Warranty_GSTagsInputLabel';
import CUSTOM_LABEL_VusionInputPlaceholder from '@salesforce/label/c.Warranty_VusionInputPlaceholder';
import CUSTOM_LABEL_GSTagsInputPlaceholder from '@salesforce/label/c.Warranty_GSTagsInputPlaceholder';
import CUSTOM_LABEL_ErrorOccured from '@salesforce/label/c.Warranty_ErrorOccured';
import CUSTOM_LABEL_hf_warranty_check_error from '@salesforce/label/c.Warranty_check_error';
import CUSTOM_LABEL_HelpParagraph from '@salesforce/label/c.Warranty_HelpParagraph';
import CUSTOM_LABEL_Search from '@salesforce/label/c.Search';

export default class PortalWarrantyCheck extends LightningElement {
    hasConnected = false;
    hasRendered = false;
    imgs = {
        VusionTag: STATIC_RESOURCE_VusionTag,
        GTag: STATIC_RESOURCE_GTag,
        STag: STATIC_RESOURCE_STag,
        DouchetteScan: STATIC_RESOURCE_DouchetteScan,
    }
    labelTypes = [
        { label: CUSTOM_LABEL_VusionLabels, value: 'VusionLabels' },
        { label: CUSTOM_LABEL_GTagAndSTagLabels, value: 'GTagAndSTagLabels' },
    ]
    labels = {
        ProductTitle: CUSTOM_LABEL_ProductTitle,
        HelpParagraph: CUSTOM_LABEL_HelpParagraph,
        Search: CUSTOM_LABEL_Search,
    }
    scdTitle = CUSTOM_LABEL_VusionTitle;
    inputLabel = CUSTOM_LABEL_VusionInputLabel;
    inputPlaceholder = CUSTOM_LABEL_VusionInputPlaceholder;
    inputHelpText = CUSTOM_LABEL_InputHelpVusionTag;
    imgSrc = STATIC_RESOURCE_Formats + '/formats/HF2.jpg';

    error = '';
    resultMsg = '';

    /**
     * Method to change the images and the text when the other type of tag is selected in the radio group
     * @param {*} event
     * @since 1.0.0
     */
    handleChangeRadioGroup(event) {
        this.radioGroupChanged(event.detail.value);
    }

    /**
     * Method to change the images and the text when the other type of tag is selected in the radio group
     * @param {*} newValue
     * @since 1.0.1
     */
    radioGroupChanged(newValue){
        if (newValue === 'VusionLabels') {
            this.scdTitle = CUSTOM_LABEL_VusionTitle;
            this.inputLabel = CUSTOM_LABEL_VusionInputLabel;
            this.inputPlaceholder = CUSTOM_LABEL_VusionInputPlaceholder;
            this.inputHelpText = CUSTOM_LABEL_InputHelpVusionTag;
            this.imgSrc = STATIC_RESOURCE_Formats + '/formats/HF2.jpg';
            this.template.querySelector('.VusionImg').style.display = '';
            this.template.querySelector('.GImg').style.display = 'none';
            this.template.querySelector('.SImg').style.display = 'none';
        } else { // GTagAndSTagLabels
            this.scdTitle = CUSTOM_LABEL_GSTagsTitle;
            this.inputLabel = CUSTOM_LABEL_GSTagsInputLabel;
            this.inputPlaceholder = CUSTOM_LABEL_GSTagsInputPlaceholder;
            this.inputHelpText = CUSTOM_LABEL_InputHelpGSTag;
            this.imgSrc = STATIC_RESOURCE_Formats + '/formats/LF.png';
            this.template.querySelector('.VusionImg').style.display = 'none';
            this.template.querySelector('.GImg').style.display = '';
            this.template.querySelector('.SImg').style.display = '';
        }
    }

    /**
     * Method to search for the warranty on the click of the Search button
     * @since 1.0.0
     */
    handleClickSearchBtn() {
        var inputValue = this.template.querySelector('.id-input').value.trim();
        console.log('portalWarrantyCheck.js - handleClickSearchBtn - inputValue : ', inputValue);
        const regExpVusion = new RegExp(/^[a-zA-Z]{1}\d{2}$/);
        const regExpGSTags = new RegExp(/^[a-zA-Z0-9 ]{7}\d{3}[a-zA-Z0-9 ]{10}$/);
        if (inputValue.length === 3 && regExpVusion.test(inputValue)) {
            this.template.querySelector('.radio-group').value = 'VusionLabels';
            this.radioGroupChanged('VusionLabels');
            checkHFWarrantyWithLabel({ labelId: inputValue })
                .then(result => {
                    this.handleResult(result);
                })
                .catch(error => {
                    console.error('Error - handleClickSearchBtn - checkHFWarrantyWithLabel :', error);
                    this.resultMsg = '';
                    this.error = CUSTOM_LABEL_ErrorOccured;
                });
        } else if (inputValue.length === 8) {
            this.template.querySelector('.radio-group').value = 'VusionLabels';
            this.radioGroupChanged('VusionLabels');
            checkHFWarrantyWebService({ labelId: inputValue })
                .then(result => {
                    this.handleResult(result);
                })
                .catch(error => {
                    console.error('Error - handleClickSearchBtn - checkHFWarrantyWebService :', error);
                    this.resultMsg = '';
                    this.error = CUSTOM_LABEL_hf_warranty_check_error;
                });
        } else if (regExpGSTags.test(inputValue)) {
            this.template.querySelector('.radio-group').value = 'GTagAndSTagLabels';
            this.radioGroupChanged('GTagAndSTagLabels');
            const serialNbWeek = inputValue.substring(7, 10);
            checkLFWarranty({ week: serialNbWeek })
                .then(result => {
                    this.handleResult(result);
                })
                .catch(error => {
                    console.error('Error - handleClickSearchBtn - checkLFWarranty :', error);
                    this.resultMsg = '';
                    this.error = CUSTOM_LABEL_ErrorOccured
                });
        } else {
            this.resultMsg = '';
            if (this.template.querySelector('.radio-group').value === 'VusionLabels') {
                this.error = CUSTOM_LABEL_InputHelpVusionTag;
            } else {
                this.error = CUSTOM_LABEL_InputHelpGSTag
            }
        }
    }

    /**
     * Method to start the search if enter is pressed in the input
     * @param {*} event 
     * @since 1.0.0
     */
    handleKeyPressedInput(event) {
        if (event.keyCode === 13) {
            this.handleClickSearchBtn();
        }
    }

    /**
     * Method to handle the result of the controller methods
     * @param {*} result 
     * @since 1.0.0
     */
    handleResult(result) {
        var lines = result.split('\\n');
        lines.forEach((line, index) => {
            if (index == 0) {
                this.resultMsg = line;
            } 
            else {
                this.resultMsg += '<br><span class="bold">' + line + '</span>';
            }
           
        });
        //this.resultMsg = lines[0] + '<br><span class="bold">' + lines[1] + '</span>';
        this.template.querySelector('.id-input').value = '';
        this.error = '';
    }

    /**
     * Used to overwrite some default CSS on some LWC defaults components
     * @since 1.0.0
     */
    renderedCallback() {
        if (this.hasRendered) return;
        this.hasRendered = true;

        const style = document.createElement('style');
        style.innerText = `
            .radio-group .slds-form-element__control{
                display: flex;
                flex-direction: row;
                flex-wrap: wrap;
                gap: 20px;
            }
 
            .radio-group .slds-form-element__control .slds-radio_faux{
                border-color: #D5D6D2!important;
            }
 
            .radio-group .slds-form-element__control .slds-radio_faux:after{
                background-color: #1B1B1B!important;
            }
 
            .radio-group .slds-form-element__control .slds-form-element__label{
                font-size: 16px;
                line-height: 24px;
                letter-spacing: 0.1px;
            }
 
            .custom-btn{
                background: linear-gradient(90deg, rgba(226,123,71,1) 0%, rgba(254,211,138,1) 100%);
                border-radius: 5px;
                padding: 1px;
                display: inline-block;
                border: none;
            }
             
            .custom-btn>button.slds-button{
                height: 36px!important;
                padding: 10px 15px!important;
                margin: 0;
                border: none;
                border-radius: 5px;
                font-family: 'Maax_Regular';
                font-size: 16px;
                background-color: white;
                color: black;
            }
 
            .custom-btn>button.slds-button:hover{
                background-color: black;
                color: white;
            }

            .result-div span.bold{
                font-size: 20px;
            }

            .help-paragraph a{
                color: #1B1B1B;
                text-decoration: underline;
            }
         `;
        this.template.querySelector('div').appendChild(style);
    }
}