/**
 * Created by gil.gourevitch on 06/05/2020.
 */

trigger OrderBeforeInsert on Order (before insert) {
	System.debug('############## START OrderBeforeInsert ##############');
	List<Order> orderToProcess = new List<Order>();

	if(PAD.canTrigger('OrderSetSalesOrgInsert')) {
		System.debug('############## START OrderSetSalesOrgInsert ##############');
		orderToProcess = new List<Order>();
		for (Order o : Trigger.new) {
			if (o.SoldToAccount__c != null){
				orderToProcess.add(o);
			}
		}

		if(orderToProcess.size() > 0){
			// set SalesOrg
			OrderInitValues.setSalesOrg(orderToProcess);
		}
		PAD.ApexForcedBypass.add('OrderSetSalesOrgInsert');
		System.debug('############## END OrderSetSalesOrgInsert ##############');
	}

	if(PAD.canTrigger('OrderSetSupplyPlantInsert')) {
		System.debug('############## START OrderSetSupplyPlantInsert ##############');
		orderToProcess = new List<Order>();
		for (Order o : Trigger.new) {
			if (o.ShipToAccount__c != null){
				orderToProcess.add(o);
			}
		}

		if(orderToProcess.size() > 0){
			// set SuplyPlant
			OrderInitValues.setSupplyPlant(orderToProcess);
		}
		PAD.ApexForcedBypass.add('OrderSetSupplyPlantInsert');
		System.debug('############## END OrderSetSupplyPlantInsert ##############');
	}
}