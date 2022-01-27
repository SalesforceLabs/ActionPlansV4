trigger APAccountTrigger on Account(before delete, after undelete) {
	ActionPlansTriggerHandlers.triggerHandler_ActionPlanAccount(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap, Trigger.operationType);

	ActionPlansTriggerHandlers.actionPlansSObjectTriggerHandler('Account');

}