import CardPaymentOptionLabel from '@salesforce/label/c.B2BStore_CardPaymentOptionLabel';

export const PaymentTypeEnum  = Object.freeze({
    PONUMBER: 'PurchaseOrderNumber',
    CARDPAYMENT: 'CardPayment'
});

export const labels  = {
    paymentMethodHeader: 'Payment Method',
    purchaseOrderOptionLabel: 'Purchase Order',
    purchaseOrderEntryHeader: 'Enter PO Number',
    cardPaymentOptionLabel: CardPaymentOptionLabel
};