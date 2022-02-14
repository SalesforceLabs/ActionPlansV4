trigger ActionPlanTemplateTaskTrigger on APTemplateTask__c(before insert, before update) {
	ActionPlansTriggerHandlers.triggerhandlerActionPlanTemplateTask(Trigger.new, Trigger.old, Trigger.oldMap, Trigger.operationType);
}