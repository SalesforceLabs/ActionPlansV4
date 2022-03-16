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
 * Extension for `Action Plan Template` Create/Edit page
 * @since v3
 * @author {@link [Rodrigo Birriel](https://www.linkedin.com/in/rbirriel)}
 * @author {@link [David Schach](https://github.com/dschach)}
 * @group Visualforce
 */
public with sharing class ActionPlanTemplateCreationController {
	private Double taskIndex;
	/**
	 * The Action Plan Template for this page
	 */
	@testVisible
	private ActionPlanTemplate__c actionPlanTemplate;
	/**
	 * Page SubTitle
	 */
	public String subTitle { get; private set; }
	/**
	 * Does the user have reminders enabled?
	 */
	public Boolean canDisplayReminder { get; private set; }
	/**
	 * Does the `Task` object have Record Types enabled?
	 */
	public Boolean taskHasRecordType { get; private set; }

	@testVisible
	private List<APTemplateTask__c> pendingTemplateTaskDeletes;
	/**
	 * If we are making this template from another template, the Id is stored here
	 */
	private Id templateId;

	/**
	 * Constructor
	 * <br>If we can obtain the Id from the page parameters then we search for that template and set the variable for that template.
	 * <br>If we can't obtain the Id from the page parameters then we create a new template and obtain from the controller.
	 * <br>Then we need to check if we are cloning the template; in that case clone the template without Id.
	 * @param stdController Standard Controller (`ActionPlanTemplate__c`)
	 */
	public ActionPlanTemplateCreationController(ApexPages.StandardController stdController) {
		this.taskIndex = 0;
		actionPlanTemplate = (ActionPlanTemplate__c) stdController.getRecord();

		if (ApexPages.currentPage().getParameters().get('clone') == '1') {
			if (ApexPages.currentPage().getParameters().containsKey('templateId')) {
				templateId = ActionPlansUtilities.getEscapedPageParameter('templateId');
				//System.debug('we have a template : ' + templateId);
			} else if (ApexPages.currentPage().getParameters().containsKey('Id') && ApexPages.currentPage().getParameters().get('Id') != null) {
				templateId = ActionPlansUtilities.getEscapedPageParameter('Id');
				//System.debug('using Id parameter : ' + templateId);
			}

			if (templateId != null) {
				ActionPlanTemplate__c apC = [SELECT Name, Description__c, SkipDay__c, SkipWeekends__c, TaskRecordTypeID__c FROM ActionPlanTemplate__c WHERE Id = :templateId LIMIT 1];

				actionPlanTemplate.Name = apC.Name;
				actionPlanTemplate.Description__c = apC.Description__c;
				actionPlanTemplate.SkipDay__c = apC.SkipDay__c;
				actionPlanTemplate.SkipWeekends__c = apC.SkipWeekends__c;
				actionPlanTemplate.TaskRecordTypeID__c = apC.TaskRecordTypeID__c;

				ApexPages.currentPage().getParameters().put('id', null);
			}
		}

		this.canDisplayReminder = ActionPlansUtilities.getCanDisplayReminder();
		this.taskHasRecordType = ActionPlansUtilities.taskUsesRecordTypes;

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
	 * Action on page load to ensure custom setting is created
	 * @return   `PageReference` null
	 */
	public PageReference onLoad() {
		ActionPlansUtilities.onPageLoad();
		if (getTemplateWrappers().isEmpty()) {
			addTemplateTask();
		}
		return null;
	}

	/**
	 * Standalone save action so the redirects are different for Save vs Save and New
	 * <br>First delete pending deletions, then upsert the template and its tasks,
	 * <br>then update dependencies
	 * @return `Boolean` Do we have an error?
	 */
	private Boolean doSave() {
		// check for pending Deletes; if something is pending send it to delete
		if (pendingTemplateTaskDeletes != null) {
			Database.delete(pendingTemplateTaskDeletes);
		}
		// update Action Plan Template object
		try {
			Database.upsert(actionPlanTemplate);
		} catch (Exception e) {
			ApexPages.addMessages(e);
			System.debug('ERROR: ' + e.getMessage());
			this.errorMsg = e.getMessage();
			return true;
		}

		// save tasks to the template and attach relation to Action Plan
		for (APTemplateTask__c t : aptTasks) {
			if (t.Action_Plan_Template__c == null) {
				t.Action_Plan_Template__c = actionPlanTemplate.Id;
			}
			if (t.DaysFromStart__c == null || t.DaysFromStart__c < 0) {
				t.DaysFromStart__c = 0;
			}
			t.DaysFromStart__c = math.abs(t.DaysFromStart__c);
		}

		try {
			Database.upsert(aptTasks);
		} catch (Exception e) {
			ApexPages.addMessages(e);
			System.debug('ERROR: ' + e.getMessage());
			this.errorMsg = e.getMessage();
			return true;
		}

		// run through the tasks and take care of dependents
		for (APTemplateTask__c t : aptTasks) {
			if (t.Dependent__c != null && t.Dependent__c != 'None') {
				t.TController__c = aptTasks[Integer.valueOf(t.Dependent__c)].Id;
			} else {
				t.TController__c = null;
				t.Dependent__c = 'None'; // Added for redundancy
			}
		}

		try {
			Database.update(aptTasks);
		} catch (Exception e) {
			ApexPages.addMessages(e);
			System.debug('ERROR: ' + e.getMessage());
			this.errorMsg = e.getMessage();
			return true;
		}
		return false;
	}

	/**
	 * Saves Action Plan Template and all tasks, then redirects to the AP template list.
	 * <br>First check for pending templates for delete; in case that exists then delete those objects.
	 * <br>Then insert or update the Action Plan Template pending to save and save tasks to the template
	 * and attach relation to Action Plan.
	 * @return `PageReference` Page.ActionPlanTemplateDetail
	 */
	public PageReference saveTemplate() {
		Boolean hasSaveError = doSave();
		if (hasSaveError) {
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
	 * @return `PageReference` Page.ActionPlanTemplateCreation
	 */
	public Pagereference saveAndNew() {
		Boolean hasSaveError = doSave();
		if (hasSaveError) {
			return null;
		}

		Pagereference newPage = Page.ActionPlanTemplateCreation;
		newPage.getParameters().clear();
		newPage.setRedirect(true);
		return newPage;
	}

	/**
	 * Cancel changes
	 * @return `PageReference` Object home or Template detail page
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
	 * Add a new row to the Template Tasks (but do not commit to the database)
	 */
	public void addTemplateTask() {
		taskIndex++;

		//in case the task limit is reached set a message error to display
		if (aptTasks.size() >= ActionPlansUtilities.MAX_APTASKS) {
			List<String> parameters = new List<String>();
			parameters.add(String.valueof(ActionPlansUtilities.MAX_APTASKS));
			errorMsg = String.format(System.Label.ap_Errors_TaskLimitError, parameters);
		} else {
			APTemplateTask__c t = new APTemplateTask__c();
			t.TaskIndex__c = taskIndex;
			aptTasks.add(t);
		}
	}

	/**
	 * Remove this row from the Template Tasks (but do not commit to the database)
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
				APTemplateTask__c aptTask = aptTasks.get(i);
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

			// before remove check if it exists in the DB. If so, add to pendingTemplateTaskDeletes to be deleted on save.
			if (aptTasks[taskIndex].Id != null) {
				if (pendingTemplateTaskDeletes == null) {
					pendingTemplateTaskDeletes = new List<APTemplateTask__c>();
				}
				pendingTemplateTaskDeletes.add(aptTasks[taskIndex]);
			}

			aptTasks.remove(taskIndex);

			// clear errorMsg if it's set.
			if (aptTasks.size() < ActionPlansUtilities.MAX_APTASKS) {
				errorMsg = null;
			}
		}
	}

	/**
	 * Iterate over aptTasks and generate wrappers for display on the page
	 * @return `List<ApTTaskWrapper>` All the template wrappers for display on the page
	 * @see ActionPlanTemplateCreationController.aptTasks
	 */
	public List<ApTTaskWrapper> getTemplateWrappers() {
		List<ApTTaskWrapper> tasksList = new List<ApTTaskWrapper>();

		Integer i = 0;
		for (APTemplateTask__c templateTask : aptTasks) {
			ApTTaskWrapper wrapper = new ApTTaskWrapper(templateTask, i, this.actionPlanTemplate.TaskRecordTypeID__c);
			tasksList.add(wrapper);
			i++;
		}
		if (i > 0) {
			tasksList[i - 1].isLast = true;
		}
		return tasksList;
	}

	@TestVisible
	private List<APTemplateTask__c> aptTasks {
		get {
			if (aptTasks == null) {
				aptTasks = new List<APTemplateTask__c>();
				aptTasks = getTemplateTasks();
			}
			return aptTasks;
		}
		set;
	}

	/**
	 * Single query for ActionPlan Template Tasks
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @param  templateId `APTemplate__c` Id
	 * @return          `List<APTemplateTask__c>` The related APTemplate Tasks
	 */
	private List<APTemplateTask__c> queryAPTTasks(Id templateId) {
		return [
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
			FROM APTemplateTask__c
			WHERE Action_Plan_Template__c = :templateId
			ORDER BY TaskIndex__c ASC
		];
	}

	/**
	 * Get all tasks related to the Action Template.
	 * @return `List<APTemplateTask__c>` ActionPlan Template Tasks
	 */
	public List<APTemplateTask__c> getTemplateTasks() {
		if (aptTasks.size() == 0) {
			if (actionPlanTemplate.Id != null) {
				aptTasks = queryAPTTasks(actionPlanTemplate.Id);
			} else {
				aptTasks = new List<APTemplateTask__c>();
				APTemplateTask__c t = new APTemplateTask__c();
				t.Reminder__c = ActionPlansUtilities.getCheckReminderByDefault();
				t.Priority__c = ActionPlansUtilities.getTaskRecordTypePriorityDefaultValues().get(actionPlanTemplate.TaskRecordTypeID__c);
				aptTasks.add(t);
			}

			// clone and clear ids
			if (ApexPages.currentPage().getParameters().get('clone') == '1') {
				aptTasks = queryAPTTasks(String.escapeSingleQuotes(templateId));
				List<APTemplateTask__c> tempTaskList = aptTasks.deepClone(false, false, false);
				aptTasks.clear();
				aptTasks = tempTaskList;

				// clear lookup relationship
				for (APTemplateTask__c t : aptTasks) {
					t.Action_Plan_Template__c = null;
				}
			}
		}
		return aptTasks;
	}

	/**
	 * Return size of the APTTemplate Tasks List.
	 * @return `Integer` the number of template tasks
	 */
	public Integer getTemplateTaskSize() {
		return aptTasks.size();
	}

	/**
	 * Call method getTemplateSubjectItems()
	 * @return `List<SelectOption>` the picklist of Task subjects
	 */
	public List<SelectOption> getTemplateSubjectItems() {
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('None', '--' + System.Label.ap_None + '--'));
		Integer i = 0;

		if (aptTasks != null) {
			for (APTemplateTask__c t : aptTasks) {
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
	 * @return `PageReference` to allow pass-through of save action
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
	 * @return `Boolean` cyclicErrorExists
	 */
	public Boolean templateCycleDependent() {
		this.errorMsg = null;
		Integer index = 0;

		for (APTemplateTask__c t : aptTasks) {
			if (t.Dependent__c != null && t.Dependent__c != 'None') {
				APTemplateTask__c link = aptTasks[Integer.valueOf(t.Dependent__c)];

				//task can not depend on themselves
				if (Integer.valueOf(t.Dependent__c) == index) {
					System.debug('self-dependency error ' + System.Label.ap_ItselfDependencyError);
					this.errorMsg = System.Label.ap_ItselfDependencyError;
					return true;
				}

				if (this.dependantCycle(link, index)) {
					//System.debug('cyclic-dependency error ' + System.Label.ap_Errors_RemoveCyclicDependency);
					this.errorMsg = System.Label.ap_Errors_RemoveCyclicDependency;
					return true;
				}
			}
			index++;
		}
		return false;
	}

	/**
	 * Check for dependent tasks
	 * @param inspectedTask We check against a specific task
	 * @param index The index (position) of the template task
	 * @return `Boolean` Is there a dependency for this task?
	 */
	private Boolean dependantCycle(APTemplateTask__c inspectedTask, Integer index) {
		Boolean hasDependency = false;
		Set<Integer> checkedTasks = new Set<Integer>();

		while (!hasDependency) {
			if (inspectedTask.Dependent__c != null && inspectedTask.Dependent__c != 'None') {
				if (checkedTasks.contains(Integer.valueOf(inspectedTask.Dependent__c))) {
					hasDependency = true;
					break;
				} else {
					checkedTasks.add(Integer.valueOf(inspectedTask.Dependent__c));
				}
			}

			if (inspectedTask.Dependent__c != null && inspectedTask.Dependent__c != 'None') {
				Integer tempIndexDestiny = Integer.valueOf(inspectedTask.Dependent__c);
				APTemplateTask__c link = aptTasks[tempIndexDestiny];

				if (link.Dependent__c != null && link.Dependent__c != 'None') {
					if (Integer.valueOf(link.Dependent__c) == index) {
						hasDependency = true;
						break;
					} else {
						//get next task in dependency chain
						inspectedTask = aptTasks[Integer.valueOf(inspectedTask.Dependent__c)];
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
	 * Store the value of the error message
	 */
	private String errorMsg;
	/**
	 * Getter method to return the error message from action plans utilities
	 * @return `String` errorMsg
	 * @see ActionPlanTemplateCreationController.errorMsg
	 */
	public String getErrorMsg() {
		return errorMsg;
	}

	/**
	 * Calculates the highest task index value
	 * @return `Double` maxIndex
	 */
	public Double calculateTaskIndexValue() {
		Double maxIndex = 0;
		for (APTemplateTask__c tsk : [SELECT Id, TaskIndex__c FROM APTemplateTask__c WHERE Action_Plan_Template__c = :actionPlanTemplate.Id]) {
			if (tsk.TaskIndex__c > maxIndex) {
				maxIndex = tsk.TaskIndex__c;
			}
		}

		return maxIndex;
	}

	/**
	 * Find user default recordtype
	 * @return `Id` The org default Task RecordTypeId
	 */
	public Id getDefaultTaskRecordTypeId() {
		return ActionPlansUtilities.getDefaultTaskRecordTypeId();
	}

	/**
	 * Generate picklist of Task Record Types
	 * @return `List<SelectOption>` A picklist of available Record Types
	 */
	public List<SelectOption> getTaskRTPicklistValues() {
		return ActionPlansUtilities.getTaskRTPicklistValues();
	}

	/**
	 * Generate picklist of Task Type
	 */
	private List<SelectOption> taskTypes;
	/**
	 * Generate a picklist of Task Type
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return `List<SelectOption>` Picklist of `Task.Type`
	 */
	public List<SelectOption> getTaskTypes() {
		if (taskTypes == null) {
			taskTypes = ActionPlansUtilities.getFieldOptions('Task', 'Type', null);
		}
		return taskTypes;
	}

	/**
	 * Generate picklist of Task Priority
	 */
	private List<SelectOption> taskPriorities;
	/**
	 * Generate picklist of Task Priorities
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return `List<SelectOption>` Picklist of `Task.Priority`
	 */
	public List<SelectOption> getTaskPriorities() {
		if (taskPriorities == null) {
			taskPriorities = ActionPlansUtilities.getFieldOptions('Task', 'Priority', true);
		}
		return taskPriorities;
	}

	/**
	 * Get the reminder time picklist options from the central utilities class
	 * @return `List<SelectOption>` Picklist of reminder times
	 */
	public List<SelectOption> getHoursOption() {
		return ActionPlansUtilities.getHoursOption();
	}

	/**
	 * Inner Wrapper Class for Action Plan Template Tasks
	 * @author {@link [Matias Menafra](https://www.linkedin.com/in/mmenafra)}
	 * @date 08/08/2010
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @date 05/2021
	 */
	public class ApTTaskWrapper {
		/**
		 * Action Plan Template Task in wrapper
		 * @return   The Action Plan Template Task
		 */
		public APTemplateTask__c task { get; set; }
		/**
		 * Task position (order on the page)
		 * @return  Index
		 */
		public Integer position { get; set; }
		/**
		 * Last Task
		 * @return   Is this AP Task the last in the list?
		 */
		public Boolean isLast { get; set; }

		/**
		 * Constructor for ActionPlan Template Task Wrapper
		 * @param apTask      Action Plan Template Task
		 * @param pos         Position/Index
		 * @param apTTaskRTId The RecordType of the related Task
		 */
		public ApTTaskWrapper(APTemplateTask__c apTask, Integer pos, Id apTTaskRTId) {
			task = apTask;
			position = pos;
			isLast = false;

			Id taskRTID = null;
			if (ActionPlansUtilities.taskUsesRecordTypes) {
				if (ActionPlansUtilities.getTaskRecordTypeStatusDefaultValues().containsKey(apTTaskRTId)) {
					taskRTID = apTTaskRTId;
				} else {
					taskRTID = ActionPlansUtilities.getDefaultTaskRecordTypeId();
				}
			}

			if (task.Id == null && task.Subject__c == null) {
				task.Priority__c = task.Priority__c != null ? task.Priority__c : ActionPlansUtilities.getTaskRecordTypePriorityDefaultValues().get(taskRTID);
				task.Type__c = ActionPlansUtilities.getTaskRecordTypeTypeDefaultValues().get(taskRTID);

				if (ApexPages.currentPage().getParameters().get('clone') != '1') {
					task.Reminder__c = ActionPlansUtilities.getCheckReminderByDefault();
				}
			}
			if (task.Id == null || !task.Reminder__c) {
				task.Minutes_Reminder__c = ActionPlansUtilities.getDefaultReminderMinutes();
			}
		}
	}
}