({
    onInit : function( component, event, helper ) {
        component.set("v.AccountSelected", component.get("v.AccountFromCart"));
        component.set("v.idAccountSelected", component.get("v.AccountFromCart").Id);
        
        var formatOptions = [{'label': $A.get("$Label.c.B2BStore_Yes"), 'value':'Yes'}, {'label': $A.get("$Label.c.B2BStore_No"), 'value':'No'}];
        component.set("v.options", formatOptions);
        
        if(component.get("v.boolbill")){
            component.set("v.iconName", "utility:tour_check");
            component.set("v.labelCardContact", $A.get("$Label.c.B2BStore_Billing_Contact"));
            component.set("v.labelCardAccount", $A.get("$Label.c.B2BStore_Billing_Address"));
            component.set("v.labelSelect", $A.get("$Label.c.B2BStore_Select_billing_account"));
            component.set("v.labelContactSelect", $A.get("$Label.c.B2BStore_Notify_the_receiver"));
            component.set("v.labelRadioGroup", $A.get("$Label.c.B2BStore_You_will_receive_a_copy_of_the_order_confirmation"));
            component.set("v.labelWarning", $A.get("$Label.c.B2BStore_NoBillToContact"));
        }
        if(component.get("v.boolship") && (component.get("v.AccountSelected").Incoterms__c == 'FCA' || component.get("v.AccountSelected").Incoterms__c == 'EXW')){
            component.set("v.labelCardAccount", $A.get("$Label.c.B2BStore_Picking_Address"));
        }
        
        if(component.get("v.AccountSelected").Incoterms__c == 'FCA' || component.get("v.AccountSelected").Incoterms__c == 'EXW'){
            let actionPicking = component.get( "c.returnPickingAccountSelected" );  
            actionPicking.setParams({  
                idAcc: component.get( "v.AccountSelected" ).Id
            });  
            actionPicking.setCallback(this, function(response) {  
                let state = response.getState();
                if ( state === "SUCCESS" ) {
                    console.log(response.getReturnValue());
                    component.set("v.PickingAccountSelected", response.getReturnValue());
                    
                } else if (state === "ERROR") {
                    console.log(response.getError());
                } 
            });  
            $A.enqueueAction( actionPicking );
        }
        
        let action = component.get( "c.returnListAccount" );  
        action.setParams({  
            acc: component.get( "v.AccountFromCart" ),
            boolShip: component.get( "v.boolship" ),
            boolBill: component.get( "v.boolbill" )
        });  
        action.setCallback(this, function(response) {  
            let state = response.getState();
            if ( state === "SUCCESS" ) {
                console.log(response.getReturnValue());
                component.set("v.AccountsFromController", response.getReturnValue());
                
            } else if (state === "ERROR") {
                console.log(response.getError());
            } 
        });  
        $A.enqueueAction( action );
        
        let action2 = component.get( "c.returnContacts" );  
        action2.setParams({  
            accId: component.get( "v.AccountFromCart" ).Id,
            boolShip: component.get( "v.boolship" ),
            boolBill: component.get( "v.boolbill" ),
            cart: component.get( "v.Cart" )
        });  
        action2.setCallback(this, function(response) {  
            let state = response.getState();
            if ( state === "SUCCESS" ) {
                component.set("v.ContactsFromController", response.getReturnValue());
                if(response.getReturnValue().length > 0){
                    component.set("v.findContact", true);
                    component.set("v.selectedContactTo", response.getReturnValue()[0].Id);
                    component.set("v.ContactSelected", response.getReturnValue()[0]);
                    component.set("v.idContactSelected", component.get("v.selectedContactTo"));
                }else{
                    component.set("v.findContact", false);
                    component.set("v.emailSelected", component.get("v.valueInput"));
                }
            } else if (state === "ERROR") {
                console.log("ERROR");
                console.log(response.getError());
            } 
        });  
        $A.enqueueAction( action2 );
    },
    
    handleSelectChange : function( component, event, helper ) {
        
        component.set("v.value", 'No');
        let action = component.get( "c.returnAccountSelected" );  
        action.setParams({  
            idAcc: component.get( "v.selectedShipTo" )
        });  
        action.setCallback(this, function(response) {  
            let state = response.getState();
            if ( state === "SUCCESS" ) {
                console.log(response.getReturnValue());
                component.set("v.AccountSelected", response.getReturnValue());
                component.set("v.idAccountSelected", component.get("v.AccountSelected").Id);
                if(component.get("v.boolship")){
                    if(component.get("v.AccountSelected").Incoterms__c == 'FCA' || component.get("v.AccountSelected").Incoterms__c == 'EXW'){
                        component.set("v.labelCardAccount", $A.get("$Label.c.B2BStore_Picking_Address"));
                    }else{
                        component.set("v.labelCardAccount", $A.get("$Label.c.B2BStore_ShippingAddress"));
                    }
                }
                if(component.get("v.AccountSelected").Incoterms__c == 'FCA' || component.get("v.AccountSelected").Incoterms__c == 'EXW'){
                    let actionPicking = component.get( "c.returnPickingAccountSelected" );  
                    actionPicking.setParams({  
                        idAcc: component.get( "v.AccountSelected" ).Id
                    });  
                    actionPicking.setCallback(this, function(response) {  
                        let state = response.getState();
                        if ( state === "SUCCESS" ) {
                            console.log('Bjr handle Picking');
                            console.log(response.getReturnValue());
                            component.set("v.PickingAccountSelected", response.getReturnValue());
                            
                        } else if (state === "ERROR") {
                            console.log(response.getError());
                        } 
                    });  
                    $A.enqueueAction( actionPicking );
                }
            } else if (state === "ERROR") {
                console.log(response.getError());
            } 
        });  
        $A.enqueueAction( action );
        
        let action2 = component.get( "c.returnContacts" );  
        action2.setParams({  
            accId: component.get( "v.selectedShipTo" ),
            boolShip: component.get( "v.boolship" ),
            boolBill: component.get( "v.boolbill" ),
            cart: component.get( "v.Cart" )
        });  
        action2.setCallback(this, function(response) {  
            let state = response.getState();
            if ( state === "SUCCESS" ) {
                component.set("v.ContactsFromController", response.getReturnValue());
                if(response.getReturnValue().length > 0){
                    component.set("v.findContact", true);
                    component.set("v.selectedContactTo", response.getReturnValue()[0].Id);
                    component.set("v.idContactSelected", component.get("v.selectedContactTo"));
                    component.set("v.ContactSelected", response.getReturnValue()[0]);
                    component.set("v.emailSelected", null);
                }else{
                    component.set("v.findContact", false);
                    component.set("v.emailSelected", component.get("v.valueInput"));
                    component.set("v.selectedContactTo", null);
                    component.set("v.idContactSelected", null);
                    component.set("v.ContactSelected", null);
                }
            } else if (state === "ERROR") {
                console.log("ERROR");
                console.log(response.getError());
            } 
        });  
        $A.enqueueAction( action2 );
       
    },
    
    handleInputChange : function( component, event, helper ) {
        component.set("v.emailSelected", component.get("v.valueInput"));
    },
    
    handleRadioGroupChange : function( component, event, helper ) {
        if(component.get("v.value") == "No"){
            component.set("v.emailSelected", null);
        }
        if(component.get("v.value") == "Yes"){
            component.set("v.emailSelected", component.get("v.valueInput"));
        }
    },
    
    handleSelectContactChange : function( component, event, helper ) {
        component.set("v.idContactSelected", component.get("v.selectedContactTo"));
        let action = component.get( "c.returnContactSelected" );  
        action.setParams({  
            idCon: component.get( "v.selectedContactTo" )
        });  
        action.setCallback(this, function(response) {  
            let state = response.getState();
            if ( state === "SUCCESS" ) {
                console.log(response.getReturnValue());
                component.set("v.ContactSelected", response.getReturnValue());
            } else if (state === "ERROR") {
                console.log(response.getError());
            } 
        });  
        $A.enqueueAction( action );
    }
})