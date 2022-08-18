@SuppressWarnings('PMD.AvoidGlobalModifier')
/*
Action Plans v4
David Schach 2022
https://appexchange.salesforce.com/appxListingDetail?listingId=a0N4V00000Gg6NVUAZ

Action Plans v3
Force.com Labs 2011
http://appexchange.salesforce.com/listingDetail?listingId=a0N30000003HcINEA0

Copyright (c) 2022, salesforce.com, inc.
All rights reserved.
SPDX-License-Identifier: BSD-3-Clause
For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
*/
/**
 * @group Invocable
 * @author {@link [David Schach](https://github.com/dschach)}
 * @since 2022
 */
global without sharing class ActionPlanCreateInvocable {
	/**
	 * Invocable Apex for creating Action Plans from a template, a parent ID, and days from now to start the task due dates
	 * @param requests Wrapper of `CreateActionPlanRequest`
	 * @see ActionPlanCreateInvocable.CreateActionPlanRequest
	 * @return `List<Id>` of the created Action Plans
	 * @example
	 * String apTemplateName;
	 * ActionPlanTemplate__c apTemplate;
	 * List<SObject> toInsert... // can use any object, such as Account, or the generic SObject class
	 * List<ActionPlanCreateInvocable.CreateActionPlanRequest> requests = new List<ActionPlanCreateInvocable.CreateActionPlanRequest>();
	 * for(SObject a : toInsert){
	 *     ActionPlanCreateInvocable.CreateActionPlanRequest req = new ActionPlanCreateInvocable.CreateActionPlanRequest();
	 *     req.templateNameOrID = apTemplate.Id;
	 *     req.relatedRecordID = a.Id;
	 *     req.daysToActionPlanStart = 0;
	 *     req.actionPlanName = apTemplate.Name + ' - ' + a.Name; // optional
	 *     requests.add(req);
	 * List<Id> resultIDs = ActionPlanCreateInvocable.makeActionPlanFromTemplate(requests);
	 */
	@InvocableMethod(label='Create Action Plan From Template' description='Takes a Template Name/Id and Record Id and makes an Action Plan for that record.' category='ActionPlans')
	global static List<Id> makeActionPlanFromTemplate(List<CreateActionPlanRequest> requests) {
		List<ActionPlan__c> actionPlansToInsert = new List<ActionPlan__c>();
		Set<Id> createdAPIDs = new Set<Id>();

		// * Collect template IDs & handle parents
		Set<String> templateNamesOrIDs = new Set<String>();
		Set<Id> relatedIDs = new Set<Id>();
		for (CreateActionPlanRequest r : requests) {
			templateNamesOrIDs.add(r.templateNameOrID);
			relatedIDs.add(r.relatedRecordID);
		}

		Map<String, ActionPlanTemplate__c> templateNameOrIdToTemplate = new Map<String, ActionPlanTemplate__c>();

		// Map contains Id AND Name because we will refer to
		for (ActionPlanTemplate__c apt : [
			SELECT
				Id,
				Description__c,
				Name,
				OwnerId,
				SkipDay__c,
				SkipWeekends__c,
				TaskRecordTypeID__c,
				(
					SELECT
						Type__c,
						Subject__c,
						Priority__c,
						Dependent__c,
						Name,
						User__c,
						User__r.Name,
						Id,
						DaysFromStart__c,
						Action_Plan_Template__c,
						TController__r.Subject__c,
						Minutes_Reminder__c,
						Reminder__c,
						SendEmail__c,
						Comments__c,
						TaskIndex__c,
						Action_Plan_Template__r.TaskRecordTypeID__c
					FROM aptTasks__r
					ORDER BY TaskIndex__c ASC
				)
			FROM ActionPlanTemplate__c
			WHERE Name IN :templateNamesOrIDs OR Id IN :templateNamesOrIDs
		]) {
			templateNameOrIdToTemplate.put(apt.Id, apt);
			templateNameOrIdToTemplate.put(apt.Name, apt);
		}

		if (templateNameOrIdToTemplate.isEmpty()) {
			return new List<Id>(createdAPIDs);
		}

		// * Handle parent records

		Map<Id, Id> relObjectOwners = ActionPlansBuilderUtilities.retrieveOwnersDataRelatedObject(relatedIDs);
		Map<Id, String> relRecordNames = ActionPlansUtilities.queryRecordIDToRecordName(relatedIDs);

		Set<String> actionPlanFields = Schema.SObjectType.ActionPlan__c.fields.getMap().keyset();

		// * Copy Template fields to new AP fields
		for (CreateActionPlanRequest r : requests) {
			if (!templateNameOrIdToTemplate.containsKey(r.templateNameOrID)) {
				continue;
			}

			ActionPlanTemplate__c actionPlanTemplate = templateNameOrIdToTemplate.get(r.templateNameOrID);
			ActionPlan__c ap = new ActionPlan__c();
			ap.Name = String.isBlank(r.actionPlanName)
				? ActionPlansUtilities.actionPlanSubjectToName(actionPlanTemplate.Name + ' - ' + relRecordNames.get(r.relatedRecordID))
				: ActionPlansUtilities.actionPlanSubjectToName(r.actionPlanName);
			ap.Description__c = actionPlanTemplate.Description__c;
			ap.SkipWeekends__c = actionPlanTemplate.SkipWeekends__c;
			ap.SkipDay__c = actionPlanTemplate.SkipDay__c;
			ap.Action_Plan_Template__c = actionPlanTemplate.Id; // Most important line
			ap.TaskRecordTypeID__c = actionPlanTemplate.TaskRecordTypeID__c;
			ap.StartDate__c = Date.today().addDays(r.daysToActionPlanStart == null ? 0 : r.daysToActionPlanStart);

			for (String s : ActionPlansUtilities.getCustomRelationshipFields()) {
				ap.put(s, null);
			}

			// * Describe parent (if needed - it was memoized) and fill related field
			Id relatedId = r.relatedRecordID;
			Schema.DescribeSObjectResult sor = ActionPlansUtilities.getRelatedSObjectDescribe(relatedId);
			String relObjName = sor.getName().toLowerCase();
			String relObjLabel = sor.getLabel();

			ap.Related_Object__c = relObjLabel;

			String namespacePrefix = ActionPlansUtilities.namespacePrefix.toLowerCase();
			String relObjField = relObjName;

			if (!relObjName.endsWithIgnoreCase('__c')) {
				relObjField = relObjField + '__c';
			}
			if (actionPlanFields.contains(namespacePrefix + relObjField)) {
				relObjField = namespacePrefix + relObjField;
			} else if (actionPlanFields.contains(relObjField)) {
				relObjField = relObjField;
			} else {
				continue;
			}
			ap.put(relObjField, relatedId);

			actionPlansToInsert.add(ap);
		}

		if (actionPlansToInsert.isEmpty()) {
			return new List<Id>(createdAPIDs);
		}

		insert actionPlansToInsert;

		// * Action Plans inserted. Handle APTasks.

		Map<String, APTask__c> planTaskIndexToTask = new Map<String, APTask__c>();

		// For each Actoin Plan, if we have a template match, make the ActionPlan tasks
		for (ActionPlan__c ap : actionPlansToInsert) {
			if (ap.Action_Plan_Template__c != null && templateNameOrIdToTemplate.containsKey(ap.Action_Plan_Template__c)) {
				ActionPlanTemplate__c actionPlanTemplate = templateNameOrIdToTemplate.get(ap.Action_Plan_Template__c);

				for (APTemplateTask__c aptTask : actionPlanTemplate.aptTasks__r) {
					APTask__c apTask = new APTask__c();
					apTask.User__c = ActionPlansBuilderUtilities.getAPTaskTemplateUser(ap, relObjectOwners, aptTask.User__c);
					apTask.Type__c = aptTask.Type__c;
					apTask.Subject__c = aptTask.Subject__c;
					apTask.Priority__c = aptTask.Priority__c;
					apTask.Dependent__c = aptTask.Dependent__c;
					apTask.TaskIndex__c = aptTask.TaskIndex__c;
					apTask.DaysFromStart__c = aptTask.DaysFromStart__c;
					apTask.Comments__c = aptTask.Comments__c;
					apTask.Reminder__c = aptTask.Reminder__c;
					apTask.Minutes_Reminder__c = aptTask.Minutes_Reminder__c;
					apTask.SendEmail__c = aptTask.SendEmail__c;

					apTask.Action_Plan__c = ap.Id;

					apTask.Status__c = ActionPlansUtilities.getTaskRecordTypeStatusDefaultValues().get(ActionPlansUtilities.getDefaultTaskRecordTypeId());

					if (apTask.Dependent__c != null && apTask.Dependent__c != 'None') {
						apTask.ActivityDate__c = null;
					} else {
						apTask.Controller__c = null;

						//set dependency taskId to none if none was selected
						if (apTask.Dependent__c == null) {
							apTask.Dependent__c = 'None';
						}

						// create due date, calculate the due date of the tasks for skip weekends feature
						if (ap.SkipWeekends__c == true && ap.SkipDay__c != null) {
							apTask.ActivityDate__c = ActionPlansUtilities.adjustTaskDueDate(ap.StartDate__c, apTask.DaysFromStart__c.intValue(), ap.SkipDay__c);
						} else {
							apTask.ActivityDate__c = ap.StartDate__c.addDays(apTask.DaysFromStart__c.intValue());
						}
					}
					planTaskIndexToTask.put(ap.Id + '' + apTask.TaskIndex__c, apTask);
				}
			}
		}
		Database.insert(planTaskIndexToTask.values());

		// We update with the controlling/dependent task IDs

		List<APTask__c> dependentTasksToUpdate = new List<APTask__c>();

		for (APTask__c apTask : planTaskIndexToTask.values()) {
			String actionPlanPlusIndex = apTask.Action_Plan__c + '' + apTask.Dependent__c;

			if (planTaskIndexToTask.containsKey(actionPlanPlusIndex)) {
				apTask.Controller__c = planTaskIndexToTask.get(actionPlanPlusIndex).Id;
				dependentTasksToUpdate.add(apTask);
			}
		}

		Database.update(dependentTasksToUpdate);

		List<Task> myTasksWithOutEmail = new List<Task>();
		List<Task> myTasksWithEmail = new List<Task>();

		Map<Id, APTask__c> mapAP = new Map<Id, APTask__c>();
		for (APTask__c a : planTaskIndexToTask.values()) {
			mapAP.put(a.Id, a);
		}

		Map<Id, ActionPlan__c> insertedActionPlans = new Map<Id, ActionPlan__c>();
		for (ActionPlan__c ap : actionPlansToInsert) {
			insertedActionPlans.put(ap.Id, ap);
		}

		for (APTask__c apTask : planTaskIndexToTask.values()) {
			ActionPlan__c insertedAP;
			// check if task exists already
			Task t = new Task();
			t.Subject = apTask.Subject__c;
			t.Priority = apTask.Priority__c;
			t.OwnerId = apTask.User__c;
			t.TaskAPTask__c = apTask.Id;

			if (apTask.Comments__c != null) {
				t.Description = apTask.Comments__c;
			}

			//set reminder based on user's default reminder setting
			if (apTask.Reminder__c == true && apTask.ActivityDate__c != null) {
				t.isReminderSet = true;
				t.ReminderDateTime = Datetime.newInstance(apTask.ActivityDate__c.year(), apTask.ActivityDate__c.month(), apTask.ActivityDate__c.day(), 0, 0, 0);
				t.ReminderDateTime = t.ReminderDateTime.addMinutes(Integer.valueOf(apTask.Minutes_Reminder__c));
			} else {
				t.isReminderSet = false;
			}

			APTask__c apt = mapAP.get(apTask.Id);

			if (apt != null) {
				insertedAP = insertedActionPlans.get(apt.Action_Plan__c);
			}

			//link to Action Plan's Related To Object
			for (String s : ActionPlansUtilities.getCustomRelationshipFields()) {
				String f = s;
				if (
					!f.equalsIgnoreCase(ActionPlansUtilities.namespacePrefix + 'Contact__c') &&
					!f.equalsIgnoreCase(ActionPlansUtilities.namespacePrefix + 'Lead__c') &&
					insertedAP.get(f) != null
				) {
					t.WhatId = (Id) insertedAP.get(f);
					break;
				}
			}

			if (insertedAP.Contact__c != null) {
				t.WhoId = insertedAP.Contact__c;
			} else if (insertedAP.Lead__c != null) {
				t.WhoId = insertedAP.Lead__c;
			}

			t.Type = apTask.Type__c;

			if (t.Id == null) {
				t.Status = apTask.Status__c;
			}
			t.ActivityDate = apTask.ActivityDate__c;

			//if (apTask.Dependent__c == 'None') {
			if (apTask.SendEmail__c == true) {
				myTasksWithEmail.add(t);
			} else {
				myTasksWithOutEmail.add(t);
			}
			//}
		}

		Database.DMLOptions dmlo = new Database.DMLOptions();

		if (myTasksWithEmail.size() > 0) {
			dmlo.EmailHeader.triggerUserEmail = true;
			Database.insert(myTasksWithEmail, dmlo);
		}

		if (myTasksWithOutEmail.size() > 0) {
			dmlo.EmailHeader.triggerUserEmail = false;
			Database.insert(myTasksWithOutEmail, dmlo);
		}

		// Collect all AP IDs for Chatter (and for returning)
		for (ActionPlan__c ap : actionPlansToInsert) {
			createdAPIDs.add(ap.Id);
		}

		Action_Plans_Settings__c mySettings = ActionPlansUtilities.getCustomSetting();

		if (mySettings != null && mySettings.Chatter_Object_Brag__c) {
			ActionPlansBuilderUtilities.generateObjectFeeds(createdAPIDs);
		}

		// Finish by returning all created ActionPlan IDs
		return new List<Id>(createdAPIDs);
	}

	/**
	 * Wrapper class for ActionPlan Request for invocable Apex.
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @since 2022
	 */
	global class CreateActionPlanRequest {
		@InvocableVariable(required=true label='The parent Record ID' description='Must have a relationship named the related record object name from Action Plan object')
		/**
		 * The parent Record ID. Must have a relationship named the related record object name from Action Plan object.
		 */
		global Id relatedRecordID;

		@InvocableVariable(required=false label='Days from trigger to start Action Plan' description='Defaults to 0, the day the plan is created')
		/**
		 * Days from trigger to start Action Plan. Defaults to 0, the day the plan is created.
		 */
		global Integer daysToActionPlanStart;

		@InvocableVariable(required=true label='The Template Id or Name to use' description='Name is not unique, so ID is preferred')
		/**
		 * The template Id or Name to use. (Name is not unique, so ID is preferred)
		 */
		global String templateNameOrID;

		@InvocableVariable(required=false label='Action Plan Name' description='If not specified, the Action Plan will be called <Template Name> - <Parent Record Name>')
		/**
		 * The Action Plan Name. If not specified, the Action Plan will be called <Template Name> - <Parent Record Name>
		 */
		global String actionPlanName;
	}
}