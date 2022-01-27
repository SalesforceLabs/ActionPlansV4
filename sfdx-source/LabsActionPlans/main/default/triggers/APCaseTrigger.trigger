trigger APCaseTrigger on Case(after undelete, before delete) {
	ActionPlansTriggerHandlers.actionPlansSObjectTriggerHandler(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap, Trigger.operationType, 'Case');
}