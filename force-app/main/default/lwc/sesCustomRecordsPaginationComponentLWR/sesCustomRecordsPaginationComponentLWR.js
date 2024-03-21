import { LightningElement, api, track } from "lwc";
import { updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const DELAY = 300;

export default class SesCustomRecordsPaginationComponentLWR extends LightningElement {

    @api showTable = false;
    @api records;
    @api recordsperpage;
    @api columns;

    @track draftValues = [];
    @track recordsToDisplay;

    @track showSeparator1 = false;
    @track showSeparator2 = false;
    @track showLastPageLink = false;

    @track totalRecords;
    pageNo;
    @track totalPages;
    startRecord;
    endRecord;
    end = false;
    pagelinks = [];
    isLoading = false;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    ortedBy;

    records_checkReloadComponent;

    connectedCallback() {
        this.isLoading = true;
        this.setRecordsToDisplay();
        this.showSeparators();

        this.records_checkReloadComponent = this.records;
    }

    renderedCallback() {
        
        // realod lightning table with records to display data if records values has changed
        if (this.records_checkReloadComponent != this.records) {
            this.pagelinks = [];
            this.setRecordsToDisplay();
            this.showSeparators();
            this.records_checkReloadComponent = this.records;
        }

        const styleWrapper = this.template.querySelector('.style-wrapper');
        
        const style = document.createElement('style');
        style.innerText = `
        /* buttons on record list custom component */
        .next-page-button .slds-button:focus, .previous-page-button .slds-button:focus, .page-button .slds-button:focus {
            box-shadow: none!important;
            outline: none!important;
        }
        /* icon color */
        .previous-page-button .slds-button__icon, .previous-page-button .slds-button__icon:hover, .next-page-button .slds-button__icon, .next-page-button .slds-button__icon:hover {
            fill: #E27B47!important;
        }
        /* disable icon color */
        .previous-page-button button:disabled .slds-button__icon, .previous-page-button button:disabled:hover .slds-button__icon, .next-page-button button:disabled .slds-button__icon, next-page-button button:disabled:hover .slds-button__icon {
            fill: #C4C4C4!important;
        }
        .previous-page-button button lightning-primitive-icon, .next-page-button button lightning-primitive-icon{
            box-shadow: 0px 2px 24px rgba(0, 0, 0, 0.15)!important;
            background: white!important;
            margin: 0px!important;
            background: white;
            border-radius: 90px!important;
        }
        .next-page-button button:disabled lightning-primitive-icon, .previous-page-button button:disabled lightning-primitive-icon {
            box-shadow: none!important;
            background: #E5E5E5!important;
            bacgkround: #E5E5E5;
        }
        /* icons padding on previous and next button */
        .previous-page-button button lightning-primitive-icon {
            padding: 3px 5px 3px 11px!important;
        }
        .next-page-button button lightning-primitive-icon {
            padding: 3px 11px 3px 5px!important;
        }

        /* remove  wrap text / clip text in table header of record list custom component */
        .slds-th__action lightning-primitive-icon {
            display: none!important;
        }

        /* remove first column on record list component table */
        thead tr th:nth-child(1) {
            display: none;
        }
        tbody tr td:nth-child(1) {
            display: none;
        }
        tbody tr th:nth-of-type(1) lightning-formatted-url a{
            font-family: 'Maax_Bold';
            text-decoration: underline;
            color: #E27B47!important;
        }
        `;

        styleWrapper.appendChild(style);

    }

    showSeparators() {
        this.showSeparator1 = this.pageNo > 2 && this.totalPages > 3;
        this.showSeparator2 = this.totalPages > 2 && this.pageNo != this.totalPages;
    }

    // display only records of the seleted page
    setRecordsToDisplay() {
        this.totalRecords = this.records.length;
        this.pageNo = 1;
        this.totalPages = Math.ceil(this.totalRecords / this.recordsperpage);
        this.showLastPageLink = this.totalPages != 0 ? true : false;
        this.preparePaginationList();

        for (let i = 1; i <= this.totalPages; i++) {
            if ( i > 1 && i != this.totalPages) {
                this.pagelinks.push(i);
            }
        }
        this.isLoading = false;
    }

    handleClick(event) {
        let title = event.target.title;
        if (title === "1") {
            this.handleFirst();
        } else if (title === "previous") {
            this.handlePrevious();
        } else if (title === "next") {
            this.handleNext();
        } else if (title === this.totalPages) {
            this.handleLast();
        }
        this.showSeparators();
    }

    handleNext() {
        this.pageNo += 1;
        this.preparePaginationList();
    }

    handlePrevious() {
        this.pageNo -= 1;
        this.preparePaginationList();
    }

    handleFirst() {
        this.pageNo = 1;
        this.preparePaginationList();
    }

    handleLast() {
        this.pageNo = this.totalPages;
        this.preparePaginationList();
    }

    preparePaginationList() {
        this.isLoading = true;
        let begin = (this.pageNo - 1) * parseInt(this.recordsperpage);
        let end = parseInt(begin) + parseInt(this.recordsperpage);
        this.recordsToDisplay = this.records.slice(begin, end);

        this.startRecord = begin + parseInt(1);
        this.endRecord = end > this.totalRecords ? this.totalRecords : end;
        this.end = end > this.totalRecords ? true : false;

        let anchor = this.template.querySelector('.anchor-pagination');
        console.log('preparePaginationList - anchor : ', anchor);
        if(anchor){
            anchor.scrollIntoView(true);
        }

        // remove this event if not used (can bu used by the parent component if needed)
        const event = new CustomEvent('pagination', {
            detail: { 
                records : this.recordsToDisplay
            }
        });
        this.dispatchEvent(event);

        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            this.disableEnableActions();
        }, DELAY);
        
        this.isLoading = false;
    }

    disableEnableActions() {
        let buttons = this.template.querySelectorAll("lightning-button");

        buttons.forEach(bun => {
            if (bun.title === this.pageNo) {
                bun.disabled = true;
            } else {
                bun.disabled = false;
            }

            // display only first, current, and last page number
            if (!['1', 'next', 'previous', this.pageNo, this.totalPages].includes(bun.title)) {
                bun.style.display = 'none';
            } else {
                bun.style.display = 'inline-block';
            }

            // disable next or previous page button if it correspond to the current page
            if (bun.title === "1") {
                bun.disabled = this.pageNo === 1 ? true : false;
            } else if (bun.title === "previous") {
                bun.disabled = this.pageNo === 1 ? true : false;
            } else if (bun.title === "next") {
                bun.disabled = this.pageNo === this.totalPages ? true : false;
            } else if (bun.title === this.totalPages) {
                bun.disabled = this.pageNo === this.totalPages ? true : false;
            }
            
        });
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        console.log('test pagination : ', actionName);
        const rowAction = new CustomEvent('actions', {
            detail: { 
                actionName : actionName,
                data : row
            }
        });
        this.dispatchEvent(rowAction);
    }

    handlePage(button) {
        this.pageNo = button.target.title;
        this.preparePaginationList();
    }

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.recordsToDisplay];
        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.recordsToDisplay = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    sortBy( field, reverse, primer ) {

        const key = primer
        ? function( x ) {
            return primer(x[field]);
        }
        : function( x ) {
            return x[field];
        };

        return function( a, b ) {
            a = key(a);
            b = key(b);
            return reverse * ( ( a > b ) - ( b > a ) );
        };
    }

    // uncomment if inline edit is allow and enable
    /*handleSave(event) {
        this.isLoading = true;
        const recordInputs =  event.detail.draftValues.slice().map(draft => {
            const fields = Object.assign({}, draft);
            return { fields };
        });
        const promises = recordInputs.map(recordInput => updateRecord(recordInput));
        window.console.log(' Updating Records.... ');
        Promise.all(promises).then(record => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'All Records updated',
                    variant: 'success'
                })
            );
            this.draftValues = [];
            eval("$A.get('e.force:refreshView').fire();");
            return refreshApex(this.recordsToDisplay);
        }).catch(error => {
            window.console.error(' error **** \n '+error);
        })
        .finally(()=>{
            this.isLoading = false;
        })
    }*/



}