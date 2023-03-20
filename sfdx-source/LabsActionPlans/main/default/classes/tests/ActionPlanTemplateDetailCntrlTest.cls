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
			Assert.areNotEqual(null, apTemplate.TaskRecordTypeID__c, 'The org has Task Record Types, but we could not get one');
		}

		Test.startTest();
		Test.setCurrentPage(Page.ActionPlanTemplateDetail);
		ActionPlanTemplateDetailController apTemplateDetailController = new ActionPlanTemplateDetailController(new ApexPages.StandardController(new ActionPlanTemplate__c()));
		apTemplateDetailController.onLoad();

		ApexPages.currentPage().getParameters().put('id', apTemplate.Id);
		apTemplateDetailController = new ActionPlanTemplateDetailController(new ApexPages.StandardController(apTemplate));

		if (apTemplateDetailController.taskHasRecordType) {
			Assert.areNotEqual('', apTemplateDetailController.getRecordTypeName(), 'Task has Record Types - but we did not populate one for the picklist');
		} else {
			Assert.areEqual('', apTemplateDetailController.getRecordTypeName(), 'Task has NO Record Types - but we populated one for the picklist');
		}

		apTemplateDetailController.getCanTransfer();
		apTemplateDetailController.getCanShare();

		Test.stopTest();

		Assert.isFalse(apTemplateDetailController.getTemplateTasks().isEmpty(), 'We failed to collect the AP Template Tasks');
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

		Assert.areEqual(true, apTemplateDetailController.taskHasRecordType, 'Failed to force test to see a Task Record Type even if one does not really exist');
		Assert.areNotEqual(null, apTemplateDetailController.getRecordTypeName(), 'Failed to force test to see a Task Record Type even if one does not really exist');
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

		Assert.areEqual('', apTemplateDetailController.getRecordTypeName(), 'Failed to force test to fail to see Record Types for Task');
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

		Assert.isTrue(apTemplateDetailController.getTemplateTasks().isEmpty(), 'It should be impossible to create Template Tasks when none are on the template itself');
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
		final Integer TASK_COUNT = 3; //NOPMD
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(TASK_COUNT);

		Assert.areEqual(TASK_COUNT, [SELECT COUNT() FROM APTemplateTask__c], 'Failed to create ' + TASK_COUNT + ' AP Template Tasks');

		Test.startTest();
		Test.setCurrentPage(Page.ActionPlanTemplateDetail);
		ActionPlanTemplateDetailController apTemplateDetailController = new ActionPlanTemplateDetailController(new ApexPages.StandardController(apTemplate));

		List<APTemplateTask__c> taskList = apTemplateDetailController.getTemplateTasks();

		Test.stopTest();

		//Checks to see if template tasks is not empty
		Assert.isFalse(taskList.isEmpty(), 'action plan Template tasks is empty');

		//checks that list contains total number of created tasks
		Assert.areEqual(TASK_COUNT, taskList.size(), 'Failed to create ' + TASK_COUNT + ' AP Template Tasks');
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
		Assert.areNotEqual(null, apTemplate2, 'we did not successfully retrieve the AP Template for the page');

		//checks to see if both action plan templates are the same
		Assert.areEqual(apTemplate2.Id, apTemplate.Id, 'The template Ids did not match');
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

		Assert.areNotEqual(null, controller.actionPlanExportXMLId, 'Failed to find an Action Plan and return its ID');

		Assert.areNotEqual(null, controller.getSuccessMessage(), 'We did not get a success message - export failed.');
	}
}