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
 * Utilities for Tests
 * @author {@link [David Schach](https://github.com/dschach)}
 * @since 2022
 * @group Utilities
 */
public inherited sharing class ActionPlansTestUtilities {
	/**
	 * Used in testing - we force an Error during tests
	 */
	public static Boolean forceError = false;

	/**
	 * Used during testing to "fool" the org into thinking that it has Task record types
	 */
	public static Boolean forceHasRecordType;

	/**
	 * Standard objects included in this package
	 */
	@TestVisible
	private static Set<String> standardObjects = new Set<String>{ 'account', 'lead', 'contact', 'contract', 'case', 'campaign', 'opportunity' };

	/**
	 * Random words are required for testing, as you will likely run into any word I can insert
	 * during a test class and produce false test results.
	 * @return A random word
	 */
	public String createRandomWord() {
		return createRandomWord('apword');
	}
	/**
	 * Make a random `String` with a specific prefix and a random `Integer`
	 * @param  prefix The prefix
	 * @return       `String` The random word
	 * @example
	 * createRandomWord('test');
	 * test123456
	 */
	public String createRandomWord(String prefix) {
		String ret = prefix + math.rint(math.random() * 10000000);
		return ret;
	}

	/**
	 * A random user is useful for testing in order to be sure that you are able to see data across posts regardless of follow status.
	 * <br>If we find a profile, INSERT the user and return it.
	 * <br>If we find no profile, return null;
	 * <br> A Permission Set would still be required
	 * @return `User` A newly-created User with Modify All Data
	 */
	public User createTestUser() {
		for (Profile p : [SELECT Id, PermissionsModifyAllData, Name FROM Profile WHERE PermissionsModifyAllData = TRUE AND UserType = 'Standard' LIMIT 1]) {
			if (p.PermissionsModifyAllData) {
				return this.createTestUser(p);
			}
		}
		return null;
	}

	/**
	 * Creates a new User with a specific profile
	 * @param p Profile (not the Id)
	 * @return `User` Testuser
	 */
	public User createTestUser(Profile p) {
		String namePrefix = this.createRandomWord('un');

		User testUser = new User();
		testUser.Email = 'test@aptest.com';
		testUser.Username = namePrefix + 'test@Testuser.com';
		testUser.LastName = 'test';
		testUser.Alias = 'test';
		testUser.ProfileId = p.Id;
		testUser.LanguageLocaleKey = 'en_US';
		testUser.LocaleSidKey = 'en_US';
		testUser.TimeZoneSidKey = 'America/Chicago';
		testUser.EmailEncodingKey = 'UTF-8';

		insert testUser;
		return testUser;
	}

	/**
	 * Create an ActionPlans Admin user, plus all other permissions, for full ability to access certain tests.
	 * @return `User` an admin user with all Action Plans permission sets
	 * @see ActionPlansTestUtilities.createTestUser
	 * @see ActionPlansTestUtilities.assignAPPermissionSets
	 **/
	public User createAdminUser() {
		User u = createTestUser();
		assignAPPermissionSets(u.Id, true);
		return u;
	}

	/**
	 * Assign a permissionSet to a user (via UserId)
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @param  testUserId The User ID
	 * @param  allOrNone  Insert allOrNone, or allow an insert of only successful assingments, failing silently
	 * @return            `List<PermissionSetAssignment>` The list of `PermissionSetAssignment` records
	 */
	public List<PermissionSetAssignment> assignAPPermissionSets(Id testUserId, Boolean allOrNone) {
		System.debug('Namespace: ' + ActionPlansUtilities.namespacePrefix);
		List<PermissionSet> pslist = [SELECT Id, Label FROM PermissionSet WHERE Name LIKE '%Action_Plans%'];
		List<PermissionSetAssignment> psalist = new List<PermissionSetAssignment>();
		for (PermissionSet ps : pslist) {
			System.debug('Adding Permission Set ' + ps.Label);
			psalist.add(new PermissionSetAssignment(AssigneeId = testUserId, PermissionSetId = ps.Id));
		}
		Database.insert(psalist, allOrNone);

		return psalist;
	}

	/**
	 * Creates a new Account SObject With option to insert or just return the record
	 * @param insertRecord Insert the record before returning it?
	 * @return new `Account`
	 */
	public Account createNewAccount(Boolean insertRecord) {
		Account newAccount = new Account();
		newAccount.Name = this.createRandomWord('AcctName');
		if (insertRecord) {
			insert newAccount;
		}

		return newAccount;
	}

	/**
	 * Creates a new Account SObject
	 * <br>Inserts before returning
	 * @return inserted `Account`
	 */
	public Account createNewAccount() {
		return createNewAccount(true);
	}

	/**
	 * Creates a new Campaign SObject
	 * @param insertRecord Insert the record before returning it?
	 * @return new `Campaign`
	 * @see ActionPlansTestUtilities.createNewCampaign[1]
	 */
	public Campaign createNewCampaign(Boolean insertRecord) {
		Campaign newCampaign = new Campaign();
		newCampaign.Name = this.createRandomWord();

		if (insertRecord) {
			insert newCampaign;
		}
		return newCampaign;
	}

	/**
	 * Creates a new Campaign SObject
	 * Inserts before returning
	 * @return inserted `Campaign`
	 * @see ActionPlansTestUtilities.createNewCampaign[0]
	 */
	public Campaign createNewCampaign() {
		return createNewCampaign(true);
	}

	/**
	 * Creates a new Case SObject
	 * @param insertRecord Insert the record before returning it?
	 * @return new `Case`
	 */
	public Case createNewCase(Boolean insertRecord) {
		Case newCase = new Case();
		newCase.Status = (String) Case.Status.getDescribe().getDefaultValue();
		newCase.Origin = 'Email';

		if (insertRecord) {
			insert newCase;
		}
		return newCase;
	}

	/**
	 * Creates a new Case Object
	 * Inserts before returning
	 * @return inserted `Case`
	 */
	public Case createNewCase() {
		return createNewCase(true);
	}

	/**
	 * Creates a new Contact Object
	 * @param insertRecord Insert the record before returning it?
	 * @return new `Contact`
	 */
	public Contact createNewContact(Boolean insertRecord) {
		Contact newContact = new Contact();
		newContact.LastName = this.createRandomWord();

		if (insertRecord) {
			insert newContact;
		}
		return newContact;
	}

	/**
	 * Creates a new Contact Object
	 * Inserts before returning
	 * @return inserted `Contact`
	 */
	public Contact createNewContact() {
		return createNewContact(true);
	}

	/**
	 * Creates a new Contract Object
	 * @param insertRecord Insert the record before returning it?
	 * @return inserted `Contract`
	 */
	public Contract createNewContract(Boolean insertRecord) {
		Contract newContract = new Contract();
		Account a = this.createNewAccount();
		newContract.AccountId = a.Id;
		newContract.StartDate = Date.today();
		newContract.ContractTerm = 1;

		if (insertRecord) {
			insert newContract;
		}
		return newContract;
	}
	/**
	 * Creates a new Contract Object
	 * Inserts before returning
	 * @return inserted `Contract`
	 */
	public Contract createNewContract() {
		return createNewContract(true);
	}

	/**
	 * Creates a new Lead Object
	 * @param insertRecord Insert the record before returning it?
	 * @return new `Lead`
	 */
	public Lead createNewLead(Boolean insertRecord) {
		Lead newLead = new Lead();
		newLead.LastName = this.createRandomWord('ln');
		newLead.Company = this.createRandomWord('company');
		//newLead.Status		= 'Open - Not Contacted';
		//newLead.Status = [SELECT ApiName, Id, IsDefault, MasterLabel, SortOrder FROM LeadStatus WHERE IsDefault = true LIMIT 1].MasterLabel;

		if (insertRecord) {
			insert newLead;
		}
		return newLead;
	}

	/**
	 * Creates a new Lead Object
	 * Inserts before returning
	 * @return inserted `Lead`
	 */
	public Lead createNewLead() {
		return createNewLead(true);
	}

	/**
	 * Creates a new Opportunity Object
	 * @param insertRecord Insert the record before returning it?
	 * @return new `Opportunity`
	 * @see ActionPlansTestUtilities.createNewOpportunity[1]
	 */
	public Opportunity createNewOpportunity(Boolean insertRecord) {
		Opportunity newOpportunity = (Opportunity) Opportunity.sObjectType.newSObject(null, true);
		newOpportunity.Name = this.createRandomWord();
		newOpportunity.CloseDate = Date.today();
		newOpportunity.StageName = (String) Opportunity.StageName.getDescribe().getPicklistValues()[0].getValue();

		if (insertRecord) {
			insert newOpportunity;
		}
		return newOpportunity;
	}

	/**
	 * Creates a new Opportunity Object
	 * Inserts before returning
	 * @return inserted `Opportunity`
	 * @see ActionPlansTestUtilities.createNewOpportunity[0]
	 */
	public Opportunity createNewOpportunity() {
		return createNewOpportunity(true);
	}

	/**
	 * Create Action Plan and APTaskss
	 * @param relatedObject The Related Object (included field) for the Action Plan
	 * @param numTasks How many tasks to create for the ActionPlan
	 * @return new `ActionPlan__c`
	 * @see ActionPlansTestUtilities.createNewActionPlanTask
	 */
	public ActionPlan__c createNewActionPlan(String relatedObject, Integer numTasks) {
		ActionPlan__c newActionPlan = new ActionPlan__c();
		newActionPlan.Name = this.createRandomWord('APName');
		newActionPlan.StartDate__c = Date.today();
		newActionPlan.OwnerId = Userinfo.getUserId();
		String objectLowerCase = relatedObject?.toLowerCase();
		switch on objectLowerCase {
			when 'account' {
				newActionPlan.Account__c = this.createNewAccount().Id;
			}
			when 'campaign' {
				newActionPlan.Campaign__c = this.createNewCampaign().Id;
			}
			when 'case' {
				newActionPlan.Case__c = this.createNewCase().Id;
			}
			when 'contact' {
				Account a = this.createNewAccount();
				Contact c = this.createNewContact(false);
				c.AccountId = a.Id;
				insert c;
				newActionPlan.Contact__c = c.Id;
			}
			when 'contract' {
				newActionPlan.Contract__c = this.createNewContract().Id;
			}
			when 'lead' {
				newActionPlan.Lead__c = this.createNewLead().Id;
			}
			when 'opportunity' {
				newActionPlan.Opportunity__c = this.createNewOpportunity().Id;
			}
		}

		insert newActionPlan;

		User user = this.createTestUser();

		List<APTask__c> apttToInsert = new List<APTask__c>();
		//Creates default tasks for Action Plan
		for (Integer i = 0; i < numTasks; i++) {
			APTask__c apt = createNewActionPlanTask(newActionPlan, i + 1, user.Id, null, null);
			System.debug(apt);
			apttToInsert.add(apt);
		}

		insert apttToInsert;

		return newActionPlan;
	}

	/**
	 * Create Action Plan Task
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @param  actionPlan The `ActionPlan__c` object
	 * @param  days       Days from actionPlan Start Date to schedule the task
	 * @param  userId     The assigned owner Id
	 * @param  category   Task Type
	 * @param  priority   Task Priority
	 * @return            `APTask__c` The created `APTask__c` record
	 */
	public APTask__c createNewActionPlanTask(ActionPlan__c actionPlan, Integer days, Id userId, String category, String priority) {
		APTask__c newAPTask = new APTask__c();
		newAPTask.Subject__c = this.createRandomWord('subject');
		newAPTask.DaysFromStart__c = days == null || days < 0 ? 0 : days;
		newAPTask.Action_Plan__c = actionPlan.Id;
		newAPTask.User__c = userId;
		Id defaultRTID = ActionPlansUtilities.getDefaultTaskRecordTypeId();
		System.debug('ActionPlansTestUtilties: defaultRTID ' + defaultRTID);
		System.debug('RTStatusMap: ' + ActionPlansUtilities.getTaskRecordTypeStatusDefaultValues());
		newAPTask.Status__c = ActionPlansUtilities.getTaskRecordTypeStatusDefaultValues().get(defaultRTID);
		newAPTask.Type__c = String.isNotBlank(category) ? category : ActionPlansUtilities.getTaskRecordTypeTypeDefaultValues().get(defaultRTID);
		newAPTask.Priority__c = String.isNotBlank(priority) ? priority : ActionPlansUtilities.getTaskRecordTypePriorityDefaultValues().get(defaultRTID);
		newAPTask.Minutes_Reminder__c = '510';
		newAPTask.TaskIndex__c = days == null || days < 0 ? 0 : days + 1;
		newAPTask.Dependent__c = 'None';
		return newAPTask;
	}

	/**
	 * Create Action Plan Template and Action Plan Template Tasks
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @param  numTasks Number of tasks to create
	 * @return          `ActionPlanTemplate__c` Action Plan Template
	 * @see ActionPlansTestUtilities.createNewActionPlanTemplateTask
	 */
	public ActionPlanTemplate__c createNewActionPlanTemplate(Integer numTasks) {
		if (numTasks < 0) {
			numTasks = 0;
		}

		ActionPlanTemplate__c apTemplate = new ActionPlanTemplate__c();
		apTemplate.Name = this.createRandomWord();
		apTemplate.SkipWeekends__c = true;
		apTemplate.SkipDay__c = 'End of previous week';

		insert apTemplate;

		List<APTemplateTask__c> auxTasks = new List<APTemplateTask__c>();
		//Creates default tasks for Action Plan
		for (Integer i = 0; i < numTasks; i++) {
			APTemplateTask__c a = this.createNewActionPlanTemplateTask(apTemplate, i + 1, null, 'Email', 'High');
			a.TaskIndex__c = i;
			auxTasks.add(a);
		}

		insert auxTasks;

		return apTemplate;
	}

	/**
	 * Create Action Plan Template Task
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @param  apTemplate The parent ActionPlanTemplate__c object
	 * @param  days       Days from now to start Action Plan
	 * @param  userId     The assigned user for each created task
	 * @param  category   Task Category
	 * @param  priority   Task Priority
	 * @return            `APTemplateTask__c` The new Action Plan Template Task Template
	 */
	public APTemplateTask__c createNewActionPlanTemplateTask(ActionPlanTemplate__c apTemplate, Integer days, Id userId, String category, String priority) {
		APTemplateTask__c newAPTTask = new APTemplateTask__c();
		newAPTTask.Action_Plan_Template__c = apTemplate.Id;
		newAPTTask.Subject__c = this.createRandomWord('subject');
		newAPTTask.DaysFromStart__c = days;
		newAPTTask.TaskIndex__c = days - 1;
		newAPTTask.Dependent__c = 'None';
		newAPTTask.User__c = userId;
		Id defaultRTID = ActionPlansUtilities.getDefaultTaskRecordTypeId();
		newAPTTask.Type__c = String.isNotBlank(category) ? category : ActionPlansUtilities.getTaskRecordTypeTypeDefaultValues().get(defaultRTID);
		newAPTTask.Priority__c = String.isNotBlank(priority) ? priority : ActionPlansUtilities.getTaskRecordTypePriorityDefaultValues().get(defaultRTID);
		newAPTTask.Minutes_Reminder__c = '510';
		newAPTTask.Comments__c = 'Comment here';

		return newAPTTask;
	}

	/**
	 * Find a non-default Task Record Type
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @return   `Id` The `Id` of a non-default `Task` Record Type for the running user
	 */
	@testVisible
	private static Id getNonDefaultAvailableTaskRecordType() {
		if (!ActionPlansUtilities.taskUsesRecordTypes) {
			return null;
		}
		List<Schema.RecordTypeInfo> recordTypeInfoList = Task.SObjectType.getDescribe().getRecordTypeInfos();
		Id defaultRecordTypeId = null;
		Id notdefaultRecordTypeId = null;
		for (RecordTypeInfo info : recordTypeInfoList) {
			//Check default record type
			if (!info.isDefaultRecordTypeMapping() && info.isAvailable() && info.getRecordTypeId() != ActionPlansUtilities.MASTER_RECORD_TYPE_ID) {
				notdefaultRecordTypeId = info.getRecordTypeId();
			} else if (info.isDefaultRecordTypeMapping()) {
				defaultRecordTypeId = info.getRecordTypeId();
			}
		}
		return notdefaultRecordTypeId;
	}

	/**
	 * Retrieves number of completed tasks (that have an activity date)
	 * @param actionPlanId Id of Action Plan so we can query closed/completed Tasks
	 * @return `Integer` Count of completed tasks for this Action Plan
	 */
	@testVisible
	private static Integer getCompleted(Id actionPlanId) {
		if (actionPlanId == null) {
			return 0;
		}
		return [SELECT COUNT() FROM APTask__c WHERE Status__c IN :ActionPlansUtilities.getClosedTaskStatuses() AND ActivityDate__c != NULL AND Action_Plan__c = :actionPlanId];
	}
}