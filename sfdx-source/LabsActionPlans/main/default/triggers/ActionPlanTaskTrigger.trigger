trigger ActionPlanTaskTrigger on Task(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	ActionPlansTriggerHandlers.triggerHandler_ActionPlanTask(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap, Trigger.operationType);
}