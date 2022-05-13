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
 * @author {@link [Rodrigo Birriel](https://www.linkedin.com/in/rbirriel)}
 * @author {@link [David Schach](https://github.com/dschach)}
 * @group Visualforce
 * @since 2022
 */
public with sharing class ActionPlanDetailController {
	/**
	 * The Action Plan
	 */
	private ActionPlan__c actionPlan;
	/**
	 * Does the org have Record Types enabled for Task SObject
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return `Boolean` Yes/No
	 */
	public Boolean hasRecordType { get; set; }

	/**
	 * Does the user have reminders enabled? If not, do not shrae the reminder option
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return `Boolean` Yes/No
	 */
	public Boolean canDisplayReminder { get; private set; }

	/**
	 * Extension Constructor
	 * @param stdController `ActionPlan__c` Standard Controller
	 */
	public ActionPlanDetailController(ApexPages.StandardController stdController) {
		if (!Test.isRunningTest()) {
			stdController.addFields(ActionPlansUtilities.getCustomRelationshipFields());
		}
		actionPlan = (ActionPlan__c) stdController.getRecord();
		hasRecordType = ActionPlansUtilities.taskUsesRecordTypes;
		canDisplayReminder = ActionPlansUtilities.getCanDisplayReminder();
	}

	/**
	 * Action on page load to ensure custom setting is created
	 * @return   `PageReference` null (required for page actions method)
	 */
	public PageReference onLoad() {
		ActionPlansUtilities.onPageLoad();
		return null;
	}

	/**
	 * Deletes the current Action Plan loaded and redirects to the AP List
	 * @return `PageReference` Page to go to after deleting `ActionPlan__c`
	 */
	public PageReference deletePlan() {
		//delete ap, which will also delete apts via master-detail relationship
		try {
			delete actionPlan;
		} catch (Exception e) {
			ApexPages.addMessages(e);
			return null;
		}

		String retURL = '/' + ActionPlansUtilities.getObjectKeyPrefix(ActionPlansUtilities.namespacePrefix + 'ActionPlan__c') + '/o';

		Boolean hasTemplateIdParam = ApexPages.currentPage().getParameters().containsKey('templateId');
		Boolean hasRetURLParam = ApexPages.currentPage().getParameters().containsKey('retURL');

		if (hasTemplateIdParam) {
			retURL = '/' + ActionPlansUtilities.getEscapedPageParameter('templateId');
		} else if (hasRetURLParam && !ActionPlansUtilities.getIsLex()) {
			retURL = '' + ActionPlansUtilities.getEscapedPageParameter('retURL');
		}
		Pagereference newPage = new PageReference('' + retURL);
		newPage.setRedirect(true);

		return newPage;
	}

	/**
	 * Display ControllingTasks column only if there are controlling tasks
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return   `Boolean` is the Controller__c field populated for any Action Plan Tasks?
	 */
	public Boolean hasControllingTasks {
		get {
			hasControllingTasks = false;
			for (TaskWrapper tw : getActionPlanTasks()) {
				if (tw.apt.Controller__c != null) {
					hasControllingTasks = true;
					break;
				}
			}
			return hasControllingTasks;
		}
		set;
	}

	/**
	 * Memoized TaskWrappers for display on the page
	 */
	private List<TaskWrapper> apTaskWrapperList;
	/**
	 * Collect and return all TaskWrappers
	 * @return `List<TaskWrapper>` List of `TaskWrapper` for this Action Plan
	 */
	public List<TaskWrapper> getActionPlanTasks() {
		if (apTaskWrapperList == null) {
			apTaskWrapperList = new List<TaskWrapper>();
			Map<Id, APTask__c> apTaskMap = new Map<Id, APTask__c>(
				[
					SELECT
						Action_Plan__c,
						ActivityDate__c,
						Comments__c,
						Controller__c,
						Controller__r.Subject__c,
						DaysFromStart__c,
						Dependent__c,
						Id,
						IsClosed__c,
						Minutes_Reminder__c,
						Name,
						Priority__c,
						Reminder__c,
						SendEmail__c,
						Status__c,
						Subject__c,
						Task_RecordTypeId__c,
						TaskIndex__c,
						Time_Reminder__c,
						Type__c,
						User__c,
						User__r.Name
					FROM APTask__c
					WHERE Action_Plan__c = :actionPlan.Id
					ORDER BY TaskIndex__c ASC
				]
			);
			Map<Id, Id> taskTaskMap = new Map<Id, Id>();
			for (Task t : [SELECT Id, TaskAPTask__c FROM Task WHERE TaskAPTask__c IN :apTaskMap.keyset()]) {
				taskTaskMap.put(t.TaskAPTask__c, t.Id);
			}
			for (APTask__c a : apTaskMap.values()) {
				TaskWrapper tw;
				Id relatedTaskId = taskTaskMap.get(a.Id);
				tw = new TaskWrapper(a, relatedTaskId);
				apTaskWrapperList.add(tw);
			}
		}
		return apTaskWrapperList;
	}

	/**
	 * Wrapper for Action Plan Task
	 * <br>It contains the `Action Plan Task` and the `Task` Id
	 */
	public class TaskWrapper {
		/**
		 * The Action Plan Task
		 */
		public APTask__c apt { get; private set; }
		/**
		 * The (standard) `Task` Id
		 */
		public Id taskId { get; private set; }

		/**
		 * Constructor for the task wrapper
		 * @param aptParam    Action Plan Task Template
		 * @param taskIdParam TaskId (for the standard object `Task`)
		 */
		public TaskWrapper(APTask__c aptParam, Id taskIdParam) {
			this.apt = aptParam;
			this.taskId = taskIdParam;
		}
	}

	/**
	 * Checks if Action Plan Template has been changed since the creation of the Action Plan.
	 * @return `Boolean` Was the AP's template modified after the Action Plan was created?
	 */
	public Boolean getVersion() {
		if (actionPlan.Action_Plan_Template__c != null) {
			ActionPlanTemplate__c tempApt = [SELECT LastModifiedDate FROM ActionPlanTemplate__c WHERE Id = :actionPlan.Action_Plan_Template__c];
			if (tempApt.LastModifiedDate > actionPlan.createdDate) {
				return true;
			}
		}
		return false;
	}

	/**
	 * The label of the Action Plan's parent record SObject
	 * @return  `String` Label of the object related to this Action Plan
	 */
	public String getRelatedObjectLabel() {
		String objLabel = '';

		for (String f : ActionPlansUtilities.getCustomRelationshipFields()) {
			if (actionPlan.get(f) != null) {
				Id objId = (Id) actionPlan.get(f);
				Schema.DescribeSObjectResult dsr = ActionPlansUtilities.getRelatedRecordInfo(objId);
				objLabel = dsr.getLabel();
				break;
			}
		}
		return objLabel;
	}

	/**
	 * The name of the parent record - show a different field based on SObject Type
	 * @return  `String` name of the object related to this Action Plan
	 */
	public String getrelatedRecordName() {
		String objName = '';
		Id objId;

		for (String f : ActionPlansUtilities.getCustomRelationshipFields()) {
			if (actionPlan.get(f) != null) {
				objId = (Id) actionPlan.get(f);
				Schema.DescribeSObjectResult dsr = ActionPlansUtilities.getRelatedRecordInfo(objId);
				objName = dsr.getName();
				break;
			}
		}

		switch on objName {
			when 'Case' {
				Case c = [SELECT Id, Subject, CaseNumber FROM Case WHERE Id = :objId LIMIT 1];
				return c.CaseNumber + ': ' + c.Subject;
			}
			when 'Contract' {
				Contract c = [SELECT Id, ContractNumber FROM Contract WHERE Id = :objId LIMIT 1];
				return c.ContractNumber;
			}
			when else {
				String relNameQuery = 'SELECT Id, Name FROM ' + objName + ' WHERE Id = \'' + objId + '\'';
				SObject so = Database.query(relNameQuery)[0];
				return (String) so.get('Name');
			}
		}
	}

	/**
	 * Convert AP Task Record Type Id to Record Type Name
	 * @return Record Type Name
	 */
	public String getRecordTypeName() {
		String toReturn = '';
		if (ActionPlansUtilities.taskUsesRecordTypes) {
			Map<Id, Schema.RecordTypeInfo> rtMapById = Task.SObjectType.getDescribe().getRecordTypeInfosById();
			if (!rtMapById.isEmpty() && rtMapById.containsKey(actionPlan.TaskRecordTypeID__c)) {
				return rtMapById.get(actionPlan.TaskRecordTypeID__c).getName();
			}
		}
		return toReturn;
	}

	/**
	 * If we have no share object, we don't need to show a Share button
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return  `Boolean` Does the user have permission to share this Action Plan?
	 */
	public Boolean getCanShare() {
		return ActionPlansUtilities.canShareRecord(actionPlan.Id, actionPlan.OwnerId);
	}

	/**
	 * Does the user have permission to transfer? We query `UserRecordAccess` to find out.
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return   `Boolean` yes/no
	 */
	public Boolean getCanTransfer() {
		return ActionPlansUtilities.getCanTransfer(actionPlan.Id);
	}
}