trigger APAccountTrigger on Account(before delete, after undelete) {
	ActionPlansTriggerHandlers.triggerhandlerActionPlanAccount(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap, Trigger.operationType);

	ActionPlansTriggerHandlers.actionPlansSObjectTriggerHandler('Account');

}