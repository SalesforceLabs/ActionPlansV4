/**
 * Assumes you have created an object called Custom_Object__c and also created a field on ActionPlan__c called Custom_Object__c
 */
Custom_Object__c co = new Custom_Object__c();
insert co;

String apTemplateName = 'New Customer Onboarding';

List<LabsActionPlans.ActionPlanCreateInvocable.CreateActionPlanRequest> requests = new List<LabsActionPlans.ActionPlanCreateInvocable.CreateActionPlanRequest>();
LabsActionPlans.ActionPlanCreateInvocable.CreateActionPlanRequest req = new LabsActionPlans.ActionPlanCreateInvocable.CreateActionPlanRequest();
req.templateNameOrID = apTemplateName;
req.relatedRecordID = co.Id;
req.daysToActionPlanStart = 1;
req.actionPlanName = co.Name + ' Onboarding';
requests.add(req);

List<Id> resultIDs = LabsActionPlans.ActionPlanCreateInvocable.makeActionPlanFromTemplate(requests);
System.debug('resultIDs ' + resultIDs);