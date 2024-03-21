({
    doInit: function (component, event, helper) {
        console.log('### LC_WebStore_Order_ConfirmController - doInit');
        // console.log("Calling helper");
        helper.doInitHelper(component, event);
    },

    createOrder: function (component, event, helper) {
        console.log('### LC_WebStore_Order_ConfirmController - createOrder');
        //Add limit to number of caracters and number of emails
        /*var emailsLst = component.find("emailnotifications");
        if(emailsLst.get("v.value") != undefined && emailsLst.get("v.value").length > 120){
            $A.util.addClass(emailsLst, 'slds-has-error');
            emailsLst.set("v.errors", [{message: $A.get("$Label.c.Z_LC_TooManyChars")}]);
            component.set("v.isModalOpen",false);
            component.set("v.Spinner",false);
        }
        else if(emailsLst.get("v.value") != undefined && emailsLst.get("v.value").split(';').length > 10){
            $A.util.addClass(emailsLst, 'slds-has-error');
            emailsLst.set("v.errors", [{message: $A.get("$Label.c.Z_LC_TooManyEmails")}]);
            component.set("v.isModalOpen",false);
            component.set("v.Spinner",false);
        }
            else{*/
        // console.log('controller createOrder');
        // si le checkbox accept CGV is checked
        if (component.get("v.DisclaimerValue")) {
            //alert("The Sales Order has been successfully created!");
            var spinner = component.find("mySpinner");
            $A.util.toggleClass(spinner, "slds-hide");
            component.set("v.Spinner", true);
            helper.createOrder(component, event, helper);
            /*if(component.get("v.isValidEmail")){
                //$A.get('e.force:refreshView').fire();
                var eUrl= $A.get("e.force:navigateToURL");
                eUrl.setParams({
                    "url": '/s/' 
                });
                eUrl.fire();
            }*/
        }
        else {
            alert($A.get("$Label.c.LC_AgreeTC"));
        }
        //}
    },

    refreshTotals: function (component, event, helper) {
        console.log('### LC_WebStore_Order_ConfirmController - refreshTotals');
        helper.refreshTotals(component, event);
    },

    setfraisdeport: function (component, event, helper) {
        console.log('### LC_WebStore_Order_ConfirmController - setfraisdeport');
        helper.setfraisdeport(component, event);
    },

    setshowfraisdeport: function (component, event, helper) {
        console.log('### LC_WebStore_Order_ConfirmController - setshowfraisdeport');
        helper.setshowfraisdeport(component, event);
    },

    setshowbillto: function (component, event, helper) {
        console.log('### LC_WebStore_Order_ConfirmController - setshowbillto');
        helper.setshowbillto(component, event);
    },

    setshowTVA: function (component, event, helper) {
        console.log('### LC_WebStore_Order_ConfirmController - setshowTVA');
        helper.setshowTVA(component, event);
    },

    setTVA: function (component, event, helper) {
        console.log('### LC_WebStore_Order_ConfirmController - setTVA');
        helper.setTVA(component, event);
    },

    /*sendEmailTest : function(component,event,helper) {
        var isValidEmail = true; 
        var emailsLst = component.find("emailnotifications");
        var emailsLstValue = emailsLst.get("v.value").split(';');
        var regExpEmailformat = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/; 
        
        //if(!$A.util.isEmpty(emailsLstValue)){
        if(emailsLstValue.length > 0){
            for(var i = 0; i < emailsLstValue.length; i++){
                if(emailsLstValue[i].match(regExpEmailformat)){
                    emailsLst.set("v.errors", [{message: null}]);
                    $A.util.removeClass(emailsLst, 'slds-has-error');
                    isValidEmail = true;
                }else{
                    $A.util.addClass(emailsLst, 'slds-has-error');
                    emailsLst.set("v.errors", [{message: "Please Enter a Valid Email Address"}]);
                    isValidEmail = false;
                }
            }
            
        }
        
        // if Email Address is valid then execute code     
        if(isValidEmail){
            // code write here..if Email Address is valid. 
        }
    },*/
    /*editRecord : function(component,event,helper) {
        component.set("v.showEditForm",true);
    },*/
    /*handleSuccess: function(component, event, helper) {
        component.set("v.Spinner",false);
        component.set("v.showEditForm",false);
        var cmpTarget = component.find('MainDiv');
        $A.util.removeClass(cmpTarget, 'slds-modal slds-fade-in-open slds-backdrop');
        helper.doInitHelper(component, event);
    },*/
    /*handleSubmit: function(component, event, helper) {
        component.set("v.Spinner",true);
    },*/
    /*handleClick: function(component, event, helper) {
        component.set("v.showEditForm",false);
        var cmpTarget = component.find('MainDiv');
        $A.util.removeClass(cmpTarget, 'slds-modal slds-fade-in-open slds-backdrop');
    },*/
    /*createRecord: function(component, event, helper) {
        component.set("v.showCreateForm",true);
    },*/
    /*handleCreateSuccess: function(component, event, helper) {
        var params = event.getParams();
        component.set("v.Spinner",false);
        component.set("v.showCreateForm",false);
        var cmpTarget = component.find('CreateDiv');
        $A.util.removeClass(cmpTarget, 'slds-modal slds-fade-in-open slds-backdrop');
        component.set("v.SelectedBillToContact",params.response.id);
        helper.doInitHelper(component, event);
    },*/
    /*handleCancel: function(component, event, helper) {
        component.set("v.showCreateForm",false);
        var cmpTarget = component.find('CreateDiv');
        $A.util.removeClass(cmpTarget, 'slds-modal slds-fade-in-open slds-backdrop');
    },*/
    /*handleError: function(component, event, helper) {
        component.set("v.Spinner",false);
    },*/

    openPopup: function (component, event, helper) {
        console.log('### LC_WebStore_Order_ConfirmController - openPopup');
        var poids = component.get("v.poids");
        if (Math.round(Number(poids)) <= 999 || !component.get("v.beforeEdit")) {
            helper.openPopup(component, event, helper);
        }
        else {
            alert($A.get("$Label.c.Z_Frais_de_Ports"));
        }
    },

    closePopup: function (component, event, helper) {
        console.log('### LC_WebStore_Order_ConfirmController - closePopup');
        helper.closePopup(component, event, helper);
    },

    createQuote: function (component, event, helper) {
        console.log('### LC_WebStore_Order_ConfirmController - createQuote');
        helper.createQuote(component, event, helper);
    },

})