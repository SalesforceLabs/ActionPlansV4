trigger APContractTrigger on Contract(after undelete, before delete) {
	ActionPlansTriggerHandlers.actionPlansSObjectTriggerHandler(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap, Trigger.operationType, 'Contract');
}