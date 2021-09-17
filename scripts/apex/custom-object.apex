/**
 * Assumes you have created an object called Custom_Object__c and also created a field on ActionPlan__c called Custom_Object__c
 */
Custom_Object__c co = new Custom_Object__c();
insert co;

String apTemplateName = 'New Customer Onboarding';

List<ActionPlanCreateInvocable.CreateActionPlanRequest> requests = new List<ActionPlanCreateInvocable.CreateActionPlanRequest>();
ActionPlanCreateInvocable.CreateActionPlanRequest req = new ActionPlanCreateInvocable.CreateActionPlanRequest();
req.templateNameOrID = apTemplateName;
req.relatedRecordID = co.Id;
req.daysToActionPlanStart = 1;
requests.add(req);

List<Id> resultIDs = ActionPlanCreateInvocable.makeActionPlanFromTemplate(requests);