@SuppressWarnings('PMD.AvoidGlobalModifier')
/*
Action Plans v4
David Schach 2022

Action Plans v3
Force.com Labs 2011
http://appexchange.salesforce.com/listingDetail?listingId=a0N30000003HcINEA0

BSD 3-Clause License

Copyright (c) 2022, salesforce.com, inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
/**
 * @group Invocable
 * @author David Schach
 * @since 2022
 */
global without sharing class ActionPlanCreateInvocable {
	/**
	 * Invocable Apex for creating Action Plans from a template, a parent ID, and days from now to start the task due dates
	 *
	 * @param requests Wrapper of `CreateActionPlanRequest`
	 * @return         `List<Id>` of the created Action Plans
	 */
	@InvocableMethod(label='Create Action Plan From Template' description='Takes a Template Name/Id and Record Id and makes an Action Plan for that record.' category='ActionPlans')
	global static List<Id> makeActionPlanFromTemplate(List<CreateActionPlanRequest> requests) {
		List<Id> resultIDs = new List<Id>();

		Set<String> templateNamesOrIDs = new Set<String>();
		for (CreateActionPlanRequest r : requests) {
			templateNamesOrIDs.add(r.templateNameOrID);
		}

		Map<String, ActionPlanTemplate__c> templateNameOrIdToTemplate = new Map<String, ActionPlanTemplate__c>();

		List<ActionPlanTemplate__c> possibleTemplates = [
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
					FROM ApTasks__r
					ORDER BY TaskIndex__c ASC
				)
			FROM ActionPlanTemplate__c
			WHERE Name IN :templateNamesOrIDs OR Id IN :templateNamesOrIDs
		];

		if (possibleTemplates.isEmpty()) {
			return resultIDs;
		}

		for (ActionPlanTemplate__c apt : possibleTemplates) {
			templateNameOrIdToTemplate.put(apt.Id, apt);
			templateNameOrIdToTemplate.put(apt.Name, apt);
		}

		Set<Id> relatedIDs = new Set<Id>();
		//Map<Id, SObject> relatedObjects = new Map<Id, SObject>();
		String relatedObjectName = requests[0].relatedRecordID.getSObjectType().getDescribe().getName();

		for (CreateActionPlanRequest r : requests) {
			relatedIDs.add(r.relatedRecordID);
		}

		Map<Id, ActionPlan__c> actionPlansToInsert = new Map<Id, ActionPlan__c>();

		Action_Plans_Settings__c mySettings = ActionPlansUtilities.getCustomSetting();

		Map<Id, Id> relatedObjectOwners = ActionPlansBatchBuilderUtilities.retrieveOwnersDataRelatedObject(relatedIDs, relatedObjectName);

		Set<String> actionPlanFields = Schema.SObjectType.ActionPlan__c.fields.getMap().keyset();

		for (CreateActionPlanRequest r : requests) {
			if (!templateNameOrIdToTemplate.containsKey(r.templateNameOrID)) {
				continue;
			}

			ActionPlanTemplate__c actionPlanTemplate = templateNameOrIdToTemplate.get(r.templateNameOrID);

			ActionPlan__c ap = new ActionPlan__c();
			ap.Name = ActionPlansUtilities.actionPlanSubjectToName(actionPlanTemplate.Name);
			ap.Description__c = actionPlanTemplate.Description__c;
			ap.SkipWeekends__c = actionPlanTemplate.SkipWeekends__c;
			ap.SkipDay__c = actionPlanTemplate.SkipDay__c;
			ap.Action_Plan_Template__c = actionPlanTemplate.Id;
			ap.TaskRecordTypeID__c = actionPlanTemplate.TaskRecordTypeID__c;
			ap.StartDate__c = Date.today().addDays(r.daysToActionPlanStart == null ? 0 : r.daysToActionPlanStart);

			for (String s : ActionPlansUtilities.getCustomRelationshipFields()) {
				ap.put(s, null);
			}

			Id relatedId = r.relatedRecordID;
			Schema.SObjectType token = relatedId.getSObjectType();
			Schema.DescribeSObjectResult sor = token.getDescribe();
			String relObjName = sor.getName().toLowerCase();

			String namespacePrefix = ActionPlansUtilities.namespacePrefix.toLowerCase();

			String relObjField = relObjName;

			if (!relObjName.endsWithIgnoreCase('__c')) {
				relObjField = relObjField + '__c';
			}

			//System.debug('relObjField ' + relObjField);
			//System.debug('namespaceField ' + namespacePrefix + relObjField);
			//System.debug(actionPlanFields);

			if (actionPlanFields.contains(namespacePrefix + relObjField)) {
				relObjField = namespacePrefix + relObjField;
			} else if (actionPlanFields.contains(relObjField)) {
				relObjField = relObjField;
			} else {
				//System.debug('Field not present. ' + relObjField);
				continue;
			}
			ap.put(relObjField, relatedId);
			actionPlansToInsert.put(r.relatedRecordID, ap);
		}

		if (actionPlansToInsert.isEmpty()) {
			return resultIDs;
		}

		insert actionPlansToInsert.values();

		Map<String, APTask__c> planTaskIndexToTask = new Map<String, APTask__c>();

		for (CreateActionPlanRequest r : requests) {
			if (!actionPlansToInsert.containsKey(r.relatedRecordID)) {
				//System.debug('PROBLEM: Did not create Action Plan.');
				continue;
			}

			ActionPlan__c ap = actionPlansToInsert.get(r.relatedRecordID);

			ActionPlanTemplate__c actionPlanTemplate = templateNameOrIdToTemplate.get(r.templateNameOrID);

			Id relatedId = r.relatedRecordID;

			for (APTemplateTask__c aptTask : actionPlanTemplate.apTasks__r) {
				Id userId;
				//Read the Custom Settings in order to asign the User to that Task
				if (aptTask.User__c != null) {
					userId = aptTask.User__c;
				} else if (aptTask.User__c == null && (mySettings != null && !mySettings.Unassigned_Task_Default__c)) {
					userId = UserInfo.getUserId();
				} else if (aptTask.User__c == null && (mySettings != null && mySettings.Unassigned_Task_Default__c)) {
					userId = relatedObjectOwners.get(relatedId);
				}

				APTask__c apTask = new APTask__c();
				apTask.Type__c = aptTask.Type__c;
				apTask.Subject__c = aptTask.Subject__c;
				apTask.Priority__c = aptTask.Priority__c;
				apTask.Dependent__c = aptTask.Dependent__c;
				apTask.TaskIndex__c = aptTask.TaskIndex__c;
				apTask.DaysFromStart__c = aptTask.DaysFromStart__c;
				apTask.User__c = userId;
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
				//System.debug('Our uniqueID is ' + ap.Id + '' + apTask.TaskIndex__c);
				planTaskIndexToTask.put(ap.Id + '' + apTask.TaskIndex__c, apTask);
			}
		}

		insert planTaskIndexToTask.values();

		// Now we have to update with the controlling/dependent task IDs

		List<APTask__c> dependentTasksToUpdate = new List<APTask__c>();

		for (APTask__c apTask : planTaskIndexToTask.values()) {
			String actionPlanPlusIndex = apTask.Action_Plan__c + '' + apTask.Dependent__c;

			if (planTaskIndexToTask.containsKey(actionPlanPlusIndex)) {
				apTask.Controller__c = planTaskIndexToTask.get(actionPlanPlusIndex).Id;
				dependentTasksToUpdate.add(apTask);
			}
		}

		Database.update(dependentTasksToUpdate);

		//Map<Id, Task> mapApTasks = new Map<Id, Task>();
		List<Task> myTasksWithOutEmail = new List<Task>();
		List<Task> myNewTasksWithEmail = new List<Task>();

		Map<Id, APTask__c> mapAP = new Map<Id, APTask__c>();
		for (APTask__c a : planTaskIndexToTask.values()) {
			mapAP.put(a.Id, a);
		}

		Map<Id, ActionPlan__c> insertedActionPlans = new Map<Id, ActionPlan__c>();
		for (ActionPlan__c ap : actionPlansToInsert.values()) {
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
				if (!f.equalsIgnoreCase(ActionPlansUtilities.namespacePrefix + 'Contact__c') && !f.equalsIgnoreCase(ActionPlansUtilities.namespacePrefix + 'Lead__c') && insertedAP.get(f) != null) {
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

			if (apTask.Dependent__c == 'None') {
				if (apTask.SendEmail__c == true) {
					myNewTasksWithEmail.add(t);
				} else {
					myTasksWithOutEmail.add(t);
				}
			}
		}

		Database.DMLOptions dmlo1 = new Database.DMLOptions();
		dmlo1.EmailHeader.triggerUserEmail = true;

		Database.DMLOptions dmlo2 = new Database.DMLOptions();
		dmlo2.EmailHeader.triggerUserEmail = false;

		if (myNewTasksWithEmail.size() > 0) {
			Database.insert(myNewTasksWithEmail, dmlo1);
		}

		if (myTasksWithOutEmail.size() > 0) {
			Database.insert(myTasksWithOutEmail, dmlo2);
		}

		Set<Id> relObjectIDs = new Set<Id>();
		for (ActionPlan__c ap : actionPlansToInsert.values()) {
			relObjectIDs.add(ap.Id);
		}

		if (mySettings != null && mySettings.Chatter_Object_Brag__c) {
			ActionPlansBatchBuilderUtilities.generateObjectFeeds(relObjectIDs);
		}

		for (CreateActionPlanRequest request : requests) {
			resultIDs.add(actionPlansToInsert.get(request.relatedRecordID).Id);
		}

		return resultIDs;
	}

	/**
	 * Wrapper class for ActionPlan Request for invocable Apex.
	 * <br>
	 * @author David Schach
	 * @since 2022
	 */
	global class CreateActionPlanRequest {
		@InvocableVariable(required=true label='The Template Id or Name to use' description='Name is not unique, so ID is preferred')
		/**
		 * The template Id or Name to use (accepts either, but Id is preferred)
		 */
		global String templateNameOrID;

		@InvocableVariable(required=true label='The parent Record ID' description='Must have a relationship named the related record object name from Action Plan object')
		/**
		 * The parent Record ID
		 */
		global Id relatedRecordID;

		@InvocableVariable(required=false label='Days from trigger to start Action Plan' description='Defaults to 0, the day the plan is created')
		/**
		 * Days from trigger to start Action Plan
		 */
		global Integer daysToActionPlanStart;
	}
}