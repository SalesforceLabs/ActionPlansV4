trigger ActionPlanTemplateTaskTrigger on APTemplateTask__c(before insert, before update) {
	ActionPlansTriggerHandlers.triggerHandler_ActionPlanTemplateTask(Trigger.new, Trigger.old, Trigger.oldMap, Trigger.operationType);
}