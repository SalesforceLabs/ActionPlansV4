trigger ActionPlanTaskTrigger on APTask__c(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	ActionPlansTriggerHandlers.triggerhandlerActionPlanTask(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap, Trigger.operationType);
}