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
 * Set to WITHOUT sharing because this is only called from a trigger handler
 * @since 2011
 * @author David Schach
 * @group Trigger Handlers
 */
public without sharing class ActionPlansTaskTriggerUtilities {
	private static List<APTask__c> dependentAptts = new List<APTask__c>();
	private static List<Task> tasksSendEmail = new List<Task>();
	private static List<Task> tasksSendNoEmail = new List<Task>();

	/**
	 * Initialize the functionalities to create all dependent Tasks
	 * @param cTasks Map of Tasks by Id
	 */
	//@future
	public static void initDependentTaskWork(Map<Id, String> cTasks) {
		tasksSendEmail = new List<Task>();
		tasksSendNoEmail = new List<Task>();

		Set<Id> closedTasks = cTasks.keyset();

		if (!closedTasks.isEmpty()) {
			//Mark all APTasks as Completed
			updateActionPlansTemplateTaskStatus(cTasks);

			//Get all dependent APTasks
			List<APTask__c> dependentAptts = queryDependentAPTaskTemplates(closedTasks);

			//Create actual Task Map
			// * Method that returns an unused variable should be checked
			List<APTask__c> updList = populateNewTaskMap(dependentAptts); //NOPMD

			//Finally, create all New Tasks and Send DMLOption Emails
			List<APTask__c> updateApttsList = populateUpdateApttsList(dependentAptts);

			Database.DMLOptions dmlo = new Database.DMLOptions();

			if (!tasksSendEmail.isEmpty()) {
				dmlo.EmailHeader.triggerUserEmail = true;
				Database.insert(tasksSendEmail, dmlo);
			}

			if (!tasksSendNoEmail.isEmpty()) {
				dmlo.EmailHeader.triggerUserEmail = false;
				Database.insert(tasksSendNoEmail, dmlo);
			}

			update updateApttsList;
		}
	}

	/**
	 * Get list of dependent Action Plan Template Tasks
	 */
	/**
	 *  Get list of dependent Action Plan Template Tasks
	 * @param  closedTasks All `Task` records for which we are finding dependent Task Templates
	 * @return             The list of dependent Templates Tasks
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

		dependentAptts = Database.query(apdependentQuery);
		return dependentAptts;
	}

	/**
	 * Cycle through list of dependent Action Plans Template Task and create actual tasks
	 * @param dependentApttList
	 * @return List of AP Tasks to update
	 */
	private static List<APTask__c> populateNewTaskMap(List<APTask__c> dependentApttList) {
		List<APTask__c> updList = new List<APTask__c>();
		Task auxTask;

		Map<Id, Task> taskMap = new Map<Id, Task>();
		for (Task t : [SELECT Id, TaskAPTask__c FROM Task WHERE TaskAPTask__c = :dependentApttList]) {
			taskMap.put(t.TaskAPTask__c, t);
		}

		for (APTask__c dependentAptt : dependentApttList) {
			//Create the new task and template
			//check if the task was already created
			if (taskMap.containsKey(dependentAptt.Id)) {
				auxTask = taskMap.get(dependentAptt.Id);
			} else {
				auxTask = new Task();
			}

			auxTask.Subject = dependentAptt.Subject__c;
			auxTask.Priority = dependentAptt.Priority__c;
			auxTask.OwnerId = dependentAptt.User__c;
			auxTask.Type = dependentAptt.Type__c;
			auxTask.TaskAPTask__c = dependentAptt.Id;
			if (ActionPlansUtilities.taskUsesRecordTypes) {
				auxTask.put('RecordTypeId', dependentAptt.Task_RecordTypeId__c);
			}

			if (dependentAptt.Status__c == null) {
				String defaultStatus = ActionPlansUtilities.getTaskRecordTypeStatusDefaultValues().get(ActionPlansUtilities.getDefaultTaskRecordTypeId());

				auxTask.Status = defaultStatus;
				dependentAptt.Status__c = defaultStatus;
				updList.add(dependentAptt);
			}

			// create due date, calculate the due date of the tasks for skip weekends feature
			if (dependentAptt.Action_Plan__r.SkipWeekends__c == true && dependentAptt.Action_Plan__r.SkipDay__c != null) {
				dependentAptt.ActivityDate__c = ActionPlansUtilities.adjustTaskDueDate(
					dependentAptt.Action_Plan__r.StartDate__c,
					dependentAptt.DaysFromStart__c.intValue(),
					dependentAptt.Action_Plan__r.SkipDay__c
				);
			} else {
				dependentAptt.ActivityDate__c = dependentAptt.Action_Plan__r.StartDate__c.addDays(dependentAptt.DaysFromStart__c.intValue());
			}
		} // end for loop

		if (!updList.isEmpty()) {
			// no permission checks because trigger handlers should run in system mode
			upsert updList;
		}
		return updList;
	}

	/**
	 * Cycle through list of dependent Action Plans Template Task and create tasks
	 * @param dependentApttList
	 * @return the list of dependent Action Plan Tasks we just updated
	 */
	private static List<APTask__c> populateUpdateApttsList(List<APTask__c> dependentApttList) {
		List<APTask__c> updateApttsList = new List<APTask__c>();

		Set<Id> apIDs = new Set<Id>();
		Set<Id> controllingIDs = new Set<Id>();
		for (APTask__c dAptt : dependentApttList) {
			apIDs.add(dAptt.Action_Plan__c);
			controllingIDs.add(dAptt.Controller__c);
		}

		Map<Id, APTask__c> controllingTasks = new Map<Id, APTask__c>([SELECT Id, ActivityDate__c FROM APTask__c WHERE Id IN :controllingIDs]);

		Map<Id, Task> taskMap = new Map<Id, Task>();
		for (Task t : [SELECT Id, TaskAPTask__c FROM Task WHERE TaskAPTask__c = :dependentApttList]) {
			taskMap.put(t.TaskAPTask__c, t);
		}

		for (APTask__c dependentAptt : dependentApttList) {
			Task t2 = new Task();
			//Create the new task and template
			if (taskMap.containsKey(dependentAptt.Id)) {
				t2 = taskMap.get(dependentAptt.Id);
			}

			t2.Subject = dependentAptt.Subject__c;
			t2.Priority = dependentAptt.Priority__c;
			t2.OwnerId = dependentAptt.User__c;
			t2.TaskAPTask__c = dependentAptt.Id;
			if (ActionPlansUtilities.taskUsesRecordTypes) {
				t2.put('RecordTypeId', dependentAptt.Task_RecordTypeId__c);
			}

			Date d = Date.today();
			if (dependentAptt.Controller__c != null && controllingTasks.containsKey(dependentAptt.Controller__c) && controllingTasks.get(dependentAptt.Controller__c).ActivityDate__c != null) {
				d = controllingTasks.get(dependentAptt.Controller__c).ActivityDate__c;
			}

			dependentAptt.ActivityDate__c = d.addDays(dependentAptt.DaysFromStart__c.intValue());

			if (dependentAptt.Comments__c != null) {
				t2.Description = dependentAptt.Comments__c;
			}

			//set reminder based on user's default reminder setting
			if (dependentAptt.Reminder__c) {
				t2.isReminderSet = dependentAptt.Reminder__c;
				t2.ReminderDateTime = datetime.newInstance(dependentAptt.ActivityDate__c.year(), dependentAptt.ActivityDate__c.month(), dependentAptt.ActivityDate__c.day(), 0, 0, 0);
				t2.ReminderDateTime = t2.ReminderDateTime.addMinutes(Integer.valueOf(dependentAptt.Minutes_Reminder__c));
			}

			ActionPlan__c ap = dependentAptt.Action_Plan__r;

			Boolean setWho = true;
			for (String s : ActionPlansUtilities.getCustomRelationshipFields()) {
				String f = s;
				if (!f.equalsIgnoreCase(ActionPlansUtilities.namespacePrefix + 'Contact__c') && !f.equalsIgnoreCase(ActionPlansUtilities.namespacePrefix + 'Lead__c') && ap.get(f) != null) {
					t2.WhatId = (Id) ap.get(f);
					setWho = false;
					break;
				}
			}

			if (dependentAptt.Action_Plan__r.Contact__c != null && setWho) {
				t2.WhoId = dependentAptt.Action_Plan__r.Contact__c;
			} else if (dependentAptt.Action_Plan__r.Lead__c != null && setWho) {
				t2.WhoId = dependentAptt.Action_Plan__r.Lead__c;
			} else if (setWho) {
				System.debug('FAILED to set who');
			}

			t2.Type = dependentAptt.Type__c;

			String defaultStatus = ActionPlansUtilities.getTaskRecordTypeStatusDefaultValues().get(ActionPlansUtilities.getDefaultTaskRecordTypeId());
			t2.Status = defaultStatus;

			t2.ActivityDate = dependentAptt.ActivityDate__c;

			updateApttsList.add(dependentAptt);

			//populate the list to send emails or not.
			if (dependentAptt.SendEmail__c) {
				tasksSendEmail.add(t2);
			} else {
				tasksSendNoEmail.add(t2);
			}
		}
		return updateApttsList;
	}

	/**
	 * Update associated aptt of task to match status
	 * @param cTasks map of ActionPlan Tasks by Id
	 */
	private static void updateActionPlansTemplateTaskStatus(Map<Id, String> cTasks) {
		if (!cTasks.keyset().isEmpty()) {
			updateAPTasksStatus(cTasks);
		}
	}

	/**
	 * Update APTasks status as passed into method
	 * @param cTasks Map of ActionPlan Tasks by Id
	 */
	public static void updateAPTasksStatus(Map<Id, String> cTasks) {
		if (!cTasks.keyset().isEmpty()) {
			//Update all APTasks
			List<APTask__c> updateApttList = [SELECT Id, Status__c FROM APTask__c WHERE Id IN :cTasks.keyset()];

			for (APTask__c aptt : updateApttList) {
				aptt.Status__c = cTasks.get(aptt.Id);
			}

			update updateApttList;
		}
	}

	/**
	 * Delete Action Plan Tasks
	 * @param aPTasks Ids of APTasks to delete
	 */
	public static void deleteAPTasks(Set<Id> aPTasks) {
		try {
			List<APTask__c> toDelete = [SELECT aPT.Id FROM APTask__c aPT WHERE aPT.Id IN :aPTasks];
			delete toDelete;
		} catch (Exception e) {
			System.debug('Error deleting APTTemplate - probably a circular error when deleting a APTTemplate, then its Task, then the template again.');
		}
	}

	/**
	 * Delete Action Plan Tasks related Tasks
	 * @param apttIds
	 */
	//@future
	public static void deleteTasks(Set<Id> apttIds) {
		List<Task> toDelete = [SELECT Id FROM Task WHERE IsClosed = FALSE AND Id IN :apttIds];
		delete toDelete;
	}

	/*
	This method reviews the task list FOR A SINGLE ACTION PLAN and removes the one with TaskIndex__c field matching tmp_taskIndex.
	Rearranges the dependencies between tasks.
	*/
	private static void generateDependentTasksAndReset(List<APTask__c> apTasks, Decimal tmp_taskIndex) {
		Set<Id> pendingIdsToDelete = new Set<Id>();

		Integer taskIndex;
		Integer dependentApTaskIndex;

		for (Integer i = 0; i < apTasks.size(); i++) {
			APTask__c apTask = apTasks[i];
			if (apTask.TaskIndex__c == tmp_taskIndex) {
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

		// before remove check if it exists in the DB; if so, add to pendingDeletes to be deleted on save.
		if (apTasks[taskIndex].Id != null) {
			pendingIdsToDelete.add(apTasks[taskIndex].Id);
		}

		apTasks.remove(taskIndex);

		Set<Id> closedTasks = pendingIdsToDelete;

		if (!closedTasks.isEmpty()) {
			//Get all dependent APTask
			List<APTask__c> dependentAptts = queryDependentAPTaskTemplates(closedTasks);

			//Create actual Task Map
			List<APTask__c> updList = populateNewTaskMap(dependentAptts); //NOPMD

			//Finally, Create all New Tasks and Send DMLOption Emails
			List<APTask__c> updateApttsList = populateUpdateApttsList(dependentAptts); //NOPMD

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
	 */
	public static void actionsOnTaskBeforeDelete(Set<Id> cTasks) {
		tasksSendEmail = new List<Task>();
		tasksSendNoEmail = new List<Task>();

		// Uncommenting this so we surface our errors
		//try{

		Map<Id, APTask__c> apIdToAPTemplateMap = new Map<Id, APTask__c>();
		List<APTask__c> lAPT = [SELECT Id, Action_Plan__c, TaskIndex__c, Dependent__c FROM APTask__c WHERE Id IN :cTasks];

		//create a map with : (APTaskId, APTaskTemplate)
		for (APTask__c aptt : lAPT) {
			apIdToAPTemplateMap.put(aptt.Action_Plan__c, aptt);
		}

		/* Map<Id, List<APTask__c>> apTasksByActionPlan = new Map<Id, List<APTask__c>>();
			for(APTask__c aptt : lAPT){
				if( !apTasksByActionPlan.containsKey(aptt.Action_Plan__c)){
					apTasksByActionPlan.put(aptt.Action_Plan__c, new List<APTask__c>);
				}
				List<APTask__c> aptList = apTasksByActionPlan.get(aptt.Action_Plan__c);
				aptList.add(aptt);
				apTasksByActionPlan.put(aptt.Action_Plan__c, aptList);
			} */

		/* List<APTask__c> tmp_lAPT;
		 APTask__c aux; */

		// TODO: Bulkify this SOQL in a loop (see above commented code)
		for (Id apId : apIdToAPTemplateMap.keySet()) {
			List<APTask__c> tmp_lAPT = [SELECT Id, Action_Plan__c, TaskIndex__c, Dependent__c FROM APTask__c WHERE Action_Plan__c = :apId]; //NOPMD

			APTask__c aux = apIdToAPTemplateMap.get(apId);
			generateDependentTasksAndReset(tmp_lAPT, aux.TaskIndex__c);
		}
	}
}