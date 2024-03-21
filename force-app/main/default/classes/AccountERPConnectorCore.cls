/**
 * Created by Te Kevin on 23/01/2020.
 */

public with sharing class AccountERPConnectorCore {

    public static Set<String> requiredFields = new Set<String> {
            'ParentId',
            'Niveau__c',
            'TypeStore__c',
            'Industry',
            'Brand__c',
            'StatutStore__c',
            'SurfaceStore__c',
            'ShippingStreet',
            'ShippingPostalCode',
            'ShippingCity',
            'ShippingCountry',
            'Phone',
            'acCore__PaymentTerm__c'

    };

    public static Set<String> getRequiredFields(){
        return requiredFields;
    }

    public static final Map<String, String> taxPayerCountries = new Map<String, String> {
            'AT' => 'Austria',
            'BE' => 'Belgium',
            'BG' => 'Bulgaria',
            'CY' => 'Cyprus',
            'CZ' => 'Czech Republic',
            'DE' => 'Germany',
            'DK' => 'Denmark',
            'EE' => 'Estonia',
            'ES' => 'Spain',
            'FI' => 'Finland',
            'FR' => 'France',
            'EL' => 'Greece',
            'GB' => 'United Kingdom',
            'HR' => 'Croatia',
            'HU' => 'Hungary',
            'IE' => 'Ireland',
            'IT' => 'Italy',
            'LT' => 'Lithuania',
            'LU' => 'Luxembourg',
            'LV' => 'Latvia',
            'MT' => 'Malta',
            'NL' => 'Netherlands',
            'PL' => 'Poland',
            'PT' => 'Portugal',
            'RO' => 'Romania',
            'SE' => 'Sweden',
            'SI' => 'Slovenia',
            'SK' => 'Slovakia'
    };

    public static Map<String, String> getPayerCountries(){
        return taxPayerCountries;
    }


    public static Map<String, Map<String, String>> fieldsFormat = new Map<String, Map<String, String>> {
            'TaxPayerID__c' => new Map<String, String> {
                    'rule' => '[0-9a-zA-Z]*',
                    'message' => 'Le n° de TVA ne doit comporter que des chiffres et des lettres.'
            }
    };

    public static Map<String, Map<String, String>> getFieldsFormat(){
        return fieldsFormat;
    }

    public static Boolean checkVat(Account currentAccount){

        String VAT = '';
        if(currentAccount.TaxPayerID__c != null && currentAccount.TaxPayerID__c != ''){
            VAT = currentAccount.TaxPayerID__c;
            if(currentAccount.TaxPayerID__c.length() >= 2){
                VAT = VAT.subString(2,VAT.length());
            }
        }

        if(currentAccount.ShippingState != null && currentAccount.ShippingState.contains('Las Palmas')){
            return true;
        }
        if(currentAccount.ShippingCountry == 'Spain'){
            if(currentAccount.ShippingPostalCode.subString(0, 2) == '35' || currentAccount.ShippingPostalCode.subString(0, 2) == '38'){ 
                return true; 
            }
        }
        if(currentAccount.ShippingCountry == 'Netherlands'){
            if(currentAccount.ShippingState == 'Sint marteen'){ 
                return true; 
            }
        }

        String accountCountry = '';
        String accountISOCountry = '';
        if(currentAccount.shippingCountry != ''){
            accountCountry = currentAccount.shippingCountry;
        }


        Boolean inTaxPayerCountries = false;
        for(String isoCode : taxPayerCountries.keySet()){
            if(taxPayerCountries.get(isoCode) == accountCountry){
                accountISOCountry = currentAccount.TaxPayerID__c.subString(0,2);
                inTaxPayerCountries = true;
                break;
            }
        }

        if(!inTaxPayerCountries){
            return true;
        }

        if(currentAccount.TaxPayerID__c != null && currentAccount.TaxPayerID__c != ''){
            if(currentAccount.TaxPayerID__c.length() > 2){
                if(currentAccount.TaxPayerID__c.subString(0,2) == 'IT'){
                    return true;
                }
            }
        }
        System.debug('LAUNCH WS CHECK VAT');
        System.debug(accountISOCountry + '  ' + VAT);
        ecEuropaEuTaxudViesServicesCheckva.checkVatPort vatChecker = new ecEuropaEuTaxudViesServicesCheckva.checkVatPort();
        vatChecker.timeout_x = 30000;
        //System.debug(vatChecker.checkVat(accountISOCountry,VAT).valid);
        return vatChecker.checkVat(accountISOCountry,VAT).valid;
    }

    public static String validFormatTaxPayer(String VAT, Account currentAccount){
        Set<String> taxPayerCountriesValues = new Set<String>(taxPayerCountries.values());

        if(currentAccount.ShippingState != null && currentAccount.ShippingState.contains('Las Palmas')){
            return 'validAccount';
        }
        if(currentAccount.ShippingCountry == 'Spain'){
            if(currentAccount.ShippingPostalCode.subString(0, 2) == '35' || currentAccount.ShippingPostalCode.subString(0, 2) == '38'){ 
                return 'validAccount'; 
            }
        }
        
        if(currentAccount.ShippingCountry == 'Netherlands'){
            if(currentAccount.ShippingState == 'Sint marteen'){ 
                return 'validAccount';
            }
        }
        String errorMessage = 'validAccount';
        System.debug('validFormatTaxPayer');
        List<String> customRules = new List<String>{'AT', 'BE', 'NL', 'CZ', 'SE', 'RO'};
        if (taxPayerCountriesValues.contains(currentAccount.ShippingCountry)) {
            if(VAT != null && VAT.length() > 2){
                String currentIsoCode = VAT.substring(0,2);
                System.debug('Current ISO Code : ' + currentIsoCode);
                Boolean isoCodeIsValid = false;
                if(taxPayerCountries.containsKey(currentIsoCode)){
                    isoCodeIsValid = true;
                }
                if(isoCodeIsValid){
                    System.debug('ISO Code is Valid ! ' + isoCodeIsValid);
                    EuropeanFormatVAT__mdt VATSettings = [SELECT MasterLabel, MinVATLength__c, MaxVATLength__c
                    FROM EuropeanFormatVAT__mdt WHERE CountryISOCode__c =: currentIsoCode LIMIT 1];
                    System.debug('VAT : ' + VAT);
                    System.debug('VAT Sub3 : ' + VAT.substring(2,3));
                    System.debug('VAT Length : ' + VAT.length());
                    System.debug('MinVATLength' + VATSettings.MinVATLength__c);
                    if(VATSettings != null){
                        System.debug('VAT Settings');
                        System.debug(VATSettings);
                        if(customRules.contains(currentIsoCode)){
                            if(currentIsoCode == 'AT' && (VAT.substring(2,3) != 'U' || VAT.length() != VATSettings.MinVATLength__c)){
                                errorMessage = 'Detected Error : The VAT number must have ' + VATSettings.MinVATLength__c.setScale(0) + ' characters and contains a \'U\' after the country code (ISO format) for a/an ' + VATSettings.MasterLabel + ' account.';
                            }
                            else if(currentIsoCode == 'BE' && (VAT.substring(2,3) != '0' || VAT.length() != VATSettings.MinVATLength__c)){
                                errorMessage = 'Detected Error : The VAT number must have ' + VATSettings.MinVATLength__c.setScale(0) + ' characters and contains a \'0\' after the country code (ISO format) for a/an ' + VATSettings.MasterLabel + ' account.';
                            }
                            else if(currentIsoCode == 'NL' && (!VAT.contains('B') || VAT.length() != VATSettings.MinVATLength__c)){
                                errorMessage = 'Detected Error : The VAT number must have ' + VATSettings.MinVATLength__c.setScale(0) + ' characters and contains a \'B\' for a/an ' + VATSettings.MasterLabel + ' account.';
                            }
                            else if((currentIsoCode == 'CZ' || currentIsoCode == 'RO') && (VAT.length() < VATSettings.MinVATLength__c || VAT.length() > VATSettings.MaxVATLength__c)){
                                errorMessage = 'Detected Error : The VAT number must have between ' + VATSettings.MinVATLength__c.setScale(0) + ' and ' + VATSettings.MaxVATLength__c.setScale(0) + ' characters for a/an ' + VATSettings.MasterLabel + ' account.';
                            }
                            else if(currentIsoCode == 'SE' && (VAT.length() != VATSettings.MinVATLength__c || VAT.substring(VAT.length() -2, VAT.length()) != '01')){
                                errorMessage = 'Detected Error : The VAT number must have ' + VATSettings.MinVATLength__c.setScale(0) + ' characters and ends by \'01\' for a/an ' + VATSettings.MasterLabel + ' account.';}
                        }
                        else{
                            if(VATSettings.MaxVATLength__c != null && VAT.length() != VATSettings.MinVATLength__c && VAT.length() != VATSettings.MaxVATLength__c){
                                errorMessage = 'Detected Error : The VAT number must have ' + VATSettings.MinVATLength__c.setScale(0) + ' or ' + VATSettings.MaxVATLength__c.setScale(0)  + ' characters for a/an ' + VATSettings.MasterLabel + ' account.';

                            }
                            else{
                                if(VATSettings.MaxVATLength__c == null && VAT.length() != VATSettings.MinVATLength__c){
                                    errorMessage = 'Detected Error : The VAT number must have ' + VATSettings.MinVATLength__c.setScale(0) + ' characters for a/an ' + VATSettings.MasterLabel + ' account.';
                                }
                            }
                        }
                    }
                    else{
                        errorMessage = Label.IncorrectVATNumber;
                    }
                }
                else{
                    errorMessage = Label.IncorrectVATNumber;
                }
            }
            else{
                errorMessage = Label.IncorrectVATNumber;
            }
        }
        return errorMessage;
    }

    public static List<String> checkLengthFields(Account currentAccount){
        List<String> listErrorLength = new List<String> ();

        if(currentAccount.Name.length() > 50){
            listErrorLength.add('The Account Name should not have more than 50 characters.');
        }
        System.debug('Name : ' +  currentAccount.Name.length());


        List<String> shippingStreetSplit = currentAccount.ShippingStreet.split('\r\n');
        System.debug('shippingStreetSplit : ' + shippingStreetSplit);

        if(!shippingStreetSplit.isEmpty()){
            for(Integer i = 0; i < shippingStreetSplit.size(); i++){
                if(shippingStreetSplit.get(i).length() > 50){
                    listErrorLength.add('Each line in the Shipping Street Address should not have more than 50 characters.');
                    break;
                }
            }
        }

        if(currentAccount.ShippingPostalCode.length() > 10){
            listErrorLength.add('The Shipping ZipCode should not have more than 10 characters.');
        }

        if(currentAccount.ShippingCity.length() > 50){
            listErrorLength.add('The Shipping City should not have more than 50 characters.');
        }

        if(currentAccount.ShippingState != null){
            if(currentAccount.ShippingState.length() > 50){
                listErrorLength.add('The Shipping State should not have more than 50 characters.');
            }
        }


        Pattern myPattern = Pattern.compile('(.*\r\n){3,}.*');
        Matcher twoLineBreaksMatcherShipping = MyPattern.matcher(currentAccount.ShippingStreet);
        Boolean moreThanTwoLineBreaks = twoLineBreaksMatcherShipping.matches();
        if(moreThanTwoLineBreaks){
            listErrorLength.add('The Shipping Street should not have more than 2 line breaks.');
        }

        return listErrorLength;
    }

    public static Map<String, String> checkRequiredFields(Account acc) {
        Set<String> requiredFields = new Set<String> ();
        requiredFields.addAll(getRequiredFields());
        Map<String, String> missingFieldsMap = new Map<String, String> ();
        Map<String,Schema.SobjectField> describe = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap();

        Set<String> taxPayerCountriesValues = new Set<String>(taxPayerCountries.values());
        if (taxPayerCountriesValues.contains(acc.ShippingCountry)) {
            requiredFields.add('TaxPayerID__c');
        }

        if(acc.ShippingState != null){
            if(acc.ShippingState.contains('Las Palmas')){
                requiredFields.remove('TaxPayerID__c');
            }
        }
        if(acc.ShippingCountry == 'Netherlands'){
            if(acc.ShippingState == 'Sint marteen'){ 
               requiredFields.remove('TaxPayerID__c'); 
            }
        }
        
        if(acc.ShippingCountry != null && acc.ShippingCountry == 'Spain'){
            if(acc.ShippingPostalCode != null){
                if(acc.ShippingPostalCode.subString(0, 2) == '35' || acc.ShippingPostalCode.subString(0, 2) == '38'){ 
                	requiredFields.remove('TaxPayerID__c'); 
            	}
            }
        }

        if(acc.ShippingCountry != null){
            if(acc.ShippingCountry.toLowerCase() == 'france'){
                requiredFields.add('SIRET__c');
            }

            if(acc.ShippingCountry.toLowerCase() == 'united states' || acc.ShippingCountry.toLowerCase() == 'canada'){
                requiredFields.add('ShippingState');
            }
        }
        
        if (acc.RecordType.DeveloperName == 'Potential_Partner'){
            requiredFields.removeAll(new Set<String> {'ParentId', 'Niveau__c', 'SurfaceStore__c', 'StatutStore__c', 'TypeStore__c'});
        }


        System.debug('LEVEL : ' + acc.Niveau__c);
        if(acc.Niveau__c == 'Groupe'){
            requiredFields.remove('ParentId');
        }

        for (String field : requiredFields) {
            if (acc.get(field) == null) {
                missingFieldsMap.put(field, describe.get(field).getDescribe().getLabel());
            }
        }

        return missingFieldsMap;
    }
    
    public static Map<String, String> checkFieldsFormat(Account acc) {
        Map<String, String> badFieldsFormatMap = new Map<String, String> ();

        Map<String,Schema.SobjectField> describe = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap();

        for (String field : fieldsFormat.keySet()) {
            Pattern myPattern = Pattern.compile(
                    fieldsFormat.get(field).get('rule')
            );

            if (acc.get(field) != null) {
                Matcher myMatcher = myPattern.matcher(
                        (String) acc.get(field)
                );

                if (!myMatcher.matches()) {
                    badFieldsFormatMap.put(
                            field,
                            describe.get(field).getDescribe().getLabel()
                    );
                }
            }
        }
        return badFieldsFormatMap;
    }


}