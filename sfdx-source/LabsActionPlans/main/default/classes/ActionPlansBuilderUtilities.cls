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
 * Builder Utilities class
 * @author {@link [Rodrigo Birriel](https://www.linkedin.com/in/rbirriel)}
 * @author {@link [David Schach](https://github.com/dschach)}
 * @group Utilities
 * @since v3
 * @see ActionPlanCreateInvocable
 * @see ActionPlanCreationController
 * @see ActionPlansQueueableBuilder
 */
public inherited sharing class ActionPlansBuilderUtilities {
	private List<APTask__c> baseAPTaskList { get; set; }

	private List<ActionPlan__c> relActionPlans { get; set; }
	private List<APTask__c> relAPTaskList { get; set; }

	private String relatedObjectName { get; set; }
	private Set<Id> relatedRecordIDs { get; set; }

	/**
	 * Editing or creating an `ActionPlan__c` record?
	 */
	private enum ApEditMode {
		MODE_EDIT_SINGLE,
		MODE_NEW
	}
	private ApEditMode mode;

	/**
	 * All tasks for upserting that will not require an email to be sent
	 */
	private List<Task> myTasksWithOutEmail { get; set; }
	// TODO: Combine these two lists and use upsert if we can with the dmlo
	private List<Task> myOldTasksWithEmail { get; set; }
	private List<Task> myNewTasksWithEmail { get; set; }

	/**
	 * Constructor
	 * @param baseObj      ActionPlan object
	 * @param aPTListparam Action Plan Task Template records
	 * @param refType      Related object Name
	 * @param oIdsLIst     Parent IDs
	 */
	public ActionPlansBuilderUtilities(ActionPlan__c baseObj, List<APTask__c> aPTListparam, String refType, Set<Id> oIdsLIst) {
		this.baseAPTaskList = aPTListparam;
		this.relActionPlans = new List<ActionPlan__c>();
		this.relatedObjectName = refType;
		this.relatedRecordIDs = oIdsLIst;

		// if the actionPlan has already an Id, then we are editing an AP and not creating a new one
		if (baseObj.id != null) {
			mode = ApEditMode.MODE_EDIT_SINGLE;
			relActionPlans.add(baseObj);
		} else {
			// If baseObjId == null, then we are inserting a single or multiple APs
			mode = ApEditMode.MODE_NEW;
			List<String> apRefFields = ActionPlansUtilities.getCustomRelationshipFields();
			Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.ActionPlan__c.fields.getMap();

			for (Id relObjId : oIdsLIst) {
				// iterate over all related IDs
				ActionPlan__c ap = new ActionPlan__c();
				ap = baseObj.clone();

				for (String s : apRefFields) {
					String relatedObject = fieldMap.get(s).getDescribe().getReferenceTo()[0].getDescribe().getName();
					if (relatedObject.equalsIgnoreCase(refType)) {
						ap.put(s, relObjId);
					}
				}
				//add Action Plan to list that will be inserted later and referenced by ActionPlanTasks
				relActionPlans.add(ap);
			}
		}
	}

	/**
	 * Generate Action Plans from parameters passed to this class
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return   `Id` of the first created `ActionPlan__c`
	 */
	public Id generateActionPlans() {
		List<APTask__c> aptList = new List<APTask__c>();
		Set<Id> upsertedAPTaskIDs = new Set<Id>();
		Map<Id, ActionPlan__c> mapIDAP = new Map<Id, ActionPlan__c>();
		ActionPlan__c apAux;
		Map<Id, Task> mapApTasks = new Map<Id, Task>();
		Integer taskTemplateNameLength = APTask__c.Name.getDescribe().getLength();

		this.myOldTasksWithEmail = new List<Task>();
		this.myNewTasksWithEmail = new List<Task>();
		this.myTasksWithOutEmail = new List<Task>();
		this.relAPTaskList = new List<APTask__c>();

		Map<Id, Id> objectOwnersMap = retrieveOwnersDataRelatedObject(this.relatedRecordIDs);
		//insert Action Plans to DB
		upsert relActionPlans;

		//create ActionPlanTemplatetasks && tasks from base ActionPlan Task List
		if (this.mode == ApEditMode.MODE_NEW) {
			// Working on multiple APs from oidsList
			for (ActionPlan__c ap : relActionPlans) {
				mapIDAP.put(ap.Id, ap);

				//Now for each inserted ap we should run through tasks and create them
				for (APTask__c t : this.baseAPTaskList) {
					APTask__c nt = new APTask__c();
					nt = t.clone();

					nt.Action_Plan__c = ap.Id;
					nt.Name = t.Id == null ? ActionPlansUtilities.actionPlanSubjectToName(t.Subject__c, taskTemplateNameLength) : nt.Name;
					nt.DaysFromStart__c = (nt.DaysFromStart__c == null || nt.DaysFromStart__c < 0) ? 0 : nt.DaysFromStart__c;
					nt.User__c = getAPTaskTemplateUser(ap, objectOwnersMap, nt.User__c);
					aptList.add(nt);
				}
			}

			upsert aptList;
		} else {
			System.assertEquals(1, relActionPlans.size());

			for (ActionPlan__c ap : relActionPlans) {
				mapIDAP.put(ap.Id, ap);

				for (APTask__c t : this.baseAPTaskList) {
					t.DaysFromStart__c = (t.DaysFromStart__c == null || t.DaysFromStart__c < 0) ? 0 : t.DaysFromStart__c;
					t.Name = t.Id == null ? ActionPlansUtilities.actionPlanSubjectToName(t.Subject__c, taskTemplateNameLength) : t.Name;
					t.User__c = getAPTaskTemplateUser(ap, objectOwnersMap, t.User__c);
				}
				aptList = this.baseAPTaskList;
			}
		}

		List<APTask__c> aptsToUpsert = new List<APTask__c>();

		String defaultTaskStatus = ActionPlansUtilities.getTaskRecordTypeStatusDefaultValues().get(ActionPlansUtilities.getDefaultTaskRecordTypeId());

		for (ActionPlan__c ap : relActionPlans) {
			for (APTask__c at : aptList) {
				if (at.Action_Plan__c != null && at.Action_Plan__c != ap.Id) {
					continue;
				}

				if (at.Action_Plan__c == null && ap.Id != null) {
					at.Action_Plan__c = ap.Id;
				} // This Id can be null because we may not have set it in the controller

				if (at.Status__c == null) {
					if (!String.isBlank(ap.TaskRecordTypeId__c) && ap.TaskRecordTypeId__c instanceof Id && ap.TaskRecordTypeId__c.startsWithIgnoreCase('012')) {
						at.Status__c = ActionPlansUtilities.getTaskRecordTypeStatusDefaultValues().get(ap.TaskRecordTypeId__c);
					} else {
						at.Status__c = defaultTaskStatus;
					}
				}

				if (at.Dependent__c != null && at.Dependent__c != 'None') {
					Integer tempIndex = Integer.valueOf(at.Dependent__c);
					at.Controller__c = aptList[tempIndex].Id;
					at.ActivityDate__c = null;
				} else {
					at.Controller__c = null;
					//set dependency taskId to none if none was selected
					at.Dependent__c = 'None';

					// create due date, calculate the due date of the tasks for skip weekends feature
					if (ap.SkipWeekends__c == true && ap.SkipDay__c != null) {
						at.ActivityDate__c = ActionPlansUtilities.adjustTaskDueDate(ap.StartDate__c, at.DaysFromStart__c.intValue(), ap.SkipDay__c);
					} else {
						at.ActivityDate__c = ap.StartDate__c.addDays(at.DaysFromStart__c.intValue());
					}
				}
				aptsToUpsert.add(at);
			}
		}

		upsert aptsToUpsert;

		// This may be unnecessary, as we can probably use the upserted list in the query, but is here for readability
		for (APTask__c apt : aptsToUpsert) {
			upsertedAPTaskIDs.add(apt.Id);
		}

		for (Task tmpTask : [SELECT Id, TaskAPTask__c, Subject FROM Task WHERE TaskAPTask__c IN :upsertedAPTaskIDs AND TaskAPTask__c != NULL]) {
			mapApTasks.put(tmpTask.TaskAPTask__c, tmpTask);
		}

		for (APTask__c refAPTask : aptsToUpsert) {
			// check if task exists already
			Task t = mapApTasks.get(refAPTask.Id);
			if (t == null) {
				//Create the new task and template
				t = new Task();
			}
			t.Subject = refAPTask.Subject__c;
			t.Priority = refAPTask.Priority__c;
			t.OwnerId = refAPTask.User__c;
			t.Type = refAPTask.Type__c;
			t.TaskAPTask__c = refAPTask.Id;

			if (String.isNotEmpty(refAPTask.Comments__c)) {
				t.Description = refAPTask.Comments__c;
			}

			if (t.Id == null) {
				t.Status = refAPTask.Status__c;
			}

			//set reminder based on user's default reminder setting
			if (refAPTask.Reminder__c == true && refAPTask.ActivityDate__c != null) {
				t.isReminderSet = true;
				t.ReminderDateTime = Datetime.newInstance(refAPTask.ActivityDate__c.year(), refAPTask.ActivityDate__c.month(), refAPTask.ActivityDate__c.day(), 0, 0, 0);
				t.ReminderDateTime = t.ReminderDateTime.addMinutes(Integer.valueOf(refAPTask.Minutes_Reminder__c));
			} else {
				t.isReminderSet = false;
			}
			t.ActivityDate = refAPTask.ActivityDate__c;

			if (mapIDAP.containsKey(refAPTask.Action_Plan__c)) {
				apAux = mapIDAP.get(refAPTask.Action_Plan__c);
			}

			if (apAux == null) {
				apAux = refAPTask.Action_Plan__r;
			}

			Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.ActionPlan__c.fields.getMap();

			Boolean setWhat = true;
			if (apAux.Contact__c != null) {
				t.WhoId = apAux.Contact__c;
				setWhat = false;
			} else if (apAux.Lead__c != null) {
				t.WhoId = apAux.Lead__c;
				setWhat = false;
			}

			if (setWhat) {
				//link to Action Plan's Related To Object
				for (String s : ActionPlansUtilities.getCustomRelationshipFields()) {
					String relatedObject = fieldMap.get(s).getDescribe().getReferenceTo()[0].getDescribe().getName();
					if (relatedObject.equalsIgnoreCase(relatedObjectName)) {
						t.WhatId = (Id) apAux.get(s);
						break;
					}
				}
			}

			if (refAPTask.Dependent__c == 'None') {
				if (refAPTask.SendEmail__c == true) {
					if (t.id == null) {
						this.myNewTasksWithEmail.add(t);
					} else {
						this.myOldTasksWithEmail.add(t);
					}
				} else {
					this.myTasksWithOutEmail.add(t);
				}
			} else {
				//only update dependant tasks that are already created
				if (t.Id != null) {
					this.myTasksWithOutEmail.add(t);
				}
			}
		}

		Database.DMLOptions dmlo = new Database.DMLOptions();
		Database.DMLOptions dmlo2 = new Database.DMLOptions();

		if (this.myNewTasksWithEmail.size() > 0) {
			dmlo.EmailHeader.triggerUserEmail = true;
			Database.insert(this.myNewTasksWithEmail, dmlo); //NOPMD
		}

		if (this.myOldTasksWithEmail.size() > 0) {
			dmlo.EmailHeader.triggerUserEmail = true;
			Database.update(this.myOldTasksWithEmail, dmlo); //NOPMD
		}

		if (this.myTasksWithOutEmail.size() > 0) {
			if (this.mode == ApEditMode.MODE_EDIT_SINGLE) {
				Database.upsert(this.myTasksWithOutEmail); //NOPMD
			} else {
				dmlo2.EmailHeader.triggerUserEmail = false;
				Database.insert(this.myTasksWithOutEmail, dmlo2); //NOPMD
			}
		}

		if (this.mode != ApEditMode.MODE_EDIT_SINGLE) {
			// Execution When a Action Plan is created that checks the Custom Setings in order to post a new FeedPost ( Object )
			Action_Plans_Settings__c mySettings = ActionPlansUtilities.getCustomSetting();

			Set<Id> relObjectIDs = new Set<Id>();
			for (ActionPlan__c ap : relActionPlans) {
				relObjectIDs.add(ap.Id);
			}

			if (mySettings != null && mySettings.Chatter_Object_Brag__c) {
				generateObjectFeeds(relObjectIDs);
			}
		}
		if (relActionPlans.size() == 1) {
			return relActionPlans[0].id;
		} else {
			return null;
		}
	}

	/**
	 * Read the Action Plan and see the custom setting to determine who should own the AP Tasks
	 * @param ap           The `ActionPlan__c`
	 * @param relObjOwners Map of `Id` to record `OwnerId`
	 * @param apTaskUser   The record user Id
	 * @return             `Id` The `APTask__c` assigned user
	 * @see ActionPlansBuilderUtilities.getRelatedRecordOwnerId
	 */
	public static Id getAPTaskTemplateUser(ActionPlan__c ap, Map<Id, Id> relObjOwners, Id apTaskUser) {
		if (String.isNotBlank(apTaskUser)) {
			return apTaskUser;
		}
		Action_Plans_Settings__c mySettings = ActionPlansUtilities.getCustomSetting();
		if (mySettings.Unassigned_Task_Assigned_to_Owner__c) {
			return getRelatedRecordOwnerId(ap, relObjOwners);
		} else {
			return UserInfo.getUserId();
		}
	}

	/**
	 * Given an Action Plan, looking in its relationship fields, find the owner of the related record from the map of records and owners
	 * @param ap           `ActionPlan__c`
	 * @param relObjOwners Map of related object `Id` to `OwnerId`
	 * @return             `Id` The related record `OwnerId`
	 */
	public static Id getRelatedRecordOwnerId(ActionPlan__c ap, Map<Id, Id> relObjOwners) {
		Id objId;

		for (String f : ActionPlansUtilities.getCustomRelationshipFields()) {
			if (ap.get(f) != null) {
				objId = (Id) ap.get(f);
				break;
			}
		}

		if (relObjOwners.containsKey(objId)) {
			return relObjOwners.get(objId);
		} else {
			return null;
		}
	}

	/**
	 * Retrieve the owner list from the related object.
	 * @param relatedRecordIDs	List of sobject Ids
	 * @return                  `Map<Id, Id>` Map of record Id to Owner Id
	 */
	public static Map<Id, Id> retrieveOwnersDataRelatedObject(Set<Id> relatedRecordIDs) {
		Map<Id, Id> relatedObjOwners = new Map<Id, Id>();
		if (relatedRecordIDs.isEmpty()) {
			return relatedObjOwners;
		}
		List<Id> recordIdList = new List<Id>(relatedRecordIDs);
		Id recId = recordIdList[0];
		String objectName = ActionPlansUtilities.getRelatedRecordInfo(recId).getName();

		String queryRetrieveOwnerIds;

		if (!relatedRecordIDs.isEmpty()) {
			queryRetrieveOwnerIds = 'SELECT Id, OwnerId FROM ' + objectName + ' WHERE Id IN :relatedRecordIDs';

			for (SObject obj : Database.query(String.escapeSingleQuotes(queryRetrieveOwnerIds))) {
				relatedObjOwners.put((Id) (obj.get('Id')), (Id) (obj.get('OwnerId')));
			}
		}
		return relatedObjOwners;
	}

	/**
	 * Generate New `FeedItems` for multiple Action Plans
	 * @param recIDs Set of IDs of records for which we may make Chatter posts
	 */
	public static void generateObjectFeeds(Set<Id> recIDs) {
		if (!Schema.getGlobalDescribe().containsKey('feeditem')) {
			return;
		}

		List<SObject> chatterPosts = new List<SObject>();

		List<String> apRefFields = ActionPlansUtilities.getCustomRelationshipFields();
		String apQuery = 'SELECT Id, Name, ' + String.join(apRefFields, ', ') + ' FROM ActionPlan__c WHERE Id IN :recIDs';

		for (SObject so : Database.query(String.escapeSingleQuotes(apQuery))) {
			ActionPlan__c ap = (ActionPlan__c) so;

			Id recId;
			Boolean chatterEnabled;

			for (String f : apRefFields) {
				if (ap.get(f) != null) {
					recId = (Id) ap.get(f);
					chatterEnabled = ActionPlansUtilities.getRelatedRecordInfo(recId).isFeedEnabled();
					//chatterEnabled = recId.getSObjectType().getDescribe().isFeedEnabled();
					break;
				}
			}

			if (chatterEnabled) {
				SObjectType token = Schema.getGlobalDescribe().get('FeedItem');
				SObject newPost = token.newSObject();
				newPost.put('Type', 'TextPost');
				newPost.put('ParentId', recId);
				newPost.put('Body', getPostObjectBody(recId, (String) ap.get('Name')));

				chatterPosts.add(newPost);
			}
		}

		insert chatterPosts;
	}

	/**
	 * Given a parentID and the name of an Action Plan, make the `FeedItem` post body
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @param  recID  Parent ID
	 * @param  apName Action Plan Name
	 * @return        `String` The `FeedItem` Body
	 */
	public static String getPostObjectBody(Id recID, String apName) {
		String objName = recID.getSObjectType().getDescribe().getLabel();
		String actionPlanName = apName;
		String runningUserName = UserInfo.getName();

		List<String> parameters = new List<String>();
		parameters.add(actionPlanName);
		parameters.add(objName);

		String chatterBody = runningUserName + ' ' + String.format(System.Label.ap_PostMessage, parameters);
		return chatterBody;
	}
}