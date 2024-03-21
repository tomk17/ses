/**
 * Custom component for the List of Orders
 *
 * @author			Marie-Line Ferron - iCom Cloud
 * Release			Portal v1.5
 * Created Date		2022-03-11
 * Used in			portal/Orders
 *
 * Date       | Author							| Version | Changes
 * ---------- | ------------------------------- |-------- | -----------------------------------------
 * 2022-03-11 | Marie-Line Ferron - iCom Cloud	|  1.0.0  | Initial version.
 * 2022-06-29 | Corentin Bernier - iCom Cloud	|  1.0.1  | Fixing translation & labels
 * 2022-10-11 | Corentin Bernier - iCom Cloud	|  1.0.2  | Changed the buttons links
 */

import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

// labels
import HomeLabel from '@salesforce/label/dsfs.Home';
import OrdersLabel from '@salesforce/label/c.Orders';
import OrdersSearchBarLabel from '@salesforce/label/c.OrdersSearchBarLabel';
import AddNewOrder from '@salesforce/label/c.AddNewOrder';
import ViewMySupportRequests from '@salesforce/label/c.ViewMyAssistanceRequest';
import FilterBy from '@salesforce/label/c.FilterBy';
import Status from '@salesforce/label/dsfs.Status';
import AccountName from '@salesforce/label/dsfs.AccountInfoAccountName';
import ShiptoAccount from '@salesforce/label/c.ShiptoAccount';
import OrderAmount from '@salesforce/label/c.OrderAmount';
import PartialDelivery from '@salesforce/label/c.PartialDelivery';
import DeliveryDate from '@salesforce/label/c.DeliveryDate';
import OrderNumber from '@salesforce/label/c.OrderNumber';
import OrderDates from '@salesforce/label/c.OrderDates';
import StartDate from '@salesforce/label/c.Start_date';
import Success from '@salesforce/label/c.B2BStore_Success';
import Error from '@salesforce/label/c.B2BStore_Error';
import ErrorWhenAdding from '@salesforce/label/c.B2BStore_Error_when_adding_products_to_cart';
import ItemsWhereAdding from '@salesforce/label/c.B2BStore_Items_were_added_to_cart';
import Reorder from '@salesforce/label/c.B2BStore_Reorder';
import Incoming from '@salesforce/label/c.B2BStore_incoming';
import EndDate from '@salesforce/label/c.End_Date';
import Validate from '@salesforce/label/c.Validate';
import PONumber from '@salesforce/label/c.PONumber';
import DatesErrorMessage from '@salesforce/label/c.DatesErrorMessage';
import Reset from '@salesforce/label/c.Reset';
import ResetFilter from '@salesforce/label/c.ResetFilter';

// import user language
import LANG from '@salesforce/i18n/lang';

// status images
import statusResources from '@salesforce/resourceUrl/statusResources';

// controller apex
import getOrders from '@salesforce/apex/OrderController.getPortalUserOrders';
import reordering from '@salesforce/apex/B2BReordering.getCartAndAddItems';

// retrive status picklist values for orders
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import Order_OBJECT from '@salesforce/schema/Order';
import Status_FIELD from '@salesforce/schema/Order.Status';

