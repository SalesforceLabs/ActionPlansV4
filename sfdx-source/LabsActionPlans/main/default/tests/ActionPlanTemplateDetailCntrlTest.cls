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
 * Tests for `ActionPlanTemplate__c` ActionPlanTemplateDetailController
 * @group Tests
 * @author {@link [David Schach](https://github.com/dschach)}
 * @since 2022
 * @see ActionPlanTemplateDetailController
 */
@IsTest
private class ActionPlanTemplateDetailCntrlTest {
	@IsTest
	private static void constructor() {
		Test.setCurrentPage(Page.ActionPlanTemplateDetail);

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(2);

		apTemplate = [SELECT Id, TaskRecordTypeId__c, OwnerId FROM ActionPlanTemplate__c WHERE Id = :apTemplate.Id LIMIT 1];

		if (ActionPlansUtilities.taskUsesRecordTypes) {
			Assert.areNotEqual(null, apTemplate.TaskRecordTypeID__c);
		}

		Test.startTest();
		Test.setCurrentPage(Page.ActionPlanTemplateDetail);
		ActionPlanTemplateDetailController apTemplateDetailController = new ActionPlanTemplateDetailController(new ApexPages.StandardController(new ActionPlanTemplate__c()));
		apTemplateDetailController.onLoad();

		ApexPages.currentPage().getParameters().put('id', apTemplate.Id);
		apTemplateDetailController = new ActionPlanTemplateDetailController(new ApexPages.StandardController(apTemplate));

		if (apTemplateDetailController.taskHasRecordType) {
			Assert.areNotEqual('', apTemplateDetailController.getRecordTypeName());
		} else {
			Assert.areEqual('', apTemplateDetailController.getRecordTypeName());
		}

		apTemplateDetailController.getCanTransfer();
		apTemplateDetailController.getCanShare();

		Test.stopTest();

		Assert.isFalse(apTemplateDetailController.getTemplateTasks().isEmpty());
	}

	@IsTest
	private static void forceRecordType() {
		ActionPlansTestUtilities.forceHasRecordType = true;

		Test.setCurrentPage(Page.ActionPlanTemplateDetail);

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(2);

		apTemplate = [SELECT Id, TaskRecordTypeId__c FROM ActionPlanTemplate__c WHERE Id = :apTemplate.Id LIMIT 1];
		ApexPages.currentPage().getParameters().put('id', apTemplate.Id);

		Test.startTest();

		ActionPlanTemplateDetailController apTemplateDetailController = new ActionPlanTemplateDetailController(new ApexPages.StandardController(apTemplate));

		Test.stopTest();

		Assert.areEqual(true, apTemplateDetailController.taskHasRecordType);
		Assert.areNotEqual(null, apTemplateDetailController.getRecordTypeName());
	}

	@IsTest
	private static void forceNoRecordType() {
		ActionPlansTestUtilities.forceHasRecordType = false;

		Test.setCurrentPage(Page.ActionPlanTemplateDetail);

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(2);

		apTemplate = [SELECT Id, TaskRecordTypeId__c FROM ActionPlanTemplate__c WHERE Id = :apTemplate.Id LIMIT 1];
		ApexPages.currentPage().getParameters().put('id', apTemplate.Id);

		Test.startTest();

		ActionPlanTemplateDetailController apTemplateDetailController = new ActionPlanTemplateDetailController(new ApexPages.StandardController(apTemplate));

		Test.stopTest();

		Assert.areEqual('', apTemplateDetailController.getRecordTypeName());
	}

	@IsTest
	private static void checkNoTasks() {
		Test.setCurrentPage(Page.ActionPlanTemplateDetail);

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(0);

		Test.startTest();

		Test.setCurrentPage(Page.ActionPlanTemplateDetail);
		ApexPages.currentPage().getParameters().put('id', apTemplate.Id);
		ActionPlanTemplateDetailController apTemplateDetailController = new ActionPlanTemplateDetailController(new ApexPages.StandardController(apTemplate));

		Test.stopTest();

		Assert.isTrue(apTemplateDetailController.getTemplateTasks().isEmpty());
	}

	@IsTest
	private static void deleteActionPlanTemplate() {
		Test.setCurrentPage(Page.ActionPlanTemplateDetail);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(2);

		ApexPages.currentPage().getParameters().put('id', apTemplate.Id);
		ActionPlanTemplateDetailController apTemplateDetailController = new ActionPlanTemplateDetailController(new ApexPages.StandardController(apTemplate));

		apTemplateDetailController.deleteTemplate();

		Test.stopTest();

		List<ActionPlanTemplate__c> auxTemplate = [SELECT Id FROM ActionPlanTemplate__c WHERE Id = :apTemplate.Id];

		//Checks to see if action plan template has been deleted
		Assert.isTrue(auxTemplate.isEmpty(), 'action plan Template was not deleted');
	}

	@IsTest
	private static void retrievingTemplateTasks() {
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(3);

		Assert.areEqual(3, [SELECT COUNT() FROM APTemplateTask__c]);

		Test.startTest();
		Test.setCurrentPage(Page.ActionPlanTemplateDetail);
		ActionPlanTemplateDetailController apTemplateDetailController = new ActionPlanTemplateDetailController(new ApexPages.StandardController(apTemplate));

		List<APTemplateTask__c> taskList = apTemplateDetailController.getTemplateTasks();

		Test.stopTest();

		//Checks to see if template tasks is not empty
		Assert.isFalse(taskList.isEmpty(), 'action plan Template tasks is empty');

		//checks that list contains total number of created tasks
		Assert.areEqual(3, taskList.size());
	}

	@IsTest
	private static void retrievingActionPlanTemplate() {
		Test.setCurrentPage(Page.ActionPlanTemplateDetail);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(3);

		ApexPages.currentPage().getParameters().put('id', apTemplate.Id);
		ActionPlanTemplateDetailController apTemplateDetailController = new ActionPlanTemplateDetailController(new ApexPages.StandardController(apTemplate));

		ActionPlanTemplate__c apTemplate2 = apTemplateDetailController.actionPlanTemplate;

		Test.stopTest();

		//Checks to see if action plan template is retrieved
		Assert.isTrue(apTemplate2 != null, 'action plan Template tasks is empty');

		//checks to see if both action plan templates are the same
		Assert.areEqual(apTemplate2.Id, apTemplate.Id);
	}

	@IsTest
	private static void exportTest() {
		Test.setCurrentPage(Page.ActionPlanTemplateDetail);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(3);

		ActionPlanTemplateDetailController controller = new ActionPlanTemplateDetailController(new ApexPages.StandardController(apTemplate));

		controller.exportTemplateToXMLDoc();

		Test.stopTest();

		Assert.isTrue(controller.actionPlanExportXMLId != null);

		Assert.areNotEqual(null, controller.getSuccessMessage());
	}
}