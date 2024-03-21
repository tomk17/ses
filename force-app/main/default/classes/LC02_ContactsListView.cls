/**
 * Controller for the LC_Contacts_List_View
 * @usedIn aura/LC_Contacts_List_View
 * @testClass LC02_ContactsListView_Test
 *
 * Date       | Author								| Version | Changes
 * ---------- | ----------------------------------- |-------- | -----------------------------------------
 * 2019-08-20 | Mohamed HUSSEIN - EI-Technologies	|  1.0.0  | Initial version.
 * 2023-02-16 | Corentin Bernier - iCom Cloud		|  1.0.1  | DMND0004248 - Changes the call to inviteContactToPortal by adding a source
 * 2023-10-19 | Tom KOUAME - iCom Cloud				|  1.0.2  | INC0040498 - Filter inactive contacts on fetch contact request 
 */
public with sharing class LC02_ContactsListView {
	/**
	 * Method used to filter list of accounts
	 * @param aQuery A string of the query
	 * @return A string of the query sanitized
	 * @since 1.0.0
	 * @lastUpdated 1.0.0
	 */
	@AuraEnabled
	public static string sanitizeQueryString(String aQuery) {
		if (aQuery == null) {
			return '%';
		}

		String trimmedQuery = aQuery.trim();
		if (trimmedQuery.length() == 0) {
			return '%';
		}
		return '%' + trimmedQuery.replaceAll('\\W+', '%') + '%';
	}

	/**
	 * Method to fetch the contact and return them as Wrappers
	 * @param nameFilterString if a filter need to be applied
	 * @param order Name of the field to order the query by
	 * @return A list of contactListWrapper
	 * @since 1.0.0
	 * @lastUpdated 1.0.0
	 */
	@AuraEnabled
	public static List<contactListWrapper> fetchContactWrapper(String nameFilterString, String order) {
		List<contactListWrapper> lstcontactListWrapper = new List<contactListWrapper>();
		String composedFilter = sanitizeQueryString(nameFilterString);
		System.debug('LC02_ContactsListView - fetchContactWrapper - composedFilter : ' + composedFilter);
		System.debug('LC02_ContactsListView - fetchContactWrapper - order : ' + order);
		if (order == null || order.equalsIgnoreCase('')) {
			order = 'name';
		}
		User u = [SELECT id, contactId, LanguageLocaleKey FROM user WHERE id = :UserInfo.getUserId()];
		// query contact records and create 'contactListWrapper' class instance for each record.
		String conId = '';
		if (u.ContactId != null) {
			conId = u.ContactId;
		}
		// US-312 - MHU : remove ( id !=\''+conId+'\' and ) from query selection
		String q =
			'Select id,Firstname, Lastname, Name, AccountId, Account.name, Email, Phone,Final_contact_language__c, Is_Customer_Portal_User__c  ' +
			'From Contact where acCore__Inactive__c = false AND Name like \'' +
			composedFilter +
			'\' ' +
			'Order by ' +
			order +
			' ASC ' +
			'Limit 1000';
		System.debug('LC02_ContactsListView - fetchContactWrapper - q : ' + q);
		List<contact> contacts = Database.query(q);
		for (Contact contact : contacts) {
			// by default checkbox should be false
			lstcontactListWrapper.add(new contactListWrapper(false, contact));
		}
		System.debug('LC02_ContactsListView - fetchContactWrapper - lstcontactListWrapper.size() : ' + lstcontactListWrapper.size());
		return lstcontactListWrapper;
	}

	/**
	 * Class for the contact list Wrapper
	 * @since 1.0.0
	 * @lastUpdated 1.0.0
	 */
	/* wrapper class */
	public class contactListWrapper {
		@AuraEnabled
		public boolean isChecked { get; set; }
		@AuraEnabled
		public Contact objContact { get; set; }
		public contactListWrapper(boolean isChecked, Contact objContact) {
			this.isChecked = isChecked;
			this.objContact = objContact;
		}
	}

	/**
	 * Method to invite the contacts to the portal
	 * @param contacts A list of the contacts to invite
	 * @return A map of String with String
	 * @since 1.0.0
	 * @lastUpdated 1.0.1
	 */
	@AuraEnabled
	public static map<String, String> inviteContactsToPortal(List<Contact> contacts) {
        String msg = '';
		String typeMsg = '';
        List<String> conName = new List<String>();
        String concatNames = '';
		map<String, String> returnTypeMsg = new Map<string, string>();
        
        List<Contact> contactsAlreadyInvitedWithSameEmailAdress = new List<Contact>();
        Set<Id> idsContactToInvite = new Set<Id>();
        Set<String> idsContactAldreadyInvitedWithSameEmailAdress = new Set<String>();
        List<String> emailCon = new List<String>();
        
        for(Contact con : contacts){
            emailCon.add(con.Email);
            idsContactToInvite.add(con.Id);
        }
        
        for(Contact con : [SELECT Id, Email, Is_Customer_Portal_User__c FROM Contact WHERE Email IN :emailCon AND Id NOT IN :idsContactToInvite]){
            if(con.Is_Customer_Portal_User__c == true){
                idsContactAldreadyInvitedWithSameEmailAdress.add(con.Email);
            }
        }
        
        for(Contact con : contacts){
            if(idsContactAldreadyInvitedWithSameEmailAdress.contains(con.Email)){
                contactsAlreadyInvitedWithSameEmailAdress.add(con);
            } 
        }
        
        if(contactsAlreadyInvitedWithSameEmailAdress.size() > 0){
            
            for(Contact con : contactsAlreadyInvitedWithSameEmailAdress){
                conName.Add(con.Name);
            }
            
            if(conName.size() > 1){
                concatNames = String.join(conName, ' ; ');
            } 
            System.debug(conName[0]);
            
            if(conName.size() > 1){
                msg = 'L\'adresse email des contacts suivants : '+ concatNames +' sont déjà utilisés. Veuillez renseigner des adresses email différentes. Aucun email d\'invitation a été envoyé.';
            } else {
                msg = 'L\'adresse email du contact suivant : '+ conName[0] +' est déjà utilisé. Veuillez renseigner une adresse email différente. Aucun email d\'invitation a été envoyé.';
            }
            
            typeMsg = 'error';
            returnTypeMsg.put(typeMsg, msg);
            return returnTypeMsg;
        }    
		
		return InviteContactsInPortal.inviteContactToPortal(contacts, 'By colleague');
	}

	/**
	 * Method to get the current user account id
	 * @return A string of the account id
	 * @since 1.0.0
	 * @lastUpdated 1.0.0
	 */
	@AuraEnabled
	public static String getAccountId() {
		String retval = '';
		User currentUser = [
			SELECT Id, Contact.Account.OwnerId, ProfileId, ContactId, Name, Contact.AccountId
			FROM User
			WHERE Id = :UserInfo.getUserId()
		];
		if (currentUser.ContactId != null) {
			retval = currentUser.Contact.AccountId;
		}
		return retval;
	}
}