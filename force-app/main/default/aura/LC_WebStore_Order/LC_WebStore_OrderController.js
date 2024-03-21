({
	doInit: function (component, event, helper) {
        console.log('### LC_WebStore_OrderController - doInit');
		// console.log('### controller ');
		var spinner = component.find("mySpinner");
		$A.util.toggleClass(spinner, "slds-hide");
		component.set("v.Spinner", true);
		helper.doInit(component, event, helper);
	},

	next: function (component, event, helper) {
        console.log('### LC_WebStore_OrderController - next');
		//Get the current selected tab value
		var currentTab = component.get("v.selTabId");
		// console.log('currentTab ' + currentTab);

		if (currentTab == 'tab1') {
			// DMND0002113
			// Added by El Mehdi MAJD - start
			var BillToAccountcreditStatus = component.get("v.BillToAccountcreditStatus");
			if (!component.get("v.transitionModalAlreadyClosed") && BillToAccountcreditStatus && !BillToAccountcreditStatus.includes($A.get("$Label.c.NoCreditHoldStatus"))) {
				component.set("v.displayTransitionModal", true);
			}
			else {
				component.set("v.selTabId", 'tab2');
			}
			// Added by El Mehdi MAJD - end
			/*var spinner = component.find("mySpinner");
			$A.util.toggleClass(spinner, "slds-hide");
			component.set("v.Spinner",true);
			console.log('go to  createCPQQuote');
			helper.createCPQQuote(component, event, helper);
			console.log('end  createCPQQuote');
			//////////////////////////////////////////////*/
		}
		else if (currentTab == 'tab2') {
			component.set("v.selTabId", 'tab3');
		} else if (currentTab == 'tab3') {
			component.set("v.selTabId", 'tab3bis');
		} else if (currentTab == 'tab3bis') {
			component.set("v.selTabId", 'tab4');
		}
	},

	/*setDefaultTab1 : function(component, event, helper) {
		var childCmp = component.find("ChildAccount");
		childCmp.setDefaultTab1();
	},*/

	checkTab1: function (component, event, helper) {
        console.log('### LC_WebStore_OrderController - checkTab1');
		// console.log('in checkTab1 ');

		var shipToId = component.get("v.ShipToAccount");
		var billToId = component.get("v.BillToAccount");
		var shipAcc = component.get("v.ShipToAcct");
		var billAcc = component.get("v.BillToAcct");
		if (shipToId && billToId) {
			helper.checkTab1(component, event, helper); // Added by Maribelle ZARAZIR - US-300

			//component.set("v.selTabId" , 'tab2');
			// call fucntion getCPQQuoteLines
			/*console.log('go to  getCPQUnitPrices');
			var childCmp = component.find("ChildSelect");
			childCmp.getCPQUnitPrices();*/
		}
		else {
			alert($A.get("{!$Label.c.Z_LC_Account_Alert1}"));
			component.set("v.selTabId", 'tab1');
		}
	},

	checkTab3: function (component, event, helper) {
        console.log('### LC_WebStore_OrderController - checkTab3');
		// console.log('in checkTab3');
		var childCmp = component.find("ChildCart");
		childCmp.refreshTotals();

		// Added by Maribelle ZARAZIR - US-300 - on 12.02.2020
		var shipToId = component.get("v.ShipToAccount");
		var billToId = component.get("v.BillToAccount");
		if (shipToId && billToId) {
			helper.checkTab1(component, event, helper); // Added by Maribelle ZARAZIR - US-300
		}
	},

	checkTab3bis: function (component, event, helper) {
        console.log('### LC_WebStore_OrderController - checkTab3bis');
		// console.log('in checkTab3bis');

		// Added by Maribelle ZARAZIR - US-300 - on 12.02.2020
		var shipToId = component.get("v.ShipToAccount");
		var billToId = component.get("v.BillToAccount");
		if (shipToId && billToId) {
			helper.checkTab1(component, event, helper); // Added by Maribelle ZARAZIR - US-300
		}

		var currentTab = component.get("v.selTabId");
		if (currentTab != 'tab1') {
			var a = component.get('c.checkTab1');
			$A.enqueueAction(a);
		}
		currentTab = component.get("v.selTabId");
		if (currentTab != 'tab1') {

			var shipToId = component.get("v.ShipToAccount");
			var billToId = component.get("v.BillToAccount");


			if (shipToId && billToId) {
				var childCmp = component.find("ChildOther");
				childCmp.init();
			}
			else {
				alert($A.get("{!$Label.c.Z_LC_Account_Alert1}"));
				component.set("v.selTabId", 'tab1');
			}
		}
	},

	checkTab4: function (component, event, helper) {
        console.log('### LC_WebStore_OrderController - checkTab4');
		// console.log('in checkTab4');

		// Added by Maribelle ZARAZIR - US-300 - on 12.02.2020
		var shipToId = component.get("v.ShipToAccount");
		var billToId = component.get("v.BillToAccount");
		var realBillToId = component.get("v.RealBillToAccount");
		if (shipToId && billToId) {
			helper.checkTab1(component, event, helper); // Added by Maribelle ZARAZIR - US-300
		}

		var currentTab = component.get("v.selTabId");
		if (currentTab != 'tab1') {

			var shipToContactId = component.get("v.SelectedShipToContact");
			var billToContactId = component.get("v.SelectedBillToContact");

			//TMACKH - ticket 53
			var RealbillToContactId = component.get("v.RealSelectedBillToContact");

			var RealbillToId = component.get("v.RealBillToAccount");
			var PONumber = component.get("v.PONumber");
			var PONumberFlag = component.get("v.PONumberFlag");

			// console.log('PONumberFlag ' + PONumberFlag);
			// console.log('PONumber ' + PONumber);
			// console.log('billToContactId ' + billToContactId);
			// console.log('billToId ' + billToId);
			// console.log('shipToId ' + shipToId);
			// console.log('RealbillToId ' + RealbillToId);
			if (shipToId && billToId) {
				//TMACKH - ticket 53
				if (shipToContactId && billToContactId && RealbillToContactId && realBillToId) {
					if (PONumberFlag && !PONumber) {
						alert($A.get("{!$Label.c.Z_LC_Account_Alert2}"));
						component.set("v.selTabId", 'tab3bis');
					}
					else if (PONumberFlag && !PONumber.trim()) {
						alert($A.get("{!$Label.c.Z_LC_Account_Alert2}"));
						component.set("v.selTabId", 'tab3bis');
					}
					else {
						component.set("v.selTabId", 'tab4');
						var childCmp = component.find("Confirm");
						//childCmp.init();
						childCmp.refreshTotals();
					}
				}
				else {
					alert($A.get("{!$Label.c.Z_LC_Account_Alert1}"));
					component.set("v.selTabId", 'tab3bis');
				}
			}
			else {
				alert($A.get("{!$Label.c.Z_LC_Account_Alert1}"));
				component.set("v.selTabId", 'tab1');
			}
		}
	},

	back: function (component, event, helper) {
        console.log('### LC_WebStore_OrderController - back');
		//Get the current selected tab value  
		var currentTab = component.get("v.selTabId");

		if (currentTab == 'tab2') {
			component.set("v.selTabId", 'tab1');
		} else if (currentTab == 'tab3') {
			component.set("v.selTabId", 'tab2');
		} else if (currentTab == 'tab3bis') {
			component.set("v.selTabId", 'tab3');
		} else if (currentTab == 'tab4') {
			component.set("v.selTabId", 'tab3bis');
		}
	},

	createCPQQuote: function (component, event, helper) {
        console.log('### LC_WebStore_OrderController - createCPQQuote');
		//Test Creation of Quote and Quote lines in CPQ
		// console.log('##call createCPQQuote');
		var shipToId = component.get("v.ShipToAccount");
		var billToId = component.get("v.BillToAccount");
		if (shipToId && billToId) {
			// function to put in helper
			var action = component.get("c.createCPQQuoteandQuoteLines");
			action.setParams({
				actId: billToId
			});
			action.setCallback(this, function (response) {
				var state = response.getState();
				if (state === "SUCCESS") {
					var oRes = response.getReturnValue();
					if (oRes) {
						console.log('oRes ' + oRes);
						component.set("v.cpqQuoteId", oRes);
						component.set("v.selTabId", 'tab2');
					}
				}
				else {
					alert('Error...');
				}
				component.set("v.Spinner", false);
			});
			$A.enqueueAction(action);
		}
		component.set("v.Spinner", false);
		///////////////////////////////////////////////
	},

	// Added by Maribelle ZARAZIR for US-319
	// #RelocateValidateOrder
	callValidateOrderMethod: function (component, event, helper) {
        console.log('### LC_WebStore_OrderController - callValidateOrderMethod');
		var ConfirmChildComponent = component.find('Confirm');
		ConfirmChildComponent.validateOrderMethod();
	},

	//Added on 10/06/2020
	//Disable currency picklist on screen 1 when user goes to another screen
	tabChanged: function (component, event, helper) {
        console.log('### LC_WebStore_OrderController - tabChanged');
		var selTabId = component.get("v.selTabId");
		if (selTabId != 'tab1' && component.get("v.currencyReadOnly") == false) {
			component.set("v.currencyReadOnly", true);
		}
	},
	// DMND0002113
	// Added by El Mehdi MAJD - start 
	closeTransitionModal: function (component, event, helper) {
        console.log('### LC_WebStore_OrderController - closeTransitionModal');
		component.set("v.displayTransitionModal", false);
		component.set("v.transitionModalAlreadyClosed", true);
		component.set("v.selTabId", 'tab2');
	},
	SoldToAccountChange: function (component, event, helper) {
        console.log('### LC_WebStore_OrderController - SoldToAccountChange');
		var soldToAccount = component.get("v.BillToAcct");
		var oldSelectedSoldToAcctId = component.get("v.oldSelectedSoldToAcctId");
		if (soldToAccount.Id) {
			if (soldToAccount.Id != oldSelectedSoldToAcctId) {
				var action = component.get("c.getCreditStatus");
				action.setParams({
					accountId: soldToAccount.Id
				});
				action.setCallback(this, function (response) {
					var state = response.getState();
					if (state === "SUCCESS") {
						var oRes = response.getReturnValue();
						// console.log('oRes ' + oRes);
						component.set("v.BillToAccountcreditStatus", oRes);
						component.set("v.oldSelectedSoldToAcctId", soldToAccount.Id);
						component.set("v.transitionModalAlreadyClosed", false);
					}
					else {
						alert('Error in getting sold to account credit status');
						// console.log('Error in getting sold to account credit status');
					}
				});
				$A.enqueueAction(action);
			}
		}
	}
	// Added by El Mehdi MAJD - end 
})