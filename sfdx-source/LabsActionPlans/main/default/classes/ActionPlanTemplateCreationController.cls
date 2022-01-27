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
public with sharing class ActionPlanTemplateCreationController {
	private Double taskIndex;
	@testVisible
	private ActionPlanTemplate__c actionPlanTemplate;
	public String subTitle { get; private set; }
	public Boolean canDisplayReminder { get; private set; }
	public Boolean taskHasRecordType { get; private set; }
	public List<APTTaskTemplate__c> pendingTemplateDeletes;
	private Id templateId;

	/**
	 * Constructor
	 * If we can obtain the Id from the page parameters then we search for that template and set the variable for that template.
	 * If we can't obtain the Id from the page parameters then we create a new template and obtain from the controller.
	 * Then we need to check if we are cloning the template; in that case clone the template without Id.
	 */
	public ActionPlanTemplateCreationController(ApexPages.StandardController stdController) {
		this.taskIndex = 0;
		actionPlanTemplate = (ActionPlanTemplate__c) stdController.getRecord();

		if (ApexPages.currentPage().getParameters().get('clone') == '1') {
			if (ApexPages.currentPage().getParameters().containsKey('templateId')) {
				templateId = ApexPages.currentPage().getParameters().get('templateId');
				//System.debug('we have a template : ' + templateId);
			} else if (ApexPages.currentPage().getParameters().containsKey('Id') && ApexPages.currentPage().getParameters().get('Id') != null) {
				templateId = ApexPages.currentPage().getParameters().get('Id');
				//System.debug('using Id parameter : ' + templateId);
			}

			if (templateId != null) {
				//System.debug('templateId ' + templateId);
				//System.debug('CLONING');

				ActionPlanTemplate__c apC = [SELECT Name, Description__c, SkipDay__c, SkipWeekends__c, TaskRecordTypeID__c FROM ActionPlanTemplate__c WHERE Id = :templateId LIMIT 1];

				actionPlanTemplate.Name = apC.Name;
				actionPlanTemplate.Description__c = apC.Description__c;
				actionPlanTemplate.SkipDay__c = apC.SkipDay__c;
				actionPlanTemplate.SkipWeekends__c = apC.SkipWeekends__c;
				actionPlanTemplate.TaskRecordTypeID__c = apC.TaskRecordTypeID__c;

				//templateId = ApexPages.currentPage().getParameters().get('templateId');

				ApexPages.currentPage().getParameters().put('id', null);
			}
		}

		this.canDisplayReminder = ActionPlansUtilities.getCanDisplayReminder();
		this.taskHasRecordType = ActionPlansUtilities.HAS_RECORD_TYPE;

		if (actionPlanTemplate.Id != null) {
			taskIndex = calculateTaskIndexValue();
			subTitle = ActionPlanTemplate.Name;
		} else {
			if (taskHasRecordType) {
				actionPlanTemplate.TaskRecordTypeID__c = getDefaultTaskRecordTypeId();
			}
			this.taskIndex = 0;
			this.subTitle = System.Label.ap_New + ' ' + Schema.getGlobalDescribe().get(ActionPlansUtilities.namespacePrefix + 'ActionPlanTemplate__c').getDescribe().getLabel();
		}
	}

	/**
	 * Saves Action Plan Template and all tasks, then redirects to the AP template list.
	 * First check for pending templates for delete, in case that exists then delete those objects.
	 * Then insert or update the Action Plan Template pending to save and save tasks to the template
	 * and attach relation to Action Plan.
	 * @return newPage
	 */
	public PageReference saveTemplate() {
		// check for pendingDeletes, if something is pending send it to delete
		if (pendingTemplateDeletes != null) {
			Database.delete(pendingTemplateDeletes);
		}

		// update Action Plan Template object
		try {
			Database.upsert(actionPlanTemplate);
		} catch (Exception e) {
			ApexPages.addMessages(e);
			return null;
		}

		// save tasks to the template and attach relation to Action Plan
		for (APTTaskTemplate__c t : aptTasks) {
			if (t.Action_Plan_Template__c == null) {
				t.Action_Plan_Template__c = actionPlanTemplate.Id;
			}
			if (t.DaysFromStart__c < 0) {
				t.DaysFromStart__c = 0;
			}
			t.DaysFromStart__c = math.abs(t.DaysFromStart__c);
		}

		try {
			Database.upsert(aptTasks);
		} catch (Exception e) {
			ApexPages.addMessages(e);
			return null;
		}

		// run through the tasks and take care of dependents
		for (APTTaskTemplate__c t : aptTasks) {
			if (t.Dependent__c != null && t.Dependent__c != 'None') {
				t.TController__c = aptTasks[Integer.valueOf(t.Dependent__c)].Id;
			} else {
				t.TController__c = null;
			}
		}

		try {
			Database.update(aptTasks);
		} catch (Exception e) {
			ApexPages.addMessages(e);
			return null;
		}

		// Send the user to the detail page for the new account.
		PageReference newPage = Page.ActionPlanTemplateDetail;
		newPage.getParameters().put('Id', actionPlanTemplate.Id);
		newPage.setRedirect(true);
		return newPage;
	}

	/**
	 * Save and go to New page for Save and New
	 * @return PageReference
	 */
	public Pagereference saveAndNew() {
		try {
			saveTemplate();
		} catch (Exception ex) {
			ApexPages.addMessages(ex);
		}
		Pagereference newPage = Page.ActionPlanTemplateCreation;
		newPage.setRedirect(true);
		return newPage;
	}

	/**
	 * Call method cancelTemplate()
	 * @return PageReference
	 */
	public PageReference cancelTemplate() {
		PageReference newPage;

		if (actionPlanTemplate.Id == null) {
			// Send the user to the list of templates.
			newPage = new PageReference('/' + Schema.ActionPlanTemplate__c.SObjectType.getDescribe().getKeyPrefix() + '/o');
		} else {
			// Send the user to the detail page for the new account.
			newPage = Page.ActionPlanTemplateDetail;
			newPage.getParameters().put('Id', actionPlanTemplate.Id);
		}
		newPage.setRedirect(true);

		return newPage;
	}

	/**
	 * Call method addTemplateTask()
	 */
	public void addTemplateTask() {
		taskIndex++;

		Boolean hasNoErrors = false;
		//in case the task limit is reached set a message error to display
		if (aptTasks.size() >= ActionPlansUtilities.MAX_APTASKS) {
			List<String> parameters = new List<String>();
			parameters.add(String.valueof(ActionPlansUtilities.MAX_APTASKS));
			errorMsg = String.format(System.Label.ap_Errors_TaskLimitError, parameters);
		} else {
			APTTaskTemplate__c t = new APTTaskTemplate__c();
			t.TaskIndex__c = taskIndex;
			aptTasks.add(t);
		}
	}

	/**
	 * Call method removeTemplateTask()
	 */
	public void removeTemplateTask() {
		if (ApexPages.currentPage().getParameters().get('remove') != null) {
			Integer taskIndex = Integer.valueOf(ApexPages.currentPage().getParameters().get('remove'));

			//check for dependent children and clear them since the parent is being removed.
			aptTasks[taskIndex].TController__c = null;
			aptTasks[taskIndex].Dependent__c = null;

			Integer dependentApTask;

			//update the current dependent position from tasks below of deleted one.
			for (Integer i = 0; i < aptTasks.size(); i++) {
				APTTaskTemplate__c aptTask = aptTasks.get(i);
				if (aptTask.Dependent__c != null && aptTask.Dependent__c != 'None') {
					dependentApTask = Integer.valueOf(aptTask.Dependent__c);
					if (dependentApTask > taskIndex) {
						aptTask.Dependent__c = String.valueOf(dependentApTask - 1);
					} else if (dependentApTask == taskIndex) {
						aptTask.Dependent__c = 'None';
						aptTask.TController__c = null;
					}
				}
			}

			// before remove check if it exists in the DB. If so, add to pendingTemplateDeletes to be deleted on save.
			if (aptTasks[taskIndex].Id != null) {
				if (pendingTemplateDeletes == null) {
					pendingTemplateDeletes = new List<APTTaskTemplate__c>();
				}
				pendingTemplateDeletes.add(aptTasks[taskIndex]);
			}

			aptTasks.remove(taskIndex);

			// clear errorMsg if it's set.
			if (aptTasks.size() < ActionPlansUtilities.MAX_APTASKS) {
				errorMsg = null;
			}
		}
	}

	/**
	 * Iterate over aptTasks
	 */
	public List<ApTTaskWrapper> getTemplateWrappers() {
		ApTTaskWrapper apTTaskWrapper;
		List<ApTTaskWrapper> tasksList = new List<ApTTaskWrapper>();

		Integer i = 0;
		for (APTTaskTemplate__c aptTaskTemplate : aptTasks) {
			ApTTaskWrapper = new ApTTaskWrapper(aptTaskTemplate, i, this.actionPlanTemplate.TaskRecordTypeID__c);
			tasksList.add(ApTTaskWrapper);
			i++;
		}
		tasksList[i - 1].isLast = true;
		return tasksList;
	}

	@TestVisible
	private List<APTTaskTemplate__c> aptTasks {
		get {
			if (aptTasks == null) {
				aptTasks = new List<APTTaskTemplate__c>();
				aptTasks = getTemplateTasks();
			}
			return aptTasks;
		}
		set;
	}

	/**
	 * Get all tasks related to the Action Template.
	 * @return aptTasks
	 */
	public List<APTTaskTemplate__c> getTemplateTasks() {
		if (aptTasks.size() == 0) {
			if (actionPlanTemplate.Id != null) {
				aptTasks = [
					SELECT
						Type__c,
						Subject__c,
						Priority__c,
						Dependent__c,
						Name,
						User__c,
						TaskIndex__c,
						Minutes_Reminder__c,
						User__r.Name,
						Id,
						DaysFromStart__c,
						CreatedById,
						Action_Plan_Template__c,
						TController__c,
						TController__r.Subject__c,
						Reminder__c,
						SendEmail__c,
						Comments__c
					FROM APTTaskTemplate__c
					WHERE Action_Plan_Template__c = :actionPlanTemplate.Id
					ORDER BY TaskIndex__c ASC
				];
			} else {
				aptTasks = new List<APTTaskTemplate__c>();
				APTTaskTemplate__c t = new APTTaskTemplate__c(); //(APTTaskTemplate__c)APTTaskTemplate__c.getSObjectType().newSObject(null, true);
				t.Reminder__c = ActionPlansUtilities.getCheckReminderByDefault();
				t.Priority__c = ActionPlansUtilities.getTaskRecordTypePriorityDefaultValues().get(actionPlanTemplate.TaskRecordTypeID__c); //(String)Task.Priority.getDescribe().getDefaultValue();
				aptTasks.add(t);
			}

			// clone and clear ids
			if (ApexPages.currentPage().getParameters().get('clone') == '1') {
				aptTasks = [
					SELECT
						Type__c,
						Subject__c,
						Priority__c,
						Dependent__c,
						Name,
						User__c,
						TaskIndex__c,
						Minutes_Reminder__c,
						User__r.Name,
						Id,
						DaysFromStart__c,
						CreatedById,
						Action_Plan_Template__c,
						TController__c,
						TController__r.Subject__c,
						Reminder__c,
						SendEmail__c,
						Comments__c
					FROM APTTaskTemplate__c
					WHERE Action_Plan_Template__c = :templateId
					ORDER BY TaskIndex__c ASC
				];

				List<APTTaskTemplate__c> tempTaskList = aptTasks.deepClone(false, false, false);
				aptTasks.clear();
				aptTasks = tempTaskList;

				// clear lookup relationship also
				for (APTTaskTemplate__c t : aptTasks) {
					if (t.Action_Plan_Template__c != null) {
						t.Action_Plan_Template__c = null;
					}
				}
			}
		}

		return aptTasks;
	}

	/**
	 * Return size of the APTTemplate Tasks List.
	 */
	public Integer getTemplateTaskSize() {
		return aptTasks.size();
	}

	/**
	 * Call method getTemplateSubjectItems()
	 */
	public List<SelectOption> getTemplateSubjectItems() {
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('None', '--' + System.Label.ap_None + '--'));
		Integer i = 0;

		if (aptTasks != null) {
			for (APTTaskTemplate__c t : aptTasks) {
				if (t.Subject__c != null) {
					options.add(new SelectOption(String.valueOf(i), t.Subject__c + ' (' + (i + 1) + ')'));
				}
				i++;
			}
		}

		return options;
	}

	/**
	 * Checks if Action Plan Tasks has cyclic dependency.
	 * @return PageReference
	 */
	public PageReference checkCycleDependent() {
		if (this.templateCycleDependent()) {
			return null;
		} else {
			return this.saveTemplate();
		}
	}

	/**
	 * Checks if Action Plans Tasks has cyclic dependency.
	 * @return Boolean cyclicErrorExists
	 */
	public Boolean templateCycleDependent() {
		this.errorMsg = null;
		Integer index = 0;

		for (APTTaskTemplate__c t : aptTasks) {
			if (t.Dependent__c != null && t.Dependent__c != 'None') {
				APTTaskTemplate__c link = aptTasks[Integer.valueOf(t.Dependent__c)];

				//task can not depend on themselves
				if (Integer.valueOf(t.Dependent__c) == index) {
					System.debug('self-dependency error ' + System.Label.ap_ItselfDependencyError);
					this.errorMsg = System.Label.ap_ItselfDependencyError;
					return true;
				}

				if (this.dependantCycle(link, index)) {
					System.debug('cyclic-dependency error ' + System.Label.ap_Errors_RemoveCyclicDependency);
					this.errorMsg = System.Label.ap_Errors_RemoveCyclicDependency;
					return true;
				}
			}
			index++;
		}
		return false;
	}

	/**
	 *
	 * @param destinyTask
	 * @param index
	 * @return Boolean
	 */
	private Boolean dependantCycle(APTTaskTemplate__c destinyTask, Integer index) {
		Boolean hasDependency = false;
		Set<Integer> visitedTasks = new Set<Integer>();

		while (!hasDependency) {
			if (destinyTask.Dependent__c != null && destinyTask.Dependent__c != 'None') {
				if (visitedTasks.contains(Integer.valueOf(destinyTask.Dependent__c))) {
					hasDependency = true;
					break;
				} else {
					visitedTasks.add(Integer.valueOf(destinyTask.Dependent__c));
				}
			}

			if (destinyTask.Dependent__c != null && destinyTask.Dependent__c != 'None') {
				Integer tempIndexDestiny = Integer.valueOf(destinyTask.Dependent__c);
				APTTaskTemplate__c link = aptTasks[tempIndexDestiny];

				if (link.Dependent__c != null && link.Dependent__c != 'None') {
					if (Integer.valueOf(link.Dependent__c) == index) {
						hasDependency = true;
						break;
					} else {
						//get next task in dependency chain
						destinyTask = aptTasks[Integer.valueOf(destinyTask.Dependent__c)];
					}
				} else {
					break;
				}
			} else {
				break;
			}
		}

		return hasDependency;
	}

	/**
	 * Getter method to return the error message from
	 * action plans utilities
	 * @return errorMsg
	 */
	private String errorMsg;
	public String getErrorMsg() {
		return errorMsg;
	}

	/**
	 * Calculates the highest task index value
	 * @return maxIndex
	 */
	public Double calculateTaskIndexValue() {
		Double maxIndex = 0;
		for (APTTaskTemplate__c tsk : [SELECT Id, TaskIndex__c FROM APTTaskTemplate__c WHERE Action_Plan_Template__c = :actionPlanTemplate.Id]) {
			if (tsk.TaskIndex__c > maxIndex) {
				maxIndex = tsk.TaskIndex__c;
			}
		}

		return maxIndex;
	}

	/**
	 * Find user default recordtype
	 */
	public Id getDefaultTaskRecordTypeId() {
		return ActionPlansUtilities.getDefaultTaskRecordTypeId();
	}

	/**
	 * Generate picklist of Task Record Types
	 */
	public List<SelectOption> getTaskRTPicklistValues() {
		return ActionPlansUtilities.getTaskRTPicklistValues();
	}

	/**
	 * Generate picklist of Task Types
	 */
	private List<SelectOption> taskTypes;
	public List<SelectOption> getTaskTypes() {
		if (taskTypes == null) {
			taskTypes = ActionPlansUtilities.getFieldOptions('Task', 'Type', null);
		}
		return taskTypes;
	}

	/**
	 * Generate picklist of Task Priorities
	 */
	private List<SelectOption> taskPriorities;
	public List<SelectOption> getTaskPriorities() {
		if (taskPriorities == null) {
			taskPriorities = ActionPlansUtilities.getFieldOptions('Task', 'Priority', null);
		}
		return taskPriorities;
	}

	public List<SelectOption> getHoursOption() {
		return ActionPlansUtilities.getHoursOption();
	}

	/**
	 * Inner Wrapper Class for Action Plan Template Tasks
	 * @author Matias Menafra
	 * @createddate 08/08/2010
	 * @author David Schach
	 * @updateddate 05/2021
	 */
	public class ApTTaskWrapper {
		public APTTaskTemplate__c task { get; set; }
		public Integer position { get; set; }
		public Boolean isLast { get; set; }

		public ApTTaskWrapper(APTTaskTemplate__c apTask, Integer pos, Id apTTaskRTId) {
			task = apTask;
			position = pos;
			isLast = false;

			Id taskRTID = null;
			if (ActionPlansUtilities.HAS_RECORD_TYPE) {
				if (ActionPlansUtilities.getTaskRecordTypeStatusDefaultValues().containsKey(apTTaskRTId)) {
					taskRTID = apTTaskRTId;
				} else {
					taskRTID = ActionPlansUtilities.getDefaultTaskRecordTypeId();
				}
			}

			if (task.Id == null && task.Subject__c == null) {
				task.Priority__c = task.Priority__c != null ? task.Priority__c : ActionPlansUtilities.getTaskRecordTypePriorityDefaultValues().get(taskRTID);
				task.Type__c = ActionPlansUtilities.getTaskRecordTypeTypeDefaultValues().get(taskRTID);

				if (System.currentPageReference().getParameters().get('clone') != '1') {
					task.Reminder__c = ActionPlansUtilities.getCheckReminderByDefault();
				}
			}
			if (task.Id == null || !task.Reminder__c) {
				task.Minutes_Reminder__c = ActionPlansUtilities.getDefaultReminderMinutes();
			}
		}
	}
}