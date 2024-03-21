({
    onInit : function( component, event, helper ) {
        let action = component.get( "c.retrieveContactEmail" );  
        action.setParams({  
            cartId: component.get( "v.cartId" )
        });  
        action.setCallback(this, function(response) {  
            let state = response.getState();
            if ( state === "SUCCESS" ) {
                console.log(response.getReturnValue());
                component.set("v.email", response.getReturnValue());
                
            } else if (state === "ERROR") {
                console.log(response.getError());
            } 
        });  
        $A.enqueueAction( action );
        
        let action2 = component.get( "c.retrieveOptionalEmail" );  
        action2.setParams({  
            cartId: component.get( "v.cartId" )
        });  
        action2.setCallback(this, function(response) {  
            let state = response.getState();
            if ( state === "SUCCESS" ) {
                component.set("v.optionalEmail", response.getReturnValue());
            } else if (state === "ERROR") {
                console.log("ERROR");
                console.log(response.getError());
            } 
        });  
        $A.enqueueAction( action2 );
        
        let actionCalculQuantity = component.get( "c.calculateAvailability" );  
        actionCalculQuantity.setParams({  
            cartId: component.get( "v.cartId" )
        });  
        actionCalculQuantity.setCallback(this, function(response) {  
            let state = response.getState();
            if ( state === "SUCCESS" ) {
				console.log("SUCCESS Calculate Availability");
            } else if (state === "ERROR") {
                console.log(response.getError());
            } 
        });  
        $A.enqueueAction( actionCalculQuantity );
        
        let action3 = component.get( "c.retrieveProduct" );  
        action3.setParams({  
            cartId: component.get( "v.cartId" )
        });  
        action3.setCallback(this, function(response) {  
            let state = response.getState();
            if ( state === "SUCCESS" ) {
                console.log("success 3 ", response.getReturnValue());
                component.set("v.products", response.getReturnValue());
            } else if (state === "ERROR") {
                console.log("ERROR");
                console.log(response.getError());
            } 
        });  
        $A.enqueueAction( action3 );
        
        let action5 = component.get( "c.retrieveSoftware" );  
        action5.setParams({  
            cartId: component.get( "v.cartId" )
        });  
        action5.setCallback(this, function(response) {  
            let state = response.getState();
            if ( state === "SUCCESS" ) {
                console.log("success 5 ", response.getReturnValue());
                component.set("v.softwares", response.getReturnValue());
            } else if (state === "ERROR") {
                console.log("ERROR");
                console.log(response.getError());
            } 
        });  
        $A.enqueueAction( action5 );
        
        let action4 = component.get( "c.retrieveCurrency" );  
        action4.setParams({  
            cartId: component.get( "v.cartId" )
        });  
        action4.setCallback(this, function(response) {  
            let state = response.getState();
            if ( state === "SUCCESS" ) {
                console.log("success 3 ", response.getReturnValue());
                component.set("v.currency", response.getReturnValue());
            } else if (state === "ERROR") {
                console.log("ERROR");
                console.log(response.getError());
            } 
        });  
        $A.enqueueAction( action4 );
    }
    
})