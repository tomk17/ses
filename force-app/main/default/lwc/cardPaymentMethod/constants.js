import CardFirstName from '@salesforce/label/c.B2BStore_CardFirstName';
import CardLastName from '@salesforce/label/c.B2BStore_CardLastName';
import CardInvalidName from '@salesforce/label/c.B2BStore_CardInvalidName';
import CardInvalidCreditCardNumber from '@salesforce/label/c.B2BStore_CardInvalidCreditCardNumber';
import CardInvalidCvv from '@salesforce/label/c.B2BStore_CardInvalidCvv';
import CardInvalidCardType from '@salesforce/label/c.B2BStore_CardInvalidCardType';
import CardInvalidExpiryMonth from '@salesforce/label/c.B2BStore_CardInvalidExpiryMonth';
import CardInvalidExpiryYear from '@salesforce/label/c.B2BStore_CardInvalidExpiryYear';
import CardInvalidExpiryDate from '@salesforce/label/c.B2BStore_CardInvalidExpiryDate';
import CardTypeLabel from '@salesforce/label/c.B2BStore_CardTypeLabel';
import CardNumberLabel from '@salesforce/label/c.B2BStore_CardNumberLabel';
import CardExpiryMonthLabel from '@salesforce/label/c.B2BStore_CardExpiryMonthLabel';
import CardExpiryYearLabel from '@salesforce/label/c.B2BStore_CardExpiryYearLabel';
import CardHolderNamePlaceholder from '@salesforce/label/c.B2BStore_CardHolderNamePlaceholder';
import CardHolderLastNamePlaceholder from '@salesforce/label/c.B2BStore_CardHolderLastNamePlaceholder';
import CardTypePlaceholder from '@salesforce/label/c.B2BStore_CardTypePlaceholder';
import CardNumberPlaceholder from '@salesforce/label/c.B2BStore_CardNumberPlaceholder';
import CardCvvPlaceholder from '@salesforce/label/c.B2BStore_CardCvvPlaceholder';
import CardExpiryYearPlaceholder from '@salesforce/label/c.B2BStore_CardExpiryYearPlaceholder';
import CardCvvInfo from '@salesforce/label/c.B2BStore_CardCvvInfo';


export const labels = {
    InvalidName: CardInvalidName,
    InvalidCreditCardNumber: CardInvalidCreditCardNumber,
    InvalidCvv: CardInvalidCvv,
    InvalidCardType: CardInvalidCardType,
    InvalidExpiryMonth: CardInvalidExpiryMonth,
    InvalidExpiryYear: CardInvalidExpiryYear,
    InvalidExpiryDate: CardInvalidExpiryDate,
    CardHolderNameLabel: CardFirstName,
    CardHolderLastNameLabel: CardLastName,
    CardTypeLabel: CardTypeLabel,
    CardNumberLabel: CardNumberLabel,
    CvvLabel: 'CVV',
    ExpiryMonthLabel: CardExpiryMonthLabel,
    ExpiryYearLabel: CardExpiryYearLabel,
    CardHolderNamePlaceholder: CardHolderNamePlaceholder,
    CardHolderLastNamePlaceholder: CardHolderLastNamePlaceholder,
    CardTypePlaceholder: CardTypePlaceholder,
    CardNumberPlaceholder: CardNumberPlaceholder,
    CvvPlaceholder: CardCvvPlaceholder,
    ExpiryMonthPlaceholder: 'MM',
    ExpiryYearPlaceholder: CardExpiryYearPlaceholder,
    CvvInfo: CardCvvInfo
};

export const cardLabels = {
    Visa: 'Visa',
    MasterCard: 'Master Card',
    AmericanExpress: 'American Express',
    //DinersClub: 'Diners Club',
    JCB: 'JCB'
};