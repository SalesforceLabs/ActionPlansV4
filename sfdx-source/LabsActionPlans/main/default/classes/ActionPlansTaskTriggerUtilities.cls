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
 * Set to WITHOUT sharing because this is only called from a trigger handler
 * @since 2022
 * @author {@link [David Schach](https://github.com/dschach)}
 * @group Trigger Handlers
 */
public without sharing class ActionPlansTaskTriggerUtilities {
	private static List<APTask__c> dependentApts = new List<APTask__c>();
	private static List<Task> tasksSendEmail = new List<Task>();
	private static List<Task> tasksSendNoEmail = new List<Task>();

	/**
	 * Initialize the functionalities to create all dependent Tasks
	 * @param taskIdMap Map of Tasks by Id
	 */
	public static void initDependentTaskWork(Map<Id, String> taskIdMap) {
		tasksSendEmail = new List<Task>();
		tasksSendNoEmail = new List<Task>();

		Set<Id> closedTasks = taskIdMap.keyset();

		if (!closedTasks.isEmpty()) {
			//Mark all APTasks as Completed
			updateAPTasksStatus(taskIdMap);

			//Get all dependent APTasks
			List<APTask__c> dependentApts = queryDependentAPTaskTemplates(closedTasks);

			//Upsert dependent APTasks
			upsertDependentAPTasks(dependentApts); //NOPMD

			//Finally, create all New Tasks and Send DMLOption Emails
			List<APTask__c> updateAptsList = populateUpdateApttsList(dependentApts);

			Database.DMLOptions dmlo = new Database.DMLOptions();

			List<Task> allTasksToInsert = new List<Task>();

			if (!tasksSendEmail.isEmpty()) {
				dmlo.EmailHeader.triggerUserEmail = true;
				for (Task t : tasksSendEmail) {
					t.setOptions(dmlo);
					allTasksToInsert.add(t);
				}
				//Database.insert(tasksSendEmail, dmlo);
			}

			if (!tasksSendNoEmail.isEmpty()) {
				dmlo.EmailHeader.triggerUserEmail = false;
				for (Task t : tasksSendNoEmail) {
					t.setOptions(dmlo);
					allTasksToInsert.add(t);
				}
				//Database.insert(tasksSendNoEmail, dmlo);
			}
			insert allTasksToInsert;

			Database.update(updateAptsList); //NOPMD
		}
	}

	/**
	 * Get list of dependent Action Plan Template Tasks
	 */
	/**
	 *  Get list of dependent Action Plan Template Tasks
	 * @param  closedTasks All `Task` records for which we are finding dependent Task Templates
	 * @return             `List<APTask__c>` The list of dependent Templates Tasks
	 */
	private static List<APTask__c> queryDependentAPTaskTemplates(Set<Id> closedTasks) {
		String apdependentQuery = 'SELECT Action_Plan__r.SkipWeekends__c, Action_Plan__r.SkipDay__c, ';

		apdependentQuery += 'Action_Plan__r.' + String.join(ActionPlansUtilities.getCustomRelationshipFields(), ', Action_Plan__r.') + ', ';

		apdependentQuery +=
			' Action_Plan__r.StartDate__c, Action_Plan__c, Type__c, Subject__c, ActivityDate__c, ' +
			'Dependent__c, Name, User__c, User__r.Name, Id, DaysFromStart__c, CreatedById, ' +
			'Controller__r.Subject__c, Controller__c, SendEmail__c,  Controller__r.Name, ' +
			'Reminder__c, Priority__c, Status__c, Comments__c, Minutes_Reminder__c, Task_RecordTypeId__c' +
			' FROM APTask__c WHERE Controller__c IN :closedTasks';
		System.debug('apdependentquery ' + apdependentQuery);

		dependentApts = Database.query(String.escapeSingleQuotes(apdependentQuery));
		return dependentApts;
	}

	/**
	 * Cycle through list of dependent Action Plans Tasks and create `Task` records
	 * @param dependentAptList The APTasks we check for dependencies before making `Task` records
	 */
	private static void upsertDependentAPTasks(List<APTask__c> dependentAptList) {
		List<APTask__c> apTasksToUpsert = new List<APTask__c>();
		Task auxTask;

		Map<Id, Task> taskMap = new Map<Id, Task>();
		for (Task t : [SELECT Id, TaskAPTask__c FROM Task WHERE TaskAPTask__c = :dependentAptList]) {
			taskMap.put(t.TaskAPTask__c, t);
		}

		for (APTask__c dependentApt : dependentAptList) {
			//Create the new task and template
			//check if the task was already created
			if (taskMap.containsKey(dependentApt.Id)) {
				auxTask = taskMap.get(dependentApt.Id);
			} else {
				auxTask = new Task();
			}

			auxTask.Subject = dependentApt.Subject__c;
			auxTask.Priority = dependentApt.Priority__c;
			auxTask.OwnerId = dependentApt?.User__c == null ? UserInfo.getUserId() : dependentApt.User__c;
			auxTask.Type = dependentApt.Type__c;
			auxTask.TaskAPTask__c = dependentApt.Id;
			if (ActionPlansUtilities.taskUsesRecordTypes) {
				auxTask.put('RecordTypeId', dependentApt.Task_RecordTypeId__c);
			}

			if (dependentApt.Status__c == null) {
				String defaultStatus = ActionPlansUtilities.getTaskRecordTypeStatusDefaultValues().get(ActionPlansUtilities.getDefaultTaskRecordTypeId());

				auxTask.Status = defaultStatus;
				dependentApt.Status__c = defaultStatus;
				apTasksToUpsert.add(dependentApt);
			}

			// create due date, calculate the due date of the tasks for skip weekends feature
			if (dependentApt.Action_Plan__r.SkipWeekends__c == true && dependentApt.Action_Plan__r.SkipDay__c != null) {
				dependentApt.ActivityDate__c = ActionPlansUtilities.adjustTaskDueDate(
					dependentApt.Action_Plan__r.StartDate__c,
					dependentApt.DaysFromStart__c.intValue(),
					dependentApt.Action_Plan__r.SkipDay__c
				);
			} else {
				dependentApt.ActivityDate__c = dependentApt.Action_Plan__r.StartDate__c.addDays(dependentApt.DaysFromStart__c.intValue());
			}
		} // end for loop

		if (!apTasksToUpsert.isEmpty()) {
			// no permission checks because trigger handlers should run in system mode
			upsert apTasksToUpsert;
		}
	}

	/**
	 * Cycle through list of dependent Action Plans Template Task and create tasks
	 * @param dependentAptList Dependent APTasks (with value in `Controller__c`)
	 * @return `List<APTask__c>` the list of dependent Action Plan Tasks we just updated
	 */
	private static List<APTask__c> populateUpdateApttsList(List<APTask__c> dependentAptList) {
		List<APTask__c> updateAptsList = new List<APTask__c>();

		Set<Id> apIDs = new Set<Id>();
		Set<Id> controllingIDs = new Set<Id>();
		for (APTask__c dApt : dependentAptList) {
			apIDs.add(dApt.Action_Plan__c);
			controllingIDs.add(dApt.Controller__c);
		}

		Map<Id, APTask__c> controllingTasks = new Map<Id, APTask__c>([SELECT Id, ActivityDate__c FROM APTask__c WHERE Id IN :controllingIDs]);

		Map<Id, Task> taskMap = new Map<Id, Task>();
		for (Task t : [SELECT Id, TaskAPTask__c FROM Task WHERE TaskAPTask__c = :dependentAptList]) {
			taskMap.put(t.TaskAPTask__c, t);
		}

		for (APTask__c dependentApt : dependentAptList) {
			Task t2 = new Task();
			//Create the new task and template
			if (taskMap.containsKey(dependentApt.Id)) {
				t2 = taskMap.get(dependentApt.Id);
			}

			t2.Subject = dependentApt.Subject__c;
			t2.Priority = dependentApt.Priority__c;
			t2.OwnerId = dependentApt?.User__c == null ? UserInfo.getUserId() : dependentApt.User__c;
			t2.TaskAPTask__c = dependentApt.Id;
			if (ActionPlansUtilities.taskUsesRecordTypes) {
				t2.put('RecordTypeId', dependentApt.Task_RecordTypeId__c);
			}

			Date d = Date.today();
			if (
				dependentApt.Controller__c != null &&
				controllingTasks.containsKey(dependentApt.Controller__c) &&
				controllingTasks.get(dependentApt.Controller__c).ActivityDate__c != null
			) {
				d = controllingTasks.get(dependentApt.Controller__c).ActivityDate__c;
			}

			dependentApt.ActivityDate__c = d.addDays(dependentApt.DaysFromStart__c.intValue());

			if (dependentApt.Comments__c != null) {
				t2.Description = dependentApt.Comments__c;
			}

			//set reminder based on user's default reminder setting
			if (dependentApt.Reminder__c) {
				t2.isReminderSet = dependentApt.Reminder__c;
				t2.ReminderDateTime = datetime.newInstance(dependentApt.ActivityDate__c.year(), dependentApt.ActivityDate__c.month(), dependentApt.ActivityDate__c.day(), 0, 0, 0);
				t2.ReminderDateTime = t2.ReminderDateTime.addMinutes(Integer.valueOf(dependentApt.Minutes_Reminder__c));
			}

			ActionPlan__c ap = dependentApt.Action_Plan__r;

			Boolean setWho = true;
			for (String s : ActionPlansUtilities.getCustomRelationshipFields()) {
				String f = s;
				if (
					!f.equalsIgnoreCase(ActionPlansUtilities.namespacePrefix + 'Contact__c') &&
					!f.equalsIgnoreCase(ActionPlansUtilities.namespacePrefix + 'Lead__c') &&
					ap.get(f) != null
				) {
					t2.WhatId = (Id) ap.get(f);
					setWho = false;
					break;
				}
			}

			if (dependentApt.Action_Plan__r.Contact__c != null && setWho) {
				t2.WhoId = dependentApt.Action_Plan__r.Contact__c;
			} else if (dependentApt.Action_Plan__r.Lead__c != null && setWho) {
				t2.WhoId = dependentApt.Action_Plan__r.Lead__c;
			} else if (setWho) {
				System.debug('FAILED to set who');
			}

			t2.Type = dependentApt.Type__c;

			String defaultStatus = ActionPlansUtilities.getTaskRecordTypeStatusDefaultValues().get(ActionPlansUtilities.getDefaultTaskRecordTypeId());
			t2.Status = defaultStatus;

			t2.ActivityDate = dependentApt.ActivityDate__c;

			updateAptsList.add(dependentApt);

			//populate the list to send emails or not.
			if (dependentApt.SendEmail__c) {
				tasksSendEmail.add(t2);
			} else {
				tasksSendNoEmail.add(t2);
			}
		}
		return updateAptsList;
	}

	/**
	 * Update APTasks status as passed into method to match Task Status
	 * @param apTasksMap Map of ActionPlan Tasks by Id to Status
	 */
	public static void updateAPTasksStatus(Map<Id, String> apTasksMap) {
		if (!apTasksMap.keyset().isEmpty()) {
			//Update all APTasks
			List<APTask__c> updateApttList = [SELECT Id, Status__c FROM APTask__c WHERE Id IN :apTasksMap.keyset()];

			for (APTask__c apt : updateApttList) {
				apt.Status__c = apTasksMap.get(apt.Id);
			}

			update updateApttList;
		}
	}

	/**
	 * Delete Action Plan Tasks
	 * @param aPTasks Ids of APTasks to delete
	 */
	public static void deleteAPTasks(Set<Id> aPTasks) {
		// We allow a silent failure here because these APTasks may already have been deleted before,
		// and we don't have a sophisticated trigger framework in place
		List<APTask__c> toDelete = [SELECT aPT.Id FROM APTask__c aPT WHERE aPT.Id IN :aPTasks];
		Database.delete(toDelete, false);
	}

	/**
	 * Delete Action Plan Tasks' related Tasks
	 * @param taskIDs `Task` IDs to delete
	 */
	@future
	public static void futureDeleteTasks(Set<Id> taskIDs) {
		delete [SELECT Id FROM Task WHERE IsClosed = FALSE AND Id IN :taskIDs];
	}

	/**
	 * This method reviews the task list FOR A SINGLE ACTION PLAN and removes the one with `TaskIndex__c` field matching taskIndexToDelete.
	 * <br>Rearranges the dependencies between tasks.
	 * @param  apTasks           All the Action Plan Tasks for the Action Plan
	 * @param  taskIndexToDelete The index of the task we are trying to delete
	 */
	private static void generateDependentTasksAndReset(List<APTask__c> apTasks, Decimal taskIndexToDelete) {
		Set<Id> pendingIdsToDelete = new Set<Id>();

		Integer taskIndex;
		Integer dependentApTaskIndex;

		for (Integer i = 0; i < apTasks.size(); i++) {
			APTask__c apTask = apTasks[i];
			if (apTask.TaskIndex__c == taskIndexToDelete) {
				taskIndex = i;
			}
		}

		//update the current dependent position from tasks below deleted one.
		for (Integer i = 0; i < apTasks.size(); i++) {
			APTask__c apTask = apTasks[i];

			if (apTask.Dependent__c != null && apTask.Dependent__c != 'None') {
				dependentApTaskIndex = Integer.valueOf(apTask.Dependent__c);

				if (dependentApTaskIndex > taskIndex) {
					apTask.Dependent__c = String.valueOf(dependentApTaskIndex - 1);
				} else {
					if (dependentApTaskIndex == taskIndex) {
						apTask.Dependent__c = 'None';
						apTask.Controller__c = null;
					}
				}
			}
		}

		// before remove check if it exists in the DB; if so, add to pendingIdsToDelete to be deleted on save.
		if (apTasks[taskIndex].Id != null) {
			pendingIdsToDelete.add(apTasks[taskIndex].Id);
		}

		apTasks.remove(taskIndex);

		Set<Id> closedTasks = pendingIdsToDelete;

		if (!closedTasks.isEmpty()) {
			//Get all dependent APTask
			List<APTask__c> dependentApts = queryDependentAPTaskTemplates(closedTasks);

			//Upsert dependent APTasks
			upsertDependentAPTasks(dependentApts); //NOPMD

			//Finally, Create all New Tasks and Send DMLOption Emails
			List<APTask__c> updateAptsList = populateUpdateApttsList(dependentApts); //NOPMD

			Database.DMLOptions dmlo = new Database.DMLOptions();

			if (!tasksSendEmail.isEmpty()) {
				dmlo.EmailHeader.triggerUserEmail = true;
				Database.insert(tasksSendEmail, dmlo);
			}

			if (!tasksSendNoEmail.isEmpty()) {
				dmlo.EmailHeader.triggerUserEmail = false;
				Database.insert(tasksSendNoEmail, dmlo);
			}
		}
		update apTasks;
	}

	/**
	 * Before deleting an APTemplate task, initialize the functionalities to create all dependent Tasks and reset index
	 * @param cTasks Set of Task template IDs to be deleted
	 * @see ActionPlansTaskTriggerUtilities.generateDependentTasksAndReset
	 */
	public static void actionsOnTaskBeforeDelete(Set<Id> cTasks) {
		tasksSendEmail = new List<Task>();
		tasksSendNoEmail = new List<Task>();

		Map<Id, APTask__c> apIdToAPTaskMap = new Map<Id, APTask__c>();
		List<APTask__c> lAPT = [SELECT Id, Action_Plan__c, TaskIndex__c, Dependent__c FROM APTask__c WHERE Id IN :cTasks];

		//create a map with : (APTaskId, APTaskTemplate)
		for (APTask__c apt : lAPT) {
			apIdToAPTaskMap.put(apt.Action_Plan__c, apt);
		}

		/* Map<Id, List<APTask__c>> apTasksByActionPlan = new Map<Id, List<APTask__c>>();
			for(APTask__c apt : lAPT){
				if( !apTasksByActionPlan.containsKey(apt.Action_Plan__c)){
					apTasksByActionPlan.put(apt.Action_Plan__c, new List<APTask__c>);
				}
				List<APTask__c> aptList = apTasksByActionPlan.get(apt.Action_Plan__c);
				aptList.add(apt);
				apTasksByActionPlan.put(apt.Action_Plan__c, aptList);
			} */

		/* List<APTask__c> tmp_lAPT;
		 APTask__c aux; */

		for (ActionPlan__c ap : [SELECT Id, (SELECT Id, Action_Plan__c, TaskIndex__c, Dependent__c FROM APTasks1__r) FROM ActionPlan__c WHERE Id IN :apIdToAPTaskMap.keyset()]) {
			APTask__c aux = apIdToAPTaskMap.get(ap.Id);
			generateDependentTasksAndReset(ap.apTasks1__r, aux.TaskIndex__c);
		}

		/* // TODO: Bulkify this SOQL in a loop (see above commented code)
		for (Id apId : apIdToAPTaskMap.keySet()) {
			List<APTask__c> tmp_lAPT = [SELECT Id, Action_Plan__c, TaskIndex__c, Dependent__c FROM APTask__c WHERE Action_Plan__c = :apId]; //NOPMD

			APTask__c aux = apIdToAPTaskMap.get(apId);
			generateDependentTasksAndReset(tmp_lAPT, aux.TaskIndex__c);
		} */
	}
}