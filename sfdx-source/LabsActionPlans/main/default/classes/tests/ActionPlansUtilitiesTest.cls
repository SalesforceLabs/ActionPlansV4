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
 * @author {@link [David Schach](https://github.com/dschach)}
 * @since 2022
 * @since 2023 System.assert to Assert class + error messages
 * @group Tests
 * @see ActionPlansUtilities
 */
@IsTest
private class ActionPlansUtilitiesTest {
	/**
	 * Set up custom settings
	 */
	@TestSetup
	private static void makeData() {
		Action_Plans_Settings__c aps = Action_Plans_Settings__c.getOrgDefaults();
		aps.Chatter_Object_Brag__c = true;
		aps.Unassigned_Task_Assigned_to_Owner__c = true;
		try {
			upsert aps;
		} catch (Exception e) {
			update aps;
		}
	}

	@IsTest
	private static void saveSingle() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		ActionPlan__c ap = testutil.createNewActionPlan('account', 0, null);

		User testUser = testutil.createTestUser();

		List<APTask__c> aptList = new List<APTask__c>();
		for (Integer i = 0; i < 3; i++) {
			//aptList.add(makeAppTask(ap));
			aptList.add(testutil.createNewActionPlanTask(ap, i + 1, testUser.Id, null, null));
		}
		insert aptList;

		Test.startTest();

		ApexPages.currentPage().getParameters().put('refType', 'Account');
		ApexPages.currentPage().getParameters().put('refId', ap.Account__c);

		ActionPlanCreationController apcc = new ActionPlanCreationController(new ApexPages.StandardController(ap));
		apcc.apTasks = aptList;

		Assert.isTrue(apcc.hasRelatedObject(), 'Should be a related object Account');

		apcc.save();

		ActionPlan__c rap = [SELECT Id FROM ActionPlan__c WHERE Id = :ap.Id];
		Assert.areNotEqual(null, rap, 'The Action Plan should exist');

		Test.stopTest();
	}

	@IsTest
	private static void saveMultiple() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		ActionPlan__c ap = testutil.createNewActionPlan('account', 0, null);

		User testUser = testutil.createTestUser();

		List<APTask__c> aptList = new List<APTask__c>();
		for (Integer i = 0; i < 3; i++) {
			//aptList.add(makeAppTask(ap));
			aptList.add(testutil.createNewActionPlanTask(ap, i + 1, testUser.Id, null, null));
		}
		insert aptList;

		Test.startTest();

		ap.SkipWeekends__c = true;
		ap.SkipDay__c = 'End of previous week';
		update ap;
		Test.setCurrentPage(Page.ActionPlanCreation);
		ApexPages.currentPage().getParameters().put('refType', 'Account');
		ApexPages.currentPage().getParameters().put('refId', ap.Account__c);
		ActionPlanCreationController apcc = new ActionPlanCreationController(new ApexPages.StandardController(ap));
		apcc.apTasks = aptList;
		apcc.saveMultipleAP();
		Test.stopTest();
		ActionPlan__c rap = [SELECT Id, Account__c FROM ActionPlan__c WHERE Id = :ap.Id];
		Assert.areEqual(rap.Account__c, ap.Account__c, 'Account Id on the Action Plan is incorrect');
	}

	@IsTest
	private static void account() {
		Assert.isTrue(testObject('Account', null), 'We did not create the test SObject correctly');
		Assert.areNotEqual(0, [SELECT COUNT() FROM ActionPlan__c], 'We should have an Action Plan');
		Test.startTest();
		delete [SELECT Id FROM Account];
		Test.stopTest();
		Assert.areEqual(0, [SELECT COUNT() FROM ActionPlan__c], 'Trigger should have deleted Action Plan with Account');
	}

	@IsTest
	private static void contact() {
		Assert.isTrue(testObject('Contact', null), 'We did not create the test SObject correctly');
		Assert.areNotEqual(0, [SELECT COUNT() FROM ActionPlan__c], 'We should have an Action Plan');
		Test.startTest();
		Account a = [SELECT Id FROM Account];
		delete a;
		Test.stopTest();
		Assert.areEqual(0, [SELECT COUNT() FROM ActionPlan__c], 'Trigger should have deleted Contact Action Plan with Account');
		undelete a;
		Assert.areEqual(1, [SELECT COUNT() FROM ActionPlan__c], 'Trigger should have undeleted Contact Action Plan with Account');
	}

	@IsTest
	private static void lead() {
		Assert.isTrue(testObject('Lead', null), 'We did not create the test SObject correctly');
	}

	@IsTest
	private static void case() {
		Assert.isTrue(testObject('Case', null), 'We did not create the test SObject correctly');
	}

	@IsTest
	private static void campaign() {
		Assert.isTrue(testObject('Campaign', null), 'We did not create the test SObject correctly');
	}

	@IsTest
	private static void contract() {
		Assert.isTrue(testObject('Contract', null), 'We did not create the test SObject correctly');
	}

	/**
	 * Pass in any object name (and its ID if a custom object) and create an Action Plan for that object
	 * <br>Will be global in the next version so test code for custom objects can access it
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @param  objectName The object name
	 * @param recordId Pass in the Id of a custom object record so we can make an Action Plan for it
	 * @return            Success at creating tasks for the Action Plan
	 */
	public static Boolean testObject(String objectName, Id recordId) {
		Test.setCurrentPage(Page.ActionPlanCreation);

		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apt = testutil.createNewActionPlanTemplate(5);

		ActionPlan__c ap = testutil.createNewActionPlan(objectName, 3, recordId);

		ApexPages.currentPage().getParameters().put('refType', objectName);
		ApexPages.currentPage().getParameters().put('templateId', null);

		ActionPlanCreationController apcc = new ActionPlanCreationController(new ApexPages.StandardController(ap));

		apcc.save();

		ApexPages.currentPage().getParameters().put('templateId', apt.Id);
		apcc = new ActionPlanCreationController(new ApexPages.StandardController(new ActionPlan__c()));
		apcc.apTasks = apcc.getAPTasks();

		apcc.save();

		Boolean hasAPTasks = !apcc.apTasks.isEmpty();

		return hasAPTasks;
	}

	@IsTest
	private static void cancel() {
		Test.startTest();

		Test.setCurrentPage(Page.ActionPlanCreation);

		ActionPlanCreationController apcc = new ActionPlanCreationController(new ApexPages.StandardController(new ActionPlan__c()));
		PageReference page = apcc.cancel();
		Assert.isTrue(page != null, 'Cancel page is null. Unexpected.');

		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();

		ActionPlan__c ap = testutil.createNewActionPlan('account', 0, null);
		ApexPages.currentPage().getParameters().put('refType', 'Account');
		ApexPages.currentPage().getParameters().put('refId', ap.Account__c + ',' + testutil.createNewAccount().id);
		apcc = new ActionPlanCreationController(new ApexPages.StandardController(new ActionPlan__c()));
		page = apcc.cancel();
		Assert.areNotEqual(null, page, 'Cancel should have returned us to a real page');

		testutil.createNewActionPlan('contact', 0, null);
		ApexPages.currentPage().getParameters().put('refType', 'Contact');
		ApexPages.currentPage().getParameters().put('refId', ap.Contact__c + ',' + testutil.createNewContact().id);
		apcc = new ActionPlanCreationController(new ApexPages.StandardController(new ActionPlan__c()));
		page = apcc.cancel();
		Assert.areNotEqual(null, page, 'Cancel should have returned us to a real page');

		testutil.createNewActionPlan('lead', 0, null);
		ApexPages.currentPage().getParameters().put('refType', 'Lead');
		ApexPages.currentPage().getParameters().put('refId', ap.Lead__c + ',' + testutil.createNewLead().id);
		apcc = new ActionPlanCreationController(new ApexPages.StandardController(new ActionPlan__c()));
		page = apcc.cancel();
		Assert.areNotEqual(null, page, 'Cancel should have returned us to a real page');

		testutil.createNewActionPlan('opportunity', 0, null);
		ApexPages.currentPage().getParameters().put('refType', 'Opportunity');
		ApexPages.currentPage().getParameters().put('refId', ap.Opportunity__c + ',' + testutil.createNewOpportunity().id);
		apcc = new ActionPlanCreationController(new ApexPages.StandardController(new ActionPlan__c()));
		page = apcc.cancel();
		Assert.areNotEqual(null, page, 'Cancel should have returned us to a real page');

		testutil.createNewActionPlan('contract', 0, null);
		ApexPages.currentPage().getParameters().put('refType', 'Contract');
		ApexPages.currentPage().getParameters().put('refId', ap.Contract__c);
		apcc = new ActionPlanCreationController(new ApexPages.StandardController(new ActionPlan__c()));
		page = apcc.cancel();
		Assert.areNotEqual(null, page, 'Cancel should have returned us to a real page');

		ActionPlanTemplate__c apt = testutil.createNewActionPlanTemplate(0);
		ApexPages.currentPage().getParameters().put('templateId', apt.Id);
		apcc = new ActionPlanCreationController(new ApexPages.StandardController(new ActionPlan__c()));
		page = apcc.cancel();
		Assert.areNotEqual(null, page, 'Cancel should have returned us to a real page');
		Test.stopTest();
	}

	@IsTest
	private static void relatedObjectId() {
		Test.startTest();

		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();

		ActionPlan__c ap = testutil.createNewActionPlan('account', 0, null);
		ActionPlanCreationController apcc = new ActionPlanCreationController(new ApexPages.StandardController(ap));
		Id recId = apcc.relatedObjectId();
		Assert.areEqual(ap.Account__c, recId, 'Related record Id did not populate correctly');

		ap = testutil.createNewActionPlan('contact', 0, null);
		apcc = new ActionPlanCreationController(new ApexPages.StandardController(ap));
		recId = apcc.relatedObjectId();
		Assert.areEqual(ap.Contact__c, recId, 'Related record Id did not populate correctly');

		ap = testutil.createNewActionPlan('lead', 0, null);
		apcc = new ActionPlanCreationController(new ApexPages.StandardController(ap));
		recId = apcc.relatedObjectId();
		Assert.areEqual(ap.Lead__c, recId, 'Related record Id did not populate correctly');

		ap = testutil.createNewActionPlan('opportunity', 0, null);
		apcc = new ActionPlanCreationController(new ApexPages.StandardController(ap));
		recId = apcc.relatedObjectId();
		Assert.areEqual(ap.Opportunity__c, recId, 'Related record Id did not populate correctly');
	}

	@IsTest
	private static void deleteActionPlans() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		System.runAs(new User(Id = UserInfo.getUserId())) {
			testutil.assignAPPermissionSets(UserInfo.getUserId(), false);
		}
		ActionPlan__c ap = testutil.createNewActionPlan('account', 0, null);
		ActionPlan__c ap2 = testutil.createNewActionPlan('account', 0, null);
		List<ActionPlan__c> lAp = new List<ActionPlan__c>();
		lAp.add(ap);
		lAp.add(ap2);
		String url = 'testURL';
		String records = ap.Id + ',' + ap2.id;

		Test.startTest();
		Test.setCurrentPage(Page.ActionPlanDetail);
		ActionPlanDetailController apdc = new ActionPlanDetailController(new ApexPages.StandardController(ap));
		ApexPages.currentPage().getParameters().put('retURL', url);
		ApexPages.currentPage().getParameters().put('records', records);
		PageReference page = apdc.deletePlan();
		Test.stopTest();

		List<ActionPlan__c> lAp2 = [SELECT Id FROM ActionPlan__c WHERE Id IN :lAp];
		Assert.isTrue(lAp2.size() == 1, 'We should have only one Action Plan referenced');
		if (!ActionPlansUtilities.getIsLex()) {
			Assert.areEqual(page.getUrl(), url, 'URL was not set to desired value: ' + url);
		}
	}

	/**
	 * A method to enable testing creating a Chatter post for any of our usual standard objects
	 *
	 * @param objectNames The object we want to make a post for
	 */
	private static void doChatterPost(List<String> objectNames) {
		Action_Plans_Settings__c aps = Action_Plans_Settings__c.getInstance();
		if (!aps.Chatter_Object_Brag__c) {
			aps.Chatter_Object_Brag__c = true;
			update aps;
		}
		Assert.isTrue(aps.Chatter_Object_Brag__c, 'Failed to set up custom setting correctly');

		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();

		ActionPlanTemplate__c apt = testutil.createNewActionPlanTemplate(5);
		for (APTemplateTask__c aptt : apt.aptTasks__r) {
			aptt.User__c = null;
		}
		update apt.aptTasks__r; //NOPMD

		apt.TaskRecordTypeID__c = ActionPlansTestUtilities.getNonDefaultAvailableTaskRecordType();
		apt.SkipWeekends__c = true;
		apt.SkipDay__c = 'End of previous week';

		update apt; //NOPMD

		Test.startTest();
		for (String k : objectNames) {
			Test.setCurrentPage(Page.ActionPlanCreation);
			switch on k {
				when 'account' {
					Account a = testutil.createNewAccount();
					ApexPages.currentPage().getParameters().put('refId', a.Id);
				}
				when 'lead' {
					Lead c = testutil.createNewLead();
					ApexPages.currentPage().getParameters().put('refId', c.Id);
				}
				when 'contract' {
					Contract c = testutil.createNewContract();
					ApexPages.currentPage().getParameters().put('refId', c.Id);
				}
				when 'campaign' {
					Campaign c = testutil.createNewCampaign();
					ApexPages.currentPage().getParameters().put('refId', c.Id);
				}
				when 'opportunity' {
					Opportunity c = testutil.createNewOpportunity();
					ApexPages.currentPage().getParameters().put('refId', c.Id);
				}
				when 'contact' {
					Contact c = testutil.createNewContact();
					ApexPages.currentPage().getParameters().put('refId', c.Id);
				}
				when 'case' {
					Case c = testutil.createNewCase();
					ApexPages.currentPage().getParameters().put('refId', c.Id);
				}
			}

			ApexPages.currentPage().getParameters().put('id', null);

			ApexPages.currentPage().getParameters().put('templateId', apt.Id);
			ActionPlanCreationController apcc = new ActionPlanCreationController(new Apexpages.StandardController(new ActionPlan__c()));
			apcc.refreshRelatedObjectsLookUp();

			apcc.actionPlan.SkipWeekends__c = true;
			apcc.actionPlan.SkipDay__c = 'End of previous week';
			apcc.getTasks();

			Assert.isFalse(apcc.getTasks().isEmpty(), 'Failed to generate our APTaskWrapper records');

			apcc.save();
		}

		Test.stopTest();
	}

	@IsTest
	private static void doChatterPostPart1() {
		List<String> objectNames = new List<String>{ 'account', 'lead', 'contact' };
		doChatterPost(objectNames);
		System.debug([SELECT Id, Account__c, Lead__c, Contact__c, Action_Plan_Template__r.Name FROM ActionPlan__c]);
		Assert.areEqual(objectNames.size(), [SELECT COUNT() FROM ActionPlan__c], 'Failed to make one Action Plan per SObject');
	}

	@IsTest
	private static void doChatterPostPart2() {
		List<String> objectNames = new List<String>{ 'contract', 'case', 'campaign', 'opportunity' };
		doChatterPost(objectNames);
		Assert.areEqual(objectNames.size(), [SELECT COUNT() FROM ActionPlan__c], 'Failed to make one Action Plan per SObject');
	}

	@IsTest
	private static void randomWord() {
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		Assert.areNotEqual(testUtil.createRandomWord('testword'), testUtil.createRandomWord(), 'We cannot ensure randomness. This is a problem.');
	}

	@IsTest
	private static void utilitiesRecordTypes() {
		if (ActionPlansUtilities.taskUsesRecordTypes) {
			if (ActionPlansTestUtilities.getNonDefaultAvailableTaskRecordType() != null) {
				String taskQuery = 'SELECT Id, RecordTypeId FROM Task';

				for (SObject t : Database.query(taskQuery)) {
					System.debug([SELECT Id, Name FROM RecordType WHERE Id = :(Id) t.get('RecordTypeId')].Name); //NOPMD
					Assert.areNotEqual(ActionPlansUtilities.getDefaultTaskRecordTypeId(), t.get('RecordTypeId'), 'Record Type is default');
				}
			}
			Assert.isFalse(ActionPlansUtilities.getTaskRTPicklistValues().isEmpty(), 'We didn\'t collect all Record Types!');
		} else {
			Assert.isTrue(ActionPlansUtilities.getTaskRTPicklistValues().isEmpty(), 'Why did we collect a Record Type for an object that does not use them?');
		}
	}

	/**
	 * Helper method to create `APTask__c` record for an `ActionPlan__c`
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @param  ap The parent Action Plan
	 * @return    The test Action Plan Task
	 */
	private static APTask__c makeAppTask(ActionPlan__c ap) {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		APTask__c at = new APTask__c();
		at.Action_Plan__c = ap.Id;
		at.Dependent__c = 'None';
		at.DaysFromStart__c = 2.0;
		at.User__c = testutil.createTestUser().Id;
		at.SendEmail__c = false;
		at.Subject__c = 'Test ';
		at.Type__c = 'Email';
		at.Priority__c = 'Low';
		at.Comments__c = 'Test';
		at.Reminder__c = true;
		at.Minutes_Reminder__c = '510';
		return at;
	}
}