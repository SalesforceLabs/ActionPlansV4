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
 * Batch Utilities class
 * @author Rodrigo Birriel
 * @author {@link [David Schach](https://github.com/dschach)}
 * @group Utilities
 * @since v3
 * @see ActionPlanCreateInvocable
 * @see ActionPlanCreationController
 * @see ActionPlansQueueableBuilder
 */
public inherited sharing class ActionPlansBatchBuilderUtilities {
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

	private List<Task> myTasksWithOutEmail { get; set; }
	private List<Task> myOldTasksWithEmail { get; set; }
	private List<Task> myNewTasksWithEmail { get; set; }

	/**
	 * Constructor
	 * @param baseObj      ActionPlan object
	 * @param aPTListparam Action Plan Task Template records
	 * @param refType      Related object Name
	 * @param oIdsLIst     Parent IDs
	 */
	public ActionPlansBatchBuilderUtilities(ActionPlan__c baseObj, List<APTask__c> aPTListparam, String refType, Set<Id> oIdsLIst) {
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
						System.debug('match on related object type ' + s);
						ap.put(s, relObjId);
					} else {
						System.debug('No match on ' + s);
					}
				}
				//add Action Plan to list that will be inserted later and referenced by ActionPlanTasks
				relActionPlans.add(ap);
			}
		}
	}

	/**
	 * Iterable method for batch
	 * @param bc    BatchableContext automatically passed
	 * @return      `Iterable<sObject>`
	 */
	public Iterable<sObject> getObjects(Database.BatchableContext bc) {
		return relActionPlans;
	}

	/**
	 * Send Action Plan records to queueable
	 * @return      `List<ActionPlan__c>`
	 */
	public List<ActionPlan__c> getObjects() {
		return relActionPlans;
	}

	/**
	 * Generate Action Plans from parameters passed to this class
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return   the `Id` of the first created `ActionPlan__c`
	 */
	public Id generateActionPlans() {
		List<APTask__c> aptList = new List<APTask__c>();
		//List<Id> aptTOTALListId = new List<Id>();
		Map<Id, APTask__c> mapAP = new Map<Id, APTask__c>();
		Map<Id, ActionPlan__c> mapIDAP = new Map<Id, ActionPlan__c>();
		ActionPlan__c apAux;
		Map<Id, Task> mapApTasks = new Map<Id, Task>();
		Integer taskTemplateNameLength = APTask__c.Name.getDescribe().getLength();

		this.myOldTasksWithEmail = new List<Task>();
		this.myNewTasksWithEmail = new List<Task>();
		this.myTasksWithOutEmail = new List<Task>();
		this.relAPTaskList = new List<APTask__c>();

		Map<Id, Id> objectOwnersMap = retrieveOwnersDataRelatedObject(this.relatedRecordIDs, this.relatedObjectName);
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
					nt.DaysFromStart__c = (nt.DaysFromStart__c < 0) ? 0 : nt.DaysFromStart__c;
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
					t.DaysFromStart__c = (t.DaysFromStart__c < 0) ? 0 : t.DaysFromStart__c;
					t.Name = t.Id == null ? ActionPlansUtilities.actionPlanSubjectToName(t.Subject__c, taskTemplateNameLength) : t.Name;
					t.User__c = getAPTaskTemplateUser(ap, objectOwnersMap, t.User__c);
				}
				aptList = this.baseAPTaskList;
			}
		}

		List<APTask__c> aptsToUpsert = new List<APTask__c>();

		for (ActionPlan__c ap : relActionPlans) {
			for (APTask__c at : aptList) {
				if (at.Action_Plan__c != null && at.Action_Plan__c != ap.Id) {
					continue;
				}

				//aptTOTALListId.add(at.Id);

				if (at.Action_Plan__c == null && ap.Id != null) {
					at.Action_Plan__c = ap.Id;
				} // This Id can be null because we may not have set it in the controller

				if (at.Status__c == null) {
					if (!String.isBlank(ap.TaskRecordTypeId__c) && ap.TaskRecordTypeId__c instanceof Id && ap.TaskRecordTypeId__c.startsWithIgnoreCase('012')) {
						at.Status__c = ActionPlansUtilities.getTaskRecordTypeStatusDefaultValues().get(ap.TaskRecordTypeId__c);
					} else {
						if (ActionPlansUtilities.taskUsesRecordTypes) {
							at.Status__c = ActionPlansUtilities.getTaskRecordTypeStatusDefaultValues().get(ActionPlansUtilities.getDefaultTaskRecordTypeId());
						} else {
							at.Status__c = ActionPlansUtilities.getTaskRecordTypeStatusDefaultValues().get(null);
						}
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

				mapAP.put(at.Id, at);
				aptsToUpsert.add(at);
			}
		}

		upsert aptsToUpsert;

		for (Task tmpTask : [SELECT Id, TaskAPTask__c, Subject FROM Task WHERE TaskAPTask__c IN :mapAP.keySet()]) {
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
			t.TaskAPTask__c = refAPTask.Id;

			if (refAPTask.Comments__c != null) {
				t.Description = refAPTask.Comments__c;
			}

			//set reminder based on user's default reminder setting
			if (refAPTask.Reminder__c == true && refAPTask.ActivityDate__c != null) {
				t.isReminderSet = true;
				t.ReminderDateTime = Datetime.newInstance(refAPTask.ActivityDate__c.year(), refAPTask.ActivityDate__c.month(), refAPTask.ActivityDate__c.day(), 0, 0, 0);
				t.ReminderDateTime = t.ReminderDateTime.addMinutes(Integer.valueOf(refAPTask.Minutes_Reminder__c));
			} else {
				t.isReminderSet = false;
			}

			if (mapIDAP.containsKey(refAPTask.Action_Plan__c)) {
				apAux = mapIDAP.get(refAPTask.Action_Plan__c);
				System.debug('apAux from mapIDAP ' + apAux);
			}

			if (apAux == null) {
				apAux = refAPTask.Action_Plan__r;
			}

			Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.ActionPlan__c.fields.getMap();

			Boolean setWhat = true;
			if (apAux.Contact__c != null) {
				System.debug('setting whoId to Contact');
				t.WhoId = apAux.Contact__c;
				setWhat = false;
			} else if (apAux.Lead__c != null) {
				System.debug('setting whoId to Lead');
				t.WhoId = apAux.Lead__c;
				setWhat = false;
			} else {
				System.debug('We do not set whoId');
			}

			if (setWhat) {
				//link to Action Plan's Related To Object
				for (String s : ActionPlansUtilities.getCustomRelationshipFields()) {
					String relatedObject = fieldMap.get(s).getDescribe().getReferenceTo()[0].getDescribe().getName();
					if (relatedObject.equalsIgnoreCase(relatedObjectName)) {
						t.WhatId = (Id) apAux.get(s);
						System.debug('Do not set what. Set who');
						break;
					} else {
						System.debug('No match on ' + s);
					}
					/* System.debug('iterating on field ' + s);
				System.debug(' with value ' + apAux?.get(s));
				if (!s.endsWithIgnoreCase(ActionPlansUtilities.namespacePrefix + 'Contact__c') && !s.equalsIgnoreCase(ActionPlansUtilities.namespacePrefix + 'Lead__c') && apAux?.get(s) != null) {
					t.WhatId = (Id) apAux.get(s);
					setWho = false;
					System.debug('Do not set what. Set who');
					break;
				} */
				}
			}

			t.Type = refAPTask.Type__c;

			if (t.Id == null) {
				t.Status = refAPTask.Status__c;
			}
			t.ActivityDate = refAPTask.ActivityDate__c;

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
				} else {
					System.debug('Unhandled task situation.');
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
	 * @param ap           `ActionPlan__c`
	 * @param relObjOwners Map of Id to record owner
	 * @param apTaskUser   The current record user
	 * @return             `Id` related OwnerID
	 * @see getRelatedRecordOwnerId
	 */
	public static Id getAPTaskTemplateUser(ActionPlan__c ap, Map<Id, Id> relObjOwners, Id apTaskUser) {
		if (String.isNotBlank(apTaskUser)) {
			return apTaskUser;
		}
		Action_Plans_Settings__c mySettings = ActionPlansUtilities.getCustomSetting();
		if (!mySettings.Unassigned_Task_Assigned_to_Owner__c) {
			return UserInfo.getUserId();
		}
		return getRelatedRecordOwnerId(ap, relObjOwners);
	}

	/**
	 * Given an Action Plan, looking in its relationship fields, find the owner of the related record from the map of records and owners
	 * @param ap           `ActionPlan__c`
	 * @param relObjOwners Map of related object `ID` to` OwnerId`
	 * @return             The related record `OwnerId`
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
	 * @param relatedRecordIDs		list of sobjects' id
	 * @param relatedObjectName     The name of the related object
	 * @return Map of record Id to Owner Id
	 */
	public static Map<Id, Id> retrieveOwnersDataRelatedObject(Set<Id> relatedRecordIDs, String relatedObjectName) {
		Map<Id, Id> relatedObjOwners = new Map<Id, Id>();
		String queryRetrieveOwnerIds;

		if (!relatedRecordIDs.isEmpty()) {
			queryRetrieveOwnerIds = 'SELECT Id, OwnerId FROM ' + String.escapeSingleQuotes(relatedObjectName) + ' WHERE Id IN :relatedRecordIDs';

			for (SObject obj : Database.query(queryRetrieveOwnerIds)) {
				relatedObjOwners.put((Id) (obj.get('Id')), (Id) (obj.get('OwnerId')));
			}
		}
		return relatedObjOwners;
	}

	/**
	 * Generate New `FeedItems` for multiple Action Plans
	 * @param objIds Set of IDs of records for which we may make Chatter posts
	 */
	public static void generateObjectFeeds(Set<Id> objIds) {
		List<SObject> chatterPosts = new List<SObject>();

		List<String> apRefFields = ActionPlansUtilities.getCustomRelationshipFields();
		String apQuery = 'SELECT Id, Name, ' + String.join(apRefFields, ', ') + ' FROM ActionPlan__c WHERE Id IN :objIds';

		if (!Schema.getGlobalDescribe().containsKey('feeditem')) {
			return;
		}
		for (SObject so : Database.query(String.escapeSingleQuotes(apQuery))) {
			ActionPlan__c ap = (ActionPlan__c) so;

			Id objId;
			Boolean chatterEnabled;

			for (String f : apRefFields) {
				if (ap.get(f) != null) {
					objId = (Id) ap.get(f);
					chatterEnabled = objId.getSObjectType().getDescribe().isFeedEnabled();
					break;
				}
			}

			if (chatterEnabled) {
				SObjectType token = Schema.getGlobalDescribe().get('FeedItem');
				SObject newPost = token.newSObject();
				newPost.put('Type', 'TextPost');
				newPost.put('ParentId', objId);
				newPost.put('Body', getPostObjectBody(objId, (String) ap.get('Name')));

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
	 * @return        `FeedItem.Body`
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