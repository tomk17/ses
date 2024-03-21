/**
 * Testing class for LC_WCheckController
 *
 * @author			Rita Bejjani - EI technologies
 * @version			1.1.1
 * Release			
 * Created Date		2020-06-02
 * Test class for	LC_WCheckController
 *
 * Date       | Author							| Version | Coverage | Changes
 * ---------- | ------------------------------- |-------- |--------- | -----------------------------------------
 * 2020-06-02 | Rita Bejjani - EI technologies	|  1.0.0  |   90%    | Initial version.
 * 2022-06-15 | Corentin Bernier - iCom Cloud	|  1.1.0  |   81%    | Added checkHFWarrantyWebServiceTest
 * 2022-10-02 | Tom KOUAME - iCom Cloud	        |  1.1.1  |   84%    | Update checkHFWarrantyWebServiceTest, HFCallWebServiceTest
 * 2022-10-31 | Tom KOUAME - iCom Cloud	        |  1.1.2  |   84%    | Update checkHFWarrantyWebServiceTest, HFCallWebServiceTest
 */
@isTest
public class LC_WCheckController_Test {
    static void setup() {
        warranty_api__c warrantyApiSettings = new warranty_api__c(
        	host__c = 'https://supitfrcprdapidiflow01.azure-api.net',
			token__c = '274f30f4575944099da4b60b8823629d'
        );
        insert warrantyApiSettings;
    } 
    
    @isTest
    public static void HFCallWebServiceTest(){
        setup();
        Test.setMock(HttpCalloutMock.class, new LC_WCheckMock());    
        Test.startTest();
        String result = LC_WCheckController.HFCallWebService('A94A4C20', true);
        Test.stopTest();
    }
    
    @isTest
    public static void HFCallWebServiceWithOldLabelTest(){
        setup();
        Test.setMock(HttpCalloutMock.class, new LC_WCheckMock());    
        Test.startTest();
        String result = LC_WCheckController.HFCallWebService('F710D416', false);
        Test.stopTest();
    }
        
    @isTest
    public static void HFCallOldWebServiceTest(){
        setup();
        Test.setMock(HttpCalloutMock.class, new LC_WCheckMock());    
        Test.startTest();
        String result = LC_WCheckController.HFCallOldWebService('F710D416');
        Test.stopTest();
    }
    /**
     * Method to test checkHFWarrantyWebService
     * @since 1.1.0
     */
    @isTest
    public static void checkHFWarrantyWebServiceTest(){
        setup();
        Test.setMock(HttpCalloutMock.class, new LC_WCheckMock());    
        Test.startTest();
        String result = LC_WCheckController.checkHFWarrantyWebService('A94A4C20');
        Test.stopTest();
    }
    
    @isTest
    public static void getUserInfoTest(){
        String stringRecordType = [select Id from RecordType where (Name='Active Partner') and (SobjectType='Account')].Id;
        Account acc = new Account(RecordTypeID = stringRecordType, ShippingCountry = 'France', Name = 'test');
        insert acc;
        Contact cont = new Contact(LastName = 'stest', FirstName = 'isTest', AccountId = acc.Id, Email = 'istest@testland.com');
        insert cont;
        Profile prof = [SELECT Id FROM Profile WHERE Name LIKE '%Community%'][0];
        User userTest = new User(ProfileId = prof.Id, ContactId = cont.Id, acCore__SalesRepCode__c = 'ISTEST', SAP_Sales_Rep_Code__c = 'ISTEST', 
                                 Username = 'istest@testland.com.preprod', LastName = 'test', Email = 'istest@testland.com', Alias = 'ISTEST', TimeZoneSidKey = 'Europe/Paris',
                                 LocaleSidKey = 'fr_FR', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'fr');
        System.runAs(userTest){
            System.assertEquals('Active Partner', LC_WCheckController.getUserInfo().Name);
        }
    }
    
    @isTest
    public static void checkHFWarranty_TestCustomer(){
        SESImagotag_RMA__c sesRMA = new SESImagotag_RMA__c();
        sesRMA.Name = 'J';
        sesRMA.Year__c = '2019';
        insert sesRMA;
        string msg2 = LC_WCheckController.checkHFWarranty('J', '36', false);
        List<String> parameters2 = new List<String>();
        parameters2.add('2019');
        parameters2.add('36');
        parameters2.add('10');
        String labelMsg2 = String.format(Label.Z_RMA_HFMsg2, parameters2);
        string msg = LC_WCheckController.checkHFWarranty('J', '10', false);
        List<String> parameters = new List<String>();
        parameters.add('2019');
        parameters.add('10');
        parameters.add('1');
        parameters.add('4');
        String labelMsg = String.format(Label.Z_RMA_HFMsg, parameters);
    }
    
