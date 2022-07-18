/*
Action Plans v4
David Schach 2022
https://appexchange.salesforce.com/appxListingDetail?listingId=a0N4V00000Gg6NVUAZ

Copyright (c) 2022, salesforce.com, inc.
All rights reserved.
SPDX-License-Identifier: BSD-3-Clause
For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
*/

/**
 * Utilities class - mostly describe methods and constants
 * @since 2022
 * @author {@link [David Schach](https://github.com/dschach)}
 * @group Utilities
 */
public without sharing class ActionPlansUtilities {
	/**
	 * Max number of APTasks per Action Plan
	 */
	public static final Integer MAX_APTASKS = 400;

	/**
	 * Max number of Action Plans that can be deleted from list
	 */
	public static final Integer MAX_APTODELETE = 1000;

	/**
	 * The standard Master `RecordType` Id
	 */
	public static final Id MASTER_RECORD_TYPE_ID = '012000000000000AAA'; //NOPMD

	/**
	 * Allows us to force the environment variable checking if Task has a Record Type for testing (forcing NO record type,). Increases code coverage.
	 */
	public static Boolean taskUsesRecordTypes {
		get {
			if (ActionPlansTestUtilities.forceHasRecordType != null) {
				return ActionPlansTestUtilities.forceHasRecordType;
			} else if (taskUsesRecordTypes == null) {
				//ActionPlansTestUtilities.forceHasRecordType = Task.sObjectType.getDescribe().fields.getMap().containsKey('recordtypeid');
				String taskRTQuery = 'SELECT COUNT() FROM RecordType WHERE SObjectType = \'Task\' AND IsActive = TRUE';
				ActionPlansTestUtilities.forceHasRecordType = Database.countQuery(taskRTQuery) > 0;
				taskUsesRecordTypes = ActionPlansTestUtilities.forceHasRecordType;
			}
			return taskUsesRecordTypes;
		}
		set;
	}

	/**
	 * Actions to perform whenever loading a Visualforce page
	 * <br>Ensures that Custom Setting is created for the org
	 * <br>Left as this method in case we want to add certain actions to both Creation Visualforce pages in the future
	 * @return   `PageReference` null
	 * @see checkOrgDefaultCustomSetting
	 */
	public static PageReference onPageLoad() {
		checkOrgDefaultCustomSetting(true);
		return null;
	}

	// Section to describe ActionPlan object to make custom relationship fields dynamic

	/**
	 * Memoized list of Action Plan custom relationship fields
	 */
	private static List<String> apCustomRelationshipFields;
	/**
	 * Check the fieldSet for all active Action Plan relationaship fields (available parent objects)
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return   `List<String>` List of field names
	 */
	public static List<String> getCustomRelationshipFields() {
		if (apCustomRelationshipFields == null) {
			List<String> referenceFieldNames = new List<String>();

			Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.ActionPlan__c.fields.getMap();
			//System.debug('Iterating over fieldset');
			for (String s : fieldMap.keyset()) {
				//System.debug('Checking field ' + s);
				if (s.containsIgnoreCase('.')) {
					continue;
				}
				Schema.DescribeFieldResult dfr = fieldMap.get(s).getDescribe();
				Schema.DisplayType dt = dfr.getType();
				if (dt.name().equalsIgnoreCase('Reference') && s.endsWithIgnoreCase('__c')) {
					String relatedObjectName = dfr.getReferenceTo()[0].getDescribe().getName();

					if (!relatedObjectName.startsWithIgnoreCase(namespacePrefix + 'ActionPlan')) {
						//System.debug('Relationship field to ' + relatedObjectName + ' is ' + s);
						referenceFieldNames.add(s);
					}
				}
			}
			apCustomRelationshipFields = referenceFieldNames;
		}
		return apCustomRelationshipFields;
	}

	/**
	 * Get prefix of sObject
	 * @param objName SObject Name
	 * @return `String` obj.getKeyPrefix()
	 * @example
	 * ActionPlansUtilities.getObjetKeyPrefix('Account');
	 * (returns '001')
	 */
	public static String getObjectKeyPrefix(String objName) {
		Schema.DescribeSObjectResult obj = Schema.getGlobalDescribe().get(objName).getDescribe();
		return obj.getKeyPrefix();
	}

	/**
	 * Memoize objects as we describe them, to save on calls
	 */
	private static Map<String, Schema.DescribeSObjectResult> prefixToDescribe;
	/**
	 * Store a map of object prefixes to describe info so we can fill the `ActionPlan__c` related record fields
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @param  recordId related record Id
	 * @return          `Schema.DescribeSObjectResult` so we can get info about the related record
	 */
	public static Schema.DescribeSObjectResult getRelatedSObjectDescribe(Id recordId) {
		if (prefixToDescribe == null) {
			prefixToDescribe = new Map<String, Schema.DescribeSObjectResult>();
		}
		String recordIdString = (String) recordId;
		String keyPrefix = recordIdString.left(3);
		if (!prefixToDescribe.containsKey(keyPrefix)) {
			prefixToDescribe.put(keyPrefix, recordId.getSobjectType().getDescribe());
		}
		return prefixToDescribe.get(keyPrefix);
	}

	/**
	 * Memoize record IDs so we don't have to keep iterating over them if we already have them
	 */
	private static Map<Id, String> recordIdToRecordName;
	/**
	 * Give a set of recordIDs and retrieve the related record names
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @param  recordIDs Set<Id> of parent records to Action Plans
	 * @return           `Map<Id, String>` Map of RecordID to Record Name (special for Case & Contract)
	 * @see getRelatedSObjectDescribe
	 */
	public static Map<Id, String> queryRecordIDToRecordName(Set<Id> recordIDs) {
		if (recordIdToRecordName == null) {
			recordIdToRecordName = new Map<Id, String>();
		}
		Map<String, Set<Id>> mapIDsByObject = new Map<String, Set<Id>>();
		Set<Id> idsToQuery = new Set<Id>();
		for (Id recId : recordIDs) {
			if (recordIdToRecordName.containsKey(recId)) {
				continue;
			}
			idsToQuery.add(recId);
			String objectName = getRelatedSObjectDescribe(recId).getName().toLowerCase();
			if (!mapIDsByObject.containsKey(objectName)) {
				mapIDsByObject.put(objectName, new Set<Id>());
			}
			mapIDsByObject.get(objectName).add(recId);
		}

		for (String objName : mapIDsByObject.keySet()) {
			switch on objName {
				when 'case' {
					List<Case> cases = [SELECT Subject, CaseNumber FROM Case WHERE Id IN :mapIDsByObject.get('case')]; // NOPMD
					for (Case ca : cases) {
						recordIdToRecordName.put(ca.Id, ((ca.Subject != null) ? ca.CaseNumber + ': ' + ca.Subject : ca.CaseNumber));
					}
				}
				when 'contract' {
					List<Contract> contracts = [SELECT ContractNumber FROM Contract WHERE Id IN :mapIDsByObject.get('contract')]; // NOPMD
					for (Contract contr : contracts) {
						recordIdToRecordName.put(contr.Id, (Contract.Name.getDescribe().getLabel() + ': ' + contr.ContractNumber));
					}
				}
				when 'order' {
					List<Order> orders = [SELECT OrderNumber FROM Order WHERE Id IN :mapIDsByObject.get('order')]; // NOPMD
					for (Order ord : orders) {
						recordIdToRecordName.put(ord.Id, (Order.OrderNumber.getDescribe().getLabel() + ': ' + ord.OrderNumber));
					}
				}
				when else {
					System.debug('Querying object name : ' + objName);
					Set<Id> queryIDs = mapIDsByObject.get(objName); //NOPMD
					System.debug('querying IDs: ' + queryIDs);
					List<SObject> genericQueryResults = Database.query('SELECT Id, Name FROM ' + String.escapeSingleQuotes(objName) + ' WHERE Id IN :queryIDs'); //NOPMD
					for (SObject so : genericQueryResults) {
						recordIdToRecordName.put((Id) so.get('Id'), ((String) so.get('Name')));
					}
				}
			}
		}
		return recordIdToRecordName;
	}

	/**
	 * Queried list of RecordType records. Kept as SObject in case the org does not use Task Record Types
	 */
	private static List<SObject> taskRecordTypes;
	/**
	 * Lazy load task record types to reduce queries
	 * <br>We use SObject so this works in orgs without Record Types for Tasks
	 * @return `List<SObject>` A list of all Task `RecordType` records
	 */
	private static List<SObject> getTaskRecordTypes() {
		if (taskRecordTypes == null) {
			String taskRTQuery = 'SELECT Id, IsActive, Name FROM RecordType WHERE SObjectType = \'Task\' AND IsActive = true ORDER BY Name ASC';
			taskRecordTypes = Database.query(taskRTQuery);
		}
		return taskRecordTypes;
	}

	/**
	 * Describe `Task.Status` only once
	 */
	private static String taskStatusDefaultValue = (String) Task.Status.getDescribe().getDefaultValue();
	/**
	 * Memoized map of `RecordTypeId` to default `Task Status`
	 */
	private static Map<Id, String> taskRecordTypeStatusDefaultValues;
	/**
	 * Generate Map of Record Type Id to default Task Status
	 * @return `Map<Id, String>` Default Status for each Task `RecordType` Id
	 */
	public static Map<Id, String> getTaskRecordTypeStatusDefaultValues() {
		if (taskRecordTypeStatusDefaultValues == null) {
			taskRecordTypeStatusDefaultValues = new Map<Id, String>();
			//System.debug('ActionPlansUtilities.taskUsesRecordTypes' + ActionPlansUtilities.taskUsesRecordTypes);
			if (ActionPlansUtilities.taskUsesRecordTypes) {
				for (SObject rt : getTaskRecordTypes()) {
					Task t = (Task) Task.sObjectType.newSObject((Id) rt.get('Id'), true);
					taskRecordTypeStatusDefaultValues.put((Id) rt.get('Id'), t.Status);
				}
			} else {
				taskRecordTypeStatusDefaultValues.put(null, taskStatusDefaultValue);
				taskRecordTypeStatusDefaultValues.put(MASTER_RECORD_TYPE_ID, taskStatusDefaultValue);
			}
		}
		taskRecordTypeStatusDefaultValues.put(null, taskStatusDefaultValue);
		taskRecordTypeStatusDefaultValues.put(MASTER_RECORD_TYPE_ID, taskStatusDefaultValue);
		return taskRecordTypeStatusDefaultValues;
	}

	/**
	 * Describe `Task.Type` only once
	 */
	private static String taskTypeDefaultValue = (String) Task.Type.getDescribe().getDefaultValue();
	/**
	 * Memoized map of `RecordTypeId` to default `Task Type`
	 */
	private static Map<Id, String> taskRecordTypeTypeDefaultValues;
	/**
	 * Generate Map of Record Type Id to default Task Type
	 * @return `Map<Id, String>` Map of `RecordTypeId` to default `Task Type`
	 */
	public static Map<Id, String> getTaskRecordTypeTypeDefaultValues() {
		if (taskRecordTypeTypeDefaultValues == null) {
			taskRecordTypeTypeDefaultValues = new Map<Id, String>();
			if (ActionPlansUtilities.taskUsesRecordTypes) {
				for (SObject rt : getTaskRecordTypes()) {
					Task t = (Task) Task.sObjectType.newSObject((Id) rt.get('Id'), true);
					taskRecordTypeTypeDefaultValues.put((Id) rt.get('Id'), t.Type);
				}
			} else {
				taskRecordTypeTypeDefaultValues.put(null, taskTypeDefaultValue);
				taskRecordTypeTypeDefaultValues.put(MASTER_RECORD_TYPE_ID, taskTypeDefaultValue);
			}
		}
		taskRecordTypeTypeDefaultValues.put(null, taskTypeDefaultValue);
		taskRecordTypeTypeDefaultValues.put(MASTER_RECORD_TYPE_ID, taskTypeDefaultValue);
		return taskRecordTypeTypeDefaultValues;
	}

	/**
	 * Describe `Task.Priority` only once
	 */
	private static String taskPriorityDefaultValue = (String) Task.Priority.getDescribe().getDefaultValue();
	/**
	 * Memoized map of `RecordTypeId` to default `Task Priority`
	 */
	private static Map<Id, String> taskRecordTypePriorityDefaultValues;
	/**
	 * Generate default Task Priority picklist
	 * @return `Map<Id, String>` Map of `RecordTypeId` to default `Task Priority`
	 */
	public static Map<Id, String> getTaskRecordTypePriorityDefaultValues() {
		if (taskRecordTypePriorityDefaultValues == null) {
			taskRecordTypePriorityDefaultValues = new Map<Id, String>();
			if (ActionPlansUtilities.taskUsesRecordTypes) {
				for (SObject rt : getTaskRecordTypes()) {
					Task t = (Task) Task.sObjectType.newSObject((Id) rt.get('Id'), true);
					taskRecordTypePriorityDefaultValues.put((Id) rt.get('Id'), t.Priority);
				}
			} else {
				//System.debug('Task does not use record types');
				taskRecordTypePriorityDefaultValues.put(null, taskPriorityDefaultValue);
				taskRecordTypePriorityDefaultValues.put(MASTER_RECORD_TYPE_ID, taskPriorityDefaultValue);
			}
		}
		taskRecordTypePriorityDefaultValues.put(null, taskPriorityDefaultValue);
		taskRecordTypePriorityDefaultValues.put(MASTER_RECORD_TYPE_ID, taskPriorityDefaultValue);

		return taskRecordTypePriorityDefaultValues;
	}

	/**
	 * Find user default `Task RecordType`
	 * @return `String` Default RecordType Id
	 */
	public static String getDefaultTaskRecordTypeId() {
		String toReturn = null;
		if (ActionPlansUtilities.taskUsesRecordTypes) {
			List<Schema.RecordTypeInfo> recordTypeInfoList = Task.SObjectType.getDescribe().getRecordTypeInfos();
			for (RecordTypeInfo info : recordTypeInfoList) {
				//Check default record type
				if (info.isDefaultRecordTypeMapping()) {
					toReturn = info.getRecordTypeId();
					break;
				}
			}
		}
		return toReturn;
	}

	/**
	 * Generate picklist of `Task RecordType`
	 * @return `List<SelectOption>` Visualforce Picklist
	 */
	public static List<SelectOption> getTaskRTPicklistValues() {
		if (taskRTs == null) {
			taskRTs = new List<SelectOption>();
			for (SObject rt : getTaskRecordTypes()) {
				SelectOption so = new SelectOption((String) rt.get('Id'), (String) rt.get('Name'), !(Boolean) rt.get('IsActive'));
				taskRTs.add(so);
			}
		}
		return taskRTs;
	}
	/**
	 * Memoized picklist of `Task` Record Types
	 */
	private static List<SelectOption> taskRTs;

	/**
	 * Lazy load open task statuses
	 * @return `Set<String>` All Open `Task Status` values
	 */
	public static Set<String> getOpenTaskStatuses() {
		if (openTaskStatuses == null) {
			openTaskStatuses = new Set<String>();
			for (TaskStatus ts : [SELECT IsClosed, MasterLabel FROM TaskStatus WHERE IsClosed = FALSE]) {
				openTaskStatuses.add(ts.MasterLabel);
			}
		}
		return openTaskStatuses;
	}
	/**
	 * Memoized open Task statuses
	 */
	private static Set<String> openTaskStatuses;

	/**
	 * Memoized closed Task statuses
	 */
	private static Set<String> closedTaskStatuses;
	/**
	 * Set of all `Task` Status values that are Closed
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return   `Set<String>` Set of closed `Task` Statuses
	 */
	public static Set<String> getClosedTaskStatuses() {
		if (closedTaskStatuses == null) {
			closedTaskStatuses = new Set<String>();
			for (TaskStatus ts : [SELECT IsClosed, MasterLabel FROM TaskStatus WHERE IsClosed = TRUE]) {
				closedTaskStatuses.add(ts.MasterLabel);
			}
		}
		return closedTaskStatuses;
	}

	/**
	 * For a given object/field, generate a Visualforce Picklist
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @param  objectname      Object Nams
	 * @param  fieldname       Field Name
	 * @param  requireValue    We can provide the option of not selecting the value by default
	 * @return                 `List<SelectOption>` Picklist for a field
	 */
	public static List<SelectOption> getFieldOptions(String objectname, String fieldname, Boolean requireValue) {
		if (requireValue == null) {
			requireValue = false;
		}
		List<SelectOption> toReturn = new List<SelectOption>();
		Schema.DescribeSObjectResult obj = Schema.getGlobalDescribe().get(objectname).getDescribe();
		Schema.SObjectField sof = obj.fields.getMap().get(fieldname);
		Boolean hasDefaultValue = false;
		for (Schema.PicklistEntry spe : sof.getDescribe().getPicklistValues()) {
			if (spe.isDefaultValue()) {
				hasDefaultValue = true;
			}
			toReturn.add(new Selectoption(spe.getValue(), spe.getLabel()));
		}
		if (hasDefaultValue == false && requireValue == false) {
			toReturn.add(0, new SelectOption('', '--' + System.Label.ap_None + '--'));
		}
		return toReturn;
	}

	/**
	 * Set the Hours for select box of Reminder Time
	 * @return `List<SelectOption>` Hours/time options
	 */
	public static List<SelectOption> getHoursOption() {
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('0', '12:00 AM'));
		options.add(new SelectOption('30', '12:30 AM'));
		options.add(new SelectOption('60', '1:00 AM'));
		options.add(new SelectOption('90', '1:30 AM'));
		options.add(new SelectOption('120', '2:00 AM'));
		options.add(new SelectOption('150', '2:30 AM'));
		options.add(new SelectOption('180', '3:00 AM'));
		options.add(new SelectOption('210', '3:30 AM'));
		options.add(new SelectOption('240', '4:00 AM'));
		options.add(new SelectOption('270', '4:30 AM'));
		options.add(new SelectOption('300', '5:00 AM'));
		options.add(new SelectOption('330', '5:30 AM'));
		options.add(new SelectOption('360', '6:00 AM'));
		options.add(new SelectOption('390', '6:30 AM'));
		options.add(new SelectOption('420', '7:00 AM'));
		options.add(new SelectOption('450', '7:30 AM'));
		options.add(new SelectOption('480', '8:00 AM'));
		options.add(new SelectOption('510', '8:30 AM'));
		options.add(new SelectOption('540', '9:00 AM'));
		options.add(new SelectOption('570', '9:30 AM'));
		options.add(new SelectOption('600', '10:00 AM'));
		options.add(new SelectOption('630', '10:30 AM'));
		options.add(new SelectOption('660', '11:00 AM'));
		options.add(new SelectOption('690', '11:30 AM'));
		options.add(new SelectOption('720', '12:00 PM'));
		options.add(new SelectOption('750', '12:30 PM'));
		options.add(new SelectOption('780', '1:00 PM'));
		options.add(new SelectOption('810', '1:30 PM'));
		options.add(new SelectOption('840', '2:00 PM'));
		options.add(new SelectOption('870', '2:30 PM'));
		options.add(new SelectOption('900', '3:00 PM'));
		options.add(new SelectOption('930', '3:30 PM'));
		options.add(new SelectOption('960', '4:00 PM'));
		options.add(new SelectOption('990', '4:30 PM'));
		options.add(new SelectOption('1020', '5:00 PM'));
		options.add(new SelectOption('1050', '5:30 PM'));
		options.add(new SelectOption('1080', '6:00 PM'));
		options.add(new SelectOption('1110', '6:30 PM'));
		options.add(new SelectOption('1140', '7:00 PM'));
		options.add(new SelectOption('1170', '7:30 PM'));
		options.add(new SelectOption('1200', '8:00 PM'));
		options.add(new SelectOption('1230', '8:30 PM'));
		options.add(new SelectOption('1260', '9:00 PM'));
		options.add(new SelectOption('1290', '9:30 PM'));
		options.add(new SelectOption('1320', '10:00 PM'));
		options.add(new SelectOption('1350', '10:30 PM'));
		options.add(new SelectOption('1380', '11:00 PM'));
		options.add(new SelectOption('1410', '11:30 PM'));

		return options;
	}

	/**
	 * Utility method to check if the page parameters contain a key, and then return the escaped value.
	 * <br>Used because PMD wants it, and because XSS is a serious problem
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @param  paramKey The page parameter key
	 * @return          `String` Escaped (single quotes escaped) value for that key, if present. Otherwise, null;
	 */
	public static String getEscapedPageParameter(String paramKey) {
		if (ApexPages.currentPage().getParameters().get(paramKey) != null) {
			String paramValue = ApexPages.currentPage().getParameters().get(paramKey);
			return String.escapeSingleQuotes(paramValue);
		}
		return null;
	}

	/**
	 * Does the user have permission to transfer? We query `UserRecordAccess`.
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @param recordId sample record Id that can be used to find user permission
	 * @return   `Boolean` yes/no
	 */
	public static Boolean getCanTransfer(Id recordId) {
		UserRecordAccess ura = [SELECT RecordId, HasTransferAccess, MaxAccessLevel FROM UserRecordAccess WHERE UserId = :UserInfo.getUserId() AND RecordId = :recordId LIMIT 1];
		return ura.HasTransferAccess;
	}

	/**
	 * We can get all the permissions and info required to see if the user can share the record
	 * <br>RecordOwner, has Full Access, has ModifyAllData
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @param  recordId        The recordId of the record in question
	 * @param  recordOwnerId   The owner Id because an owner can share even without "Modify all Data"
	 * @return                 `Boolean` Can the user share the record?
	 */
	public static Boolean canShareRecord(Id recordId, Id recordOwnerId) {
		try {
			UserRecordAccess ura = [SELECT RecordId, HasAllAccess FROM UserRecordAccess WHERE UserId = :UserInfo.getUserId() AND RecordId = :recordId];
			if (ura.HasAllAccess) {
				return true;
			}
		} catch (Exception e) {
			return false;
		}
		if (recordOwnerId == UserInfo.getUserId()) {
			return true;
		}

		//Share does not exist, custom object is public read write, or user lacks permissions
		return false;
	}

	/**
	 * Verifies that the user is able to add reminders.
	 * <br>Checks the existence of a reminder setting field of the user object.
	 * <br>Mathod can be improved by asking for Reminder Options at Activity settings.
	 * <br>Does not query if the user wants reminders by default.
	 * @return `Boolean` if the user has access to reminders
	 */
	public static Boolean getCanDisplayReminder() {
		if (canDisplayReminder == null) {
			canDisplayReminder = Schema.sObjectType.User.fields.getMap().containsKey('UserPreferencesTaskRemindersCheckboxDefault');
		}
		return canDisplayReminder;
	}
	private static Boolean canDisplayReminder;

	/**
	 * Check user preferences for whether to show task reminders by default
	 * @return `Boolean` if Task reminder checkbox should be checked by default (this will override default value)
	 */
	public static Boolean getCheckReminderByDefault() {
		if (checkReminderByDefault == null) {
			checkReminderByDefault = false;
			if (getCanDisplayReminder()) {
				User u = [SELECT Name, UserPreferencesTaskRemindersCheckboxDefault FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1]; //NOPMD
				checkReminderByDefault = u.UserPreferencesTaskRemindersCheckboxDefault;
			}
		}
		return checkReminderByDefault;
	}
	private static Boolean checkReminderByDefault;

	/**
	 * Gets task reminder default time for current user
	 * @return `String` picklist value for default minutes after midnight for reminder
	 */
	public static String getDefaultReminderMinutes() {
		if (defaultMinutesForReminderTime == null) {
			defaultMinutesForReminderTime = '480';

			List<UserPreference> uP = [SELECT Value FROM UserPreference WHERE UserId = :Userinfo.getUserId() AND Preference = '58'];
			if (!uP.isEmpty()) {
				defaultMinutesForReminderTime = uP[0].Value;
			}
		}
		return defaultMinutesForReminderTime;
	}
	private static String defaultMinutesForReminderTime;

	/**
	 * Memoized Action_Plans_Settings__c record (organization or instance)
	 */
	private static Action_Plans_Settings__c apSettings;
	/**
	 * Get the "Default" Custom Setting and return it.
	 * @return `Action_Plans_Settings__c` cSetting
	 */
	public static Action_Plans_Settings__c getCustomSetting() {
		if (apSettings != null) {
			return apSettings;
		}
		apSettings = Action_Plans_Settings__c.getOrgDefaults();
		if (apSettings.Id == null) {
			apSettings = checkOrgDefaultCustomSetting(false);
		} else {
			apSettings = Action_Plans_Settings__c.getInstance();
		}
		return apSettings;
	}

	/**
	 * Get the Default Custom Setting (Organization level) and insert if specified
	 * <br>We cannot insert in a Visualforce constructor, but we can in a page OnLoad action
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @param  insertIfNull `Boolean` Should we insert the Organization Custom Setting if there isn't one?
	 * @return              `Action_Plans_Settings__c` The Settings object
	 */
	public static Action_Plans_Settings__c checkOrgDefaultCustomSetting(Boolean insertIfNull) {
		apSettings = Action_Plans_Settings__c.getOrgDefaults();
		if (apSettings.Id == null) {
			Action_Plans_Settings__c apSettings = new Action_Plans_Settings__c(SetupOwnerId = UserInfo.getOrganizationId());
			apSettings.Action_Plans_Business_Hours_ID__c = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE][0].Id;
			apSettings.Default_Object_on_Lead_Conversion__c = 'Contact';
			apSettings.Unassigned_Task_Assigned_to_Owner__c = (Boolean) Action_Plans_Settings__c.Unassigned_Task_Assigned_to_Owner__c.getDescribe().getDefaultValue();
			apSettings.Chatter_Object_Brag__c = (Boolean) Action_Plans_Settings__c.Chatter_Object_Brag__c.getDescribe().getDefaultValue();
			if (insertIfNull && CanTheUser.ups(new Action_Plans_Settings__c())) {
				upsert apSettings; //NOPMD
			}
		}
		return apSettings;
	}

	/**
	 * Single method to shorten long strings to the hard-coded 80 character length of record name field
	 * @param subject the long string
	 * @return `String` the full string or shortened if longer than 80 characters
	 */
	public static String actionPlanSubjectToName(String subject) {
		return actionPlanSubjectToName(subject, 80);
	}

	/**
	 * Single method to shorten long strings to the dynamically described character length of record name field
	 * @param subject the long string
	 * @param maxChars the maximum length allowed for Action Plan Subject
	 * @return `String` the full string (or shortened if longer than max characters)
	 */
	public static String actionPlanSubjectToName(String subject, Integer maxChars) {
		if (String.isBlank(subject)) {
			return '';
		}
		if (subject.trim().length() > maxChars) {
			return subject.left(maxChars - 3).trim() + '...';
		} /* else if (subject.trim().length() < maxChars - 3) {
			return subject.left(maxChars - 3).trim() + ' - ';
		} */
		return subject;
	}

	/**
	 * Is the org allowed to send emails?
	 * <br>This could be because deliverability is off, or because we have hit the org limits for emails
	 * @return `Boolean` Can the org send an email?
	 */
	public static Boolean canSendEmails() {
		Boolean orgCanSendEmails;
		if (orgCanSendEmails == null) {
			// An attempt to reserve some email capacity is the only means available for determining permissions
			// or limits issues. In the case of a lack of permissions, System.NoAccessException is thrown. If
			// limits are exhausted then System.HandledException is thrown
			try {
				Messaging.reserveSingleEmailCapacity(1);
				orgCanSendEmails = true;
			} catch (Exception e) {
				orgCanSendEmails = false;
			}
		}
		return orgCanSendEmails;
	}

	/**
	 * Given a date, give the English day of the week
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @param  theDate The given date
	 * @return   `String` The day of hte week in English
	 */
	public static String getDayOfWeek(Date theDate) {
		Date monday = Date.newInstance(1900, 1, 1);
		Integer dayOfWeek = Math.mod(monday.daysBetween(theDate), 7);
		return dayOfWeekEnglish.get(dayOfWeek);
	}

	/**
	 * Map of day of week (as number) to English day
	 */
	private static Map<Integer, String> dayOfWeekEnglish = new Map<Integer, String>{
		0 => 'Monday',
		1 => 'Tuesday',
		2 => 'Wednesday',
		3 => 'Thursday',
		4 => 'Friday',
		5 => 'Saturday',
		6 => 'Sunday'
	};

	/**
	 * Get the Custom Metadata record for the weekend day
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @param  developerName English day (Saturday, Sunday, etc)
	 * @return               `Weekend_Day__mdt` Custom Metadata
	 */
	public static Weekend_Day__mdt getWeekendDay(String developerName) {
		return Weekend_Day__mdt.getInstance(developerName);
	}

	/**
	 * Given a task due date, we adjust it here for weekends
	 * @param actionPlanStartDate the start date of the action plan
	 * @param taskDaysFromStart the days after the initial date that the task will be due
	 * @param apSkipDay Start or End (determines how to handle weekend day)
	 * @return `Date` the new task due date
	 */
	public static Date adjustTaskDueDate(Date actionPlanStartDate, Integer taskDaysFromStart, String apSkipDay) {
		Date dueDate = actionPlanStartDate.addDays(taskDaysFromStart);

		// find if the due date fall on a Saturday or Sunday.  Add 1 day for Sunday and 2 for Saturday
		//Date refDate        = Date.newInstance(1900, 1, 7);  // Jan 7 1900 = Sun
		//Integer dayOfWeek   = Math.mod(refDate.daysBetween(dueDate), 7); // 0 = Sun ... 6 = Sat

		String dayName = ActionPlansUtilities.getDayOfWeek(dueDate);

		Weekend_Day__mdt cmdt = ActionPlansUtilities.getWeekendDay(dayName);

		Integer addDays = 0;

		if (apSkipDay != null && apSkipDay.startsWithIgnoreCase('End')) {
			Integer daysToAdjust = cmdt.Days_from_end_of_previous_week__c.intValue();
			addDays = addDays - daysToAdjust;
		} else if (apSkipDay != null && apSkipDay.startsWithIgnoreCase('Start')) {
			Integer daysToAdjust = cmdt.Days_to_start_of_next_week__c.intValue();
			addDays = addDays + daysToAdjust;
		}
		return dueDate.addDays(addDays);
	}

	/**
	 * Detect user theme - TRUE if we are in LEX
	 * @return `Boolean` Are we in Lightning Experience?
	 */
	public static Boolean getIsLex() {
		return (UserInfo.getUiThemeDisplayed().containsIgnoreCase('theme4'));
	}

	/**
	 *  Check if we are in a managed package - if so, return the namespace prefix
	 * @return `String` The namespace prefix (`LabsActionPlans`) if in managed package
	 */
	public static String namespacePrefix {
		get {
			if (namespacePrefix == null) {
				String[] parts = String.valueOf(ActionPlansUtilities.class).split('\\.', 2);
				namespacePrefix = parts.size() == 2 ? parts[0] + '__' : '';
			}
			return namespacePrefix;
		}
		set;
	}

	/**
	 * Basic utility method to avoid repeatedly casting Ids to Strings to test for startsWith (User vs Group)
	 * @author David Schach
	 * @param  idParam       The Id passed to the method
	 * @param  compareString The string we compare for the string's start
	 * @return               `Boolean` true/false
	 */
	public static Boolean idStartsWith(Id idParam, String compareString) {
		String idString = (String) idParam;
		return idString.startsWithIgnoreCase(compareString);
	}
}