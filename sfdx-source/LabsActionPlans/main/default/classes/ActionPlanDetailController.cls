/*
Action Plans v4
David Schach 2021

Action Plans v3
Force.com Labs 2011
http://appexchange.salesforce.com/listingDetail?listingId=a0N30000003HcINEA0

BSD 3-Clause License

Copyright (c) 2021, salesforce.com, inc.
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
 * @group Visualforce
 */
public with sharing class ActionPlanDetailController {
	private ActionPlan__c actionPlan;
	public Boolean hasRecordType { get; set; }
	public Boolean canDisplayReminder { get; private set; }

	/**
	 * Constructor
	 */
	public ActionPlanDetailController(ApexPages.StandardController stdController) {
		actionPlan = (ActionPlan__c) stdController.getRecord();

		hasRecordType = ActionPlansUtilities.HAS_RECORD_TYPE;

		canDisplayReminder = ActionPlansUtilities.getCanDisplayReminder();
	}

	/**
	 * Deletes the current Action Plan loaded and redirects to the AP List
	 * @return newPage
	 */
	public PageReference deletePlan() {
		//delete ap, which will also delete apts via master-detail relationship
		try {
			new ActionPlansSafely().doDelete(actionPlan);
		} catch (Exception e) {
			ApexPages.addMessages(e);
			return null;
		}

		SetupEntityAccess[] accessSettings = [
			SELECT Id
			FROM SetupEntityAccess
			WHERE
				SetupEntityId IN (
					SELECT Id
					FROM ApexPage
					WHERE
						//NamespacePrefix = :your_namespace AND
						Name = 'ActionPlansHome'
				)
				AND ParentId IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId())
		];
		Boolean useString = true;
		String retURL = '/' + ActionPlansUtilities.namespacePrefix + ActionPlansUtilities.getObjectKeyPrefix(ActionPlansUtilities.namespacePrefix + 'ActionPlan__c') + '/o';

		if (ApexPages.currentPage().getParameters().get('templateId') != null) {
			retUrl = '/' + ApexPages.currentPage().getParameters().get('templateId');
		} else if (ApexPages.currentPage().getParameters().get('retURL') != null && !ActionPlansUtilities.getIsLex()) {
			retURL = '' + ApexPages.currentPage().getParameters().get('retURL');
		}
		Pagereference newPage = new PageReference('' + retURL);
		newPage.setRedirect(true);

		return newPage;
	}

	/**
	 * Collect and return all TaskWrappers
	 */
	private List<TaskWrapper> apTaskWrapperList;
	public List<TaskWrapper> getActionPlanTasks() {
		if (apTaskWrapperList == null) {
			apTaskWrapperList = new List<TaskWrapper>();
			Map<Id, APTaskTemplate__c> apTaskMap = new Map<Id, APTaskTemplate__c>(
				[
					SELECT
						Action_Plan__c,
						ActivityDate__c,
						Controller__c,
						Controller__r.Subject__c,
						Comments__c,
						DaysFromStart__c,
						Dependent__c,
						Id,
						IsClosed__c,
						Minutes_Reminder__c,
						Name,
						Priority__c,
						Reminder__c,
						Time_Reminder__c,
						SendEmail__c,
						Status__c,
						Subject__c,
						Task_RecordTypeId__c,
						TaskIndex__c,
						Type__c,
						User__c,
						User__r.Name
					FROM APTaskTemplate__c
					WHERE Action_Plan__c = :actionPlan.Id
					ORDER BY TaskIndex__c ASC
				]
			);
			Map<Id, Id> taskTaskMap = new Map<Id, Id>();
			for (Task t : [SELECT Id, TaskAPTaskTemplate__c FROM Task WHERE TaskAPTaskTemplate__c IN :apTaskMap.keyset()]) {
				taskTaskMap.put(t.TaskAPTaskTemplate__c, t.Id);
			}
			for (APTaskTemplate__c a : apTaskMap.values()) {
				TaskWrapper tw;
				Id relatedTaskId = taskTaskMap.get(a.Id);
				tw = new TaskWrapper(a, relatedTaskId);
				apTaskWrapperList.add(tw);
			}
		}
		return apTaskWrapperList;
	}

	public class TaskWrapper {
		public APTaskTemplate__c apt { get; private set; }
		public Id taskId { get; private set; }

		public TaskWrapper(APTaskTemplate__c aptParam, Id taskIdParam) {
			this.apt = aptParam;
			this.taskId = taskIdParam;
		}
	}

	/**
	 * Returns number of completed tasks
	 */
	public Integer getCompleted() {
		if (actionPlan.Id == null) {
			return 0;
		}

		List<APTaskTemplate__c> ts = [
			SELECT Id
			FROM APTaskTemplate__c
			WHERE Status__c IN :ActionPlansUtilities.getClosedTaskStatuses() AND ActivityDate__c != NULL AND Action_Plan__c = :actionPlan.Id
		];

		return (ts != null) ? ts.size() : 0;
	}

	/**
	 * Checks if Action Plan Template has been changed since the creation of the Action Plan.
	 * @return Boolean
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
	 *
	 * @return  label of the object related to this Action Plan
	 */
	public String getRelatedObjectLabel() {
		String objLabel = '';

		for (String f : ActionPlansUtilities.getCustomRelationshipFields()) {
			if (actionPlan.get(f) != null) {
				Id objId = (Id) actionPlan.get(f);
				Schema.DescribeSObjectResult dsr = objId.getSObjectType().getDescribe();
				objLabel = dsr.getLabel();
				break;
			}
		}
		return objLabel;
	}

	/**
	 *
	 * @return  name of the object related to this Action Plan
	 */
	public String getrelatedRecordName() {
		String objName = '';
		Id objId;

		for (String f : ActionPlansUtilities.getCustomRelationshipFields()) {
			if (actionPlan.get(f) != null) {
				objId = (Id) actionPlan.get(f);
				Schema.DescribeSObjectResult dsr = objId.getSObjectType().getDescribe();
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
	 * Convert Record Type Id to Record Type Name
	 * @return Record Type Name
	 */
	public String getRecordTypeName() {
		String toReturn = '';
		if (ActionPlansUtilities.HAS_RECORD_TYPE) {
			Map<Id, Schema.RecordTypeInfo> rtMapById = Task.SObjectType.getDescribe().getRecordTypeInfosById();
			if (!rtMapById.isEmpty() && rtMapById.containsKey(actionPlan.TaskRecordTypeID__c)) {
				return rtMapById.get(actionPlan.TaskRecordTypeID__c).getName();
			}
		}
		return toReturn;
	}
}
