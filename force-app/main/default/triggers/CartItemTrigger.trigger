trigger CartItemTrigger on CartItem (after insert, after update, after delete) {
    
    //public static Product2 transportation = [SELECT Id, ProductCode FROM Product2 WHERE ProductCode = '6669'];
    //
    System.debug('cart item trigger : insert : ' +  Trigger.isInsert + ' delete : ' + Trigger.isDelete + ' update : ' + Trigger.isUpdate);
    
    if(PAD.canTrigger('UpdateCartWithSoftwareProducts')){
        if(!Trigger.isDelete && !Test.isRunningTest()){
            PAD.ApexForcedBypass.add('UpdateCartWithSoftwareProducts');
        }
        
        /*if(Trigger.isInsert){
            System.debug('Trigger - CartItemTrigger - after insert start');
            for(CartItem ci : Trigger.new){
                CartItemTriggerClass.createCartItemForSoftwareProductInInsert(ci);
            }        
        }
        
        if(Trigger.isDelete){
            System.debug('Trigger - CartItemTrigger - after delete start');
            for(CartItem ci : Trigger.old){
                CartItemTriggerClass.updateCartItemForSoftwareProductInDelete(ci);
            }        
        }
        
        if(Trigger.isUpdate){
            System.debug('Trigger - CartItemTrigger - after update start');
            for(CartItem ci : Trigger.new){
                CartItemTriggerClass.updateCartItemForSoftwareProductInUpdate(Trigger.newMap.get(ci.Id), Trigger.oldMap.get(ci.Id));
            }        
        }*/

        cartItemTriggerClass.calculateSoftware(Trigger.new, Trigger.old);
    }
}