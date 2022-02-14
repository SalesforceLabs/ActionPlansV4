trigger ActionPlanTemplateTrigger on ActionPlanTemplate__c(before insert, after insert, before update, after update) {
	ActionPlansTriggerHandlers.triggerhandlerActionPlanTemplate(Trigger.new, Trigger.old, Trigger.oldMap, Trigger.operationType);
}