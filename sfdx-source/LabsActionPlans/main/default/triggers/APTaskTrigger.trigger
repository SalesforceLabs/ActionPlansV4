trigger APTaskTrigger on Task(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	ActionPlansTriggerHandlers.triggerHandler_Task(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap, Trigger.operationType);
}