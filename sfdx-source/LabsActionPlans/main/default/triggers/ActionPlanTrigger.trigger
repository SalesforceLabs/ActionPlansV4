trigger ActionPlanTrigger on ActionPlan__c ( before insert, after insert, before update, after update, before delete, after undelete ){

	ActionPlansTriggerHandlers.triggerHandler_ActionPlan(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap, Trigger.operationType);

}