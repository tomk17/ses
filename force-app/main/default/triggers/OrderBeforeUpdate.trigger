/**
 * Created by gil.gourevitch on 06/05/2020.
 */

trigger OrderBeforeUpdate on Order (before update) {
	System.debug('############## START OrderBeforeUpdate ##############');
	List<Order> orderToProcess = new List<Order>();

	if(PAD.canTrigger('OrderSetSalesOrgUpdate')) {
        OrderInitValues.setInvoicedIfEpicor(trigger.new);
		System.debug('############## START OrderSetSalesOrgUpdate ##############');
		orderToProcess = new List<Order>();
		for (Order o : Trigger.new) {
			if (o.SoldToAccount__c != Trigger.oldMap.get(o.Id).SoldToAccount__c){
				orderToProcess.add(o);
			}
		}

		if(orderToProcess.size() > 0){
			// set SalesOrg
			OrderInitValues.setSalesOrg(orderToProcess);
		}
		PAD.ApexForcedBypass.add('OrderSetSalesOrgUpdate');
		System.debug('############## END OrderSetSalesOrgUpdate ##############');
	}

	if(PAD.canTrigger('OrderSetSupplyPlantUpdate')) {
		System.debug('############## START OrderSetSupplyPlantUpdate ##############');
		orderToProcess = new List<Order>();
		for (Order o : Trigger.new) {
			if (o.ShipToAccount__c != Trigger.oldMap.get(o.Id).ShipToAccount__c){
				orderToProcess.add(o);
			}
		}

		if(orderToProcess.size() > 0){
			// set SuplyPlant
			OrderInitValues.setSupplyPlant(orderToProcess);
		}
		PAD.ApexForcedBypass.add('OrderSetSupplyPlantUpdate');
		System.debug('############## END OrderSetSupplyPlantUpdate ##############');
	}
}