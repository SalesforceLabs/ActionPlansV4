trigger ActionPlanTemplateTrigger on ActionPlanTemplate__c (before insert, after insert, before update, after update) {
	ActionPlansTriggerHandlers.triggerHandler_ActionPlanTemplate(Trigger.new, Trigger.old, Trigger.oldMap, Trigger.operationType);
}