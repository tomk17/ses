({
    /* doInitHelper funcation to fetch all records, and set attributes value on component load */
    doInitHelper : function(component,event){
        var action = component.get("c.fetchContactWrapper");
        action.setParams({
            nameFilterString: '',
            order: ''
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                var oRes = response.getReturnValue();
                if(oRes.length > 0){
                    component.set('v.listOfAllContacts', oRes);
                    var pageSize = component.get("v.pageSize");
                    var totalRecordsList = oRes;
                    var totalLength = totalRecordsList.length ;
                    console.log(totalLength);
                    component.set("v.totalRecordsCount", totalLength);
                    component.set("v.startPage",0);
                    component.set("v.endPage",pageSize-1);
                    
                    var PaginationLst = [];
                    for(var i=0; i < pageSize; i++){
                        if(component.get("v.listOfAllContacts").length > i){
                            PaginationLst.push(oRes[i]);    
                        } 
                    }
                    component.set('v.PaginationList', PaginationLst);
                    component.set("v.selectedCount" , 0);
                    //use Math.ceil() to Round a number upward to its nearest integer
                    component.set("v.totalPagesCount", Math.ceil(totalLength / pageSize));    
                }else{
                    // if there is no records then display message
                    component.set("v.bNoRecordsFound" , true);
                    component.set("v.totalRecordsCount", 0);
                }
                
                
                var action1 = component.get("c.getAccountId");
                
                action1.setCallback(this, function(response1) {
                    var state1 = response1.getState();
                    if (state1 === "SUCCESS"){
                        var AccountId = response1.getReturnValue();
                        component.set("v.AccountId", AccountId);
                    }
                    else{
                        alert($A.get("$Label.c.ErrorGeneralMessage"));
                    }
                });
                $A.enqueueAction(action1);
                
                
                
            }
            else{
                alert($A.get("$Label.c.ErrorGeneralMessage"));
            }
        });
        $A.enqueueAction(action);  
    },
    // navigate to next pagination record set   
    next : function(component,event,sObjectList,end,start,pageSize){
        var Paginationlist = [];
        var counter = 0;
        for(var i = end + 1; i < end + pageSize + 1; i++){
            if(sObjectList.length > i){ 
                if(component.find("selectAllId").get("v.value")){
                    Paginationlist.push(sObjectList[i]);
                }else{
                    Paginationlist.push(sObjectList[i]);  
                }
            }
            counter ++ ;
        }
        start = start + counter;
        end = end + counter;
        component.set("v.startPage",start);
        component.set("v.endPage",end);
        component.set('v.PaginationList', Paginationlist);
    },
    // navigate to previous pagination record set   
    previous : function(component,event,sObjectList,end,start,pageSize){
        var Paginationlist = [];
        var counter = 0;
        for(var i= start-pageSize; i < start ; i++){
            if(i > -1){
                if(component.find("selectAllId").get("v.value")){
                    Paginationlist.push(sObjectList[i]);
                }else{
                    Paginationlist.push(sObjectList[i]); 
                }
                counter ++;
            }else{
                start++;
            }
        }
        start = start - counter;
        end = end - counter;
        component.set("v.startPage",start);
        component.set("v.endPage",end);
        component.set('v.PaginationList', Paginationlist);
    },
    InviteContactsToPortal : function(component) {
        // Prepare the action to load contact record
        var action = component.get("c.inviteContactsToPortal");
        action.setParams({"contacts": component.get("v.selectedRecords")});
        // Configure response handler
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var retMap = response.getReturnValue();
                for(var key in retMap){
                    console.log('NATHAN');
                    console.log(key);
                    if(key === 'confirm'){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            mode: 'sticky',
                            title: key,
                            message: retMap[key],
                            type: 'success'
                        });
                        toastEvent.fire();
                    }
                    if(key === 'error'){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            mode: 'sticky',
                            title: key,
                            message: retMap[key],
                            type: 'error'
                        });
                        toastEvent.fire();
                    }
                }
                component.set("v.Spinner",false);
            } else {
                var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        mode: 'sticky',
                        "title": "error",
                        "message": $A.get("$Label.c.ErrorGeneralMessage"),
                        type: error
                    });
                    toastEvent.fire();
                component.set("v.Spinner",false);
            }
        });
        $A.enqueueAction(action);
    },
    // Search function
    loadList: function(component) {
        console.log('inn');
        var nameFilterString = component.find("nameFilter").get("v.value");
        var orderBy = component.get("v.orderBy");
        console.log(nameFilterString);
        console.log('here '+orderBy);
        var action = component.get("c.fetchContactWrapper");
        action.setParams({
            nameFilterString: nameFilterString,
            order:orderBy
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                var oRes = response.getReturnValue();
                if(oRes.length > 0){
                    component.set("v.bNoRecordsFound" , false);
                    component.set('v.listOfAllContacts', oRes);
                    var pageSize = component.get("v.pageSize");
                    var totalRecordsList = oRes;
                    var totalLength = totalRecordsList.length ;
                    console.log(totalLength);
                    component.set("v.totalRecordsCount", totalLength);
                    component.set("v.startPage",0);
                    component.set("v.endPage",pageSize-1);
                    
                    var PaginationLst = [];
                    for(var i=0; i < pageSize; i++){
                        if(component.get("v.listOfAllContacts").length > i){
                            PaginationLst.push(oRes[i]);    
                        } 
                    }
                    component.set('v.PaginationList', PaginationLst);
                    component.set("v.selectedCount" , 0);
                    //use Math.ceil() to Round a number upward to its nearest integer
                    component.set("v.totalPagesCount", Math.ceil(totalLength / pageSize));    
                }else{
                    // if there is no records then display message
                    component.set("v.bNoRecordsFound" , true);
                    component.set("v.totalRecordsCount", 0);
                }
                component.set("v.Spinner",false);
            }
            else{
                alert($A.get("$Label.c.ErrorGeneralMessage"));
                component.set("v.Spinner",false);
            }
        });
        $A.enqueueAction(action); 
    }
})