trigger LUXContractLineItemTrigger on ContractLineItem__c (After Insert, After Update) {
    if(Trigger.isAfter) {
        if(Trigger.isInsert || Trigger.isUpdate) {
            LUXContractLineItemUtil.setContractFlds(Trigger.new);
        }
    }
}