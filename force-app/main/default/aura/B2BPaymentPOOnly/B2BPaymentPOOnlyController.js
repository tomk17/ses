({
    onInit : function( component, event, helper ) {
        
        let shippingCountry = component.get( "v.AccountFromCart" ).ShippingCountry;
              
        if(shippingCountry == 'Canada'){
            if(component.get( "v.languageFromUser" ) == 'fr'){
                component.set( "v.termsAndCondition", '/2020_General_Terms_and_Conditions__CANADA_FR_CLEAN.pdf');
            }else{
                component.set( "v.termsAndCondition", '/2020_General_Terms_and_Conditions__Global_CANADA__EN_CLEAN.pdf');
            }
        }else if(shippingCountry == 'United States'){
            component.set( "v.termsAndCondition", '/2020_General_Terms_and_Conditions__Global_USA_CLEAN.pdf');
        }else if(shippingCountry == 'France'){
            component.set( "v.termsAndCondition", '/2022_General_Terms_and_Conditions_EUROPE_FR_CLEAN.pdf');
        }else if(shippingCountry == 'Italy'){
            component.set( "v.termsAndCondition", '/2022_General_Terms_and_Conditions_EUROPE_IT_CLEAN.pdf');
        }else if(shippingCountry == 'Germany'){
            component.set( "v.termsAndCondition", '/2022_General_Terms_and_Conditions_EUROPE_DE_CLEAN.pdf');
        }else{
            component.set( "v.termsAndCondition", '/2022_General_Terms_and_Conditions_GLOBAL_EN_CLEAN.pdf');
        }
        
        if(shippingCountry != 'Canada' && shippingCountry != 'United States'){
            component.set( "v.valueCheckbox3" , true);
        }
        
        let action = component.get( "c.returnPaymentTerm" );  
        action.setParams({  
            idAcc: component.get( "v.AccountFromCart" ).Id
        });  
        action.setCallback(this, function(response) {  
            let state = response.getState();
            if ( state === "SUCCESS" ) {
                component.set("v.paymentTerm", response.getReturnValue());
                
            } else if (state === "ERROR") {
                console.log(response.getError());
            } 
        });  
        $A.enqueueAction( action );
    },
    onButtonPressed : function(component, event, helper) {
        let shippingCountry = component.get( "v.AccountFromCart" ).ShippingCountry;
        var valueCheckbox1 = component.get("v.valueCheckbox1");
        var valueCheckbox2 = component.get("v.valueCheckbox2");
        var valueCheckbox3 = component.get("v.valueCheckbox3");
        
        if(valueCheckbox1 && valueCheckbox3 && (shippingCountry == 'United States')){
            var navigate = component.get("v.navigateFlow");
            navigate("NEXT");
        }else if(valueCheckbox1 && valueCheckbox2 && valueCheckbox3){
            var navigate = component.get("v.navigateFlow");
            navigate("NEXT");
        }else{
            component.set("v.warning", true);
        }
    },
    handleChange1 : function(component, event, helper) {
        var boolChecked = component.get( "v.valueCheckbox1" );
        if(boolChecked){
            component.set( "v.valueCheckbox1" , false);
        }else{
            component.set( "v.valueCheckbox1" , true);
        }
        var valueCheckbox1 = component.get("v.valueCheckbox1");
        var valueCheckbox2 = component.get("v.valueCheckbox2");
        var valueCheckbox3 = component.get("v.valueCheckbox3");
        
        if(valueCheckbox1 && valueCheckbox2 && valueCheckbox3){
            component.set("v.warning", false);
        }
    },
    handleChange2 : function(component, event, helper) {
        var boolChecked = component.get( "v.valueCheckbox2" );
        if(boolChecked){
            component.set( "v.valueCheckbox2" , false);
        }else{
            component.set( "v.valueCheckbox2" , true);
        }
        
        var valueCheckbox1 = component.get("v.valueCheckbox1");
        var valueCheckbox2 = component.get("v.valueCheckbox2");
        var valueCheckbox3 = component.get("v.valueCheckbox3");
        
        if(valueCheckbox1 && valueCheckbox2 && valueCheckbox3){
            component.set("v.warning", false);
        }
    },
    handleChange3 : function(component, event, helper) {
        var boolChecked = component.get( "v.valueCheckbox3" );
        if(boolChecked){
            component.set( "v.valueCheckbox3" , false);
        }else{
            component.set( "v.valueCheckbox3" , true);
        }
        
        var valueCheckbox1 = component.get("v.valueCheckbox1");
        var valueCheckbox2 = component.get("v.valueCheckbox2");
        var valueCheckbox3 = component.get("v.valueCheckbox3");
        
        if(valueCheckbox1 && valueCheckbox2 && valueCheckbox3){
            component.set("v.warning", false);
        }
    }
})