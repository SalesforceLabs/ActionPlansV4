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
 * Tests for `ActionPlan__c` View Controller
 * @group Visualforce
 */
@IsTest
private class ActionPlanDetailControllerTest {
	@IsTest
	private static void constructorTests() {
		PageReference pageRef = Page.ActionPlanDetail;
		Test.setCurrentPage(pageRef);

		Test.startTest();

		System.currentPageReference().getParameters().put('id', null);
		ActionPlanDetailController apDetailController = new ActionPlanDetailController(new ApexPages.StandardController(new ActionPlan__c()));
		System.assert(apDetailController.getActionPlanTasks().isEmpty(), 'New Action Plan has no tasks');
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan = testUtil.createNewActionPlan('account', 1);

		System.currentPageReference().getParameters().put('id', actionPlan.Id);
		ActionPlanDetailController apDetailController2 = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));

		Test.stopTest();
		System.assertNotEquals(null, apDetailController2.hasRecordType);
	}

	@IsTest
	private static void printConstructorTests() {
		Test.setCurrentPage(Page.ActionPlanPrint);

		Test.startTest();

		ActionPlanDetailController apDetailController = new ActionPlanDetailController(new ApexPages.StandardController(new ActionPlan__c()));
		System.assert(apDetailController.getActionPlanTasks().isEmpty(), 'New Action Plan has no tasks');
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan = testUtil.createNewActionPlan('account', 1);

		ActionPlanDetailController apDetailController2 = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));

		apDetailController2.getRecordTypeName();

		Test.stopTest();

		System.assertEquals([SELECT Name FROM Account LIMIT 1].Name, apDetailController2.getrelatedRecordName());
		System.assertEquals('Account', apDetailController2.getRelatedObjectLabel());
	}

	@IsTest
	private static void checkTasks() {
		PageReference pageRef = Page.ActionPlanPrint;
		Test.setCurrentPage(pageRef);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan = testUtil.createNewActionPlan('account', 3);

		ActionPlanDetailController apDetailController = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));
		List<ActionPlanDetailController.TaskWrapper> apTasks = apDetailController.getActionPlanTasks();

		//Checks to see that list of tasks is not empty
		System.assert(!apTasks.isEmpty(), 'task list is empty');

		Test.stopTest();
	}

	@IsTest
	private static void checkCompletedTasks() {
		PageReference pageRef = Page.ActionPlanDetail;
		Test.setCurrentPage(pageRef);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan = testUtil.createNewActionPlan('account', 3);

		ActionPlanDetailController apDetailController = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));
		Integer completedTasks = apDetailController.getCompleted();

		//verifies number of completed tasks
		System.assertEquals(0, completedTasks);

		Test.stopTest();
	}

	@IsTest
	private static void checkActionPlanTemplateVersion() {
		PageReference pageRef = Page.ActionPlanDetail;
		Test.setCurrentPage(pageRef);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan = testUtil.createNewActionPlan('account', 2);
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(2);

		actionPlan.Action_Plan_Template__c = apTemplate.Id;
		update actionPlan;

		System.currentPageReference().getParameters().put('id', actionPlan.Id);
		ActionPlanDetailController apDetailController = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));
		boolean versionName = apDetailController.getVersion();

		Test.stopTest();

		//Checks if Action Plan Template has not been changed since the creation of the Action Plan.
		System.assert(!versionName);

		apTemplate.Name = 'new name';
		update apTemplate;

		System.currentPageReference().getParameters().put('id', actionPlan.Id);
		apDetailController = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));
		versionName = apDetailController.getVersion();

		//Checks if Action Plan Template has been changed since the creation of the Action Plan.
		//Will fail because tests run too fast on Salesforce Platform
		//System.assert( versionName );
	}

	@IsTest
	private static void checkDeleteActionPlan() {
		PageReference pageRef = Page.ActionPlanDetail;
		Test.setCurrentPage(pageRef);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan = testUtil.createNewActionPlan('account', 2);

		System.currentPageReference().getParameters().put('id', actionPlan.Id);
		ActionPlanDetailController apDetailController = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));
		apDetailController.deletePlan();

		List<ActionPlan__c> actionPlanList = [SELECT Id FROM ActionPlan__c WHERE Id = :actionPlan.Id LIMIT 1];

		Test.stopTest();

		System.assert(actionPlanList.isEmpty(), 'Action Plan was not deleted');
	}

	@IsTest
	private static void checkGetrelatedRecordName() {
		PageReference pageRef = Page.ActionPlanDetail;
		Test.setCurrentPage(pageRef);
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();

		ActionPlan__c actionPlan = testUtil.createNewActionPlan('account', 0);
		System.currentPageReference().getParameters().put('id', actionPlan.Id);
		ActionPlanDetailController apdc = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));
		String recName = apdc.getrelatedRecordName();
		System.assert(recName != null);

		actionPlan = testUtil.createNewActionPlan('campaign', 0);
		System.currentPageReference().getParameters().put('id', actionPlan.Id);
		apdc = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));
		recName = apdc.getrelatedRecordName();
		System.assert(recName != null);

		actionPlan = testUtil.createNewActionPlan('case', 0);
		System.currentPageReference().getParameters().put('id', actionPlan.Id);
		apdc = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));
		recName = apdc.getrelatedRecordName();
		System.assert(recName != null);

		actionPlan = testUtil.createNewActionPlan('contact', 0);
		System.currentPageReference().getParameters().put('id', actionPlan.Id);
		apdc = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));
		recName = apdc.getrelatedRecordName();
		System.assert(recName != null);

		actionPlan = testUtil.createNewActionPlan('contract', 0);
		System.currentPageReference().getParameters().put('id', actionPlan.Id);
		apdc = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));
		recName = apdc.getrelatedRecordName();
		System.assert(recName != null);

		actionPlan = testUtil.createNewActionPlan('lead', 0);
		System.currentPageReference().getParameters().put('id', actionPlan.Id);
		apdc = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));
		recName = apdc.getrelatedRecordName();
		System.assert(recName != null);

		actionPlan = testUtil.createNewActionPlan('opportunity', 0);
		System.currentPageReference().getParameters().put('id', actionPlan.Id);
		apdc = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));
		recName = apdc.getrelatedRecordName();
		System.assert(recName != null);
	}

	@IsTest
	private static void testForceNoRecordType() {
		ActionPlansTestUtilities.forceHasRecordType = false;

		PageReference pageRef = Page.ActionPlanDetail;
		Test.setCurrentPage(pageRef);

		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan = testUtil.createNewActionPlan('account', 1);

		System.currentPageReference().getParameters().put('id', actionPlan.Id);
		ActionPlanDetailController apDetailController2 = new ActionPlanDetailController(new ApexPages.StandardController(actionPlan));

		Test.stopTest();

		System.assertEquals(false, apDetailController2.hasRecordType);
		System.assertEquals('', apDetailController2.getRecordTypeName());
	}
}