// reordering
import uId from '@salesforce/user/Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SesCustomOrdersListComponent extends NavigationMixin(LightningElement) {

    labels = {
        HomeLabel,
        OrdersLabel,
        OrdersSearchBarLabel,
        AddNewOrder,
        ViewMySupportRequests,
        FilterBy,
        Status,
        AccountName,
        ShiptoAccount,
        OrderAmount,
        PartialDelivery,
        DeliveryDate,
        OrderNumber,
        OrderDates,
        StartDate,
        EndDate,
        Validate,
        PONumber,
        DatesErrorMessage,
        Reorder,
        Incoming,
        Reset,
        Success,
        Error,
        ItemsWhereAdding,
        ErrorWhenAdding
    };

    @api paddingLeft
    @api paddingRight

    @api displayAddNewOrderButton
    @api displayViewRequestsButton

    @api pageNameToNavigateTo

    @api reordering
    userId = uId;

    // set columns to the record list custom component 
    columns = [
        //{ label: 'Order Number', fieldName: 'Order_Number__c', wrapText: 'true', sortable: false, editable: false },
        {
            label: this.labels.OrderNumber, fieldName: 'Order_Url', type: 'url', typeAttributes: {
                tooltip: { fieldName: 'Order_Number' },
                label: {
                    fieldName: 'Order_Number'
                }
            }
        },
        { label: this.labels.OrderDates, fieldName: 'Order_Date__c', wrapText: 'true', sortable: false, editable: false },
        { label: this.labels.PONumber, fieldName: 'PoNumber', wrapText: 'true', sortable: false, editable: false },
        { label: this.labels.AccountName, fieldName: 'Account_Name', wrapText: 'true', sortable: false, editable: false },
        { label: this.labels.ShiptoAccount, fieldName: 'ShiptToAccount_Name', wrapText: 'true', sortable: false, editable: false },
        { label: this.labels.OrderAmount, fieldName: 'Order_Amount_Ex_Tax__c', wrapText: 'true', sortable: false, editable: false },
        { label: this.labels.Status, fieldName: 'Status', wrapText: 'true', sortable: false, editable: false, cellAttributes: { class: { fieldName: 'StatusImgClass__c' } } },
        /*{ label: 'Status2', fieldName: 'StatusImgClass__c', wrapText: 'true', sortable: false, editable: false},*/
        { label: this.labels.PartialDelivery, fieldName: 'PartialOrder__c', wrapText: 'true', sortable: false, editable: false },
        { label: this.labels.DeliveryDate, fieldName: 'Delivery_Date_Custom', wrapText: 'true', sortable: false, editable: false }
    ]

    // display orders
    ordersToDisplay
    @track allOrders
    @track ordersSize
    @track error

    // status filter
    statusFilterValues

    // dates filter
    @track enableDateFilter = false
    @track showDatePickerSelectors
    @track showDatesFilterError = false
    @track startDateFilter = null
    @track endDateFilter = null

    // get status picklist values
    @wire(getObjectInfo, { objectApiName: Order_OBJECT })
    orderMetadata;
    @wire(getPicklistValues, { recordTypeId: '$orderMetadata.data.defaultRecordTypeId', fieldApiName: Status_FIELD })
    orderStatusPicklistValues({ data, error }) {
        this.statusFilterValues = [];
        if (data) {
            data.values.forEach(el => {
                this.statusFilterValues.push({ label: el['label'], value: el['value'] });
            })
            this.statusFilterValues.push({ label: '-- ' + ResetFilter, value: 'reset' });
        }
    }

    @wire(getOrders, {})
    portalUserOrders({ error, data }) {

        if (data) {
            let ordersFormated = JSON.parse(JSON.stringify(data));
            this.ordersSize = data.length;

            // add key-values to match with this.columns fieldnames (used to display fields in the custom pagination component)
            ordersFormated.forEach(element => {   
                element['PoNumber'] = element['PoNumber'] ? element['PoNumber'] : ' - ';
                element['Account_Name'] = element['Account'] ? element['Account']['Name'] : '';
                element['ShiptToAccount_Name'] = element['ShipToAccount__r'] ? element['ShipToAccount__r']['Name'] : '';
                element['Order_Url'] = '/order/' + element['Id'];
                element['Order_Amount_Ex_Tax__c'] = element['TECH_ConvertCurrency__c'] == '€' ? element['Order_Amount_Ex_Tax__c']+element['TECH_ConvertCurrency__c'] : element['TECH_ConvertCurrency__c']+element['Order_Amount_Ex_Tax__c'];
                element['Order_Number'] = element['Order_Number__c'] ? element['Order_Number__c'] : this.labels.Incoming;
                element['Delivery_Date_Custom'] = element['DeliveryDate__c'].includes('href') ? element['DeliveryDate__c'].replace('</a>', '').split('"">')[1] : element['DeliveryDate__c'];
                element['displayButton'] =  element['Order_Origin__c'] == 'B2B Commerce' && element['Status'] != 'Draft' ? 'showReordering' : 'hideReordering';
            });

            this.ordersToDisplay = ordersFormated;
            this.allOrders = ordersFormated;

        } else {

            this.error = JSON.stringify(error);

        }

    }

    get isLoading() {
        return this.ordersToDisplay == undefined ? true : false;
    }

    //reordering
    connectedCallback() {
        if(this.reordering){
            this.columns.push(
                { type: "button", cellAttributes: { class: { fieldName: 'displayButton' } },
                    typeAttributes: {  
                        label: this.labels.Reorder,  
                        name: 'Reorder',  
                        title: 'Reorder',  
                        disabled: false,  
                        value: 'reorder',  
                        iconPosition: 'left'  
                    } 
                }  
            )
        }
    }


    //reordering
    handleRowActions(event){
        //this.showSpinner = true;
        reordering({userId: this.userId, orderId: event.detail.data.Id})
        .then(result => {
            const event = new ShowToastEvent({
                title: this.labels.Success+'!',
                message: this.labels.ItemsWhereAdding,
                variant: 'success'
            });
            this.dispatchEvent(event);
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: result,
                    objectApiName: 'Cart',
                    actionName: 'view'
                }
            });
        })
        .catch(error => {
            const event = new ShowToastEvent({
                title: this.labels.Error+'!',
                message: this.labels.ErrorWhenAdding,
                variant: 'error',
                mode: 'sticky',
            });
            this.dispatchEvent(event);
            //window.location.reload();
        });
    }

    renderedCallback() {
        if (this.hasRendered) return;
        this.hasRendered = true;

        // apply the padding left and right that comes from component parameters
        const sectionsList = [this.template.querySelector('.header-component-wrapper'), this.template.querySelector('.black-wrapper'), this.template.querySelector('.orders-and-filters-wrapper')];
        sectionsList.forEach(section => {
            if (section) {
                section.style.paddingLeft = '11%';
                section.style.paddingRight = '11%';
            }
        })

        const styleWrapper = this.template.querySelector('.style-wrapper');

        const style = document.createElement('style');
        style.innerText = `
            .showReordering button {
                display: block;
            }
            
            .hideReordering button {
                display: none;
            }

            button.slds-button.slds-button_neutral {
                background: linear-gradient(45deg, #FF9646 0%, #FFD264 100%)!important;
                color: black!important;
                border: 2px solid #f49744!important;
                font-weight:800!important;
                padding-left: 3%;
                padding-right: 3%;
                font-size: 0.8rem;
                min-width: 60px;
            }

            button.slds-button.slds-button_neutral:hover {
                background: linear-gradient(45deg, #ff7b16 0%, #ffbc18 100%)!important;
            }
            
            lightning-primitive-cell-button lightning-button .slds-button:hover {
            
                background: linear-gradient(45deg, #ff7b16 0%, #ffbc18 100%)!important;
                color: black!important;
            }
            button[lightning-basecombobox_basecombobox] {
                height: 50px;
                align-items: center;
            }
            .breadcrumbs-wrapper a {
                color: black;
            }
            /*lightning-input.slds-form-element {
                position: relative;
                top: -11px;
            }*/

            /*  order status background img  */
            .delivered, .open, .onhold, .closed, .solved, .picking, .shipped, .invoiced, .canceled, .closed, .in-progress, .draft {
                background-size: auto 27px!important;
                background-repeat: no-repeat!important;
                background-position: 10px center;
            }
            .open {
                background-image: url('${statusResources + '/' + LANG + '/open.png'}')!important;
            }
            .delivered {
                background-image: url('${statusResources + '/' + LANG + '/delivered.png'}')!important;
            }
            .onhold {
                background-image: url('${statusResources + '/' + LANG + '/onhold.png'}')!important;
            }
            .closed {
                background-image: url('${statusResources + '/' + LANG + '/closed.png'}')!important;
            }
            .solved {
                background-image: url('${statusResources + '/' + LANG + '/solved.png'}')!important;
            }
            .picking {
                background-image: url('${statusResources + '/' + LANG + '/picking.png'}')!important;
            }
            .shipped {
                background-image: url('${statusResources + '/' + LANG + '/shipped.png'}')!important;
            }
            .invoiced {
                background-image: url('${statusResources + '/' + LANG + '/invoiced.png'}')!important;
            }
            .canceled {
                background-image: url('${statusResources + '/' + LANG + '/canceled.png'}')!important;
            }
            .closed {
                background-image: url('${statusResources + '/' + LANG + '/closed.png'}')!important;
            }
            .inprogress {
                background-image: url('${statusResources + '/' + LANG + '/inprogress.png'}')!important;
            }
            .draft {
                background-image: url('${statusResources + '/' + LANG + '/draft.png'}')!important;
            }

            .delivered lightning-base-formatted-text, .open lightning-base-formatted-text, .inprogress lightning-base-formatted-text, .closed lightning-base-formatted-text, .canceled lightning-base-formatted-text, .invoiced lightning-base-formatted-text, .shipped lightning-base-formatted-text, .picking lightning-base-formatted-text, .solved lightning-base-formatted-text, .closed lightning-base-formatted-text, .onhold lightning-base-formatted-text, .draft lightning-base-formatted-text {
                display : none!important;
            }

        `;
        styleWrapper.appendChild(style);
    }

    get orderstodisplay() {
        return JSON.stringify(this.ordersToDisplay);
    }

    displayOrdersFilteredByStatus(event) {
        const statusValue = event.detail.value;
        if (statusValue == 'reset') {
            // reset lightning combobox value
            const statusLightningCombobox = this.template.querySelector('lightning-combobox');
            statusLightningCombobox.value = '';
            // display all orders
            this.ordersToDisplay = this.allOrders;
        } else if (statusValue != 'Status') {
            // filter orders to display
            this.ordersToDisplay = this.allOrders.filter(function (order) {
                return order['Status'] == statusValue;
            });
        } else {
            // display all orders
            this.ordersToDisplay = this.allOrders;
        }
    }

    displayOrdersBetweenDates() {

        const start = this.startDateFilter;
        const end = this.endDateFilter;

        this.ordersToDisplay = this.allOrders.filter(function (order) {
            // check if there is an order date 
            // and select only orders with an 
            // order date between selected dates
            if (order['Order_Date__c'] != undefined) {

                const orderDate = new Date(order['Order_Date__c']).getTime();
                const startDate = new Date(start).getTime();
                const endDate = new Date(end).getTime();

                return orderDate >= startDate && orderDate <= endDate;

            } else {
                return false
            }
        });

    }

    displayOrdersByNumber(event) {
        if (event.keyCode == 13) {
            if (event.target.value != '') {
                this.ordersToDisplay = this.allOrders.filter(function (order) {
                    return (order['Order_Number__c'] != undefined && order['Order_Number__c'].includes(event.target.value)) ||
                    (order['PoNumber'] != undefined && order['PoNumber'].includes(event.target.value));
                });
            } else {
                this.ordersToDisplay = this.allOrders;
            }
        }
    }

    validateAndSetDateFilters() {
        // ensure that start date is before end date
        if (this.startDateFilter != null && this.endDateFilter != null && new Date(this.startDateFilter) <= new Date(this.endDateFilter)) {
            this.showDatePickerSelectors = false;
            this.showDatesFilterError = false;
            this.enableDateFilter = true;
            this.displayOrdersBetweenDates();
        } else {
            // show error in date picker selectors
            this.showDatesFilterError = true;
        }
    }

    resetDateFilters() {
        this.showDatePickerSelectors = false;
        this.showDatesFilterError = false;
        this.enableDateFilter = false;
        this.startDateFilter = null;
        this.endDateFilter = null;
        this.ordersToDisplay = this.allOrders;
    }

    navigateToHomepage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'home'
            }
        });
    }

    toggleDatePickerSelectors() {
        this.showDatePickerSelectors = !this.showDatePickerSelectors;
    }

    handleStartDateFilter(event) {
        this.startDateFilter = event.target.value;
    }
    handleEndDateFilter(event) {
        this.endDateFilter = event.target.value;
    }

}