@SuppressWarnings('PMD.ExcessivePublicCount')
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
 * Controller for ActionPlan Create and ActionPlan Edit screens (the same page overrides both actions)
 * @group Visualforce
 * @author {@link [Rodrigo Birriel](https://www.linkedin.com/in/rbirriel)}
 * @author {@link [David Schach](https://github.com/dschach)}
 * @since 2022
 * @see ActionPlanCreateInvocable
 */
public with sharing class ActionPlanCreationController {
	/**
	 * Max taskIndex for this Action Plan
	 */
	private Double taskIndex;
	/**
	 * Page Action Plan
	 */
	@TestVisible
	private ActionPlan__c actionPlan;
	/**
	 * TemplateId is pulled from the page parameters and tells us if we're making an Action Plan based on a template
	 * <br>It can also be set by choosing a template when applying a template to one or more records
	 */
	public Id templateId { get; set; }
	/**
	 * Related Record IDs
	 */
	private Set<Id> relatedRecordIDs;
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

	/**
	 * Error message to display (outside of Apex.PageMessages)
	 */
	private String errorMsg;
	/**
	 * Is the User able to see reminders?
	 */
	public Boolean canDisplayReminder { get; set; }
	/**
	 * Map to retrieve our APTaskWrapper records by APTask Id
	 * <br>Currently unused; should be deleted if package testing passes
	 */
	private Map<Id, ApTaskWrapper> mapTasksListBkp; //NOPMD
	/**
	 * The subtitle shown on the page
	 */
	public String subtitle { get; set; }

	/**
	 * Stored `APTask__c` records for the page. See getAPTasks()
	 */
	@testVisible
	private List<APTask__c> apTasks;
	/**
	 * Temporary list of APTasks to delete, based on taskIndex
	 */
	private List<APTask__c> pendingDeletes;

	/**
	 * Are we cloning an Action Plan? If so, this is 1. Otherwise, it is 0.
	 */
	private String cloneParam = '0';
	/**
	 * Esure we are working in Visualforce context. For future functionality allowing invocable Apex to call this class directly
	 */
	@testVisible
	private Boolean inVisualforceContext = false;
	/**
	 * The `APTask__c` instantiated when clicking the Add New Task link on the page
	 */
	@testVisible
	private APTask__c addedTask;

	/**
	 * Constructor for ActionPlan Create/Edit Page
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @param  stdController `ActionPlan__c` standard controller
	 */
	public ActionPlanCreationController(ApexPages.StandardController stdController) {
		this.inVisualforceContext = true;

		this.taskIndex = 0;

		this.hasRelated = false;
		this.hasRelatedObject = false;
		this.relatedRecordIDs = new Set<Id>();

		if (!Test.isRunningTest()) {
			stdController.addFields(getAllRelationshipFields());
		}
		this.actionPlan = (ActionPlan__c) stdController.getRecord();

		this.apTasks = getAPTasks();

		this.cloneParam = ActionPlansUtilities.getEscapedPageParameter('clone');
		this.templateId = ActionPlansUtilities.getEscapedPageParameter('templateId');
		this.refId = ActionPlansUtilities.getEscapedPageParameter('refId');
		this.refType = ActionPlansUtilities.getEscapedPageParameter('refType');

		this.taskOwnerMap = new Map<Id, OwnerWrapper>();

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
		this.taskIndex = this.calculateMaxTaskIndex();
		this.subtitle = this.actionPlan.Name;
		this.taskOwnerMap = this.queryAPTaskOwners(this.actionPlan);
	}

	/**
	 * Initalize controller for cloning an Action Plan
	 */
	private void initCloneActionPlan() {
		List<APTask__c> tC = this.apTasks.deepClone(false, true);

		this.apTasks.clear();
		this.apTasks = tC;

		// clear task relations
		for (APTask__c apt : this.apTasks) {
			apt.IsClosed__c = false;
			apt.Action_Plan__c = null;
		}
		String templateName = actionPlan.Action_Plan_Template__r.Name;

		if (templateName != null) {
			actionPlan.Name = templateName;
		} else {
			actionPlan.Name = null;
		}
		this.actionPlan.Id = null;
		this.actionPlan.StartDate__c = Date.today();
		for (String s : getAllRelationshipFields()) {
			actionPlan.put(s, null);
		}

		this.subtitle = System.Label.ap_Clone + ' ' + Schema.getGlobalDescribe().get(getNamespacePrefix() + 'ActionPlan__c').getDescribe().getLabel();

		this.hasRelatedObject = false;
		this.hasRelated = false;
	}

	/**
	 * Initalize controller for creating a new Action Plan from a template
	 * <br>Used so we can instantiate this controller from Invocable Apex
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @param visualforceContext Are we in Visualforce context?
	 */
	private void initNewActionPlanFromTemplate(Boolean visualforceContext) {
		initNewActionPlanFromTemplate(visualforceContext, null);
	}

	/**
	 * Set up a new Action Plan from a template
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @param  visualforceContext Are we in Visualforce context?
	 * @param  apt                `ActionPlanTemplate__c` record
	 */
	private void initNewActionPlanFromTemplate(Boolean visualforceContext, ActionPlanTemplate__c apt) {
		System.debug('in initNewActionPlanFromTemplate');
		this.initNewActionPlan();
		ActionPlanTemplate__c apTemplate;
		if (apt == null) {
			List<ActionPlanTemplate__c> listAPT = [
				SELECT Id, Name, Description__c, LastModifiedDate, SkipWeekends__c, SkipDay__c, TaskRecordTypeID__c, Archived__c
				FROM ActionPlanTemplate__c
				WHERE Id = :this.templateId
			];
			if (!listAPT.isEmpty()) {
				apTemplate = listAPT.get(0);
			}
		} else {
			apTemplate = apt;
		}

		this.actionPlan.Name = ActionPlansUtilities.actionPlanSubjectToName(apTemplate.Name);
		this.actionPlan.Description__c = apTemplate.Description__c;
		this.actionPlan.SkipWeekends__c = apTemplate.SkipWeekends__c;
		this.actionPlan.SkipDay__c = apTemplate.SkipDay__c == null ? '' : apTemplate.SkipDay__c;
		this.actionPlan.Action_Plan_Template__c = apTemplate.Id;
		this.actionPlan.TaskRecordTypeID__c = apTemplate.TaskRecordTypeID__c;

		if (refId != null) {
			this.hasRelated = true;
			this.referedObjectInit();
			if (!refId.containsIgnoreCase(',') && refType != null) {
				String displayFieldName = chooseDisplayField(refType);
				String queryText = 'SELECT Id, ' + displayFieldName + ' FROM ' + refType + ' WHERE Id = :refId';
				//System.debug(queryText);
				List<SObject> qResult = Database.query(queryText);
				this.actionPlan.Name += ' - ' + (String) qResult[0]?.get(displayFieldName);
			}
		}

		if (visualforceContext) {
			this.taskIndex = this.calculateMaxTemplateTaskIndex();
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

	// Set up OwnerWrappers to handle Queue-owned Tasks
	/**
	 * Map of Action Plan Task Id to the Task owner (or APTask User if no Task has been created)
	 */
	public Map<Id, OwnerWrapper> taskOwnerMap { get; private set; }

	/**
	 * Query all `Task` records for the Action Plan's Tasks so we can display the owher name read-only if it is a queue
	 * @author David Schach
	 * @param  ap The Action Plan
	 * @return    Map of `Task` by Id
	 */
	private Map<Id, OwnerWrapper> queryAPTaskOwners(ActionPlan__c ap) {
		Map<Id, OwnerWrapper> toReturn = new Map<Id, OwnerWrapper>();
		if (ap.Id == null) {
			System.debug('toReturn: ' + toReturn);
			return toReturn;
		}

		//Map<Id, Task> tasksByAPTask = new Map<Id, Task>();
		Set<Id> apTaskIDs = new Set<Id>();
		for (APTask__c apt : [SELECT Id FROM APTask__c WHERE Action_Plan__c = :ap.Id]) {
			apTaskIDs.add(apt.Id);
		}
		for (Task t : [SELECT Id, OwnerId, Owner.Name, TaskAPTask__c FROM Task WHERE TaskAPTask__c IN :apTaskIDs]) {
			//tasksByAPTask.put(t.TaskAPTask__c, t);
			toReturn.put(t.TaskAPTask__c, new OwnerWrapper(t.OwnerId, t.Owner.Name));
		}
		for (APTask__c apt : [SELECT Id, User__c, User__r.Name FROM APTask__c WHERE Action_Plan__c = :ap.Id]) {
			if (!toReturn.containsKey(apt.Id)) {
				toReturn.put(apt.Id, new OwnerWrapper(apt.User__c, apt.User__r.Name));
			}
		}
		System.debug('toReturn: ' + toReturn);
		return toReturn;
	}

	/**
	 * Wrapper class for `Task` owner, with Name and Id. Used to determine if owned by a Queue
	 */
	public class OwnerWrapper {
		/**
		 * Constructor for OwnerWrapper
		 * @author David Schach
		 * @param  taskOwnerId   `Task.OwnerId`
		 * @param  taskOwnerName `Task.Owner.Name` (User or Queue)
		 */
		public OwnerWrapper(Id taskOwnerId, String taskOwnerName) {
			this.tOwnerId = taskOwnerId;
			this.tOwnerName = taskOwnerName;
		}

		/**
		 * Task Owner Name (User or Queue)
		 */
		public String tOwnerName { get; private set; }

		/**
		 * Task Owner Id (User or Queue)
		 */
		public Id tOwnerId { get; private set; }
	}

	/**
	 * Send Action Plan's Template Name to the Visualforce page
	 * <br>Because the record has not been saved, the Action Plan Name on initialization is the same as the name of the template
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return `String` `ActionPlan__c.Name` (from `ActionPlan__c.Action_Plan_Template__r.Name`)
	 */
	public String getTemplateName() {
		if (actionPlan.Action_Plan_Template__c != null) {
			return actionPlan.Name;
		}
		return '';
	}

	/**
	 * If the Task object has Record Types enabled, return `true`
	 * @return `Boolean` Does the Task object have Record Types enabled?
	 */
	public Boolean taskHasRecordType {
		get {
			if (taskHasRecordType == null) {
				taskHasRecordType = ActionPlansUtilities.taskUsesRecordTypes;
			}
			return taskHasRecordType;
		}
		set;
	}

	/**
	 * Get the specific lookup field used by this Action Plan
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return  `String` The field Name
	 */
	public String relatedFieldName {
		get {
			// should not be null, as is set in controller, but here for completeness.
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
			Schema.DescribeSObjectResult dsr = sot.getDescribe(SObjectDescribeOptions.DEFERRED);
			this.relatedObjectName = dsr.getName();
			System.debug('relatedObjectName: ' + this.relatedObjectName);
			this.relatedObjDisplayField = chooseDisplayField(this.relatedObjectName);
			System.debug('objectDisplayField: ' + this.relatedObjDisplayField);
		}
	}
	/**
	 * Memoize relationship fields
	 */
	private List<String> relationshipFields;
	/**
	 * Get a list of all relationship fields to avoid SOQL error for unqueried fields
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return   `List<String>` Relationship fields from AcitonPlansUtilities
	 * @see ActionPlansUtilities.getCustomRelationshipFields
	 */
	public List<String> getAllRelationshipFields() {
		if (relationshipFields == null) {
			relationshipFields = ActionPlansUtilities.getCustomRelationshipFields();
		}
		return relationshipFields;
	}

	/**
	 * Based on the related object name, we display a field from that object as the related record
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @param  objectName SObject Name
	 * @return            `String` The display field
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
	 * @return   `PageReference` null (required for page actions method)
	 * @see ActionPlansUtilities.onPageLoad
	 */
	public PageReference onLoad() {
		ActionPlansUtilities.onPageLoad();
		return null;
	}

	/**
	 * Getter and Setter for refId (related record Id)
	 */
	public String refId {
		get {
			if (refId == null) {
				refId = ActionPlansUtilities.getEscapedPageParameter('refId');
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
				refType = ActionPlansUtilities.getRelatedSObjectDescribe(shortId).getName();
			} else if (refId == null) {
				refType = ActionPlansUtilities.getEscapedPageParameter('refType');
			}
			return refType;
		}
		set;
	}

	/**
	 * Returns the related object Id from lookup fields.
	 * @return `Id` the related object id
	 */
	@testVisible
	private Id relatedObjectId() {
		Id currentId;
		for (String s : getAllRelationshipFields()) {
			if (actionPlan.get(s) != null) {
				currentId = (Id) actionPlan.get(s);
				break;
			}
		}

		return currentId;
	}

	/**
	 * Check if the action plan has a related object
	 * @return `Boolean` Is a relationship field filled?
	 * @see ActionPlansUtilities.getCustomRelationshipFields
	 */
	public Boolean hasRelatedObject() {
		for (String f : getAllRelationshipFields()) {
			try {
				//System.debug('Evaluate AP field ' + f + ' with value ' + actionPlan.get(f));
				if (actionPlan.get(f) != null) {
					return true;
				}
			} catch (SObjectException e) {
				continue;
			}
		}
		return false;
	}

	/**
	 * Check if have pending Tasks to delete
	 */
	private void checkPendingDeletes() {
		if (this.pendingDeletes != null && !pendingDeletes.isEmpty()) {
			Set<Id> deleteApttIds = new Set<Id>();

			for (APTask__c deleteAptt : this.pendingDeletes) {
				deleteApttIds.add(deleteAptt.Id);
			}
			//do not delete completed tasks
			Database.delete(pendingDeletes);
			delete [SELECT Id FROM Task WHERE IsClosed = FALSE AND IsDeleted = FALSE AND TaskAPTask__c IN :deleteApttIds];
		}
	}

	/**
	 * Action that saves a new Action Plan
	 * @return `PageReference` null
	 * @see ActionPlanCreationController.checkCycleDependent
	 * @see ActionPlanCreationController.saveHandler
	 */
	public PageReference save() {
		PageReference pageRef = null;
		//pageRef = this.saveHandler();
		try {
			if (!this.checkCycleDependent()) {
				System.debug('Cycle check ok');
				pageRef = this.saveHandler();
			}
		} catch (Exception e) {
			Apexpages.addMessages(e);
			return null;
		}

		return pageRef;
	}

	/* public Pagereference onTemplateSelection() {
		System.debug('onTemplateSelection');
		PageReference pr = Page.ActionPlanCreation;
		pr.getParameters().put('refType', this.refType);
		pr.getParameters().put('refId', this.refId);
		pr.getParameters().put('templateId', this.actionPlan.Action_Plan_Template__c);

		pr.setRedirect(true);
		return pr;
	} */

	/**
	 * Saves Action Plan Instance and task. Also creates all due dates for tasks, then redirects to the AP list
	 * @return `Id` Action Plan Id
	 */
	private Id saveSingleAP() {
		Id newActionPlanId;
		Id objId;
		String objName;
		List<Id> oIdsList = new List<Id>();
		if (refId == null) {
			for (String s : getAllRelationshipFields()) {
				if (actionPlan.get(s) != null) {
					objId = (Id) actionPlan.get(s);
					System.debug('objId: ' + objId);
					Schema.DescribeSObjectResult dsr = objId.getSObjectType().getDescribe(SObjectDescribeOptions.DEFERRED);
					objName = dsr.getName();
					System.debug('saveSingleAP objName = ' + objName);
					break;
				}
			}

			oIdsList.add(objId);
		} else {
			objName = refType;
			oIdsList = parseRelatedIDs(refId);
			System.debug('objName : ' + objName + ' with IDs ' + refId);
		}

		//check for pendingDeletes
		this.checkPendingDeletes();

		if (String.isNotBlank(objName) && oIdsList.size() == 1) {
			Set<Id> parentIDs = new Set<Id>();
			parentIDs.addAll(oIdsList);

			if (actionPlan.Id == null && !this.inVisualforceContext && !System.isFuture() && !System.isBatch()) {
				System.enqueueJob(new ActionPlansQueueableBuilder(actionPlan, this.apTasks, objName, parentIDs));
			} else {
				newActionPlanId = new ActionPlansBuilderUtilities(actionPlan, this.apTasks, objName, parentIDs).generateActionPlans();
			}
		}
		return newActionPlanId;
	}

	/**
	 * Saves Action Plan Instance and tasks and returns to the creation page with the previous Action Plan's details.
	 * @return newPage
	 */
	public PageReference saveAndNew() {
		save();

		PageReference newPage = Page.ActionPlanCreation;
		newPage.setRedirect(true);
		newPage.getParameters().put('templateId', this.templateId);

		return newPage;
	}

	/**
	 * Save Action Plans for multiple related object instances.
	 * <br>Invokes queueable process that creates: ActionPlan, ActionPlanTasksTemplate, and Tasks
	 * @return Pagereference (null or ActionPlansHome with confirmation)
	 * @see ActionPlansUtilities.getEscapedPageParameter
	 */
	@TestVisible
	private PageReference saveMultipleAP() {
		String oIds = ActionPlansUtilities.getEscapedPageParameter('refId');
		List<Id> oIdsList = new List<Id>();
		if ((refType != null || refType != '') && (oIds != null || oIds != '')) {
			try {
				oIdsList = parseRelatedIDs(oIds);
				Set<Id> parentIDs = new Set<Id>(oIdsList);
				//For each inserted AP we should run through tasks and create them
				ActionPlansQueueableBuilder taskQueue = new ActionPlansQueueableBuilder(this.actionPlan, this.apTasks, refType, parentIDs);
				System.enqueueJob(taskQueue);
			} catch (Exception e) {
				Apexpages.addMessages(e);
				errorMsg = e.getMessage();
				return null;
			}
		}

		PageReference newPage = Page.ActionPlansHome;
		String confirmation =
			oIdsList.size() +
			' ' +
			ActionPlan__c.sObjectType.getDescribe().getLabelPlural() +
			' ' +
			System.Label.ap_Created +
			' ' +
			System.Label.ap_ConfirmationofCreation;
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
	 * @see ActionPlanCreationController.saveMultipleAP
	 */
	private PageReference saveHandler() {
		System.debug('in saveHandler');
		if (!this.actionPlan.SkipWeekends__c) {
			this.actionPlan.SkipDay__c = null;
		}
		String oIds = ActionPlansUtilities.getEscapedPageParameter('refId');
		List<Id> oIdsList = new List<Id>();

		if (oIds != null) {
			oIdsList = parseRelatedIDs(oIds);
			System.debug('oidslist: ' + oIdsList);
			return (oIdsList.size() > 1) ? this.saveMultipleAP() : this.savePageRef();
		} else {
			return this.savePageRef();
		}
	}

	/**
	 * Saves Action Plan Instance and tasks and redirects to that detail page
	 * @return newPage
	 * @see ActionPlanCreationController.saveSingleAP
	 */
	private PageReference savePageRef() {
		Id newApId;
		//String ap_Prefix;

		try {
			newApId = saveSingleAP();
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

			String confirmation = this.actionPlan.Name + ' ' + System.Label.ap_Created;
			newPage.getParameters().put('message', confirmation);
			newPage.getParameters().put('severity', 'success');
			newPage.setRedirect(true);
			return newPage;
		}
	}

	/**
	 * Action that redirects to previous page
	 * @return `PageReference` previousPage
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
	 * Creates a blank `APTask__c` record and adds it to apTasks
	 * <br>Sets addedTask to the `APTask__c`
	 * @return `PageReference` but we return null for a page refresh
	 * @see ActionPlanCreationController.addedTask
	 */
	public PageReference addTask() {
		this.taskIndex++;

		Boolean hasError = false;
		if (this.apTasks.size() >= ActionPlansUtilities.MAX_APTASKS) {
			List<String> parameters = new List<String>();
			parameters.add(String.valueof(ActionPlansUtilities.MAX_APTASKS));

			errorMsg = String.format(System.Label.ap_Errors_TaskLimitError, parameters);
			return null;
		} else {
			APTask__c newApt = new APTask__c();
			newApt.Reminder__c = ActionPlansUtilities.getCheckReminderByDefault();
			newApt.Minutes_Reminder__c = ActionPlansUtilities.getDefaultReminderMinutes();
			newApt.Name = null;
			newApt.TaskIndex__c = this.taskIndex;

			// validate subject and days before adding another
			for (APTask__c apt : apTasks) {
				hasError = (hasError == true) || (apt.Subject__c == null);
				apt.DaysFromStart__c = (apt.DaysFromStart__c < 0) ? 0 : apt.DaysFromStart__c;
			}
			if (!hasError) {
				this.apTasks.add(newApt);
			}
			this.addedTask = newApt;
		}
		return null;
	}

	/**
	 * Action for removing a existing Action Plan Task
	 * @return `PageReference` null to refresh current page
	 */
	public PageReference removeTask() {
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
		return null;
	}

	/**
	 * Method that retrieves all AP tasks for a Action Plan for Visualforce Page
	 * @return  `List<ApTaskWrapper>` of AP Task Wrappers for Visualforce Page
	 */
	public List<ApTaskWrapper> getTasks() {
		List<ApTaskWrapper> tasksList = new List<ApTaskWrapper>();
		Integer i = 0;
		for (APTask__c apTask : this.getAPTasks()) {
			//ApTaskWrapper newTaskWrapper;

			//check if the lookup has to be shown
			/* if (apTask.Id != null) {
				newTaskWrapper = this.mapTasksListBkp.get(apTask.Id);
			} */

			ApTaskWrapper apTWrapper = new ApTaskWrapper(actionPlan, apTask, i, actionPlan.TaskRecordTypeID__c);
			tasksList.add(apTWrapper);
			/* if (String.isNotBlank(apTask.Id)) {
				this.mapTasksListBkp.put(apTask.Id, apTWrapper);
			} */
			i++;
		}
		if (i > 0) {
			tasksList[i - 1].isLast = true;
		}
		return tasksList;
	}

	/**
	 * Gets Tasks related to an Action Plan, or initializes from the Action Plan Template
	 * @return `List<APTask__c>` Action Plan Tasks
	 */
	public List<APTask__c> getAPTasks() {
		if (this.apTasks == null || this.apTasks.isEmpty()) {
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
					APTask__c apt = new APTask__c();
					//Read the Custom Settings in order to asign the User to that Task
					if (aptTask.User__c != null) {
						apt.User__c = aptTask.User__c;
					}
					apt.Type__c = aptTask.Type__c;
					apt.Subject__c = aptTask.Subject__c;
					apt.Priority__c = aptTask.Priority__c;
					apt.Dependent__c = aptTask.Dependent__c;
					apt.TaskIndex__c = aptTask.TaskIndex__c;
					apt.DaysFromStart__c = aptTask.DaysFromStart__c;
					apt.Reminder__c = aptTask.Reminder__c;

					if (aptTask.Reminder__c && String.isBlank(aptTask.Minutes_Reminder__c)) {
						apt.Minutes_Reminder__c = ActionPlansUtilities.getDefaultReminderMinutes();
					} else if (aptTask.Reminder__c) {
						apt.Minutes_Reminder__c = aptTask.Minutes_Reminder__c;
					} else if (!aptTask.Reminder__c) {
						apt.Minutes_Reminder__c = null;
					}
					if (!ActionPlansUtilities.getCanDisplayReminder()) {
						apt.Reminder__c = false;
						apt.Minutes_Reminder__c = null;
					}

					apt.SendEmail__c = aptTask.SendEmail__c;
					apt.Comments__c = aptTask.Comments__c;
					this.apTasks.add(apt);
				}
			} else if (actionPlan.Id != null) {
				this.apTasks = retrieveTaskFromExistingActionPlan(actionPlan.Id);
				//check reminders and set 'send email' as false
				String tmpReminderDefaultTime = ActionPlansUtilities.getDefaultReminderMinutes();
				for (APTask__c apt : this.apTasks) {
					if (apt.Reminder__c == null || apt.Reminder__c == false) {
						apt.Reminder__c = false;
						apt.Minutes_Reminder__c = tmpReminderDefaultTime;
					}
					//t.SendEmail__c = false;
				}
			} else {
				this.apTasks = new List<APTask__c>();
				APTask__c apt = new APTask__c();
				apt.Reminder__c = ActionPlansUtilities.getCheckReminderByDefault();
				apt.Minutes_Reminder__c = ActionPlansUtilities.getDefaultReminderMinutes();
				this.apTasks.add(apt);
			}
		}

		return this.apTasks;
	}

	/**
	 * Get a Existing Action Plan Task List
	 * @param actionPlanId Parent `ActionPlan__c` Id
	 * @return `List<APTask__c>` All template tasks
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
				IsClosed__c,
				Action_Plan__r.Name
			FROM APTask__c
			WHERE Action_Plan__c = :actionPlanId
			ORDER BY TaskIndex__c ASC
		];

		return myList;
	}

	/**
	 * Retrieves if template lookup must be displayed
	 * @return `Boolean` True if there is a related record or if there is a template ID provided
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
	 * @see ActionPlanCreationController.retrieveNameRelatedRecord
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
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @param  relatedIDs The page URL parameters
	 * @return `List<Id>` A list (not set) of all related IDs from the URL
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
	 * @return `List<String>` List of related record names
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

	/**
	 * We need a list of parent RECORD names when showing all the parents when we mass-create action plans
	 * <br>This initializes the list, and then divides it into three parts for three columns on the page.
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return `List<String>` The list of related object Names (not labels)
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
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return  `Integer` The picklist size
	 */
	public Integer getNameListSize() {
		return relatedObjNameList.size();
	}

	/**
	 * Column one of related records
	 */
	public List<String> relatedRecordsOne { get; private set; }
	/**
	 * Column two of related records
	 */
	public List<String> relatedRecordsTwo { get; private set; }
	/**
	 * Column three of related records
	 */
	public List<String> relatedRecordsThree { get; private set; }

	/**
	 * Checks if Action Plan Tasks has cyclic dependency.
	 * @return `Boolean` True if there is a cyclic dependency
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
	 * @return `Double` maxIndex
	 */
	private Double calculateMaxTaskIndex() {
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
	 * @return `Double` maxIndex
	 */
	private Double calculateMaxTemplateTaskIndex() {
		Double maxIndex = 0;
		List<AggregateResult> arList = [SELECT MAX(TaskIndex__c) m FROM APTemplateTask__c WHERE Action_Plan_Template__c = :this.templateId];
		if (!arList.isEmpty()) {
			maxIndex = (Double) arList[0].get('m');
			maxIndex = (maxIndex == null ? 0 : maxIndex);
		}
		return maxIndex;
	}

	/**
	 * Picklist of related object options, generated from the Field Set on Action Plan
	 */
	private List<SelectOption> relatedObjectOptions;
	/**
	 * Getter method with the related object options by default.
	 * @return `List<SelectOption>` Picklist of all related objects to Action Plan
	 * @see ActionPlanCreationController.findActivityEnabledObjects
	 */
	public List<SelectOption> getRelatedObjectOptions() {
		if (relatedObjectOptions == null) {
			relatedObjectOptions = new List<SelectOption>();

			// Describe the fieldSet so we can make sure that we only add SelectOptions for desired records
			Schema.FieldSet fs = Schema.SObjectType.ActionPlan__c.fieldSets.Related_Objects;
			System.assert(!fs.getFields().isEmpty(), 'Field Set of related objects must have at least one value');

			Set<String> activityEnabledObjects = findActivityEnabledObjects();

			for (Schema.FieldSetMember fsm : fs.getFields()) {
				String s = fsm.getFieldPath();
				//System.debug('FieldPath to related record: ' + s);
				Schema.DisplayType dt = fsm.getType();
				if (s.contains('.') || !dt.name().equalsIgnoreCase('Reference') || !s.endsWithIgnoreCase('__c')) {
					continue; // only look at custom references one object up
				}

				Schema.DescribeFieldResult dfr = fsm.getSObjectField().getDescribe();
				Schema.DescribeSObjectResult dsr = dfr.getReferenceTo()[0].getDescribe(SObjectDescribeOptions.DEFERRED);
				Boolean hasActivities = activityEnabledObjects.contains(dsr.getName());
				Boolean canSeeRelatedObject = dsr.isAccessible();
				Boolean canUpdateLookupField = dfr.isUpdateable();

				if (canSeeRelatedObject && canUpdateLookupField && hasActivities) {
					String value = dfr.getName();
					String label = dsr.getLabel();
					relatedObjectOptions.add(new SelectOption(value, label));
				}
			}
			relatedObjectOptions.sort();
		}
		if (relatedObjectOptions.isEmpty()) {
			if (Test.isRunningTest()) {
				relatedObjectOptions.add(new SelectOption(getNamespacePrefix() + 'Account__c', 'Account'));
			} else {
				relatedObjectOptions.add(new SelectOption('', System.label.ap_None));
			}
		}
		return relatedObjectOptions;
	}

	/**
	 * Get all available WhatId and WhoId objects
	 * @return  `Set<String>` Objects that Task can use in WhoId or WhatId
	 */
	private Set<String> findActivityEnabledObjects() {
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
	 * @see ActionPlansUtilities.getEscapedPageParameter
	 */
	public PageReference refreshRelatedObjectsLookUp() {
		relatedFieldName = ActionPlansUtilities.getEscapedPageParameter('relatedFieldName');
		return null;
	}

	/**
	 * Find user default task recordtype
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return `Id` default Task record type Id
	 * @see ActionPlansUtilities.getDefaultTaskRecordTypeId
	 */
	@testVisible
	private Id getDefaultTaskRecordTypeId() {
		return ActionPlansUtilities.getDefaultTaskRecordTypeId();
	}

	/**
	 * Convert Record Type Id to Record Type Name for the Action Plan's Tasks
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return `String` Task Record Type Name for the current Action Plan
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
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return `List<SelectOption>` Picklist of `Task.RecordType` options
	 * @see ActionPlansUtilities.getTaskRTPicklistValues
	 */
	public List<SelectOption> getTaskRTPicklistValues() {
		return ActionPlansUtilities.getTaskRTPicklistValues();
	}

	/**
	 * Picklist of `Task.Type` values
	 */
	private List<SelectOption> taskTypes;
	/**
	 * Generate picklist of Task Types
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return Picklist of `Task.Type`
	 * @see ActionPlansUtilities.getFieldOptions
	 */
	public List<SelectOption> getTaskTypes() {
		if (taskTypes == null) {
			taskTypes = ActionPlansUtilities.getFieldOptions('Task', 'Type', null);
		}
		return taskTypes;
	}

	/**
	 * Picklist of `Task.Priority` values
	 */
	private List<SelectOption> taskPriorities;
	/**
	 * Generate picklist of Task Priorities
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return `List<SelectOption>` Picklist of `Task.Priority`
	 * @see ActionPlansUtilities.getFieldOptions
	 */
	public List<SelectOption> getTaskPriorities() {
		if (taskPriorities == null) {
			taskPriorities = ActionPlansUtilities.getFieldOptions('Task', 'Priority', true);
		}
		return taskPriorities;
	}

	/**
	 * Generate picklist of available task due times
	 * @return  `List<SelectOption>` picklist of 30-minute intervals
	 * @see ActionPlansUtilities.getHoursOption
	 */
	public List<SelectOption> getHoursOption() {
		return ActionPlansUtilities.getHoursOption();
	}

	/**
	 * Retrieve the Namespace Prefix in case we are in a managed package. Needed for the JavaScript in the page
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return `String` Namespace Prefix (LabsActionPlans or empty string)
	 * @see ActionPlansUtilities.namespacePrefix
	 */
	public String getNamespacePrefix() {
		return ActionPlansUtilities.namespacePrefix;
	}

	/**
	 * Wrapper Class for AP Task SObject
	 * @author {@link [Rodrigo Birriel](https://www.linkedin.com/in/rbirriel)}
	 * @since 08/01/2010
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @since 4/2022
	 */
	public class ApTaskWrapper {
		/**
		 * Action Plan in wrapper
		 */
		private ActionPlan__c ap;
		/**
		 * Action Plan Task in wrapper
		 * @return  `APTask__c` The Action Plan task
		 */
		public APTask__c apt { get; set; }
		/**
		 * Task position (order on the page)
		 * @return  `Integer` Index
		 */
		public Integer position { get; set; }
		/**
		 * Last Task
		 * @return   `Boolean` Is this AP Task the last in the list?
		 */
		public Boolean isLast { get; set; }
		/**
		 * Does blank User field default to parent owner?
		 * <br>Filled from custom setting
		 * @return `Boolean` Blank user lookup assigns to parent owner
		 */
		private Boolean assignToOwner;

		/**
		 * Constructor for wrapper to display related `APTask__c` records on `ActionPlan__c` create/edit page
		 * @param ap              Action Plan record
		 * @param apTask          Action Plan Task record
		 * @param position        Position (in the list of AP Tasks) on the Page
		 * @param apTaskRTId      The Record Type of the Task eventually to be created
		 */
		public ApTaskWrapper(ActionPlan__c ap, APTask__c apTask, Integer position, Id apTaskRTId) {
			this.ap = ap;
			this.apt = apTask;
			this.position = position;
			this.isLast = false;
			this.assignToOwner = ActionPlansUtilities.getCustomSetting().Unassigned_Task_Assigned_to_Owner__c;

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
		}

		/**
		 * Defines if we set the `APTask__c` Assigned To field to required
		 * @author {@link [David Schach](https://github.com/dschach)}
		 * @return   `Boolean` Should the field be required?
		 */
		public Boolean userRequired {
			get {
				if (userRequired == null) {
					getUserRender();
				}
				return userRequired;
			}
			set;
		}

		/**
		 * Logic for determining how to show the Assigned To field for the AP Task
		 * <br>If we show the UserLookup, set the UserRequired property to determine if the field is required
		 * @author {@link [David Schach](https://github.com/dschach)}
		 * @return   `String` UserReadOnly, UserLookup, OwnerPlaceholder
		 */
		public String getUserRender() {
			Id templateId = ActionPlansUtilities.getEscapedPageParameter('templateId');

			if (templateId != null && apt.User__c != null) {
				return 'UserReadOnly';
			} else if (templateId == null && ap.Id == null) {
				return 'UserLookup';
			}

			Boolean canEdit = Schema.sObjectType.APTask__c.fields.User__c.isUpdateable();
			userRequired = false;

			if (!assignToOwner) {
				if (!canEdit) {
					apt.User__c = UserInfo.getUserId();
					return 'UserReadOnly';
				} else if (apt.Id != null && canEdit) {
					userRequired = true;
					return 'UserLookup';
				} else if (apt.Id != null) {
					return 'UserReadOnly';
				}
				userRequired = true;
				return 'UserLookup';
			} else {
				if (apt.User__c == null || !canEdit) {
					return 'OwnerPlaceholder';
				} else if (apt.User__c != null) {
					return 'UserLookup';
				}
				return 'UserLookup';
			}
		}
	}

	/**
	 * Main code for lightning lookup. Included in this class because we use this as the controller for our main page
	 * <br>The code is duplicated from ActionPlanSectionHeaderController because there is a lookup directly in this page (for now)
	 *
	 * @param queryText SOQL query to return records for the lookup
	 * @return          `List<SObject>` Returned records
	 * @see ActionPlanSectionHeaderController
	 */
	@RemoteAction
	public static List<SObject> getRecords(String queryText) {
		System.debug('querytext ' + queryText);
		return Database.query(queryText);
	}
}