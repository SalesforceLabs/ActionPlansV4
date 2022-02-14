trigger APLeadTrigger on Lead(after update, after undelete, before delete) {
	ActionPlansTriggerHandlers.actionPlansSObjectTriggerHandler(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap, Trigger.operationType, 'Lead');

	ActionPlansTriggerHandlers.triggerhandlerActionPlanLead(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap, Trigger.operationType);

}