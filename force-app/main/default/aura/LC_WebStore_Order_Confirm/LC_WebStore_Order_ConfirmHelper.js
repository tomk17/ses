({
    doInitHelper: function (component, event) {
        console.log('### LC_WebStore_Order_ConfirmHelper - doInitHelper');
        // console.log('## doInitHelper ');
        var action = component.get("c.getUserLanguage");
        action.setCallback(this, function (response) {
            var state = response.getState();
            var result = response.getReturnValue();
            if (state === "SUCCESS") {
                component.set("v.userLanguage", result);
            }
        });
        $A.enqueueAction(action);

    },

    deleteFromCart: function (component, event) {
        console.log('### LC_WebStore_Order_ConfirmHelper - deleteFromCart');
    },

    refreshTotals: function (component, event) {
        console.log('### LC_WebStore_Order_ConfirmHelper - refreshTotals');
        // console.log("refreshTotals called");
        var OrderList = component.get("v.OrderList");
        // console.log("OrderList list : " + OrderList.length);
        var msg = component.get("v.fraisdeportmsg");
        // console.log("msg : " + msg);
        //var userCountry = component.get("v.ShipToAcct").ShippingCountry;         
        var shipToCountry;
        if (component.get("v.ShipToAcct").pw_cc__ShippingCountryLookup__c != null && component.get("v.ShipToAcct").pw_cc__ShippingCountryLookup__c != undefined) {
            var shipToCountry = component.get("v.ShipToAcct").pw_cc__ShippingCountryLookup__r.pw_cc__IsoCode_2__c;
            if (shipToCountry != 'FR') {
                component.set("v.hideTaxes", true);
            }
        }
        // console.log("shipToCountry " + shipToCountry);

        msg = "";
        var TotalHT = 0;
        if (component.get("v.beforeEdit") == true) {
            var fraisdeport = 0;
        }
        else {
            fraisdeport = component.get("v.fraisdeport");
        }
        var totalet = 0;
        if (component.get("v.tvaEdited") == true) {
            tva = component.get("v.tva");
        }
        else {
            var tva = 0;
        }
        var totalttc = 0;
        var price = 0;
        var poids = 0;
        var usedValues = '';
        var hasRailProduct = false;
        var railPalletNumber = 0;
        var eslPalletNumber = 0;
        var otherPalletNumber = 0;
        var totalRailQuantity = 0;
        for (var i = 0; i < OrderList.length; i++) {
            price = OrderList[i].unitPrice * OrderList[i].quantity;
            // console.log('price ' + price);
            OrderList[i].totalPrice = price;
            TotalHT += price;
            /*if(OrderList[i].objStoreConfig.Product__r.hasOwnProperty("ProductCode"))
            {
                var code = OrderList[i].objStoreConfig.Product__r.ProductCode;
                if(code.startsWith("1202"))
                {
                    msg=$A.get("{!$Label.c.Z_LC_Order_Confirm_fdp_msg}");
                }
            }*/
            //// console.log('Unit_Gross_Weight_kg__c '+OrderList[i].objStoreConfig.Product__r.Unit_Gross_Weight_kg__c);
            //if(OrderList[i].objStoreConfig.Product__r.hasOwnProperty("Unit_Gross_Weight_kg__c") && !OrderList[i].objStoreConfig.Product__r.CatalogFamilyCode__c.startsWith("12")) //added tkt 32 catalog family condition 04-07-2020

            //prendre en consideration la famille 12 dans le calcul des frais de port - TMACKH ticket 42 - 05/20/2020
            if (OrderList[i].objStoreConfig.Product__r.hasOwnProperty("Unit_Gross_Weight_kg__c")) {
                // console.log('Unit_Gross_Weight_kg__c ' + OrderList[i].objStoreConfig.Product__r.Unit_Gross_Weight_kg__c);
                poids += Number(OrderList[i].objStoreConfig.Product__r.Unit_Gross_Weight_kg__c * OrderList[i].quantity);
            }
            //Added on 03.06.2020 - v4
            //Check if the order contains rail products + calculate pallet number per category (method B)
            if (OrderList[i].objStoreConfig.Product__r.UnitPerPallet__c != null && OrderList[i].objStoreConfig.Product__r.UnitPerPallet__c != undefined) {
                if (OrderList[i].objStoreConfig.Product__r.CatalogFamilyCode__c.startsWith("12") &&
                    OrderList[i].objStoreConfig.Product__r.CatalogSubFamilyCode__c.startsWith("02")) {
                    hasRailProduct = true;
                    railPalletNumber += (OrderList[i].quantity / OrderList[i].objStoreConfig.Product__r.UnitPerPallet__c);
                    totalRailQuantity += OrderList[i].quantity;
                } else if (OrderList[i].objStoreConfig.Product__r.CatalogFamilyCode__c.startsWith("11")) {
                    eslPalletNumber += (OrderList[i].quantity / OrderList[i].objStoreConfig.Product__r.UnitPerPallet__c);
                } else {
                    otherPalletNumber += (OrderList[i].quantity / OrderList[i].objStoreConfig.Product__r.UnitPerPallet__c);
                }
            }
        }
        var roundedTotalHT = TotalHT.toFixed(2);
        TotalHT = Number(roundedTotalHT);
        railPalletNumber = Math.ceil(railPalletNumber);
        eslPalletNumber = Math.ceil(eslPalletNumber);
        otherPalletNumber = Math.ceil(otherPalletNumber);
        // console.log('railPalletNumber ' + railPalletNumber + 'eslPalletNumber ' + eslPalletNumber + 'otherPalletNumber ' + otherPalletNumber)
        //Calculate total pallet number
        var totalPalletNumber = railPalletNumber + eslPalletNumber + otherPalletNumber;
        // console.log('totalPalletNumber ' + totalPalletNumber)

        // console.log('TotalHT ' + TotalHT);
        // console.log('poids ' + poids);
        // console.log('msg ' + msg);
        component.set("v.poids", poids);
        //if(msg!="" || Math.round(Number(poids)) > 999 //commented tkt 32 07/04/2020
        //if(msg!="" || Math.round(Number(poids))===0 || Math.round(Number(poids)) > 999 || userCountry === undefined || userCountry === "")

        // TMACKH ticket 42 - 5/20/2020         
        if (msg != "" || Math.round(Number(poids)) > 999 || shipToCountry === undefined || shipToCountry === "") {
            // console.log('Frais de port non calculé');
            // console.log('ckh shipToCountry =' + shipToCountry);
            // console.log('ckh poids =' + Math.round(Number(poids)));
            if (shipToCountry === undefined || shipToCountry === "") {
                msg = $A.get("{!$Label.c.Z_LC_ConfirmOrder_IscoCodeMissing}");
            } else {
                msg = $A.get("{!$Label.c.Z_LC_Order_Confirm_fdp_msg}");
            }

            totalet = fraisdeport + TotalHT;
            if (component.get("v.tvaEdited") == true) {
                tva = component.get("v.tva");
            }
            else {
                tva = totalet * 20 / 100;
            }
            var roundedTVA = tva.toFixed(2);
            tva = Number(roundedTVA);
            var roundedTotalet = totalet.toFixed(2);
            totalet = Number(roundedTotalet);
            totalttc = totalet + tva;
            component.set("v.OrderList", OrderList);
            component.set("v.TotalHT", TotalHT);
            component.set("v.fraisdeport", fraisdeport);
            component.set("v.fraisdeportmsg", msg);
            component.set("v.totalet", totalet);
            component.set("v.tva", tva);
            component.set("v.totalttc", totalttc);
        }
        else {
            ////////////////////Calcul des Frais de Ports/////////////////////////////////
            // console.log('Calcul des Frais de Ports');
            // console.log('shipToCountry ' + shipToCountry);
            var action = component.get("c.getUserFreightCharges");
            action.setParams({
                country: shipToCountry
            });
            // Configure response handler
            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var currencyRate = component.get("v.currencyRate");
                    var retVal = response.getReturnValue();
                    if (retVal.notFound == true) {
                        msg = $A.get("{!$Label.c.Z_LC_ConfirmOrder_IscoCodeMissing}");
                        totalet = fraisdeport + TotalHT;
                        if (component.get("v.tvaEdited") == true) {
                            tva = component.get("v.tva");
                        }
                        else {
                            tva = totalet * 20 / 100;
                        }
                        var roundedTVA = tva.toFixed(2);
                        tva = Number(roundedTVA);
                        var roundedTotalet = totalet.toFixed(2);
                        totalet = Number(roundedTotalet);
                        totalttc = totalet + tva;
                        component.set("v.OrderList", OrderList);
                        component.set("v.TotalHT", TotalHT);
                        component.set("v.fraisdeport", fraisdeport);
                        component.set("v.fraisdeportmsg", msg);
                        component.set("v.totalet", totalet);
                        component.set("v.tva", tva);
                        component.set("v.totalttc", totalttc);
                    } else {
                        var palletFC = retVal.PaletFreightCharge;
                        var packageFC = retVal.PackageFreightCharge;
                        var palletA = 0;
                        var palletB = 0;
                        var packageA = 0;
                        var packageB = 0;
                        if (component.get("v.beforeEdit") == true) {
                            var palletTotalAmount = 0;
                            var packageTotalAmount = 0;
                            //Calculate Pallet Method
                            if (palletFC) {
                                palletA = palletFC.Coeffa__c;
                                palletB = palletFC.Coeffb__c;
                                // console.log('pallet FC a: ' + palletA + ' b: ' + palletB);
                                palletTotalAmount = Number(totalPalletNumber) * palletA + palletB;
                                //convert to used currency (freight charges are always in euro)                         
                                palletTotalAmount = palletTotalAmount * currencyRate;
                                var roundedTotalPallet = palletTotalAmount.toFixed(2);
                                palletTotalAmount = Number(roundedTotalPallet);
                            }

                            //check if order contains Rail products                       
                            if (hasRailProduct == true && totalRailQuantity > 80) {
                                //use Pallet Method                                                   
                                fraisdeport = palletTotalAmount;
                            } else {
                                //calculate Package Method then choose lowest amount
                                if (packageFC) {
                                    packageA = packageFC.Coeffa__c;
                                    packageB = packageFC.Coeffb__c;
                                    // console.log('package FC a: ' + packageA + ' b: ' + packageB);
                                    packageTotalAmount = Number(poids) * packageA + packageB;
                                    //Convert to used currency
                                    packageTotalAmount = packageTotalAmount * currencyRate;
                                    var roundedTotalPackage = packageTotalAmount.toFixed(2);
                                    packageTotalAmount = Number(roundedTotalPackage);
                                }
                                //compare pallet and packgae amount to get the lowest
                                fraisdeport = Math.min(palletTotalAmount, packageTotalAmount);
                            }
                        } else {
                            fraisdeport = component.get("v.fraisdeport");
                        }
                        usedValues = currencyRate + '_' + poids + '_' + packageA + '_' + packageB + '_' + packageTotalAmount + '_' + currencyRate + '_' + railPalletNumber
                            + '_' + eslPalletNumber + '_' + otherPalletNumber + '_' + palletA + '_' + palletB + '_' + palletTotalAmount;
                        component.set("v.fraisdeportUsedValues", usedValues);
                        /*var fc = response.getReturnValue();
                    // console.log('fc '+fc);
                    if(fc.a__c)
                    {
                        // console.log('2');
                        var a = fc.a__c;
                        var b = fc.b__c;
                        // console.log('fc a:'+a+' b: '+b);
                        // console.log('poids '+poids);
                        // console.log('Math.round(Number(poids) '+Math.round(Number(poids)));
                        //fraisdeport=(Math.round(Number(poids))*a) + b;
                        if(component.get("v.beforeEdit") == true){
                            fraisdeport=Number(poids)*a + b;
                            // console.log('fraisdeport before round '+fraisdeport);
                            var roundedString = fraisdeport.toFixed(2);
                            // console.log('roundedString '+roundedString);
                            fraisdeport = Number(roundedString);
                        }
                        else{
                            fraisdeport = component.get("v.fraisdeport");
                        }
                        // console.log('fraisdeport '+fraisdeport);
                    }
                    else
                    {
                        // console.log('3');
                        msg=$A.get("{!$Label.c.Z_LC_Order_Confirm_fdp_msg}");
                    }*/
                        totalet = fraisdeport + TotalHT;
                        var stringTotalet = totalet.toFixed(2);
                        totalet = Number(stringTotalet);
                        if (component.get("v.tvaEdited") == true) {
                            tva = component.get("v.tva");
                        }
                        else {
                            tva = totalet * 20 / 100;
                        }
                        var stringTva = tva.toFixed(2);
                        tva = Number(stringTva);
                        totalttc = totalet + tva;
                        var stringTotalTTC = totalttc.toFixed(2);
                        totalttc = Number(stringTotalTTC);
                        component.set("v.OrderList", OrderList);
                        component.set("v.TotalHT", TotalHT);
                        component.set("v.fraisdeport", fraisdeport);
                        component.set("v.fraisdeportmsg", msg);
                        component.set("v.totalet", totalet);
                        component.set("v.tva", tva);
                        component.set("v.totalttc", totalttc);
                    }
                } else {
                    // console.log('Problem getting Freight Charges, response state: ' + state);
                }
            });
            $A.enqueueAction(action);
            //////////////////////////////////////////////////////////////////////////////
        }

        // console.log("#MG TVA 2 :  " + component.get("v.tva"));
        // console.log("#MG fraisdeport 2 :  " + component.get("v.fraisdeport"));
        // console.log("#MG beforeEdit 2 :  " + component.get("v.beforeEdit"));
        // console.log("#MG tvaEdited 2 :  " + component.get("v.tvaEdited"));
    },

    setfraisdeport: function (component, event) {
        console.log('### LC_WebStore_Order_ConfirmHelper - setfraisdeport');
        var selectedId = '';
        selectedId = event.target.getAttribute('id');
        // console.log('selectedId ' + selectedId);
        var fraisdeport = component.get("v.fraisdeport");
        fraisdeport = document.getElementById(selectedId).value;
        // console.log("fraisdeport" + fraisdeport);
        var a = parseFloat(fraisdeport);

        if (isNaN(a)) {
            alert($A.get("{!$Label.c.z_LC_EnterFreightCharges}"));
        }
        else {
            component.set("v.fraisdeport", a);
            var totalet = a + component.get("v.TotalHT");
            var stringtotalet = totalet.toFixed(2);
            component.set("v.totalet", Number(totalet));
            if (component.get("v.changeTVA") == true) {
                component.set("v.tva", component.get("v.totalet") * 0.2);
            }
            var totalttc = component.get("v.tva") + totalet;
            var stringTotalttc = totalttc.toFixed(2);
            component.set("v.totalttc", Number(stringTotalttc));
        }
    },

    setTVA: function (component, event) {
        console.log('### LC_WebStore_Order_ConfirmHelper - setTVA');
        var selectedId = '';
        selectedId = event.target.getAttribute('id');
        // console.log('selectedId ' + selectedId);
        var tva = component.get("v.tva");
        tva = document.getElementById(selectedId).value;
        // console.log("tva" + tva);
        //var fdp= 2+fraisdeport;
        var a = parseFloat(tva);
        if (isNaN(a)) {
            alert($A.get("{!$Label.c.z_LC_EnterTVA}"));
        }
        else {
            component.set("v.tva", a);
            component.set("v.changeTVA", false);
            var totalttc = a + component.get("v.totalet");
            var stringTotalttc = totalttc.toFixed(2);
            component.set("v.totalttc", Number(stringTotalttc));
        }
    },

    createOrder: function (component, event, helper) {
        console.log('### LC_WebStore_Order_ConfirmHelper - createOrder');
        // console.log('helper createOrder');
        var emailsLstValue = [];

        //var isValidEmail = true;
        //var noEmailEntered = true;
        var emailsLst = component.find("emailnotifications");

        // console.log('ckh emailsLst =' + emailsLst);

        if (emailsLst.get("v.value") != undefined && emailsLst.get("v.value") != '') {
            emailsLstValue = emailsLst.get("v.value").split(';');
            //noEmailEntered = false;
        }
        /*var regExpEmailformat = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/; 
        
        if(emailsLstValue.length > 0 && emailsLstValue != ''){
            for(var i = 0; i < emailsLstValue.length; i++){
                if(emailsLstValue[i].match(regExpEmailformat)){
                    emailsLst.set("v.errors", [{message: null}]);
                    $A.util.removeClass(emailsLst, 'slds-has-error');
                    isValidEmail = true;
                }else{
                    $A.util.addClass(emailsLst, 'slds-has-error');
                    emailsLst.set("v.errors", [{message: $A.get("{!$Label.c.Z_LC_InvalidEmail}")}]);
                    isValidEmail = false;
                    component.set("v.isModalOpen",false);
                    component.set("v.Spinner",false);
                }
            }
        }
        
        // if Email Address is valid then execute code     
        if(isValidEmail){
            component.set("v.isValidEmail", true);
            // code write here..if Email Address is valid. 
            // console.log("createOrder called");*/
        component.set("v.isModalOpen", false);
        var action = component.get("c.CreateOrder");
        // console.log("#MG TVA :  " + component.get("v.tva"));
        action.setParams({
            beforeEdit: component.get("v.beforeEdit"),
            tva: component.get("v.tva"),
            sendEmailRealBill: component.get("v.sendEmailRealBill"),
            sendEmailShip: component.get("v.sendEmailShip"),
            sendEmailBill: component.get("v.sendEmailBill"),
            lstStoreConfigWrapper: component.get("v.OrderList"),
            emailsLst: emailsLstValue,
            poNumber: component.get("v.PONumber"),
            totalHT: component.get("v.TotalHT"),
            fraisDePort: component.get("v.fraisdeport"),
            msgFraisDePort: component.get("v.fraisdeportmsg"),
            BillToAcct: component.get("v.BillToAcct"),
            realBillingAccount: component.get("v.RealBillToAcct"),
            ShipToAcct: component.get("v.ShipToAcct"),
            billingCont: component.get("v.SelectedBillToCon"),
            realBillingContact: component.get("v.RealSelectedBillToCon"),
            shippingCont: component.get("v.SelectedShipToCon"),
            CommLogId: component.get("v.communityLogId"),
            currencyCode: component.get("v.currency"),
            fraisdeportUsedValues: component.get("v.fraisdeportUsedValues")
        });
        // Configure response handler
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var orderId = '';
                var retMap = response.getReturnValue();
                if (retMap) {
                    for (var key in retMap) {
                        //alert (key + ' t '+retMap[key]);
                        orderId = retMap[key];
                        // console.log('orderId ' + orderId);
                        component.set("v.msg", retMap[key]);
                        component.set("v.title", key);
                        component.set("v.Spinner", false);
                        break;
                    }
                }
                else {
                    var errors = response.getError();
                    // console.log('Error message' + errors[0].message);
                    // console.log('Problem getting Order, response state: ' + state);
                    component.set("v.msg", errors[0].message);
                    component.set("v.title", 'error');
                    component.set("v.Spinner", false);
                }
                if (component.get("v.title") === 'confirm') {
                    alert($A.get("$Label.c.Z_LC_Cart_Order_Confirm1") + ' ' + $A.get("$Label.c.Z_LC_Cart_Order_Confirm2"));
                    var eUrl = $A.get("e.force:navigateToURL");
                    eUrl.setParams({
                        "url": '/s/order/' + orderId
                    });
                    eUrl.fire();
                }

                /*var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "message": $A.get("{!$Label.c.Z_LC_OrderCreated}")
                    });
                    toastEvent.fire();*/
            }
            else {
                var errors = response.getError();
                // console.log('Error message' + errors[0].message);
                // console.log('Problem getting Order, response state: ' + state);
                component.set("v.msg", errors[0].message);
                component.set("v.title", 'error');
                component.set("v.Spinner", false);
            }

        });
        $A.enqueueAction(action);
        //}      
    },

    setshowfraisdeport: function (component, event) {
        console.log('### LC_WebStore_Order_ConfirmHelper - setshowfraisdeport');
        var showfraisdeport = Boolean(component.get("v.showfraisdeport"));
        // console.log("showfraisdeport" + showfraisdeport);
        showfraisdeport = (showfraisdeport == true ? false : true);
        // console.log("newsshowfraisdeport" + showfraisdeport);
        component.set("v.showfraisdeport", showfraisdeport);
        component.set("v.beforeEdit", false);
    },

    setshowTVA: function (component, event) {
        console.log('### LC_WebStore_Order_ConfirmHelper - setshowTVA');
        var showTVA = Boolean(component.get("v.showTVA"));
        // console.log("showTVA" + showTVA);
        showTVA = (showTVA == true ? false : true);
        // console.log("newsshowTVA" + showTVA);
        component.set("v.showTVA", showTVA);
        component.set("v.tvaEdited", true);
    },

    setshowbillto: function (component, event) {
        console.log('### LC_WebStore_Order_ConfirmHelper - setshowbillto');
        var showbillto = Boolean(component.get("v.showbillto"));
        // console.log("showfraisdeport" + showbillto);
        showbillto = (showbillto == true ? false : true);
        // console.log("newsshowfraisdeport" + showbillto);
        component.set("v.showbillto", showbillto);
    },

    openPopup: function (component, event, helper) {
        console.log('### LC_WebStore_Order_ConfirmHelper - openPopup');
        var regExpEmailformat = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        // Set isModalOpen attribute to true
        var emailsLst = component.find('emailnotifications');//.get("v.value");
        // console.log(emailsLst.get("v.value"));
        // check si l'emails list est vide
        if (emailsLst.get("v.value") === undefined || emailsLst.get("v.value") === "") {
            component.set("v.isModalOpen", true);
        }
        // check si l'emails list n'est pas vide
        else {
            if (emailsLst.get("v.value") != undefined && emailsLst.get("v.value").split(';').length > 10) {
                // console.log('error 1');
                $A.util.addClass(emailsLst, 'slds-has-error');
                emailsLst.set("v.errors", [{ message: $A.get("$Label.c.Z_LC_TooManyEmails") }]);
            }
            else {
                // console.log('check 2');
                var lst = emailsLst.get("v.value").split(';');
                for (var i = 0; i < lst.length; i++) {
                    var email = lst[i];
                    // console.log('email ' + email);
                    if (!email.match(regExpEmailformat)) {
                        // console.log('error 2');
                        emailsLst.set("v.errors", [{ message: $A.get("$Label.c.Z_LC_InvalidEmail") }]);
                        return;
                    }
                    else if (email.length > 120) {
                        // console.log('error 3');
                        emailsLst.set("v.errors", [{ message: $A.get("$Label.c.Z_LC_TooManyChars") }]);
                        return;
                    }
                }
                component.set("v.isModalOpen", true);
            }
        }
    },

    closePopup: function (component, event, helper) {
        console.log('### LC_WebStore_Order_ConfirmHelper - closePopup');
        // Set isModalOpen attribute to false  
        component.set("v.isModalOpen", false);
    },

    createQuote: function (component, event, helper) {
        console.log('### LC_WebStore_Order_ConfirmHelper - createQuote');
        alert(1);
        var OrderList = component.get("v.OrderList");
        var shipToAccount = component.get("v.ShipToAccount");
        var billToAccount = component.get("v.BillToAccount");
        alert(2);
        var action = component.get("c.createQuoteCase");
        alert(3);
        action.setParams({
            lstStoreConfigWrapper: OrderList,
            billingActId: billToAccount,
            shippingActId: shipToAccount,
            currencyCode: 'EUR'
        });
        alert(4);
        action.setCallback(this, function (response) {
            alert(5);
            var state = response.getState();
            alert(6);
            if (state === "SUCCESS") {
                alert('Quote and Case created');
            }
            else {
                alert('Error...');
            }
        });
        $A.enqueueAction(action);

    },
})