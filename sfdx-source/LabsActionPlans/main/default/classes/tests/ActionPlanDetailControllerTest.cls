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
 * Tests for `ActionPlan__c` View Controller
 * @author {@link [David Schach](https://github.com/dschach)}
 * @see ActionPlanDetailController
 * @group Tests
 */
@IsTest
private class ActionPlanDetailControllerTest {
	@IsTest
	private static void constructorTests() {
		PageReference pageRef = Page.ActionPlanDetail;
		Test.setCurrentPage(pageRef);

		Test.startTest();

		ApexPages.currentPage().getParameters().put('id', null);
		ActionPlanDetailController apDetailController = new ActionPlanDetailController(new ApexPages.StandardController(new ActionPlan__c()));
		apDetailController.onLoad();
		Assert.areEqual(0, ActionPlansTestUtilities.getCompleted(null), 'New AP should have no completed tasks');
		Assert.isTrue(apDetailController.getActionPlanTasks().isEmpty(), 'New Action Plan has no tasks');
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan = testUtil.createNewActionPlan('account', 1, null);

		ApexPages.currentPage().getParameters().put('id', actionPlan.Id);
		ActionPlanDetailController apDetailController2 = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));
		Assert.areEqual('Account', apDetailController2.getRelatedObjectLabel(), 'Incorrect Related Object Label');
		apDetailController2.getCanTransfer();
		apDetailController2.getCanShare();
		Assert.areNotEqual(null, apDetailController2.hasRecordType, 'HasRecordType should be true or false. Never null.');

		ActionPlanDetailController apDetailController3 = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));

		Test.stopTest();
		Assert.isFalse(apDetailController3.getActionPlanTasks().isEmpty(), 'Failed to collect AP Tasks (TaskWrappers)');
	}

	@IsTest
	private static void checkTasks() {
		PageReference pageRef = Page.ActionPlanDetail;
		Test.setCurrentPage(pageRef);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan = testUtil.createNewActionPlan('account', 3, null);

		ActionPlanDetailController apDetailController = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));
		List<ActionPlanDetailController.TaskWrapper> apTasks = apDetailController.getActionPlanTasks();

		//Checks to see that list of tasks is not empty
		Assert.isFalse(apTasks.isEmpty(), 'task list is empty');

		Test.stopTest();
	}

	@IsTest
	private static void checkNoTasks() {
		PageReference pageRef = Page.ActionPlanDetail;
		Test.setCurrentPage(pageRef);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan = testUtil.createNewActionPlan('account', 0, null);

		ActionPlanDetailController apDetailController = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));
		List<ActionPlanDetailController.TaskWrapper> apTasks = apDetailController.getActionPlanTasks();

		//Checks to see that list of tasks is not empty
		Assert.isTrue(apTasks.isEmpty(), 'task list is empty');

		Test.stopTest();
	}

	@IsTest
	private static void checkDependentTasks() {
		PageReference pageRef = Page.ActionPlanDetail;
		Test.setCurrentPage(pageRef);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan = testUtil.createNewActionPlan('account', 3, null);
		List<APTask__c> apTasks = [SELECT Id, Controller__c FROM APTask__c];
		apTasks[1].Controller__c = apTasks[0].Id;
		update apTasks;

		ActionPlanDetailController apDetailController = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));
		apDetailController.getActionPlanTasks();
		Test.stopTest();
		Assert.isTrue(apDetailController.gethasControllingTasks(), 'Failed to find controlling tasks');
	}

	@IsTest
	private static void checkActionPlanTemplateVersion() {
		PageReference pageRef = Page.ActionPlanDetail;
		Test.setCurrentPage(pageRef);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan = testUtil.createNewActionPlan('account', 2, null);
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(2);

		actionPlan.Action_Plan_Template__c = apTemplate.Id;
		update actionPlan;

		ApexPages.currentPage().getParameters().put('id', actionPlan.Id);
		ActionPlanDetailController apDetailController = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));
		Boolean versionName = apDetailController.getVersion();

		Test.stopTest();

		//Checks if Action Plan Template has not been changed since the creation of the Action Plan.
		Assert.isFalse(versionName, 'Somebody changed the APTemplate!');

		apTemplate.Name = 'new name';
		update apTemplate;

		ApexPages.currentPage().getParameters().put('id', actionPlan.Id);
		apDetailController = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));
		versionName = apDetailController.getVersion();

		//Checks if Action Plan Template has been changed since the creation of the Action Plan.
		//Will fail because tests run too fast on Salesforce Platform
		//Assert.isTrue( versionName );
	}

	@IsTest
	private static void checkDeleteActionPlan() {
		PageReference pageRef = Page.ActionPlanDetail;
		Test.setCurrentPage(pageRef);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan = testUtil.createNewActionPlan('account', 2, null);

		ApexPages.currentPage().getParameters().put('id', actionPlan.Id);
		ActionPlanDetailController apDetailController = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));
		apDetailController.deletePlan();

		List<ActionPlan__c> actionPlanList = [SELECT Id FROM ActionPlan__c WHERE Id = :actionPlan.Id LIMIT 1];

		Test.stopTest();

		Assert.isTrue(actionPlanList.isEmpty(), 'Action Plan was not deleted');
		Assert.areEqual(0, [SELECT COUNT() FROM Task], 'Should not have found any Tasks');
	}

	@IsTest
	private static void checkGetRelatedRecordName() {
		PageReference pageRef = Page.ActionPlanDetail;
		Test.setCurrentPage(pageRef);
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();

		ActionPlan__c actionPlan = testUtil.createNewActionPlan('account', 0, null);
		ApexPages.currentPage().getParameters().put('id', actionPlan.Id);
		ActionPlanDetailController apdc = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));
		String recName = apdc.getrelatedRecordName();
		Assert.areNotEqual(null, recName, 'Failed to get correct related Record Name');
		Assert.areEqual('Account', apdc.getRelatedObjectLabel(), 'Incorrect Related Object Label');

		actionPlan = testUtil.createNewActionPlan('campaign', 0, null);
		ApexPages.currentPage().getParameters().put('id', actionPlan.Id);
		apdc = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));
		recName = apdc.getrelatedRecordName();
		Assert.areNotEqual(null, recName, 'Failed to get correct related Record Name');

		actionPlan = testUtil.createNewActionPlan('case', 0, null);
		ApexPages.currentPage().getParameters().put('id', actionPlan.Id);
		apdc = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));
		recName = apdc.getrelatedRecordName();
		Assert.areNotEqual(null, recName, 'Failed to get correct related Record Name');

		actionPlan = testUtil.createNewActionPlan('contact', 0, null);
		ApexPages.currentPage().getParameters().put('id', actionPlan.Id);
		apdc = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));
		recName = apdc.getrelatedRecordName();
		Assert.areNotEqual(null, recName, 'Failed to get correct related Record Name');
		Assert.areEqual('Contact', apdc.getRelatedObjectLabel(), 'Incorrect Related Object Label');

		actionPlan = testUtil.createNewActionPlan('contract', 0, null);
		ApexPages.currentPage().getParameters().put('id', actionPlan.Id);
		apdc = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));
		recName = apdc.getrelatedRecordName();
		Assert.areNotEqual(null, recName, 'Failed to get correct related Record Name');

		actionPlan = testUtil.createNewActionPlan('lead', 0, null);
		ApexPages.currentPage().getParameters().put('id', actionPlan.Id);
		apdc = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));
		recName = apdc.getrelatedRecordName();
		Assert.areNotEqual(null, recName, 'Failed to get correct related Record Name');

		actionPlan = testUtil.createNewActionPlan('opportunity', 0, null);
		ApexPages.currentPage().getParameters().put('id', actionPlan.Id);
		apdc = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));
		recName = apdc.getrelatedRecordName();
		Assert.areNotEqual(null, recName, 'Failed to get correct related Record Name');
	}

	@IsTest
	private static void forceRecordType() {
		ActionPlansTestUtilities.forceHasRecordType = true;

		PageReference pageRef = Page.ActionPlanDetail;
		Test.setCurrentPage(pageRef);

		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan = testUtil.createNewActionPlan('account', 1, null);

		ApexPages.currentPage().getParameters().put('id', actionPlan.Id);
		ActionPlanDetailController apDetailController = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));

		Test.stopTest();

		Assert.areEqual(true, apDetailController.hasRecordType, 'Failed to find the Record Type');
		Assert.areNotEqual(null, apDetailController.getRecordTypeName(), 'Failed to find the Record Type Name');
	}

	@IsTest
	private static void forceNoRecordType() {
		ActionPlansTestUtilities.forceHasRecordType = false;

		PageReference pageRef = Page.ActionPlanDetail;
		Test.setCurrentPage(pageRef);

		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan = testUtil.createNewActionPlan('account', 1, null);

		ApexPages.currentPage().getParameters().put('id', actionPlan.Id);
		ActionPlanDetailController apDetailController2 = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));

		Test.stopTest();

		Assert.areEqual(false, apDetailController2.hasRecordType, 'Found a nonexistent Record Type');
		Assert.areEqual('', apDetailController2.getRecordTypeName(), 'Found a nonexistent Record Type Name!');
	}
}