trigger ActionPlanTaskTemplateTrigger on APTaskTemplate__c (before insert, after insert, before update, after update, before delete, after delete, after undelete) {

	ActionPlansTriggerHandlers.triggerHandler_ActionPlanTaskTemplate(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap, Trigger.operationType);

}