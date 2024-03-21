/* *******************************************************************************************************
 * Name               : B2B_AvalaraWebCallAPI                                                        *
 * Description        :                                                                                  *
 * Created Date       : 13.01.2021                                                                       *
 * Created By         : Joao Mota @Waeg                                                                *
 * -----------------------------------------------------------------------------------------------       *
 * VERSION    AUTHOR                 DATE                                                                *
 *   1.0 -    Joao Mota @Waeg        13-Jan-2021 Initial version                                         *
 ******************************************************************************************************* */
global class B2B_AvalaraWebCallAPI  {

    public class B2BAvataxException extends Exception {}

    private static final String AVATAX_DEVELOPER_NAME = 'Avatax_API_Connection';
	private static final String AVATAX_DOC_VOIDED = 'DocVoided';
	private static final String AVATAX_TRANSACTION_TYPE = 'SalesInvoice';
	private static final String AVATAX_CALCULATE_ONLY_TRANSACTION_TYPE = 'SalesOrder';
	private static final String SKU = 'SKU';
	private static final String SUB = 'SUB';
    private static final String AVALARA_STATUS_PENDING = 'Pending';
    //Avalara SOAP Information Placeholders
    private static final String PH_AVATAX_ADDRESS_LINE = '[ADDRESS_LINE]';
    private static final String PH_AVATAX_CITY = '[CITY]';
    private static final String PH_AVATAX_STATE = '[STATE]';
    private static final String PH_AVATAX_COUNTRY = '[COUNTRY]';
    private static final String PH_AVATAX_POSTAL_CODE = '[POSTAL_CODE]';
    private static final String PH_AVATAX_LINE_ITEM = '[LINE_ITEM]';
    private static final String PH_AVATAX_ITEM_NUM = '[ITEM_NUM]';
    private static final String PH_AVATAX_TAX_CODE = '[TAX_CODE]';
    private static final String PH_AVATAX_QUANTITY = '[QUANTITY]';
    private static final String PH_AVATAX_AMOUNT = '[AMOUNT]';
    private static final String PH_AVATAX_ITEM_CODE = '[ITEM_CODE]';
    private static final String PH_AVATAX_DATE = '[DATE]';
    private static final String PH_AVATAX_COMPANY_CODE = '[COMPANY_CODE]';
    private static final String PH_AVATAX_TYPE = '[TYPE]';
    private static final String PH_AVATAX_COMMIT = '[COMMIT]';
    private static final String PH_AVATAX_CURRENCY = '[CURRENCY]';
    private static final String PH_AVATAX_TAX_INCLUDED = '[TAX_INCLUDED]';
    private static final String PH_AVATAX_TRANSACTION_CODE = '[TRANSACTION_CODE]';
    private static final String PH_AVATAX_DOC_VOIDED = '[DOC_VOIDED]';
    private static final String PH_AVATAX_BATCH_NAME = '[NAME]';
    private static final String PH_AVATAX_BATCH_CONTENT = '[BATCH_CONTENT]';
    private static final String PH_AVATAX_LOCATIONCODE_FROM = '[AVATAX_LOCATIONCODE_FROM]';
    private static final String PH_AVATAX_ADDRESS_LINE_FROM = '[ADDRESS_LINE_FROM]';
    private static final String PH_AVATAX_CITY_FROM = '[CITY_FROM]';
    private static final String PH_AVATAX_STATE_FROM = '[STATE_FROM]';
    private static final String PH_AVATAX_COUNTRY_FROM = '[COUNTRY_FROM]';
    private static final String PH_AVATAX_POSTAL_CODE_FROM = '[POSTAL_CODE_FROM]';
    private static final String PH_AVATAX_ADDRESS_LINE_TO = '[ADDRESS_LINE_TO]';
    private static final String PH_AVATAX_CITY_TO = '[CITY_TO]';
    private static final String PH_AVATAX_STATE_TO = '[STATE_TO]';
    private static final String PH_AVATAX_COUNTRY_TO = '[COUNTRY_TO]';
    private static final String PH_AVATAX_POSTAL_CODE_TO = '[POSTAL_CODE_TO]';
    private static final String PH_AVATAX_REF1 = '[REF1]';    
     
    
    public static AvalaraTransaction calculateAvataxTransation(WebCart cart){
        List<AvalaraInputItem> inputItems = new List<AvalaraInputItem>();

        List<CartItem> itemsList = [SELECT Id, Quantity, TotalAmount, TotalPrice, SKU, Product2.Id, Product2.CatalogFamilyDescription__c, Product2.Name, Product2.ProductGroup__c, Product2.Material_group__c FROM CartItem WHERE cartId =: cart.Id AND Product2.CatalogFamilyDescription__c != 'Software'];  
        /*if(cart.CartItems == null){
            itemsList.addAll([SELECT Id, Quantity, TotalAmount, TotalPrice, SKU, Product2.Id, Product2.Name, Product2.ProductGroup__c, Product2.Material_group__c 
                                FROM CartItem WHERE cartId =: cart.Id]);
        }else{
            itemsList.addAll(cart.CartItems);
        }*/
        

        //List<CartDeliveryGroup> deliveryGroupsList = new List<CartDeliveryGroup>();        
        //deliveryGroupsList.addAll(cart.CartDeliveryGroups);
        List<CartDeliveryGroup> deliveryGroupsList = [SELECT Id, DeliverToName, DeliverToAddress, DeliverToStreet, DeliverToCity, 
                                                            DeliverToState, DeliverToCountry, DeliverToPostalCode  
                                                        FROM CartDeliveryGroup WHERE CartId = :cart.Id];
		
        Avalara_Tax_Code__mdt taxCodes = [SELECT Tax_Code_Freight_Services__c, Tax_Code_Services__c, Tax_Code_Software__c FROM Avalara_Tax_Code__mdt LIMIT 1];

        
		for(CartItem item : itemsList){

            //Set tax code based on Product "Account Assignment Group" (ProductGroup__c) and "Material Group" (Material_group__c)
            /*01 - Trading Goods --> empty
            02 - Services --> if MaterialGrp = Installation >> SI020100 else empty
            03 - Finish Products --> empty
            04 - Freight Services --> FR020200
            05 - Software --> DC010600 - now it's SW054003*/
            String taxCode = '';
                        
            if(item.Product2.ProductGroup__c == '02 - Services' && item.Product2.Material_group__c == 'F00000027'){
                taxCode = taxCodes.Tax_Code_Services__c;
            }else if(item.Product2.ProductGroup__c == '04 - Freight Services'){
                taxCode = taxCodes.Tax_Code_Freight_Services__c;
            }else if(item.Product2.ProductGroup__c == '05 - Software'){
                taxCode = taxCodes.Tax_Code_Software__c;
            }       
            
            inputItems.add(new AvalaraInputItem(String.valueOf(item.Quantity), 
												String.valueOf(item.TotalPrice),
                                                String.valueOf(item.Sku),
                                                String.valueOf(item.Id),
                                                taxCode
                                                ));
		}

        String cartCountryName = deliveryGroupsList.isEmpty() ? '' : deliveryGroupsList[0].DeliverToCountry ;
        String cartStateName = deliveryGroupsList.isEmpty() ? '' : deliveryGroupsList[0].DeliverToState ;
        
        //Get ISO code for the cart country and states
        List<pw_cc__CountryObject__c> cartCountryList = [SELECT id, Name, pw_cc__IsoCode_2__c, pw_cc__IsoCode_3__c,
                                                    (SELECT id, Name, pw_cc__IsoCode__c
                                                        FROM pw_cc__States__r WHERE Name =: cartStateName)
                                                FROM pw_cc__CountryObject__c
                                                WHERE Name =: cartCountryName];
        
        pw_cc__State__c cartState = String.isBlank(cartCountryName) || String.isBlank(cartStateName) || cartCountryList.isEmpty() ? null : (cartCountryList[0].pw_cc__States__r.isEmpty() ? null : cartCountryList[0].pw_cc__States__r[0]);

        String cartCountryISO = (!cartCountryList.isEmpty() && String.isNotBlank(cartCountryList[0].pw_cc__IsoCode_2__c) ? cartCountryList[0].pw_cc__IsoCode_2__c : cartCountryName);
        String cartStateISO = (cartState != null && String.isNotBlank(cartState.pw_cc__IsoCode__c) ? cartState.pw_cc__IsoCode__c : cartStateName);

		AvalaraInput input = new AvalaraInput(	cart.Id, //avataxTransactionCode
                                                cartCountryISO, //country
												deliveryGroupsList.isEmpty() ? '' : deliveryGroupsList[0].DeliverToStreet, //Ship To Address Line
                                                deliveryGroupsList.isEmpty() ? '' : deliveryGroupsList[0].DeliverToCity, //Ship To City
                                                cartStateISO, //Ship To State
                                                cartCountryISO, //Ship To Country
                                                deliveryGroupsList.isEmpty() ? '' : deliveryGroupsList[0].DeliverToPostalCode, //Ship To Postal Code
                                                '', //Ship From Address Line
                                                '', //Ship From City
                                                '', //Ship From State
                                                '', //Ship From Country
                                                '', //Ship From Postal Code
                                                cart.CurrencyIsoCode, //currency
												AVATAX_CALCULATE_ONLY_TRANSACTION_TYPE, //transaction Type
                                                inputItems);
                                                
        
		return createAvataxTransaction(false, false, input, deliveryGroupsList[0].DeliverToCountry);
    }

	//HTTP Request to Create Avalara Avatax Transactions2B
	private static AvalaraTransaction createAvataxTransaction(Boolean toCommit, Boolean isTaxIncluded, AvalaraInput input, String DeliverToCountry){
		Avalara_Settings__mdt avataxSettings =  B2B_Constants.Avalara_Settings;
        AvalaraTransaction avalaraResponse = new AvalaraTransaction();
                
        try {
            if (avataxSettings != null) {
            
                //Authentication
                String accountId = avataxSettings.Avatax_Account_Id__c;
                String licenseKey = avataxSettings.Avatax_License_Key__c;

                Blob headerValue = Blob.valueOf(accountId + ':' + licenseKey);
                String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);

                String lineItemBase = avataxSettings.Avatax_Line_Item__c;
                String lineItemShippingCost = avataxSettings.Avatax_Line_Item_Shipping_Costs__c;
                String lineItem = '';
                String avalaraSubscriptionSku = '';
                Integer nextItem = 1;

                //Populate Transaction Line Item
                if(!input.items.isEmpty()){
                    for(AvalaraInputItem thisItem : input.items){
                       
                        if(nextItem > 1){
                            lineItem = lineItem + ',';
                        }

                        String itemString = lineItemBase.replace(PH_AVATAX_ITEM_NUM,String.valueOf(nextItem));
                        itemString = itemString.replace(PH_AVATAX_QUANTITY, String.isBlank(thisItem.avataxQuantity) ? '' : thisItem.avataxQuantity);
                        itemString = itemString.replace(PH_AVATAX_AMOUNT, String.isBlank(thisItem.avataxSubAmount) ? '' :thisItem.avataxSubAmount);
                        itemString = itemString.replace(PH_AVATAX_ITEM_CODE, String.isBlank(thisItem.avataxSku) ? '' : thisItem.avataxSku);
                        itemString = itemString.replace(PH_AVATAX_TAX_CODE, String.isBlank(thisItem.avataxTaxCode) ? '' : thisItem.avataxTaxCode);
                        itemString = itemString.replace(PH_AVATAX_REF1, String.isBlank(thisItem.avataxRef1) ? '' : thisItem.avataxRef1);
                        
                        lineItem = lineItem + itemString;

                        nextItem ++;
                    }
                }
				
                String currencyISOCode = String.isNotBlank(input.avataxCurrency) ? input.avataxCurrency : 'USD';

                //Replace Body with Order Values
                String reqBody = avataxSettings.Avatax_Body_Create_Transaction__c;
                
                Organization org = [SELECT InstanceName,Name, IsSandbox, OrganizationType FROM Organization];
                String companyCode = '';
                
                if(org.IsSandbox == true){
                    companyCode = 'TEST';
                }else{
                    if(DeliverToCountry == 'Canada'){
                        companyCode = '2910';
                    }else if(DeliverToCountry == 'United States'){
                        companyCode = '1710';
                    }
                }
                
                System.debug('companyCode : ' + companyCode);
                
                reqBody = reqBody.replace(PH_AVATAX_LOCATIONCODE_FROM, '');
                reqBody = reqBody.replace(PH_AVATAX_ADDRESS_LINE_FROM, String.isBlank(input.avataxAddressLineFrom) ? '' : input.avataxAddressLineFrom);
                reqBody = reqBody.replace(PH_AVATAX_CITY_FROM, String.isBlank(input.avataxCityFrom) ? '' : input.avataxCityFrom);
                reqBody = reqBody.replace(PH_AVATAX_STATE_FROM, String.isBlank(input.avataxStateFrom) ? '' : input.avataxStateFrom);
                reqBody = reqBody.replace(PH_AVATAX_COUNTRY_FROM, String.isBlank(input.avataxCountryFrom) ? '' : input.avataxCountryFrom);
                reqBody = reqBody.replace(PH_AVATAX_POSTAL_CODE_FROM, String.isBlank(input.avataxPostalCodeFrom) ? '' : input.avataxPostalCodeFrom);

                reqBody = reqBody.replace(PH_AVATAX_ADDRESS_LINE_TO, String.isBlank(input.avataxAddressLineTo) ? '' : input.avataxAddressLineTo);
                reqBody = reqBody.replace(PH_AVATAX_CITY_TO, String.isBlank(input.avataxCityTo) ? '' : input.avataxCityTo);
                reqBody = reqBody.replace(PH_AVATAX_STATE_TO, String.isBlank(input.avataxStateTo) ? '' : input.avataxStateTo);
                reqBody = reqBody.replace(PH_AVATAX_COUNTRY_TO, String.isBlank(input.avataxCountryTo) ? '' : input.avataxCountryTo);
                reqBody = reqBody.replace(PH_AVATAX_POSTAL_CODE_TO, String.isBlank(input.avataxPostalCodeTo) ? '' : input.avataxPostalCodeTo);

                reqBody = reqBody.replace(PH_AVATAX_LINE_ITEM, lineItem);
                reqBody = reqBody.replace(PH_AVATAX_DATE, Datetime.now().format('yyyy-MM-dd'));
                reqBody = reqBody.replace(PH_AVATAX_COMPANY_CODE,companyCode);
                reqBody = reqBody.replace(PH_AVATAX_TYPE, String.isBlank(input.avataxType) ? '' : input.avataxType);
                reqBody = reqBody.replace(PH_AVATAX_COMMIT, String.valueOf(toCommit));
                reqBody = reqBody.replace(PH_AVATAX_CURRENCY, currencyISOCode);
                reqBody = reqBody.replace(PH_AVATAX_TAX_INCLUDED, String.valueOf(isTaxIncluded));
                reqBody = reqBody.replace(PH_AVATAX_TRANSACTION_CODE, String.isBlank(input.avataxTransactionCode) ? '' : input.avataxTransactionCode);

                //Create request (create or adjust transaction)
                HttpRequest req = new HttpRequest();
                //req.setEndpoint(B2B_Constants.thisOrganization.IsSandbox ? avataxSettings.Avatax_Upsert_Transaction_Test_EndPoint__c : avataxSettings.Avatax_Upsert_Transaction_Prod_EndPoint__c);
                req.setEndpoint(avataxSettings.Avatax_Upsert_Transaction_Prod_EndPoint__c);
                req.setMethod('POST');
                req.setHeader('Authorization', authorizationHeader);
                req.setHeader('Content-Type', avataxSettings.Avatax_Content_Type__c);

                req.setBody(reqBody);
                
                //Send request
                Http http = new Http();
                HTTPResponse res = http.send(req);
				if (res.getStatusCode() > 199 && res.getStatusCode() < 300) {
                    //Parse Response into Object
                    avalaraResponse = (AvalaraTransaction) JSON.deserialize(res.getBody(), AvalaraTransaction.class);
                    avalaraResponse.statusCode = res.getStatusCode();
                }else{
                    
                    //Try to check if it's duplicate, if it isnt, void transaction
                    String myErrorResponse = res.getBody().replace('number', 'errorNumber');
                    AvalaraErrorResponse errorResponse = (AvalaraErrorResponse) JSON.deserialize(myErrorResponse, AvalaraErrorResponse.class);
                    String errorMessage = '';
                    for (AvalaraErrorDetailItem errorDetailItem : errorResponse.error.details) {
                        errorMessage += ' ' + errorDetailItem.message + errorDetailItem.refersTo; 
                    }
                    avalaraResponse.errorMessage = errorMessage;
                    avalaraResponse.statusCode = res.getStatusCode();
                    avalaraResponse.status = 'Error';
                }
       
                return avalaraResponse;
            }

        }catch(Exception e) {
            avalaraResponse.errorMessage = e.getMessage();
            avalaraResponse.statusCode = 500;
            avalaraResponse.status = 'Error';
            avalaraResponse.totalAmount = '0';
            avalaraResponse.totalTax = '0';
            avalaraResponse.code =  e.getStackTraceString() + ' Line ' + e.getLineNumber();
        }

        return avalaraResponse;
    }  
    

    global class AvalaraTransaction {
         public String code = '';
         public String companyId = '';
         public String status = '';
         public String currencyCode = '';
         public String totalAmount = '';
         public String totalTax = '';
         public String totalTaxable = '';
         public String totalTaxCalculated = '';
         public Integer statusCode = 0;
         public String errorMessage = '';
         public List<AvalaraLineItem> lines = new List<AvalaraLineItem>();
    }

    global class AvalaraLineItem {
        public String id = '';
        public String companyId = '';
        public String lineNumber = '';
        public String itemCode = '';
        public String lineAmount = '';
        public String tax = '';
        public String ref1 = '';
        public List<AvalaraTaxDetail> details = new List<AvalaraTaxDetail>();
    }

    global class AvalaraTaxDetail {
        public String id = '';
        public String taxName = '';
        public String rate = '';
        public String tax = '';
        public String taxableAmount = '';        
        public String taxCalculated = '';
    }

    global class AvalaraErrorResponse {

        public AvalaraErrorDetail error = new AvalaraErrorDetail();

    }

    global class AvalaraErrorDetail {

        public List<AvalaraErrorDetailItem> details = new List<AvalaraErrorDetailItem>();
    }

    global class AvalaraErrorDetailItem {

        public String code = '';
        public String errorNumber = '';
        public String message = '';
        public String refersTo = '';
    }

	/**
	* @description Wrapper class to allow avatax transactions (tax calculation) to be executed using either a CC cart or a CC order as input
	*/ 
	global class AvalaraInput {		

		private String country;
		private String avataxTransactionCode;
        private String avataxCurrency;
        
		private String avataxAddressLineTo;
        private String avataxCityTo;
        private String avataxStateTo;
		private String avataxCountryTo;
        private String avataxPostalCodeTo;
        
        private String avataxAddressLineFrom;
        private String avataxCityFrom;
        private String avataxStateFrom;
		private String avataxCountryFrom;
        private String avataxPostalCodeFrom;

        private String avataxType;
		private AvalaraInputItem[] items;

        public AvalaraInput( String avataxTransactionCode, String country,
            String avataxAddressLineTo, String avataxCityTo, String avataxStateTo, String avataxCountryTo, String avataxPostalCodeTo,
            String avataxAddressLineFrom, String avataxCityFrom, String avataxStateFrom, String avataxCountryFrom, String avataxPostalCodeFrom,
            String avataxCurrency, String avataxType, AvalaraInputItem[] items) {

			this.country = country;
			this.avataxTransactionCode = avataxTransactionCode;
						
			this.avataxAddressLineTo = avataxAddressLineTo;
			this.avataxCityTo = avataxCityTo;
            this.avataxStateTo = avataxStateTo;
            this.avataxCountryTo = avataxCountryTo;
            this.avataxPostalCodeTo = avataxPostalCodeTo;
            
            this.avataxAddressLineFrom = avataxAddressLineFrom;
			this.avataxCityFrom = avataxCityFrom;
            this.avataxStateFrom = avataxStateFrom;
            this.avataxCountryFrom = avataxCountryFrom;
            this.avataxPostalCodeFrom = avataxPostalCodeFrom;

            this.avataxCurrency = avataxCurrency;
            this.avataxType = avataxType;
			this.items = items;
		}

	}

	global class AvalaraInputItem {
		private String avataxQuantity;
		private String avataxSubAmount;
		private String avataxItemCode;
        private String avataxSKU;
        private String avataxRef1;
        private String avataxTaxCode;

		public AvalaraInputItem(String avataxQuantity, String avataxSubAmount, String avataxSKU, String avataxRef1, String avataxTaxCode){
			this.avataxQuantity = avataxQuantity;
			this.avataxSubAmount = avataxSubAmount;
            this.avataxSKU = avataxSKU;
            this.avataxRef1 = avataxRef1;
            this.avataxTaxCode = avataxTaxCode;
		}

	}

}