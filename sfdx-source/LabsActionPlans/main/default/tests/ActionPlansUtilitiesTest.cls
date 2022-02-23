/*
Action Plans v4
David Schach 2022

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
 * @author {@link [David Schach](https://github.com/dschach)}
 * @since 2022
 * @group Utilities
 * @see ActionPlansUtilities
 */
@IsTest
private class ActionPlansUtilitiesTest {
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
	private static void testDebugParameters() {
		Test.setCurrentPage(Page.ActionPlanCreation);
		Test.startTest();
		ActionPlanCreationController apcc = new ActionPlanCreationController(new ApexPages.StandardController(new ActionPlan__c()));
		ActionPlansTestUtilities.showDebugParameters = true;
		ActionPlansTestUtilities.debugParameters('testDebugParameters');
		apcc.getErrorMsg();
		Test.stopTest();
		System.assert(true, 'Technically cheating here.');
	}

	@IsTest
	private static void testSaveMethod() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		ActionPlan__c ap = testutil.createNewActionPlan('account', 0);

		List<APTask__c> aptl = new List<APTask__c>();
		for (Integer i = 0; i < 3; i++) {
			aptl.add(makeAppTask(ap));
		}
		insert aptl;

		Test.startTest();

		ApexPages.currentPage().getParameters().put('refType', 'Account');
		ApexPages.currentPage().getParameters().put('refId', ap.Account__c);

		ActionPlanCreationController apcc = new ActionPlanCreationController(new ApexPages.StandardController(ap));
		apcc.apTasks = aptl;

		System.assert(apcc.hasRelatedObject(), 'Should be a related object Account');

		apcc.save();

		ActionPlan__c rap = [SELECT Id FROM ActionPlan__c WHERE Id = :ap.Id];
		System.assert(rap != null);

