trigger APCaseTrigger on Case(before delete, after undelete) {
	ActionPlansTriggerHandlers.actionPlansSObjectTriggerHandler(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap, Trigger.operationType, 'Case');
}