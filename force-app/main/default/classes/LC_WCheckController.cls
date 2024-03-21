/**
 * Controller for LC_WarrantyCheck component
 * @author          Rita Bejjani - EI-Technologies 
 * Release          
 * Created Date     2020-06-01
 * Used in          aura/LC_WarrantyCheck, aura/LC_WarrantyCheckVusion, lightning/portalWarrantyCheck
 * Test class       LC_WCheckController_Test
 * 
 *  Date      | Author							| Version | Changes
 * ---------- | ------------------------------- |-------- | -----------------------------------------
 * 2020-06-01 | Rita Bejjani - EI-Technologies	|  1.0.0  | Initial version.
 * 2022-11-19 | Vianney Gourrin - iCom Cloud	|  1.1.0  | Added 'HFCallWebService', 'getUserInfo', 'ManageDate'
 * 2022-06-09 | Corentin Bernier - iCom Cloud	|  1.2.0  | Added 'isPartner', 'checkHFWarrantyWithLabel', 'checkHFWarrantyWebService', 'WrapperResponse', 'WrapperLabel'
 * 2022-10-02 | Tom KOUAME - iCom Cloud	        |  1.2.1  | Updated : 'checkHFWarrantyWebService', 'WrapperResponse';  removed 'WrapperLabel'
 * 2022-10-25 | Tom KOUAME - iCom Cloud	        |  1.2.2  | Updated : Mix old api and new api (if no results on new api => call old api)
 */
public class LC_WCheckController {

    /**
     * Method to check if the current user is a Partner
     * @return              A boolean to true if they are a Partner
     * @since               1.2.0
     */
    public static Boolean isPartner(){
        Id currentUserId = userInfo.getUserId();
        User currentUser = [SELECT Account.RecordType.Name FROM User WHERE Id =: currentUserId][0];
        return (currentUser != null && currentUser.Account.RecordType.Name == 'Active Partner');
    }

     /**
     * Method to calculate the Warranty date for HF using the web service
     * @author              Corentin Bernier - iCom Cloud
     * @param labelId       The Label Id
     * @return              The message to display
     * @since               1.2.1
     */
    @AuraEnabled
    public static String checkHFWarrantyWebService(String labelId) {
        String result = HFCallWebService(labelId, true);
        Boolean newApi = true; 
        System.debug('********* RESULT **********');
        System.debug(result);
        if(result.indexOf('errorCode') != -1) {
            result = HFCallOldWebService(labelId);
        } else {
            WrapperResponseNewWebService response = (WrapperResponseNewWebService)JSON.deserialize(result, WrapperResponseNewWebService.class);
            DateTime startDate = getDateFromString(response.WarrantyStartDate);
            DateTime endDate = getDateFromString(response.WarrantyEndDate);
            System.debug('Start date :' + startDate);
            System.debug('End date :' + endDate);
            if(startDate == null || endDate == null) {
                result = HFCallOldWebService(labelId);
            } else {
                result = ManageDateNewApi(startDate, endDate);
            }
        }
        if(result.indexOf('errorCode') != -1) {
            CalloutException e = new CalloutException();
            e.setMessage('Label not found');
            throw e;
        }
        System.debug('Result  :' + result);
        return result;
    }

    public static String HFCallOldWebService(String labelId) {
        System.debug('************** HFCallOldWebService ****************');
        String result = HFCallWebService(labelId, false);

        System.debug(result);
        if(result.indexOf('errorCode') != -1) {
            return result;
        }
        
        WrapperResponse response = (WrapperResponse)JSON.deserialize(result, WrapperResponse.class);
        System.debug(response);
        System.debug(response.label.production_time);

        return ManageDate(response.label.production_time, isPartner());

    }


    public static DateTime getDateFromString(String dateString) {
        
        DateTime result_date = null;
        Pattern p = Pattern.compile('.*\\((\\d*)\\).*$');
        Matcher pm = p.matcher(dateString);
        
        if(pm.matches()) {
            Long t = long.valueof(pm.group(1));
            result_date = DateTime.newInstance(t);
        }
        return result_date;

    }

