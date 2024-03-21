import { LightningElement, wire } from "lwc";
import { subscribe, MessageContext } from "lightning/messageService";
import TOAST_MESSAGE_SERVICE_CHANNEL from "@salesforce/messageChannel/toastMessageServiceChannel__c";

const TIMEOUT = 3000;

export default class CustomToastCmp extends LightningElement {
    title;
    message;
    variant;
    displayToast = false;
    subscription;
    @wire(MessageContext)
    messageContext;

    // Encapsulate logic for LMS subscribe.
    subscribeToMessageChannel() {

        if(this.subscription) return;

        this.subscription = subscribe(
            this.messageContext, 
            TOAST_MESSAGE_SERVICE_CHANNEL, 
            (message) => this.handleMessage(message)
        );
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    // Standard lifecycle hooks used to sub/unsub to message channel
    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    // Handler for message received by component
    handleMessage(message) {
        console.log("Toast message:", JSON.stringify(message));
        this.title = message.title;
        this.message = message.message;
        this.variant = message.variant;
        this.displayToast = true;
        this.closeToast();
    }

    closeToast() {
        setTimeout(() => {
            this.displayToast = false;
        }, TIMEOUT);
    }

    get iconName() {
        return this.variant === "success" ? "utility:success" : "utility:error";
    }

    get toastClass() {
        return `toast toast-${this.variant}`;
    }
}