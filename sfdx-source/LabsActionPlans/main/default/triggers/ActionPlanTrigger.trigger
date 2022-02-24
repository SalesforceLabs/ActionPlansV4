trigger ActionPlanTrigger on ActionPlan__c(before insert, before update, after update, before delete, after undelete) {
	ActionPlansTriggerHandlers.triggerhandlerActionPlan(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap, Trigger.operationType);
}