    @AuraEnabled
    public static String HFCallWebService(String sesId, boolean newApi){
        System.debug('***********  HFCallWebService *********** ');
        // Call HF web service 
        String status;
        Integer statusCode;
        String result = '';
        // old webservice endpoint (default)
        String endpoint = 'https://portal.imagotag.com/api/v1/query/' + sesId + '.json?token=' + Label.TokenAPIWarranty;
        if (newApi == true) {
            System.debug('***********  New API *********** ');
            // new api endpoint is called
            // retrieve api data From custom settings
            warranty_api__c warrantyApiSettings = [SELECT id, host__c, token__c FROM warranty_api__c LIMIT 1];
            system.debug(warrantyApiSettings);
            if(warrantyApiSettings == null || warrantyApiSettings.host__c == '' || warrantyApiSettings.token__c == '') {
                return '{error :{errorCode : 1000, errormessage : webservice settings are not set}}';
            }
            // enpoint dev exemple : 
            // https://supitfrcprdapidiflow01.azure-api.net/warranty/getwarranty/A94A4C20?subscription-key=274f30f4575944099da4b60b8823629d
            endpoint = warrantyApiSettings.host__c + '/warranty/getwarranty/' + sesId + '?subscription-key=' + warrantyApiSettings.token__c; 
        }

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setTimeout(60000);
        request.setMethod('GET');
        HttpResponse response = new HttpResponse();       
        try {
            response = http.send(request);
            system.debug('HTTP RESPONSE');
            result = response.getBody();
            if( response.getStatusCode() != 200) {
                result = '{error :{errorCode :' + response.getStatus() + ', errormessage : ' + response.getStatus() + '}}';
            }
        } catch(System.CalloutException e) {
            System.debug('Error: ' + e);
            result = '{error :{errorCode :'+e.getCause()+', errormessage : '+e.getStackTraceString() + '}}';
        }
        return result;
    }


    @AuraEnabled
    public static RecordType getUserInfo(){
        RecordType rec = new RecordType();
        Set<Id> setProfileId = new Set<Id>();
        for(Profile prof : [SELECT Id FROM Profile WHERE Name LIKE '%Community%']){
            setProfileId.add(prof.Id);
        }
        if(setProfileId.contains(userInfo.getProfileId())){
            Id currentUserId = userInfo.getUserId();
            User currentUser = [SELECT Account.RecordTypeId FROM User WHERE Id =: currentUserId][0];
            Id recordId = currentUser.Account.RecordTypeId;
            rec = [SELECT Name FROM RecordType WHERE sObjectType = 'Account' AND Id =: recordId][0];
        }
        return rec;
    }

    /**
     * Method to calculate the Warranty date for HF
     * @author              Corentin Bernier - iCom Cloud
     * @param labelId       The Label Id
     * @return              The message to display
     * @since               1.2.0
     */
    @AuraEnabled
    public static String checkHFWarrantyWithLabel(String labelId){
        String yLetter = labelId.substring(0, 1).toUpperCase();
        String week = labelId.substring(1, 3);
        return checkHFWarranty(yLetter, week, isPartner());
    }
    
