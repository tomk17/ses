/* *******************************************************************************************************
 * Name               :                                                                                  *
 * Description        :                                                                                  *
 * Created Date       : 05.02.2021                                                                       *
 * Created By         : Joao Mota @Waeg                                                                  *
 * -----------------------------------------------------------------------------------------------       *
 * VERSION    AUTHOR                 DATE                                                                *
 *   1.0 -    Joao Mota   @Waeg      05-Feb-2021 Initial version                                         *
 ******************************************************************************************************* */
@isTest
private class B2B_CartTaxCalculationsImplTest {
    static List<String> skuList = new List<String>{'000000000000003684'};
    static List<Decimal> amountList = new List<Decimal>{5540};
    static List<Integer> quantityList = new List<Integer>{50};

    static String usernameBase = 'sesImagoTest@test.Imago.com.';
    static String username = usernameBase + Datetime.now().format('yyyyMMddHHmmssS');
    static String cartName = 'sesImagoTestCart';

    @testSetup static void setup() {        
        B2B_TestDataUtility.createWebCartContext2(username, cartName, skuList, amountList, quantityList);
    }

    @isTest static void cartTaxCalculationSuccess() {
        User u = [SELECT Id FROM User WHERE Username LIKE :usernameBase + '%' LIMIT 1];
        Id cartId = [SELECT Id FROM WebCart WHERE Name =:cartName].Id;
        System.debug('cartId in test : ' + cartId);
        List<CartItem> cartItems = [SELECT Id FROM CartItem WHERE cartId =:cartId];
        System.debug('cartItems in test : ' + cartItems);
        String taxLineDetail = '{ "id":"9999", "taxName":"IL STATE TAX", "rate":"2", "tax":"10", "taxableAmount":"5540", "taxCalculated":"10"}';
        String taxLine = '{"ref1":"'+cartItems[0].Id+'", "details":[' + taxLineDetail +']}';
        AvalaraHttpCalloutMock unitResponse = new AvalaraHttpCalloutMock(201,'SUCCESS','{"code":"123", "status":"commited", "totalAmount":"10", "totalTax":"2", "statusCode":"201", "lines":[' + taxLine + ']}','application/json');
        
        System.runAs(u) {
            sfdc_checkout.IntegrationInfo integrationInfo = new sfdc_checkout.IntegrationInfo();
                        
            Decimal shippingCost = 0;
            for(Integer i=0; i < amountList.size(); i++){
                shippingCost += amountList[0]*0.02;
            }
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, unitResponse);

            B2B_CartTaxCalculationsImpl taxCalculations = new B2B_CartTaxCalculationsImpl();

            sfdc_checkout.IntegrationStatus result = taxCalculations.startCartProcessAsync(integrationInfo, cartId);

            List<CartTax> cartTaxes = [SELECT Amount, TaxRate FROM CartTax WHERE Cartid =:cartId];
            
            System.debug('cartTaxes in test : ' + cartTaxes);

            System.assertEquals(sfdc_checkout.IntegrationStatus.Status.SUCCESS, result.status);
            System.assertEquals(1, cartTaxes.size());
            System.assertEquals(10, cartTaxes[0].Amount);
            System.assertEquals(2, cartTaxes[0].TaxRate);

            Test.stopTest();
        }
    }
    
}