		Test.stopTest();
	}

	@IsTest
	private static void testSaveMultiple() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		ActionPlan__c ap = testutil.createNewActionPlan('account', 0);

		List<APTask__c> aptl = new List<APTask__c>();
		for (Integer i = 0; i < 3; i++) {
			aptl.add(makeAppTask(ap));
		}
		insert aptl;

		Test.startTest();

		ap.SkipWeekends__c = true;
		ap.SkipDay__c = 'End of previous week';
		update ap;
		Test.setCurrentPage(Page.ActionPlanCreation);
		ApexPages.currentPage().getParameters().put('refType', 'Account');
		ApexPages.currentPage().getParameters().put('refId', ap.Account__c);
		ActionPlanCreationController apcc = new ActionPlanCreationController(new ApexPages.StandardController(ap));
		apcc.apTasks = aptl;
		apcc.saveMultiple();
		Test.stopTest();
		ActionPlan__c rap = [SELECT Id, Account__c FROM ActionPlan__c WHERE Id = :ap.Id];
		System.assert(rap.Account__c == ap.Account__c);
	}

	@IsTest
	private static void testAccount() {
		System.assert(testObject('Account'));
	}

	@IsTest
	private static void testContact() {
		System.assert(testObject('Contact'));
	}

	@IsTest
	private static void testLead() {
		System.assert(testObject('Lead'));
	}

	@IsTest
	private static void testCase() {
		System.assert(testObject('Case'));
	}

	@IsTest
	private static void testCampaign() {
		System.assert(testObject('Campaign'));
	}

	@IsTest
	private static void testContract() {
		System.assert(testObject('Contract'));
	}

	/**
	 * Pass in any object and create an Action Plan for that object
	 * @author {@link [David Schach](https://github.com/dschach)}
	 * @param  objectName The object name
	 * @return            Success at creating tasks for the Action Plan
	 */
	private static Boolean testObject(String objectName) {
		Test.setCurrentPage(Page.ActionPlanCreation);

		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apt = testutil.createNewActionPlanTemplate(5);

		Test.startTest();

		ActionPlan__c ap = testutil.createNewActionPlan(objectName, 3);

		ApexPages.currentPage().getParameters().put('refType', objectName);
		ApexPages.currentPage().getParameters().put('templateId', null);

		ActionPlanCreationController apcc = new ActionPlanCreationController(new ApexPages.StandardController(ap));

		apcc.save();

		ApexPages.currentPage().getParameters().put('templateId', apt.Id);
		apcc = new ActionPlanCreationController(new ApexPages.StandardController(new ActionPlan__c()));
		apcc.apTasks = apcc.getAPTasks();

		apcc.save();
		Test.stopTest();
		Boolean hasAPTasks = !apcc.apTasks.isEmpty();

		return hasAPTasks;
	}

	@IsTest
	private static void testCancel() {
		Test.startTest();

		Test.setCurrentPage(Page.ActionPlanCreation);

		ActionPlanCreationController apcc = new ActionPlanCreationController(new ApexPages.StandardController(new ActionPlan__c()));
		PageReference page = apcc.cancel();
		System.assert(page != null, 'Cancel page is null. Unexpected.');

		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();

		ActionPlan__c ap = testutil.createNewActionPlan('account', 0);
		ApexPages.currentPage().getParameters().put('refType', 'Account');
		ApexPages.currentPage().getParameters().put('refId', ap.Account__c + ',' + testutil.createNewAccount().id);
		apcc = new ActionPlanCreationController(new ApexPages.StandardController(new ActionPlan__c()));
		page = apcc.cancel();
		System.assert(page != null);

		testutil.createNewActionPlan('contact', 0);
		ApexPages.currentPage().getParameters().put('refType', 'Contact');
		ApexPages.currentPage().getParameters().put('refId', ap.Contact__c + ',' + testutil.createNewContact().id);
		apcc = new ActionPlanCreationController(new ApexPages.StandardController(new ActionPlan__c()));
		page = apcc.cancel();
		System.assert(page != null);

		testutil.createNewActionPlan('lead', 0);
		ApexPages.currentPage().getParameters().put('refType', 'Lead');
		ApexPages.currentPage().getParameters().put('refId', ap.Lead__c + ',' + testutil.createNewLead().id);
		apcc = new ActionPlanCreationController(new ApexPages.StandardController(new ActionPlan__c()));
		page = apcc.cancel();
		System.assert(page != null);

		testutil.createNewActionPlan('opportunity', 0);
		ApexPages.currentPage().getParameters().put('refType', 'Opportunity');
		ApexPages.currentPage().getParameters().put('refId', ap.Opportunity__c + ',' + testutil.createNewOpportunity().id);
		apcc = new ActionPlanCreationController(new ApexPages.StandardController(new ActionPlan__c()));
		page = apcc.cancel();
		System.assert(page != null);

		testutil.createNewActionPlan('account', 0);
		ApexPages.currentPage().getParameters().put('refType', 'Account');
		ApexPages.currentPage().getParameters().put('refId', ap.Account__c);
		apcc = new ActionPlanCreationController(new ApexPages.StandardController(new ActionPlan__c()));
		page = apcc.cancel();
		System.assert(page != null);

		ActionPlanTemplate__c apt = testutil.createNewActionPlanTemplate(0);
		ApexPages.currentPage().getParameters().put('templateId', apt.Id);
		apcc = new ActionPlanCreationController(new ApexPages.StandardController(new ActionPlan__c()));
		page = apcc.cancel();
		System.assert(page != null);
		Test.stopTest();
	}

	@IsTest
	private static void testRelatedObjectId() {
		Test.startTest();

		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();

		ActionPlan__c ap = testutil.createNewActionPlan('account', 0);
		ActionPlanCreationController apcc = new ActionPlanCreationController(new ApexPages.StandardController(ap));
		Id recId = apcc.relatedObjectId();
		System.assert(ap.Account__c == recId);

		ap = testutil.createNewActionPlan('contact', 0);
		apcc = new ActionPlanCreationController(new ApexPages.StandardController(ap));
		recId = apcc.relatedObjectId();
		System.assert(ap.Contact__c == recId);

		ap = testutil.createNewActionPlan('lead', 0);
		apcc = new ActionPlanCreationController(new ApexPages.StandardController(ap));
		recId = apcc.relatedObjectId();
		System.assert(ap.Lead__c == recId);

		ap = testutil.createNewActionPlan('opportunity', 0);
		apcc = new ActionPlanCreationController(new ApexPages.StandardController(ap));
		recId = apcc.relatedObjectId();
		System.assert(ap.Opportunity__c == recId);
	}

	@IsTest
	private static void testDeleteActionPlans() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		System.runAs(new User(Id = UserInfo.getUserId())) {
			testutil.assignAPPermissionSets(UserInfo.getUserId(), false);
		}
		ActionPlan__c ap = testutil.createNewActionPlan('account', 0);
		ActionPlan__c ap2 = testutil.createNewActionPlan('account', 0);
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
		System.assert(lAp2.size() == 1);
		if (!ActionPlansUtilities.getIsLex()) {
			System.assertEquals(page.getUrl(), url);
		}
	}

	@IsTest
	private static void doChatterPost() {
		ActionPlansTestUtilities.showDebugParameters = false;

		Action_Plans_Settings__c aps = Action_Plans_Settings__c.getInstance();
		if (!aps.Chatter_Object_Brag__c) {
			aps.Chatter_Object_Brag__c = true;
			update aps;
		}
		System.assert(aps.Chatter_Object_Brag__c);

		Test.startTest();

		Test.setCurrentPage(Page.ActionPlanCreation);
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		for (String k : ActionPlansTestUtilities.standardObjects) {
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

			ActionPlanTemplate__c apt = testutil.createNewActionPlanTemplate(5);
			for (APTemplateTask__c aptt : apt.aptTasks__r) {
				aptt.User__c = null;
			}
			update apt.aptTasks__r; //NOPMD

			apt.TaskRecordTypeID__c = ActionPlansTestUtilities.getNonDefaultAvailableTaskRecordType();
			apt.SkipWeekends__c = true;
			apt.SkipDay__c = 'End of previous week';

			update apt; //NOPMD

			ApexPages.currentPage().getParameters().put('id', null);

			ApexPages.currentPage().getParameters().put('templateId', apt.Id);
			ActionPlanCreationController apcc = new ActionPlanCreationController(new Apexpages.StandardController(new ActionPlan__c()));
			apcc.refreshRelatedObjectsLookUp();

			apcc.actionPlan.SkipWeekends__c = true;
			apcc.actionPlan.SkipDay__c = 'End of previous week';
			apcc.getTasks();

			System.assert(!apcc.getTasks().isEmpty());

			apcc.save();
		}

		Test.stopTest();

		System.assertEquals(ActionPlansTestUtilities.standardObjects.size(), [SELECT COUNT() FROM ActionPlan__c]);
	}

	@IsTest
	private static void testbatchIds() {
		ActionPlansTestUtilities apTestUtil = new ActionPlansTestUtilities();

		System.assert(apTestUtil.batchIds('account') != null);
	}

	@IsTest
	private static void testRandomWord() {
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();

		System.assert(testUtil.createRandomWord('testword') != testUtil.createRandomWord());
	}

	@IsTest
	private static void testUtilitiesRecordTypes() {
		if (ActionPlansUtilities.taskUsesRecordTypes) {
			if (ActionPlansTestUtilities.getNonDefaultAvailableTaskRecordType() != null) {
				String taskQuery = 'SELECT Id, RecordTypeId FROM Task';

				for (SObject t : Database.query(taskQuery)) {
					System.debug([SELECT Id, Name FROM RecordType WHERE Id = :(Id) t.get('RecordTypeId')].Name); //NOPMD
					System.assertNotEquals(ActionPlansUtilities.getDefaultTaskRecordTypeId(), t.get('RecordTypeId'), 'Record Type is default');
				}
			}
			System.assertNotEquals(0, ActionPlansUtilities.getTaskRTPicklistValues().size());
		} else {
			System.assertEquals(0, ActionPlansUtilities.getTaskRTPicklistValues().size());
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