    @AuraEnabled
    public static String checkHFWarranty(String yLetter, String week, Boolean isPartner){
        String msg = '';
        try{
            Map<Integer,String> monthNameMap=new Map<Integer, String>{1 => Label.January, 2=> Label.February, 3=> Label.March, 4=> Label.April, 5=> Label.May,
                                                                    6=> Label.June, 7=> Label.July , 8=> Label.August, 9=> Label.September ,10=> Label.October,
                                                                    11=> Label.November, 12=> Label.December};

            SESImagotag_RMA__c yRuleSetting = SESImagotag_RMA__c.getValues(yLetter);
            String yearValue = yRuleSetting.Year__c;
            Integer yearInt = Integer.valueOf(yearValue);
            Integer weekNumber = Integer.valueOf(week);
            /*if(isPartner){
                System.debug('1');
                if(weekNumber + 39 < 53){
                    weekNumber += 39;
                }
                else{
                    yearInt += 1;
                    weekNumber = weekNumber + 39 - 52;
                }
            }
            else{
                System.debug('2');
                if(weekNumber + 26 < 53){
                    weekNumber += 26;
                }
                else{
                    yearInt += 1;
                    weekNumber = weekNumber + 26 - 52;
                }
            }*/
            if(isPartner){
                if(weekNumber - 39 > 0){
                    weekNumber -= 39;
                }
                else if(weekNumber - 39 == 0){
                    weekNumber = 1;
                }
                else{
                    yearInt -= 1;
                    weekNumber = weekNumber + 39 - 52;
                }
            }
            else{
                if(weekNumber - 26 > 0){
                    weekNumber -= 26;
                }
                else if(weekNumber - 26 == 0){
                    weekNumber = 1;
                }
                else{
                    yearInt -= 1;
                    weekNumber = weekNumber + 26 - 52;
                }
            }
            System.debug('yeraInt ' + yearInt);
            // build a Date instance of January 1 of that year, then of the start of that week...
            Date startOfYear = Date.newInstance(yearInt, 1, 1);
            Date startOfWeekOne = startOfYear.toStartOfWeek();
            Date startOfWeekFour = startOfWeekOne.addDays(weekNumber * 7);
            String Month = monthNameMap.get(startOfWeekFour.month());
            Date apiDate = date.newInstance(yearInt, startOfWeekFour.month(), 15);
            startOfWeekFour = startOfWeekFour.addDays(-7);
            //integer numberMonthsDue = startOfWeekFour.monthsBetween(Date.today());
            integer numberMonthsDue = apiDate.monthsBetween(Date.today());
            /*if( numberMonthsDue > 0){
                numberMonthsDue -=1 ;
            }*/
            //Integer actualYear = Date.Today().Year();
            //Integer nbrYears = actualYear - integer.valueof(yearValue);
            
            Integer nbrYears = numberMonthsDue/12;
            System.debug('nbrYears '+ nbrYears);
            numberMonthsDue = integer.valueof(math.abs(math.mod(numberMonthsDue, 12)));
            
            Date startOfNextYear = Date.newInstance(yearInt+1, 1, 1);
            integer yearWeeks = startOfYear.daysBetween(startOfNextYear)/7;

            system.debug('noYears: '+nbrYears);
            system.debug('year: '+yearValue); 
            system.debug('date: '+startOfWeekFour);
            system.debug('yearWeeks: '+yearWeeks); 
            
            if(nbrYears>0){
                List<String> parameters = new List<String>();
                parameters.add(string.valueOf(Month));
                parameters.add(string.valueOf(yearInt));
                parameters.add(string.valueOf(nbrYears));
                parameters.add(string.valueOf(numberMonthsDue));
                //parameters.add(string.valueOf(startOfWeekFour.format()));
                msg = String.format(Label.Z_RMA_HFMsg, parameters);
            }
            else{
                List<String> parameters = new List<String>();
                parameters.add(string.valueOf(Month));
                parameters.add(string.valueOf(yearInt));
                parameters.add(string.valueOf(numberMonthsDue));
                //parameters.add(string.valueOf(startOfWeekFour.format()));
                msg = String.format(Label.Z_RMA_HFMsg2, parameters);
            }
            //msg = 'This item was produced in year of '+yearInt+' in cw '+weekNumber+'. \n In '+nbrYears+' year(s) and '+numberMonthsDue+' month(s). \n Date: '+startOfWeekFour.format()+'.';
        }
        catch(exception e){
            msg = label.Z_RMA_SNNotDefined;
        }
        return msg;
    }
    @AuraEnabled
    public static String ManageDateNewApi(DateTime apiStartDateTime, DateTime apiEndDateTime){

        String msg = '';

        List<String> parameters = new List<String>();
        parameters.add(apiStartDateTime.format().split(' ')[0]);
        parameters.add(apiEndDateTime.format().split(' ')[0]);
        system.debug(parameters);
        msg = String.format(Label.Z_RMA_HFMsg_New, parameters);
        return msg;
    }

