trigger ActionPlanTemplateTaskTrigger on APTTaskTemplate__c(before insert, before update) {
	ActionPlansTriggerHandlers.triggerHandler_ActionPlanTemplateTaskTemplate(Trigger.new, Trigger.old, Trigger.oldMap, Trigger.operationType);
}