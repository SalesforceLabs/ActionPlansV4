trigger APTaskTrigger on Task(before insert, after update, before delete, after delete) {
	ActionPlansTriggerHandlers.triggerhandlerTask(Trigger.new, Trigger.old, Trigger.operationType);
}