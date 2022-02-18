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
 * Controller for ActionPlan Create and ActionPlan Edit screens (the same page overrides both actions)
 * @group Visualforce
 * @author Rodrigo Birriel
 * @author David Schach
 * @since 2011
 * @see ActionPlanCreateInvocable
 */
public with sharing class ActionPlanCreationController {
	private Double taskIndex;
	@TestVisible
	private ActionPlan__c actionPlan;
	private Id templateId;
	/**
	 * Related Record IDs
	 */
	private Set<Id> relatedRecordIDs { get; set; }
	/**
	 * Related Object Name (Plural)
	 */
	public String relatedObjLabelPlural { get; set; }

	/**
	 * Is there a related record or template when we load the page?
	 */
	public Boolean hasRelated { get; set; }
	/**
	 * Set to true if a relationship field is filled
	 */
	public Boolean hasRelatedObject { get; set; }
	/**
	 * The name of the object (the same as the relationship field, except for standard objects) the AP is related to.
	 * <br>NOT the name of the related record
	 */
	public String relatedObjectName { get; private set; }
	/**
	 * The field on the related record we use to display on the ActionPlan. (Not Name for Case and Contract)
	 */
	public String relatedObjDisplayField { get; set; }

	private String errorMsg;
	/**
	 * Is the User able to see reminders?
	 */
	public Boolean canDisplayReminder { get; set; }
	private Map<Id, ApTaskWrapper> mapTasksListBkp;
	/**
	 * The subtitle shown on the page
	 */
	public String subtitle { get; set; }

	@testVisible
	private List<APTask__c> apTasks;
	private List<APTask__c> pendingDeletes;

	private String cloneParam = '0';
	@testVisible
	private Boolean inVisualforceContext = false;

	/**
	 * Constructor for ActionPlan Create/Edit Page
	 * @author David Schach
	 * @param  stdController `ActionPlan__c` standard controller
	 */
	public ActionPlanCreationController(ApexPages.StandardController stdController) {
		this.inVisualforceContext = true;

		this.taskIndex = 0;

		this.hasRelated = false;
		this.hasRelatedObject = false;
		this.relatedRecordIDs = new Set<Id>();
		this.mapTasksListBkp = new Map<Id, ApTaskWrapper>();
		this.actionPlan = (ActionPlan__c) stdController.getRecord();

		this.apTasks = getAPTasks();

		this.cloneParam = ActionPlansUtilities.getEscapedPageParameter('clone');
		this.templateId = ActionPlansUtilities.getEscapedPageParameter('templateId');
		this.refId = ActionPlansUtilities.getEscapedPageParameter('refId');
		this.refType = ActionPlansUtilities.getEscapedPageParameter('refType');

		if (cloneParam == '1') {
			initCloneActionPlan();
		} else if (this.actionPlan.Id != null) {
			initEditActionPlan();
		} else if (this.templateId != null) {
			initNewActionPlanFromTemplate(this.inVisualforceContext);
		} else {
			initNewActionPlan();
		}

		this.canDisplayReminder = ActionPlansUtilities.getCanDisplayReminder();
		this.relatedFieldName = getRelatedObjectOptions()[0].getValue();
	}

	/**
	 * Initalize controller for editing an Action Plan
	 */
	private void initEditActionPlan() {
		this.hasRelatedObject = this.hasRelatedObject();
		this.taskIndex = this.calculateAPTaskIndexValue();
		this.subtitle = this.actionPlan.Name;
	}

	/**
	 * Initalize controller for cloning an Action Plan
	 */
	private void initCloneActionPlan() {
		this.actionPlan.StartDate__c = Date.today();
		this.actionPlan.SkipWeekends__c = false;
		this.actionPlan.Name = null;
		this.subtitle = this.actionPlan.Name;

		List<APTask__c> tC = this.apTasks.deepClone(false, true);

		this.apTasks.clear();
		this.apTasks = tC;

		// clear task relations
		for (APTask__c t : this.apTasks) {
			t.Action_Plan__c = null;
		}

		for (String s : ActionPlansUtilities.getCustomRelationshipFields()) {
			this.actionPlan.put(s, null);
		}

		this.hasRelatedObject = false;
		this.hasRelated = false;
	}

	/**
	 * Initalize controller for creating a new Action Plan from a template
	 * <br>Used so we can instantiate this controller from Invocable Apex
	 * @author David Schach
	 * @param visualforceContext Are we in Visualforce context?
	 */
	private void initNewActionPlanFromTemplate(Boolean visualforceContext) {
		initNewActionPlanFromTemplate(visualforceContext, null);
	}

	/**
	 * initNewActionPlanFromTemplate description
	 * @author David Schach
	 * @param  visualforceContext visualforceContext description
	 * @param  apt                apt description
	 */
	private void initNewActionPlanFromTemplate(Boolean visualforceContext, ActionPlanTemplate__c apt) {
		this.initNewActionPlan();
		ActionPlanTemplate__c actionPlanTemplate;
		if (apt == null) {
			List<ActionPlanTemplate__c> listAPT = [
				SELECT Id, Name, Description__c, LastModifiedDate, SkipWeekends__c, SkipDay__c, TaskRecordTypeID__c
				FROM ActionPlanTemplate__c
				WHERE Id = :this.templateId
			];
			if (!listAPT.isEmpty()) {
				actionPlanTemplate = listAPT.get(0);
			}
		} else {
			actionPlanTemplate = apt;
		}

		this.actionPlan.Name = ActionPlansUtilities.actionPlanSubjectToName(actionPlanTemplate.Name);
		this.actionPlan.Description__c = actionPlanTemplate.Description__c;
		this.actionPlan.SkipWeekends__c = actionPlanTemplate.SkipWeekends__c;
		this.actionPlan.SkipDay__c = actionPlanTemplate.SkipDay__c == null ? '' : actionPlanTemplate.SkipDay__c;
		this.actionPlan.Action_Plan_Template__c = actionPlanTemplate.Id;
		this.actionPlan.TaskRecordTypeID__c = actionPlanTemplate.TaskRecordTypeID__c;

		if (visualforceContext) {
			this.taskIndex = this.calculateAPTTaskIndexValue();
			this.subtitle = System.Label.ap_New + ' ' + Schema.getGlobalDescribe().get(getNamespacePrefix() + 'ActionPlan__c').getDescribe().getLabel();
		}
		this.apTasks = this.getAPTasks();
	}

	/**
	 * Initalize controller for creating a new Action Plan
	 */
	private void initNewActionPlan() {
		this.actionPlan.StartDate__c = Date.today();
		this.actionPlan.SkipWeekends__c = false;
		if (taskHasRecordType) {
			this.actionPlan.TaskRecordTypeID__c = getDefaultTaskRecordTypeId();
		}
		if (refId != null) {
			this.hasRelated = true;
			this.referedObjectInit();
		}
		this.subtitle = System.Label.ap_New + ' ' + Schema.getGlobalDescribe().get(getNamespacePrefix() + 'ActionPlan__c').getDescribe().getLabel();
	}

	/**
	 * If the Task object has Record Types enabled, return `true`
	 * @return Does the Task object have Record Types enabled?
	 */
	public Boolean taskHasRecordType {
		get {
			if (taskHasRecordType == null) {
				taskHasRecordType = ActionPlansUtilities.taskUsesRecordTypes;
			}
			return taskHasRecordType;
		}
		private set;
	}

	/**
	 * Get the specific lookup field used by this Aciton Plan
	 * @author David Schach
	 * @return   The field Name
	 */
	public String relatedFieldName {
		get {
			if (relatedFieldName == null) {
				relatedFieldName = getRelatedObjectOptions()[0].getValue();
			}
			return relatedFieldName;
		}
		set {
			relatedFieldName = value;
			if (relatedFieldName == null) {
				relatedFieldName = getRelatedObjectOptions()[0].getValue();
			}
			if (!relatedFieldName.endsWithIgnoreCase('__c')) {
				relatedFieldName += '__c';
			}
			Schema.DescribeFieldResult dfr = Schema.sObjectType.ActionPlan__c.fields.getMap().get(relatedFieldName).getDescribe();
			Schema.SObjectType sot = dfr.getReferenceTo()[0];
			Schema.DescribeSObjectResult dsr = sot.getDescribe();
			this.relatedObjectName = dsr.getName();
			System.debug('relatedObjectName: ' + this.relatedObjectName);
			this.relatedObjDisplayField = chooseDisplayField(this.relatedObjectName);
			System.debug('objectDisplayField: ' + this.relatedObjDisplayField);
		}
	}

	private Action_Plans_Settings__c mySettings {
		get {
			System.debug('mySettings ' + mySettings);
			if (mySettings == null) {
				mySettings = ActionPlansUtilities.getCustomSetting();
			}
			System.debug('mysettings: ' + mySettings);
			return mySettings;
		}
		private set;
	}

	/**
	 * Utility method for checking if we default ownership to parent record owner if we can't edit the field
	 * <br>This could be replaced by a $Setup tag in Visualforce, but our logic may become more complex here
	 * @return      `Boolean` Is the Custom Setting present, and do we default uneditable assigned user fields to the parent record owner?
	 */
	public Boolean getAssignToParentOwner() {
		return mySettings.Unassigned_Task_Default_to_Owner__c;
	}

	/**
	 * Based on the related object name, we display a field from that object as the related record
	 * @author David Schach
	 * @param  objectName SObject Name
	 * @return            The display field
	 */
	private String chooseDisplayField(String objectName) {
		switch on objectName {
			when 'Case' {
				return 'CaseNumber';
			}
			when 'Contract' {
				return 'ContractNumber';
			}
			when else {
				return 'Name';
			}
		}
	}

	/**
	 * Action on page load to ensure custom setting is created
	 * @return   null (required for page actions method)
	 */
	public PageReference onLoad() {
		ActionPlansUtilities.onPageLoad();
		if (getTasks().isEmpty()) {
			addTask();
		}
		return null;
	}

	/**
	 * Getter and Setter for refId (related record Id)
	 */
	public String refId {
		get {
			if (refId == null) {
				refId = ActionPlansUtilities.getEscapedPageParameter('refId'); //String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('refId'));
			}
			return refId;
		}
		set;
	}

	/**
	 * Getter and Setter for RefType (related object Name)
	 */
	public String refType {
		get {
			if (refType == null && refId != null) {
				Id shortId = refId.left(15);
				refType = shortId.getSobjectType().getDescribe().getName();
			} else if (refId == null) {
				refType = ActionPlansUtilities.getEscapedPageParameter('refType'); //String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('refType'));
			}
			return refType;
		}
		set;
	}

	/**
	 * Returns the related object Id from lookup fields.
	 * @return the related object id
	 */
	@testVisible
	private Id relatedObjectId() {
		Id currentId;
		for (String s : ActionPlansUtilities.getCustomRelationshipFields()) {
			if (actionPlan.get(s) != null) {
				currentId = (Id) actionPlan.get(s);
				break;
			}
		}

		return currentId;
	}

	/**
	 * Check if the action plan has a related object
	 * @return Is a relationship field filled?
	 */
	public Boolean hasRelatedObject() {
		for (String f : ActionPlansUtilities.getCustomRelationshipFields()) {
			if (actionPlan.get(f) != null) {
				return true;
			}
		}
		return false;
	}

	/**
	 * Check if have pending Tasks to delete
	 */
	private void checkPendingDeletes() {
		if (this.pendingDeletes != null && !pendingDeletes.isEmpty()) {
			List<Task> tasksToDelete = new List<Task>();
			Set<Id> deleteApttIds = new Set<Id>();

			for (APTask__c deleteAptt : this.pendingDeletes) {
				deleteApttIds.add(deleteAptt.Id);
			}
			//do not delete completed tasks
			tasksToDelete = [SELECT Id FROM Task WHERE TaskAPTask__c IN :deleteApttIds AND IsClosed = FALSE];
			/* if(CanTheUser.destroy('Task') ){
				delete tasksToDelete;
			} */
			Database.delete(tasksToDelete);
			/* if(CanTheUser.destroy('APTask__c')){
				delete pendingDeletes;
			} */
			Database.delete(pendingDeletes);
		}
	}

	/**
	 * Action which saves a new Action Plan
	 * @return PageReference
	 * @see ActionPlanCreationController.saveHandler
	 */
	public PageReference save() {
		PageReference pageRef = null;
		if (!this.actionPlan.SkipWeekends__c) {
			this.actionPlan.SkipDay__c = null;
		}

		try {
			if (!this.checkCycleDependent()) {
				pageRef = this.saveHandler();
			}
		} catch (Exception e) {
			Apexpages.addMessages(e);
			if (Test.isRunningTest()) {
				throw e;
			}
			return null;
		}

		return pageRef;
	}

	/**
	 * Saves Action Plan Instance and task. Also creates all due dates for tasks, then redirects to the AP list
	 * @return `ActionPlan__c` Id
	 */
	private Id saveAp() {
		Id actionPlanId;
		Id objId;
		String objName;
		List<Id> oIdsList = new List<Id>();
		if (refId == null) {
			for (String s : ActionPlansUtilities.getCustomRelationshipFields()) {
				if (actionPlan.get(s) != null) {
					objId = (Id) actionPlan.get(s);
					Schema.DescribeSObjectResult dsr = objId.getSObjectType().getDescribe();
					objName = dsr.getName();
					break;
				}
			}

			oIdsList.add(objId);
		} else {
			objName = refType;
			oIdsList = parseRelatedIDs(refId);
		}

		//check for pendingDeletes
		this.checkPendingDeletes();

		if (String.isNotBlank(objName) && oIdsList.size() == 1) {
			Set<Id> parentIDs = new Set<Id>();
			parentIDs.addAll(oIdsList);

			if (actionPlan.Id == null && !this.inVisualforceContext && !System.isFuture() && !System.isBatch()) {
				Database.ExecuteBatch(new ActionPlansBatchBuilder(this.actionPlan, this.apTasks, objName, parentIDs));
			} else {
				System.debug('Running batch builder utilities');
				ActionPlansBatchBuilderUtilities taskBatch = new ActionPlansBatchBuilderUtilities(this.actionPlan, this.apTasks, objName, parentIDs);
				actionPlanId = taskBatch.generateActionPlans();
			}
		}
		return actionPlanId;
	}

	/**
	 * Saves Action Plan Instance and tasks and returns to the creation page with the previous Action Plan's details.
	 * @return newPage
	 */
	public PageReference saveAndNew() {
		saveAp();

		PageReference newPage = Page.ActionPlanCreation;
		newPage.setRedirect(true);

		return newPage;
	}

	/**
	 * Save Action Plans for Multiple Related Object Instances.
	 * <br>Invokes batch process that creates : ActionPlan, ActionPlanTasksTemplate AND Tasks
	 * @return Pagereference (null or ActionPlansHome with confirmation)
	 */
	@TestVisible
	private PageReference saveMultiple() {
		//System.debug('SAVING MULTIPLE');
		String oName = refType;
		String oIds = ActionPlansUtilities.getEscapedPageParameter('refId'); //String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('refId'));

		List<Id> oIdsList = new List<Id>();
		if ((oName != null || oName != '') && (oIds != null || oIds != '')) {
			try {
				oIdsList = parseRelatedIDs(oIds);
				Set<Id> parentIDs = new Set<Id>(oIdsList);
				//Now for each inserted AP we should run through tasks and create them
				ActionPlansBatchBuilder taskBatch = new ActionPlansBatchBuilder(this.actionPlan, this.apTasks, oName, parentIDs);
				Database.ExecuteBatch(taskBatch);
			} catch (Exception e) {
				Apexpages.addMessages(e);
				errorMsg = e.getMessage();
				return null;
			}
		}

		PageReference newPage = Page.ActionPlansHome;
		String confirmation = oIdsList.size() + ' ' + ActionPlan__c.sObjectType.getDescribe().getLabelPlural() + ' ' + System.Label.ap_Created + ' ' + System.Label.ap_ConfirmationofCreation;
		newPage.getParameters().put('message', confirmation);
		newPage.getParameters().put('severity', 'success');
		newPage.setRedirect(true);
		return newPage;
	}

	/**
	 * Saves Action Plan Handler.
	 * <br>Decides if we are assigning to multiple parent records or just one
	 * @return Pagereference called Method
	 * @see ActionPlanCreationController.save
	 * @see ActionPlanCreationController.savePageRef
	 * @see ActionPlanCreationController.saveMultiple
	 */
	private PageReference saveHandler() {
		String oIds = ActionPlansUtilities.getEscapedPageParameter('refId');
		List<Id> oIdsList = new List<Id>();

		if (oIds != null) {
			oIdsList = parseRelatedIDs(oIds); // oIds.deleteWhitespace().split(',');
			System.debug('oidslist: ' + oIdsList);
			return (oIdsList.size() > 1) ? this.saveMultiple() : this.savePageRef();
		} else {
			return this.savePageRef();
		}
	}

	/**
	 * Saves Action Plan Instance and tasks and redirects to that detail page
	 * @return newPage
	 * @see ActionPlanCreationController.saveAp
	 */
	private PageReference savePageRef() {
		Id newApId;
		//String ap_Prefix;

		try {
			newApId = saveAp();
		} catch (DmlException e) {
			System.debug('savePageRef_dmlexception ' + e.getMessage());
			Apexpages.addMessages(e);
			return null;
		}

		if (newApId != null) {
			PageReference newPage = Page.ActionPlanDetail;
			newPage.getParameters().put('Id', newApId);
			return newPage;
		} else {
			PageReference newPage = Page.ActionPlansHome;

			String confirmation = actionPlan.Name + ' ' + System.Label.ap_Created;
			newPage.getParameters().put('message', confirmation);
			newPage.getParameters().put('severity', 'success');
			newPage.setRedirect(true);
			return newPage;
		}
	}

	/**
	 * Action that redirects to previous page
	 * @return PageReference
	 */
	public PageReference cancel() {
		String objectType = refType;
		String objectIds = ActionPlansUtilities.getEscapedPageParameter('refId');
		String retURL = ActionPlansUtilities.getEscapedPageParameter('retURL');
		Id paramid = this.actionPlan.Id != null ? this.actionPlan.Id : (Id) ActionPlansUtilities.getEscapedPageParameter('id');
		String pageRef;
		String aPlanListUrl;

		// Reference action plan detail page
		if (paramid != null) {
			PageReference cancelPage = Page.ActionPlanDetail;
			cancelPage.getParameters().put('id', paramid);
			cancelPage.setRedirect(true);
			return cancelPage;
		} else if (this.templateId != null) {
			// Reference action plans template
			pageRef = '/' + this.templateId;
		} else if (objectType != null && objectIds != null) {
			List<Id> oIdsList = parseRelatedIDs(objectIds);
			// Reference object list page
			if (oIdsList.size() == 1) {
				// Reference object detail page
				String cancelId = oIdsList.get(0) == null ? '' : oIdsList.get(0);
				pageRef = '/' + cancelId;
			} else {
				pageRef = '/' + ActionPlansUtilities.getObjectKeyPrefix(objectType);
			}
		} else if (retURL != null) {
			// Reference previous page if defined
			pageRef = retUrl;
		} else {
			// Reference action plans list by default
			aPlanListUrl = Schema.ActionPlan__c.sObjectType.getDescribe().getKeyPrefix();
			pageRef = '/' + aPlanListUrl;
		}

		PageReference previousPage = new PageReference(pageRef);
		previousPage.setRedirect(true);

		return previousPage;
	}

	/**
	 * Retrieves number of completed tasks
	 * @return Integer
	 */
	public Integer getCompleted() {
		if (actionPlan.Id == null) {
			return 0;
		}

		return [SELECT COUNT() FROM APTask__c WHERE Status__c IN :ActionPlansUtilities.getClosedTaskStatuses() AND ActivityDate__c != NULL AND Action_Plan__c = :actionPlan.Id];
	}

	/**
	 * Creates a blank `APTask__c` record and adds it to apTasks
	 * @return the `APTask__c` we are adding
	 */
	public APTask__c addTask() {
		this.taskIndex++;

		Boolean hasError = false;
		if (this.apTasks.size() >= ActionPlansUtilities.MAX_APTASKS) {
			List<String> parameters = new List<String>();
			parameters.add(String.valueof(ActionPlansUtilities.MAX_APTASKS));

			errorMsg = String.format(System.Label.ap_Errors_TaskLimitError, parameters);
			return null;
		} else {
			APTask__c t = new APTask__c();
			t.Reminder__c = ActionPlansUtilities.getCheckReminderByDefault();
			t.Minutes_Reminder__c = ActionPlansUtilities.getDefaultReminderMinutes();
			t.Name = null;
			t.TaskIndex__c = this.taskIndex;

			// validate subject and days before adding another
			for (APTask__c apt : apTasks) {
				hasError = (hasError == true) || (apt.Subject__c == null);
				apt.DaysFromStart__c = (apt.DaysFromStart__c < 0) ? 0 : apt.DaysFromStart__c;
			}
			if (!hasError) {
				this.apTasks.add(t);
			}
			return t;
		}
	}

	/**
	 * Action for removing a existing Action Plan Task
	 */
	public void removeTask() {
		if (ApexPages.currentPage().getParameters().get('remove') != null) {
			Integer taskIndex = Integer.valueOf(ApexPages.currentPage().getParameters().get('remove'));

			//check for dependent children and clear them since the parent is being removed.
			apTasks[taskIndex].Controller__c = null;
			apTasks[taskIndex].Dependent__c = null;

			APTask__c apTask;
			Integer dependentApTask;

			//update the current dependent position from tasks below deleted one.
			for (Integer i = 0; i < this.apTasks.size(); i++) {
				apTask = this.apTasks.get(i);
				if (apTask.Dependent__c != null && apTask.Dependent__c != 'None') {
					dependentApTask = Integer.valueOf(apTask.Dependent__c);
					if (dependentApTask > taskIndex) {
						apTask.Dependent__c = String.valueOf(dependentApTask - 1);
					} else if (dependentApTask == taskIndex) {
						apTask.Dependent__c = 'None';
						apTask.Controller__c = null;
					}
				}
			}

			// before remove, check if it exists in the DB. If so, add to pendingDeletes to be deleted on save.
			if (this.apTasks[taskIndex].Id != null) {
				if (pendingDeletes == null) {
					pendingDeletes = new List<APTask__c>();
				}
				pendingDeletes.add(this.apTasks[taskIndex]);
			}

			apTasks.remove(taskIndex);

			// clear errorMsg if it's set.
			if (this.apTasks.size() < ActionPlansUtilities.MAX_APTASKS) {
				errorMsg = null;
			}
		}
	}

	/**
	 * Method that retrieves all AP tasks for a Action Plan for Visualforce Page
	 * @return  The `List<ApTaskWrapper>` of AP Task Wrappers for Visualforce Page
	 */
	public List<ApTaskWrapper> getTasks() {
		List<ApTaskWrapper> tasksList = new List<ApTaskWrapper>();
		Integer i = 0;
		for (APTask__c apTask : this.getAPTasks()) {
			ApTaskWrapper newTaskWrapper;

			//check if the lookup has to be shown
			if (apTask.Id != null) {
				newTaskWrapper = this.mapTasksListBkp.get(apTask.Id);
			}

			Boolean userRequired = false;
			Boolean displayLookUp = Schema.sObjectType.APTask__c.fields.User__c.isUpdateable();

			if (templateId != null && apTask.Id == null && apTask.User__c != null) {
				displayLookUp = false;
			}

			//! We need to account for the User being filled AND having the option to change it
			//! How can we refer to the template task?

			//! User is Required if the ap parent id is null and we don't give unassigned to record owner
			//! We always display the lookup (if editable) because we never FORCE the task to be assigned to the record owner

			/* if (newTaskWrapper == null){
				userRequired    = mySettings == null || !mySettings.Unassigned_Task_Default_to_Owner__c || actionPlan.get(relatedFieldName) == null; // true if not auto-assigned to record owner. User may have been set via template, but is still required.
			} else { // editing existing task
				userRequired    = mySettings == null || !mySettings.Unassigned_Task_Default_to_Owner__c;
			} */
			userRequired = mySettings == null || !mySettings.Unassigned_Task_Default_to_Owner__c;

			ApTaskWrapper apTWrapper = new ApTaskWrapper(apTask, i, displayLookup, userRequired, actionPlan.TaskRecordTypeID__c);
			tasksList.add(apTWrapper);
			if (String.isNotBlank(apTask.Id)) {
				this.mapTasksListBkp.put(apTask.Id, apTWrapper);
			}
			i++;
		}
		if (i > 0) {
			tasksList[i - 1].isLast = true;
		}
		return tasksList;
	}

	/**
	 * Gets Tasks related to an Action Plan, or initializes from the Action Plan Template
	 * @return Action Plan Tasks
	 */
	public List<APTask__c> getAPTasks() {
		if (this.apTasks == null || this.apTasks.size() == 0) {
			if (templateId == null) {
				templateId = ActionPlansUtilities.getEscapedPageParameter('templateId');
			}

			if (templateId != null) {
				List<APTemplateTask__c> aptTasks = [
					SELECT
						Subject__c,
						Priority__c,
						Dependent__c,
						Name,
						User__c,
						User__r.Name,
						Id,
						Type__c,
						DaysFromStart__c,
						CreatedById,
						Action_Plan_Template__c,
						TController__r.Subject__c,
						Reminder__c,
						Minutes_Reminder__c,
						SendEmail__c,
						Comments__c,
						TaskIndex__c,
						Action_Plan_Template__r.TaskRecordTypeID__c
					FROM APTemplateTask__c
					WHERE Action_Plan_Template__c = :templateId
					ORDER BY TaskIndex__c ASC
				];

				this.apTasks = new List<APTask__c>();

				for (APTemplateTask__c aptTask : aptTasks) {
					APTask__c t = new APTask__c();
					//Read the Custom Settings in order to asign the User to that Task
					if (aptTask.User__c != null) {
						t.User__c = aptTask.User__c;
					} else if (aptTask.User__c == null && (!mySettings.Unassigned_Task_Default_to_Owner__c)) {
						t.User__c = UserInfo.getUserId();
					}
					/* else if( aptTask.User__c == null && ( mySettings != null &&  mySettings.Unassigned_Task_Default_to_Owner__c ) ) {
						userId = null;
					}
					else if( aptTask.User__c == null && mySettings == null ){
						userId = UserInfo.getUserId();
					} */

					t.Type__c = aptTask.Type__c;
					t.Subject__c = aptTask.Subject__c;
					t.Priority__c = aptTask.Priority__c;
					t.Dependent__c = aptTask.Dependent__c;
					t.TaskIndex__c = aptTask.TaskIndex__c;
					t.DaysFromStart__c = aptTask.DaysFromStart__c;
					//t.User__c = userId;
					t.Reminder__c = aptTask.Reminder__c;

					if (aptTask.Reminder__c && String.isBlank(aptTask.Minutes_Reminder__c)) {
						t.Minutes_Reminder__c = ActionPlansUtilities.getDefaultReminderMinutes();
					} else if (aptTask.Reminder__c) {
						t.Minutes_Reminder__c = aptTask.Minutes_Reminder__c;
					} else if (!aptTask.Reminder__c) {
						t.Minutes_Reminder__c = null;
					}
					if (!ActionPlansUtilities.getCanDisplayReminder()) {
						t.Reminder__c = false;
						t.Minutes_Reminder__c = null;
					}

					t.SendEmail__c = aptTask.SendEmail__c;
					t.Comments__c = aptTask.Comments__c;
					this.apTasks.add(t);
				}
			} else if (actionPlan.Id != null) {
				this.apTasks = retrieveTaskFromExistingActionPlan(actionPlan.Id);
				//check reminders and set 'send email' as false
				String tmpReminderDefaultTime = ActionPlansUtilities.getDefaultReminderMinutes();
				for (APTask__c t : this.apTasks) {
					if (t.Reminder__c == null || t.Reminder__c == false) {
						t.Reminder__c = false;
						t.Minutes_Reminder__c = tmpReminderDefaultTime;
					}
					t.SendEmail__c = false;
				}
			} else {
				this.apTasks = new List<APTask__c>();
				APTask__c t = new APTask__c();
				t.Reminder__c = ActionPlansUtilities.getCheckReminderByDefault();
				t.Minutes_Reminder__c = ActionPlansUtilities.getDefaultReminderMinutes();
				this.apTasks.add(t);
			}

			// Clone. Clear ids.
			if (cloneParam == '1') {
				List<APTask__c> tC = this.apTasks.deepClone(false);
				this.apTasks.clear();
				this.apTasks = tC;

				// clear task relations
				for (APTask__c t : this.apTasks) {
					t.Action_Plan__c = null;
				}
			}
		}

		return this.apTasks;
	}

	/**
	 * Get a Existing Action Plan Task List
	 * @param actionPlanId Parent `ActionPlan__c` Id
	 * @return All template tasks
	 */
	private List<APTask__c> retrieveTaskFromExistingActionPlan(Id actionPlanId) {
		List<APTask__c> myList = [
			SELECT
				Subject__c,
				ActivityDate__c,
				Priority__c,
				Status__c,
				Dependent__c,
				Type__c,
				Name,
				User__c,
				User__r.Name,
				Id,
				DaysFromStart__c,
				CreatedById,
				Controller__r.Name,
				Controller__r.Subject__c,
				Controller__c,
				Action_Plan__c,
				Reminder__c,
				SendEmail__c,
				Comments__c,
				Minutes_Reminder__c,
				TaskIndex__c,
				Time_Reminder__c,
				Task_RecordTypeId__c,
				IsClosed__c
			FROM APTask__c
			WHERE Action_Plan__c = :actionPlanId
			ORDER BY TaskIndex__c ASC
		];

		return myList;
	}

	/**
	 * Retrieves if template lookup must be displayed
	 * @return True if there is a related record or if there is a template ID provided
	 */
	public Boolean getDisplayTemplateLookup() {
		return (this.hasRelated || this.templateId != null);
	}

	/**
	 * Returns list of Dependent tasks to fill drop down
	 * @return `List<SelectOption>` All other AP Task subjects
	 */
	public List<SelectOption> getSubjectItems() {
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('None', '--' + System.Label.ap_None + '--'));
		Integer i = 0;

		if (this.apTasks != null) {
			for (APTask__c t : this.apTasks) {
				if (t.Subject__c != null) {
					options.add(new SelectOption(String.valueOf(i), t.Subject__c + ' (' + (i + 1) + ')'));
				}
				i++;
			}
		}
		return options;
	}

	/**
	 * Set the Refered object to Create New Action Plan
	 */
	@TestVisible
	private void referedObjectInit() {
		String nameParam = '';
		String idsParam;

		if (refType != null) {
			nameParam = refType;
			idsParam = refId;

			if (String.isNotBlank(idsParam)) {
				List<Id> paramList = parseRelatedIDs(idsParam);
				this.relatedRecordIDs = new Set<Id>(paramList);
			}
		}

		relatedObjNameList = retrieveNameRelatedRecord(relatedRecordIDs, nameParam);
	}

	/**
	 * Take related IDs parameter and put into a list if each is an Id.
	 * <br>Discard invalid IDs
	 * @author David Schach
	 * @param  relatedIDs The page URL parameters
	 * @return            A list (not set) of all related IDs from the URL
	 */
	private List<Id> parseRelatedIDs(String relatedIDs) {
		List<String> paramList = relatedIDs.deleteWhitespace().split(',');
		List<Id> toReturn = new List<Id>();
		for (String s : paramList) {
			try {
				Id validId = s;
				toReturn.add(validId);
			} catch (Exception ex) {
				System.debug('RelatedId did not have the form of a valid ID');
				return new List<Id>();
			}
		}
		return toReturn;
	}

	/**
	 * Query the names of the parent records from the IDs. Some standard objects have special "name" fields
	 * @param relatedRecordIDs The related object IDs
	 * @param relatedObjectName The name of the SObject for which the IDs refer
	 * @return List of related record names
	 */
	private List<String> retrieveNameRelatedRecord(Set<Id> relatedRecordIDs, String relatedObjectName) {
		List<String> nameList = new List<String>();

		String objectlower = relatedObjectName.toLowerCase();

		Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
		Schema.SObjectType sot = gd.get(objectlower);
		relatedObjLabelPlural = sot.getDescribe().getLabelPlural();

		switch on objectlower {
			when 'case' {
				if (CanTheUser.read('Case')) {
					for (Case ca : [SELECT Subject, CaseNumber FROM Case WHERE Id IN :relatedRecordIDs]) {
						nameList.add((ca.Subject != null) ? ca.CaseNumber + ': ' + ca.Subject : ca.CaseNumber);
					}
				}
			}
			when 'contract' {
				if (CanTheUser.read('Contract')) {
					for (Contract contr : [SELECT ContractNumber FROM Contract WHERE Id IN :relatedRecordIDs]) {
						nameList.add(Contract.Name.getDescribe().getLabel() + ': ' + contr.ContractNumber);
					}
				}
			}
			when else {
				//System.debug('checking perms and querying related record for object ' + relatedObjectName);
				if (CanTheUser.read(relatedObjectName)) {
					for (SObject so : Database.query('SELECT Id, Name FROM ' + String.escapeSingleQuotes(relatedObjectName) + ' WHERE Id IN :relatedRecordIDs')) {
						//System.debug('adding record name ' + (String)so.get('Name'));
						nameList.add((String) so.get('Name'));
					}
				} else {
					nameList.add('Related Record');
				}
			}
		}
		return nameList;
	}

	private Map<Id, String> relatedObjectNameMap = new Map<Id, String>();

	/**
	 * We need a list of parent RECORD names when showing all the parents when we mass-create action plans
	 * <br>This initializes the list, and then divides it into three parts for three columns on the page.
	 * @author David Schach
	 * @return   The list of related object Names (not labels)
	 */
	@TestVisible
	private List<String> relatedObjNameList {
		get {
			if (relatedObjNameList == null) {
				relatedObjNameList = new List<String>();
			}
			return relatedObjNameList;
		}
		set {
			relatedObjNameList = value;
			relatedObjNameList.sort();
			relatedRecordsOne = new List<String>();
			relatedRecordsTwo = new List<String>();
			relatedRecordsThree = new List<String>();
			for (Integer i = 0; i < getNameListSize(); i++) {
				if (Math.mod(i, 3) == 0) {
					relatedRecordsOne.add(relatedObjNameList[i]);
				} else if (Math.mod(i, 3) == 1) {
					relatedRecordsTwo.add(relatedObjNameList[i]);
				} else if (Math.mod(i, 3) == 2) {
					relatedRecordsThree.add(relatedObjNameList[i]);
				}
			}
		}
	}

	/**
	 * The size of the list of related objects available as parents to the Action Plan
	 * @author David Schach
	 * @return   The picklist size
	 */
	public Integer getNameListSize() {
		return relatedObjNameList.size();
	}

	public List<String> relatedRecordsOne { get; private set; } //NOPMD
	public List<String> relatedRecordsTwo { get; private set; } //NOPMD
	public List<String> relatedRecordsThree { get; private set; } //NOPMD

	/**
	 * Checks if Action Plan Tasks has cyclic dependency.
	 * @return True if there is a cyclic dependency
	 */
	public Boolean checkCycleDependent() {
		this.errorMsg = null;
		Boolean exists = false;
		Integer index = 0;

		for (APTask__c t : this.apTasks) {
			if (t.Dependent__c != null && t.Dependent__c != 'None') {
				APTask__c link = this.apTasks[Integer.valueOf(t.Dependent__c)];

				//task can not depend on themselves
				if (Integer.valueOf(t.Dependent__c) == index) {
					//  || t.Id == t.Controller__c
					this.errorMsg = System.Label.ap_ItselfDependencyError;
					return true;
				}

				if (this.dependantCycle(link, index)) {
					this.errorMsg = System.Label.ap_Errors_RemoveCyclicDependency;
					return true;
				}
			}
			index++;
		}
		return exists;
	}

	/**
	 * Check for cyclically dependent tasks
	 * @param  controllingTask The task we are checking
	 * @param  index           The index of the task (for referencing the controllign one)
	 * @return `Boolean` Does this task have a dependency?
	 */
	private Boolean dependantCycle(APTask__c controllingTask, Integer index) {
		Boolean hasDependency = false;
		Set<Integer> visitedTasks = new Set<Integer>();

		while (!hasDependency) {
			if (controllingTask.Dependent__c != null && controllingTask.Dependent__c != 'None') {
				if (visitedTasks.contains(Integer.valueOf(controllingTask.Dependent__c))) {
					hasDependency = true;
					break;
				} else {
					visitedTasks.add(Integer.valueOf(controllingTask.Dependent__c));
				}
			}

			if (controllingTask.Dependent__c != null && controllingTask.Dependent__c != 'None') {
				APTask__c link = this.apTasks[Integer.valueOf(controllingTask.Dependent__c)];

				if (link.Dependent__c != null && link.Dependent__c != 'None') {
					if (Integer.valueOf(link.Dependent__c) == index) {
						hasDependency = true;
						break;
					} else {
						//get Next task in dependency chain
						controllingTask = this.apTasks[Integer.valueOf(controllingTask.Dependent__c)];
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
	 * Getter method to return the error message
	 * @return `String` Error message
	 */
	public String getErrorMsg() {
		System.debug('ERROR MESSAGE: ' + errorMsg);
		return errorMsg;
	}

	/**
	 * Calculates the highest task index value for Action Plan Tasks
	 * @return maxIndex
	 */
	private Double calculateAPTaskIndexValue() {
		Double maxIndex = 0;
		List<AggregateResult> arList = [SELECT MAX(TaskIndex__c) m FROM APTask__c WHERE Action_Plan__c = :this.actionPlan.Id];
		if (!arList.isEmpty()) {
			maxIndex = (Double) arList[0].get('m');
			maxIndex = (maxIndex == null ? 0 : maxIndex);
		}
		return maxIndex;
	}

	/**
	 * Calculates the highest task index value for Action Plan Template Tasks
	 * @return maxIndex
	 */
	private Double calculateAPTTaskIndexValue() {
		Double maxIndex = 0;
		List<AggregateResult> arList = [SELECT MAX(TaskIndex__c) m FROM APTemplateTask__c WHERE Action_Plan_Template__c = :this.templateId];
		if (!arList.isEmpty()) {
			maxIndex = (Double) arList[0].get('m');
			maxIndex = (maxIndex == null ? 0 : maxIndex);
		}
		return maxIndex;
	}

	private List<SelectOption> relatedObjectOptions;
	/**
	 * Getter method with the related object options by default.
	 * @return Picklist of all related objects to Action Plan
	 */
	public List<SelectOption> getRelatedObjectOptions() {
		if (relatedObjectOptions == null) {
			relatedObjectOptions = new List<SelectOption>();
			//Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

			// Describe the fieldSet so we can make sure that we only add SelectOptions for desired records
			Schema.FieldSet fs = Schema.SObjectType.ActionPlan__c.fieldSets.Related_Objects;
			System.assert(fs.getFields().size() > 0);

			Set<String> activityEnabledObjects = findActivityEnabledObjects();

			for (Schema.FieldSetMember fsm : fs.getFields()) {
				//System.debug('Field Set field ' + fsm.getFieldPath());
				String s = fsm.getFieldPath();
				System.debug('FieldPath to related record: ' + s);
				Schema.DisplayType dt = fsm.getType();
				if (s.contains('.') || !dt.name().equalsIgnoreCase('Reference') || !s.endsWithIgnoreCase('__c')) {
					continue; // only look at custom references one object up
				}

				Schema.DescribeFieldResult dfr = fsm.getSObjectField().getDescribe();
				Schema.DescribeSObjectResult dsr = dfr.getReferenceTo()[0].getDescribe();
				Boolean hasActivities = activityEnabledObjects.contains(dsr.getName());
				Boolean canSeeRelatedObject = dsr.isAccessible();
				Boolean canUpdateLookupField = dfr.isUpdateable();

				if (canSeeRelatedObject && canUpdateLookupField && hasActivities) {
					String value = dfr.getName();
					String label = dsr.getLabel();
					System.debug('label: ' + label + ' : value: ' + value);
					relatedObjectOptions.add(new SelectOption(value, label));
				}
			}
			relatedObjectOptions.sort();
		}
		if (relatedObjectOptions.isEmpty()) {
			relatedObjectOptions.add(new SelectOption(getNamespacePrefix() + 'Account__c', 'Account'));
		}
		return relatedObjectOptions;
	}

	private Set<String> findActivityEnabledObjects() {
		//Set<Schema.SObjectType> objectsWithActivitiesEnabled = new Set<Schema.SObjectType>();
		Set<String> relatedToObjects = new Set<String>();
		for (Schema.SObjectType objectType : Task.WhatId.getDescribe().getReferenceTo()) {
			relatedToObjects.add(objectType.getDescribe().getName());
		}
		for (Schema.SObjectType objectType : Task.WhoId.getDescribe().getReferenceTo()) {
			relatedToObjects.add(objectType.getDescribe().getName());
		}
		return relatedToObjects;
	}

	/**
	 * Refresh the related object lookup field.
	 * @return `PageReference` null
	 */
	public PageReference refreshRelatedObjectsLookUp() {
		relatedFieldName = ActionPlansUtilities.getEscapedPageParameter('relatedFieldName');
		return null;
	}

	/**
	 * Find user default task recordtype
	 * @return default task record type Id
	 */
	@testVisible
	private Id getDefaultTaskRecordTypeId() {
		return ActionPlansUtilities.getDefaultTaskRecordTypeId();
	}

	/**
	 * Convert Record Type Id to Record Type Name for the Action Plan's Tasks
	 * @return Task Record Type Name for the current Action Plan
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
	 * Generate picklist of Task Record Types
	 * @return Picklist of `Task.RecordType` options
	 */
	public List<SelectOption> getTaskRTPicklistValues() {
		return ActionPlansUtilities.getTaskRTPicklistValues();
	}

	private List<SelectOption> taskTypes;
	/**
	 * Generate picklist of Task Types
	 * @return Picklist of `Task.Type`
	 */
	public List<SelectOption> getTaskTypes() {
		if (taskTypes == null) {
			taskTypes = ActionPlansUtilities.getFieldOptions('Task', 'Type', null);
		}
		return taskTypes;
	}

	private List<SelectOption> taskPriorities;
	/**
	 * Generate picklist of Task Priorities
	 * @return Picklist of `Task.Priority`
	 */
	public List<SelectOption> getTaskPriorities() {
		if (taskPriorities == null) {
			taskPriorities = ActionPlansUtilities.getFieldOptions('Task', 'Priority', true);
		}
		return taskPriorities;
	}

	/**
	 * Generate picklist of available task due times
	 * @return   picklist of 30-minute intervals
	 */
	public List<SelectOption> getHoursOption() {
		return ActionPlansUtilities.getHoursOption();
	}

	/**
	 * Retrieve the Namespace Prefix in case we are in a managed package. Needed for the JavaScript in the page
	 * @return `String` Namespace Prefix (LabsActionPlans or empty string)
	 */
	public String getNamespacePrefix() {
		return ActionPlansUtilities.namespacePrefix;
	}

	/**
	 * Wrapper Class for AP Task SObject
	 * @author Rodrigo Birriel
	 * @since 08/01/2010
	 * @author David Schach
	 * @since 4/2022
	 */
	public class ApTaskWrapper {
		/**
		 * Action Plan Task in wrapper
		 * @return   The Action Plan task
		 */
		public APTask__c apt { get; set; }
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
		 * Should we display the lookup?
		 */
		public Boolean displayLookUp { get; set; }
		/**
		 * Is the User lookup required?
		 */
		public Boolean userRequired { get; set; }

		/**
		 * Constructor
		 *
		 * @param apTask     Action Plan Task Template
		 * @param pos        Position (in the list of AP Tasks) on the Page
		 * @param looKp      Should the User lookup (for assignment) be displayed?
		 * @param userReq    Should the assigned user field be required?
		 * @param apTaskRTId The Record Type of the Task eventually to be created
		 */
		public ApTaskWrapper(APTask__c apTask, Integer pos, Boolean looKp, Boolean userReq, Id apTaskRTId) {
			apt = apTask;
			position = pos;
			isLast = false;
			displayLookUp = looKp;
			userRequired = userReq;

			Id taskRTID = null;
			if (ActionPlansUtilities.taskUsesRecordTypes) {
				if (ActionPlansUtilities.getTaskRecordTypeStatusDefaultValues().containsKey(apTaskRTId)) {
					taskRTID = apTaskRTId;
				} else {
					taskRTID = ActionPlansUtilities.getDefaultTaskRecordTypeId();
				}
			}

			if (apt.Id == null) {
				apt.Priority__c = apt.Priority__c != null ? apt.Priority__c : ActionPlansUtilities.getTaskRecordTypePriorityDefaultValues().get(taskRTID);
				apt.Status__c = ActionPlansUtilities.getTaskRecordTypeStatusDefaultValues().get(taskRTID);
				apt.Type__c = apt.Type__c != null ? apt.Type__c : ActionPlansUtilities.getTaskRecordTypeTypeDefaultValues().get(taskRTID);
				apt.Minutes_Reminder__c = ActionPlansUtilities.getDefaultReminderMinutes();
				apt.Reminder__c = ActionPlansUtilities.getCheckReminderByDefault();
			}

			if (apt.User__c == null && displayLookUp && userRequired) {
				apt.User__c = UserInfo.getUserId();
			}
		}
	}
}