    @isTest
    public static void checkHFWarranty_TestPartner(){
        SESImagotag_RMA__c sesRMA = new SESImagotag_RMA__c();
        sesRMA.Name = 'J';
        sesRMA.Year__c = '2019';
        insert sesRMA;
        string msg2 = LC_WCheckController.checkHFWarranty('J', '36', true);
        List<String> parameters2 = new List<String>();
        parameters2.add('2019');
        parameters2.add('36');
        parameters2.add('10');
        String labelMsg2 = String.format(Label.Z_RMA_HFMsg2, parameters2);
        string msg = LC_WCheckController.checkHFWarranty('J', '10', true);
        List<String> parameters = new List<String>();
        parameters.add('2019');
        parameters.add('10');
        parameters.add('1');
        parameters.add('4');
        String labelMsg = String.format(Label.Z_RMA_HFMsg, parameters);
    }
    
    @isTest
    public static void checkLFWarranty_Test(){
        string msg = LC_WCheckController.checkLFWarranty('002');
        List<String> parameters = new List<String>();
        parameters.add('002');
        parameters.add('10');
        parameters.add('6');
        String labelMsg = String.format(Label.Z_RMA_LFMsg, parameters);
    }
    
    @isTest
    public static void manageDateTestPartner(){
        String stringRecordType = [select Id from RecordType where (Name='Active Partner') and (SobjectType='Account')].Id;
        Account acc = new Account(RecordTypeID = stringRecordType, ShippingCountry = 'France', Name = 'test');
        insert acc;
        Contact cont = new Contact(LastName = 'stest', FirstName = 'isTest', AccountId = acc.Id, Email = 'istest@testland.com');
        insert cont;
        Profile prof = [SELECT Id FROM Profile WHERE Name LIKE '%Community%'][0];
        User userTest = new User(ProfileId = prof.Id, ContactId = cont.Id, acCore__SalesRepCode__c = 'ISTEST', SAP_Sales_Rep_Code__c = 'ISTEST', 
                                 Username = 'istest@testland.com.preprod', LastName = 'test', Email = 'istest@testland.com', Alias = 'ISTEST', TimeZoneSidKey = 'Europe/Paris',
                                 LocaleSidKey = 'fr_FR', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'fr');
        Datetime myDateTime = Datetime.newInstance(2020, 01, 01);
        System.runAs(userTest){
            String msg = '';
            List<String> parameters = new List<String>();
            parameters.add(myDateTime.format().split(' ')[0]);
            parameters.add(myDateTime.format().split(' ')[0]);
            msg = String.format(Label.Z_RMA_HFMsg_New, parameters);

            String result = LC_WCheckController.ManageDateNewApi(myDateTime, myDateTime);
            system.debug('***** Result *****');
            system.debug(parameters);
            system.debug(msg);
            system.debug(result);
            System.assertEquals(result, msg);
        }
    }
    
    @isTest
    public static void manageDateTestCustomer(){
        String stringRecordType = [select Id from RecordType where (Name='Customer') and (SobjectType='Account')].Id;
        Account acc = new Account(RecordTypeID = stringRecordType, ShippingCountry = 'France', Name = 'test', Incoterms__c = 'EXW',
        Incoterm_Locations__c = 'Local Warehouse');
        insert acc;
        Contact cont = new Contact(LastName = 'stest', FirstName = 'isTest', AccountId = acc.Id, Email = 'istest@testland.com');
        insert cont;
        Profile prof = [SELECT Id FROM Profile WHERE Name LIKE '%Community%'][0];
        User userTest = new User(ProfileId = prof.Id, ContactId = cont.Id, acCore__SalesRepCode__c = 'ISTEST', SAP_Sales_Rep_Code__c = 'ISTEST', 
                                 Username = 'istest@testland.com.preprod', LastName = 'test', Email = 'istest@testland.com', Alias = 'ISTEST', TimeZoneSidKey = 'Europe/Paris',
                                 LocaleSidKey = 'fr_FR', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'fr');
        Datetime myDateTime = Datetime.newInstance(2020, 01, 01);
        System.runAs(userTest){
            String msg = '';
            List<String> parameters = new List<String>();
            parameters.add(myDateTime.format().split(' ')[0]);
            parameters.add(myDateTime.format().split(' ')[0]);
            msg = String.format(Label.Z_RMA_HFMsg_New, parameters);
            String result = LC_WCheckController.ManageDateNewApi(myDateTime, myDateTime);
            System.assertEquals(result, msg);

        }
    }
    
