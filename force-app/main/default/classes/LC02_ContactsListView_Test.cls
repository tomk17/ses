/**
 * Testing class for LC02_ContactsListView
 * @testClassFor LC02_ContactsListView
 *
 * Date       | Author								| Version | Coverage | Changes
 * ---------- | ----------------------------------- |-------- |--------- | -----------------------------------------
 * 2019-08-20 | Mohamed HUSSEIN - EI-Technologies	|  1.0.0  |   ??%    | Initial version.
 * 2023-06-15 | Corentin Bernier - iCom Cloud		|  1.0.0  |   82%    | Initial version.
 */
@isTest
public class LC02_ContactsListView_Test {
	@isTest
	static void test_InviteContactsFromThePortal() {
		Profile admin = [
			SELECT Id, Name
			FROM Profile
			WHERE Name = 'System Administrator'
			LIMIT 1
		];
		User newUser = new User(
			FirstName = 'qqq',
			LastName = 'qqq',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			TimeZoneSidKey = 'America/Los_Angeles',
			Alias = 'aaa',
			EmailEncodingKey = 'UTF-8',
			Username = 'qqqq.qqqq@portal-ses-imagotag.force.com.Test',
			Email = 'qqq.qqq@ddd.ggg.lll',
			ProfileId = admin.Id,
			acCore__SalesRepCode__c = 'eit'
		);
		insert newUser;

		Brand__c brand = Test_Utils_EI.createBrand('testBrand', '1234567');
		Account a = Test_Utils_EI.createProspectAccount('testAct1', 'Group', brand, 'INDEPENDANT', 'DIRECT', 'Automotive');
		a.ShippingCountry = 'France';
		insert a;
		Contact c = Test_Utils_EI.createCustomerContact('contactNumber1', 'contact1', a);
		insert c;

		Contact c2 = Test_Utils_EI.createCustomerContact('AnotherTEst', 'contactAnotherTEst', a);
		c2.Email = 'fff@fff.fff';
		insert c2;

		System.Test.startTest();

		System.runAs(newUser) {
            String idAcc = LC02_ContactsListView.getAccountId();
			String testtt = LC02_ContactsListView.sanitizeQueryString(null);
			testtt = LC02_ContactsListView.sanitizeQueryString('  ');
			LC02_ContactsListView.fetchContactWrapper('%', '');
			LC02_ContactsListView.inviteContactsToPortal(new List<Contact>{ c });

			LC02_ContactsListView.inviteContactsToPortal(new List<Contact>{ c2 });
			EmailTemplate et = SuperUser.getWelcomeEmailTemaplate()[0];
			/*Network myNetwork = LC02_ContactsListView.getMyNetwork();
            LC02_ContactsListView.getEmailWelcomeBody(new User(Id = UserInfo.getUserId(), FirstName='first', Username = 'test@username.com'), 'String Email Body', myNetwork);
            
            Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(et.Id, null, null);
            email.setTemplateId(et.BrandTemplateId);         
            LC02_ContactsListView.sendEmailWelcome(c, 'body', 'subject',  email);
            
            Profile p = LC02_ContactsListView.getCommunityUserProfile();
            LC02_ContactsListView.createUsers(New List<Contact>{c}, p);
            LC02_ContactsListView.getUserName(c);
            String retval = LC02_ContactsListView.getAccountOwnerId();*/
		}
		System.Test.stopTest();
	}
}