    @AuraEnabled
    public static String ManageDate(DateTime apiDateTime, Boolean isPartner){

        Map<Integer,String> monthNameMap=new Map<Integer, String>{1 => Label.January, 2=> Label.February, 3=> Label.March, 4=> Label.April, 5=> Label.May,
            6=> Label.June, 7=> Label.July , 8=> Label.August, 9=> Label.September ,10=> Label.October,
            11=> Label.November, 12=> Label.December};

            
        System.debug('apidatetime '+ apiDateTime);
        String msg = '';
        Datetime warrantyStartDate;
        if(isPartner){
            warrantyStartDate = apiDateTime.addMonths(6);
        }
        else{
            warrantyStartDate = apiDateTime.addMonths(3);
        }
        //Date apiDate = date.newInstance(warrantyStartDate.year(), warrantyStartDate.month(), warrantyStartDate.day());
        Date apiDate = date.newInstance(warrantyStartDate.year(), warrantyStartDate.month(), 15);
        Date todayDate = Date.today();
        String stringNbYear = String.valueOf(Math.abs(todayDate.monthsBetween(apiDate) / 12));
        String stringNbMonth = String.valueOf(Math.abs(Math.mod(todayDate.monthsBetween(apiDate), 12)));
        //String monthName = warrantyStartDate.format('MMMM');
        String monthName = monthNameMap.get(warrantyStartDate.month());
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
        return msg;
    }

    @AuraEnabled
    public static String checkLFWarranty(String week)
    {
        Map<Integer,String> monthNameMap=new Map<Integer, String>{1 => Label.January, 2=> Label.February, 3=> Label.March, 4=> Label.April, 5=> Label.May,
                                                                    6=> Label.June, 7=> Label.July , 8=> Label.August, 9=> Label.September ,10=> Label.October,
                                                                    11=> Label.November, 12=> Label.December};
		
        Integer weekNumber = Integer.valueOf(week); //878
        system.debug('weekNumber ' + weekNumber);
        Date startOfYear = Date.newInstance(2010, 1, 4); //2010-01-04
        system.debug('startOfYear ' + startOfYear);
        Date startOfWeekOne = startOfYear.toStartOfWeek(); //2010-01-04
        system.debug('startOfWeekOne ' + startOfWeekOne);
        Date startOfWeekFour = startOfWeekOne.addDays(weekNumber * 7); //2026-11-02
        system.debug('startOfWeekFour ' + startOfWeekFour);
        String Month = monthNameMap.get(startOfWeekFour.month()); // november
        system.debug('Month: ' + Month);
        
        startOfWeekFour = startOfWeekFour.addDays(-7);
        system.debug('startOfWeekFour ' + startOfWeekFour);
        
        integer numberMonthsDue = startOfWeekFour.monthsBetween(Date.today());
        system.debug('numberMonthsDue ' + numberMonthsDue);
        
        //Integer actualYear = Date.Today().Year();
        //Integer nbrYears = actualYear - startOfWeekFour.year();
        
        Integer nbrYears = numberMonthsDue/12;
        system.debug('nbrYears ' + nbrYears);
        numberMonthsDue = math.mod(numberMonthsDue, 12);
        system.debug('numberMonthsDue ' + numberMonthsDue);
        if(nbrYears>0)
        {
            List<String> parameters = new List<String>();
            parameters.add(Month + ' ' + startOfWeekFour.year());
            parameters.add(string.valueOf(nbrYears));
            parameters.add(string.valueOf(numberMonthsDue));
            //parameters.add(string.valueOf(startOfWeekFour.format()));
            
            return String.format(Label.Z_RMA_LFMsg, parameters);
        }
        else
        {
            List<String> parameters = new List<String>();
            parameters.add(Month + ' ' + startOfYear.year());
            parameters.add(string.valueOf(numberMonthsDue));
            //parameters.add(string.valueOf(startOfWeekFour.format()));
            
            return String.format(Label.Z_RMA_LFMsg2, parameters);
        }
        
       //return 'This item was produced in the week '+week+' after the 4th January 2010. \n In '+nbrYears+' year(s) and '+numberMonthsDue+' month(s). \n Date: '+startOfWeekFour.format()+'.';
        
    }

    /**
     * Wrapper for the web service response
     */
    class WrapperResponseNewWebService {
        String metadata;
        String SerialNumber;
        String DeliveryNumber;
        String ShipToNumber;
        String Material;
        String ShipToName;
        String SalesOrder;
        String MaterialDesc;
        String Quantity;
        String UoM;
        String WarrantyStartDate;
        String WarrantyEndDate;
        String NetValue;
        
    }

        /**
     * Wrapper for the web service response
     */
    public class WrapperResponse {
        WrapperLabel label;
    }

    /**
     * Wrapper for the web service response
     */
    public class WrapperLabel{
        String label_id;
        String part_number;
        Datetime production_time;
        String serial;
    }
}