    @isTest
    public static void manageDateTestPartnerOldApi(){
        String stringRecordType = [select Id from RecordType where (Name='Active Partner') and (SobjectType='Account')].Id;
        Account acc = new Account(RecordTypeID = stringRecordType, ShippingCountry = 'France', Name = 'test');
        insert acc;
        Contact cont = new Contact(LastName = 'stest', FirstName = 'isTest', AccountId = acc.Id, Email = 'istest@testland.com');
        insert cont;
        Profile prof = [SELECT Id FROM Profile WHERE Name LIKE '%Community%'][0];
        User userTest = new User(ProfileId = prof.Id, ContactId = cont.Id, acCore__SalesRepCode__c = 'ISTEST', SAP_Sales_Rep_Code__c = 'ISTEST', 
                                 Username = 'istest@testland.com.preprod', LastName = 'test', Email = 'istest@testland.com', Alias = 'ISTEST', TimeZoneSidKey = 'Europe/Paris',
                                 LocaleSidKey = 'fr_FR', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'fr');
        Datetime myDateTime = Datetime.newInstance(2020, 01, 01);
        System.runAs(userTest){
            String msg = '';
            Datetime warrantyStartDate;
            warrantyStartDate = myDateTime.addMonths(6);
            Date apiDate = date.newInstance(warrantyStartDate.year(), warrantyStartDate.month(), warrantyStartDate.day());
            Date todayDate = Date.today();
            String stringNbYear = String.valueOf(Math.abs(todayDate.monthsBetween(apiDate) / 12));
            String stringNbMonth = String.valueOf(Math.abs(Math.mod(todayDate.monthsBetween(apiDate), 12)));
            String monthName = Label.July;
            String dateYear = String.valueOf(warrantyStartDate.year());
            if(Math.abs(todayDate.monthsBetween(apiDate) / 12) > 0){
                List<String> parameters = new List<String>();
                parameters.add(monthName);
                parameters.add(dateYear);
                parameters.add(stringNbYear);
                parameters.add(stringNbMonth);
                msg = String.format(Label.Z_RMA_HFMsg, parameters);
            }
            else{
                List<String> parameters = new List<String>();
                parameters.add(monthName);
                parameters.add(dateYear);
                parameters.add(stringNbMonth);
                msg = String.format(Label.Z_RMA_HFMsg2, parameters);
            }
            String result = LC_WCheckController.ManageDate(myDateTime, true);
            System.debug('result ' + result);
            System.debug('msg ' + msg);
            System.assertEquals(result, msg);
        }
    }
    
    @isTest
    public static void manageDateTestCustomerOldApi(){
        String stringRecordType = [select Id from RecordType where (Name='Customer') and (SobjectType='Account')].Id;
        Account acc = new Account(RecordTypeID = stringRecordType, ShippingCountry = 'France', Name = 'test', Incoterms__c = 'EXW',
        Incoterm_Locations__c = 'Local Warehouse');
        insert acc;
        Contact cont = new Contact(LastName = 'stest', FirstName = 'isTest', AccountId = acc.Id, Email = 'istest@testland.com');
        insert cont;
        Profile prof = [SELECT Id FROM Profile WHERE Name LIKE '%Community%'][0];
        User userTest = new User(ProfileId = prof.Id, ContactId = cont.Id, acCore__SalesRepCode__c = 'ISTEST', SAP_Sales_Rep_Code__c = 'ISTEST', 
                                 Username = 'istest@testland.com.preprod', LastName = 'test', Email = 'istest@testland.com', Alias = 'ISTEST', TimeZoneSidKey = 'Europe/Paris',
                                 LocaleSidKey = 'fr_FR', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'fr');
        Datetime myDateTime = Datetime.newInstance(2020, 01, 01);
        System.runAs(userTest){
            String msg = '';
            Datetime warrantyStartDate;
            warrantyStartDate = myDateTime.addMonths(3);
            Date apiDate = date.newInstance(warrantyStartDate.year(), warrantyStartDate.month(), warrantyStartDate.day());
            Date todayDate = Date.today();
            String stringNbYear = String.valueOf(Math.abs(todayDate.monthsBetween(apiDate) / 12));
            String stringNbMonth = String.valueOf(Math.abs(Math.mod(todayDate.monthsBetween(apiDate), 12)));
            String monthName = Label.April;
            String dateYear = String.valueOf(warrantyStartDate.year());
            if(Math.abs(todayDate.monthsBetween(apiDate) / 12) > 0){
                List<String> parameters = new List<String>();
                parameters.add(monthName);
                parameters.add(dateYear);
                parameters.add(stringNbYear);
                parameters.add(stringNbMonth);
                msg = String.format(Label.Z_RMA_HFMsg, parameters);
            }
            else{
                List<String> parameters = new List<String>();
                parameters.add(monthName);
                parameters.add(dateYear);
                parameters.add(stringNbMonth);
                msg = String.format(Label.Z_RMA_HFMsg2, parameters);
            }
            String result = LC_WCheckController.ManageDate(myDateTime, false);
            System.assertEquals(result, msg);
        }
    }
}