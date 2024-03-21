({
	doInit: function (component, event, helper) {
        console.log('### LC_WebStore_OrderHelper - doInit');
		// console.log('### helper')
		var action = component.get("c.getConnectedUser");

		action.setCallback(this, function (response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				// console.log('doInit - getConnectedUser - response.getReturnValue', response.getReturnValue());
				component.set("v.isADVPermissionSet", response.getReturnValue().isADVPermissionSet);
				var connectedUser = response.getReturnValue().connectedUser;
				// console.log('##MZ connected user : ' + connectedUser.Name);
				var isWithOppOver70 = response.getReturnValue().isWithOppOver70; // added by maribelle 06.02.2020
				component.set("v.isWithOppOver70", isWithOppOver70); // added by maribelle 12.02.2020                
				// check Credit Hold
				// set Default Billing Account/ Contact
				// console.log('doInit - connectedUser.hasOwnProperty(ContactId) : ', connectedUser.hasOwnProperty('ContactId'));
				if (connectedUser.hasOwnProperty('ContactId')) {
					// console.log('doInit - ContactId ', connectedUser.ContactId);
					// console.log('doInit - acCore__CreditHold__c ', connectedUser.Contact.Account.acCore__CreditHold__c);
					// console.log('doInit - AccountId ', connectedUser.Contact.AccountId);
					// console.log('doInit - Account.Name ', connectedUser.Contact.Account.Name);
					// console.log('doInit - user id ', connectedUser.Id);


					var isCreditHolder = connectedUser.Contact.Account.acCore__CreditHold__c;
					var accRecType = connectedUser.Contact.Account.RecordType.DeveloperName;
					var parentAcc = connectedUser.Contact.Account.ParentId;
					var isERPInactive = connectedUser.Contact.Account.ERP_InActive__c;
					var accNiveau = connectedUser.Contact.Account.Niveau__c;

					var creditStatus = connectedUser.Contact.Account.Credit_Status__c;
					// console.log('doInit - creditStatus ', creditStatus);
					// console.log('doInit - accNiveau ', accNiveau);
					// console.log('doInit - accRecType ', accRecType);
					// console.log('doInit - ERP inactive : ', isERPInactive);

					//TMACKH - ticket 51 / 58
					//if(isCreditHolder == true || ( accRecType == 'Prospect' && accNiveau != 'Groupe') || isERPInactive == true)
					if (creditStatus != null || (accRecType == 'Prospect' && accNiveau != 'Groupe')) {
						component.set("v.isVisibleTabset", false);
					}
					else 		//if (isCreditHolder==false || isCreditHolder==null)
					{
						component.set("v.isVisibleTabset", true);
					}
					component.set("v.BillToAccount", connectedUser.Contact.AccountId);
					component.set("v.currency", connectedUser.Contact.Account.CurrencyIsoCode);
					component.set("v.SelectedBillToContact", connectedUser.ContactId);
					component.set("v.RealSelectedBillToContact", connectedUser.ContactId);
					component.set("v.SelectedBillToCon", connectedUser.Contact);
					component.set("v.RealSelectedBillToCon", connectedUser.Contact);
					var childCmp = component.find("ChildAccount");
					childCmp.setBillToAccount();

					var leftCurrencies = $A.get("{!$Label.c.Z_LC_LeftCurrencies}").split(",");
					// console.log('###leftCurrencies: ' + leftCurrencies);
					//alert('currency '+ component.get("v.currency"));
					//var isLeft = leftCurrencies.includes(component.get("v.currency"));
					if (leftCurrencies.indexOf(component.get("v.currency")) > -1) {
						component.set("v.isLeft", true);
					}
					else {
						component.set("v.isLeft", false);
					}

					//alert('isLeft: '+component.get("v.isLeft"));
				}
				else {
					component.set("v.isVisibleTabset", true);
				}
				// check profile of user connected
				var profileName = connectedUser.Profile.Name;
				// console.log('profileName ' + profileName);
				if (profileName === $A.get("{!$Label.c.Z_LC_AddProduct_ProfileName1}") || profileName === $A.get("{!$Label.c.Z_LC_AddProduct_ProfileName}")) {
					component.set("v.isADV", true);
				} if (profileName === $A.get("{!$Label.c.Z_LC_AddProduct_ProfileName1}")) {
					component.set("v.isSystemAdmin", true);
				}
				// console.log("##MZ before createLog Call");
				this.createLog(component, event, helper); // Added by Maribelle ZARAZIR - US-208
			}
		});

		$A.enqueueAction(action);
		component.set("v.Spinner", false);
	},

	getAddress: function (component, attr, aId) {
        console.log('### LC_WebStore_OrderHelper - getAddress');
		// console.log('call getAddress');
		// console.log('atr ' + attr);
		// console.log('aId ' + aId);
		var action = component.get("c.getAddressesByAccount");
		action.setParams({
			accountId: aId
		});
		action.setCallback(this, function (response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				var oRes = response.getReturnValue();
				// console.log('@ ' + oRes.Tech_PO_Number__c);
				if (attr === undefined || attr === "shipto") {
					component.set("v.ShipToAcct", oRes);
					component.set("v.ShipToAccount", aId);
				}
				else if (attr === "billto") {
					component.set("v.BillToAcct", oRes);
					component.set("v.BillToAccount", aId);
					component.set("v.PONumberFlag", oRes.Tech_PO_Number__c);
				}
			}
			else {
				alert('Error...');
			}
		});
		$A.enqueueAction(action);
	},

	// Added by Maribelle ZARAZIR for US-208
	createLog: function (component, event, helper) {
        console.log('### LC_WebStore_OrderHelper - createLog');
		// console.log('##MZ in createLog!!');
		// console.log('isVisibleTabset = ' + component.get("v.isVisibleTabset"));
		var action = component.get("c.createCommunityLog");
		action.setParams({
			isVisibleTabset: component.get("v.isVisibleTabset")
		});
		action.setCallback(this, function (response) {
			var state = response.getState();
			// console.log('state : ' + response.getState());
			if (state == "SUCCESS") {
				var commLogId = response.getReturnValue();
				component.set("v.communityLogId", commLogId);
				// console.log('Community Log created - Id = ' + commLogId);
			}
		});
		$A.enqueueAction(action);
	},

	// Added by Maribelle ZARAZIR - US-300
	checkTab1: function (component, event, helper) {
        console.log('### LC_WebStore_OrderHelper - checkTab1');
		var shipAcc = component.get("v.ShipToAcct");
		var billAcc = component.get("v.BillToAcct");
		//component.get("v.isWithOppOver70") || 
		// TMASESIMAGOTAG-44 CKH Begin

		var isWithOppOver70 = (shipAcc.OpenOpportunitieswithprobability70__c > 0 && shipAcc.ParentId == null && shipAcc.RecordType.Name == 'Potential Partner')
			|| (billAcc.OpenOpportunitieswithprobability70__c > 0 && billAcc.ParentId == null && billAcc.RecordType.Name == 'Potential Partner');
		// console.log('in check tab 1 , opp over 70? : ' + isWithOppOver70);
		if (isWithOppOver70) {
			//alert($A.get("{!$Label.c.Z_LC_WebStore_OpportunityOver70}"));
			alert($A.get("{!$Label.c.Z_LC_WebStore_Potential_Partner}"));
			component.set("v.selTabId", 'tab1');
		}
		// TMASESIMAGOTAG-44 CKH End
	}


	/*,
    
	createCPQQuote : function (component, event, helper)
	{
		//Test Creation of Quote and Quote lines in CPQ
		console.log("##in createCPQQuote");
		var shipToId = component.get("v.ShipToAccount");
		var billToId = component.get("v.BillToAccount");
		if(shipToId&&billToId)
		{
			// function to put in helper
			console.log("##call createCPQQuote");
			var action = component.get("c.createCPQQuoteandQuoteLines");
			action.setParams({
				actId : billToId
			});
			action.setCallback(this, function(response) {
				var state = response.getState();
				if (state === "SUCCESS"){
					var oRes = response.getReturnValue();
					if(oRes)
					{
						console.log('oRes '+oRes);
						component.set("v.cpqQuoteId", oRes);
						component.set("v.Spinner", false);
						component.set("v.selTabId" , 'tab2');
					}
				}
				else{
					alert('Error...');
					component.set("v.Spinner",false);
				}
			});
			$A.enqueueAction(action);
		}
	}*/
})