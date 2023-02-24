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
 * @author {@link [David Schach](https://github.com/dschach)}
 * 2since 2022
 * @see ActionPlanTemplateCreationController
 * @group Tests
 */
@IsTest
private class ActionPlanTemplateCreationCntrlTest {
	private static final Integer TEMPLATE_TASKS_COUNT = 2;

	@IsTest
	private static void contructor() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(2);

		ApexPages.currentPage().getParameters().put('id', null);
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(new ActionPlanTemplate__c()));
		aptcc.getTemplateTasks();

		ApexPages.currentPage().getParameters().put('id', apTemplate.Id);
		aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));
		aptcc.getTemplateTasks();

		ApexPages.currentPage().getParameters().put('clone', '1');
		aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));
		aptcc.getTemplateTasks();
		aptcc.getTemplateWrappers();
		aptcc.getDefaultTaskRecordTypeId();
		aptcc.getTaskRTPicklistValues();
		aptcc.getTaskTypes();
		aptcc.getTaskPriorities();
		aptcc.getHoursOption();

		Test.stopTest();

		Assert.isFalse(aptcc.getTemplateTasks().isEmpty(), 'Failed to collect all Template Tasks for the page');
	}

	@IsTest
	private static void save() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = new ActionPlanTemplate__c();

		apTemplate.Name = testUtil.createRandomWord('Name');

		APTemplateTask__c newAPTTask = new APTemplateTask__c();

		newAPTTask.Subject__c = testUtil.createRandomWord('subject');
		newAPTTask.DaysFromStart__c = 2;
		newAPTTask.Type__c = 'Email';
		newAPTTask.Priority__c = 'High';

		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));
		aptcc.aptTasks = new List<APTemplateTask__c>();
		aptcc.aptTasks.add(newAPTTask);
		Pagereference page = aptcc.saveTemplate();

		Test.stopTest();

		Assert.areNotEqual(null, page, 'Failed to instantiate a PageReference to go after saving the Template');
		Assert.areNotEqual(null, aptcc.saveAndNew(), 'Failed to successfully save the Template and start a new one');
	}

	//Test Saves Action Plan Template and all tasks
	@IsTest
	private static void saveTemplate() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);

		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apt = testutil.createNewActionPlanTemplate(5);
		User tUser = testutil.createTestUser();
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apt));
		Test.startTest();

		aptcc.pendingTemplateTaskDeletes = new List<APTemplateTask__c>();
		aptcc.pendingTemplateTaskDeletes.add(testutil.createNewActionPlanTemplateTask(apt, 3, tUser.Id, 'Email', 'High'));
		insert aptcc.pendingTemplateTaskDeletes;
		aptcc.aptTasks.add(testutil.createNewActionPlanTemplateTask(apt, 4, null, null, null));
		aptcc.aptTasks.add(testutil.createNewActionPlanTemplateTask(apt, 5, tUser.Id, 'Email', 'High'));
		aptcc.aptTasks.get(0).Dependent__c = '1';

		aptcc.saveTemplate();

		Assert.isFalse(aptcc.pendingTemplateTaskDeletes.isEmpty(), 'Failed to collect all Template Tasks for deletion');

		//Enter Task Catch()
		aptcc.pendingTemplateTaskDeletes = new List<APTemplateTask__c>();
		aptcc.aptTasks.clear();
		APTemplateTask__c aptt = testutil.createNewActionPlanTemplateTask(apt, 5, null, null, null);
		aptt.DaysFromStart__c = -3;
		aptcc.aptTasks.add(aptt);
		//aptcc.aptTasks.add(new APTemplateTask__c(DaysFromStart__c = -3));
		aptcc.saveTemplate();

		Assert.isFalse(aptcc.aptTasks.isEmpty(), 'Failed to collect all Template Tasks for the page');

		//Enter APT Catch()
		aptcc.actionPlanTemplate = null;
		aptcc.saveTemplate();
		Test.stopTest();
		Assert.isFalse(aptcc.aptTasks.isEmpty(), 'Failed to collect all Template Tasks for the page');
	}

	@IsTest
	private static void cancel() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(new ActionPlanTemplate__c()));
		aptcc.cancelTemplate();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(2);

		ApexPages.currentPage().getParameters().put('id', apTemplate.Id);
		aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));
		PageReference cancelPage = aptcc.cancelTemplate();

		Test.stopTest();

		String urlVal = cancelPage.getUrl();
		Assert.isTrue(urlVal.containsIgnoreCase(apTemplate.Id), 'Failed to construct the cancel page URL correctly: ' + urlVal);
	}

	@IsTest
	private static void setTaskRecordType() {
		ActionPlansTestUtilities.forceHasRecordType = true;

		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		//ActionPlanTemplate__c apTemplate = testutil.createNewActionPlanTemplate('contact', 2);

		Test.startTest();
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		//ApexPages.currentPage().getParameters().put('id', apTemplate.Id);
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(new ActionPlanTemplate__c()));

		aptcc.actionPlanTemplate.Name = testutil.createRandomWord('APName');
		aptcc.actionPlanTemplate.OwnerId = Userinfo.getUserId();
		aptcc.actionPlanTemplate.TaskRecordTypeID__c = aptcc.getDefaultTaskRecordTypeId();
		aptcc.actionPlanTemplate.SkipWeekends__c = true;
		aptcc.actionPlanTemplate.SkipDay__c = 'Start of next week';

		APTemplateTask__c newAPTTask = new APTemplateTask__c();
		newAPTTask.DaysFromStart__c = 1;
		newAPTTask.User__c = UserInfo.getUserId();
		newAPTTask.Type__c = 'Meeting';
		newAPTTask.Minutes_Reminder__c = '510';
		aptcc.aptTasks.clear();
		aptcc.aptTasks.add(newAPTTask);

		aptcc.getTemplateWrappers();
		aptcc.saveTemplate();

		Test.stopTest();
		Assert.areEqual(1, aptcc.getTemplateTaskSize(), 'Failed to collect 1 Template Task for the page');
	}

	@IsTest
	private static void forceNoRecordType() {
		ActionPlansTestUtilities.forceHasRecordType = false;

		Test.setCurrentPage(Page.ActionPlanTemplateCreation);

		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(5);

		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));
		aptcc.getTemplateWrappers();
		Test.stopTest();

		Assert.areEqual(false, aptcc.taskHasRecordType, 'Failed to force test to fail to see Record Types for Task');
	}

	@IsTest
	private static void checkMaxTasksError() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(ActionPlansUtilities.MAX_APTASKS + 1);

		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));
		aptcc.getTemplateTasks();
		ApexPages.currentPage().getParameters().put('add ', '1');
		aptcc.addTemplateTask();
		Test.stopTest();
		String errorMsg = aptcc.getErrorMsg();
		Assert.isTrue(errorMsg.containsIgnoreCase(String.valueOf(ActionPlansUtilities.MAX_APTASKS)), 'Error message does not show correct nax tasks allowed');
	}

	@IsTest
	private static void addTemplateTask() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(2);

		ApexPages.currentPage().getParameters().put('id', apTemplate.Id);
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));
		//aptcc.getTemplateTasks();
		ApexPages.currentPage().getParameters().put('add ', '1');
		aptcc.addTemplateTask();

		Test.stopTest();

		Integer taskCount = aptcc.getTemplateTaskSize();
		Assert.isTrue(taskCount > 2, 'We should have started a third Template Task wrapper for the page');
	}

	@IsTest
	private static void addNewActionPlanTemplateTask() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c actionPlanTemplate = testUtil.createNewActionPlanTemplate(3);

		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(actionPlanTemplate));

		aptcc.addTemplateTask();

		Assert.areEqual(null, aptcc.geterrorMsg(), 'An error was returned when adding a template task ');

		ActionPlanTemplate__c actionPlanTemplate2 = testUtil.createNewActionPlanTemplate(ActionPlansUtilities.MAX_APTASKS);
		aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(actionPlanTemplate2));

		aptcc.getTemplateTasks();

		aptcc.addTemplateTask();

		Assert.areNotEqual(null, aptcc.geterrorMsg(), 'An error was not returned when adding a template task');

		Test.stopTest();
	}

	@IsTest
	private static void removeTemplateTask() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(4);

		ApexPages.currentPage().getParameters().put('id', apTemplate.Id);
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));
		aptcc.getTemplateTasks();
		ApexPages.currentPage().getParameters().put('remove', '1');
		aptcc.removeTemplateTask();

		Test.stopTest();

		Assert.areEqual(3, aptcc.getTemplateTaskSize(), 'Should have removed 1 task from 4');
	}

	@IsTest
	private static void removingActionPlanTemplateTask() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c actionPlanTemplate = testUtil.createNewActionPlanTemplate(5);

		Assert.areEqual(5, [SELECT COUNT() FROM APTemplateTask__c], 'We created 5 tasks');

		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(actionPlanTemplate));
		aptcc.getTemplateTasks();
		Assert.areEqual(5, aptcc.aptTasks.size(), 'Should have 5 tasks on the template');

		ApexPages.currentPage().getParameters().put('remove', '1');
		aptcc.removeTemplateTask();

		aptcc.saveTemplate();

		Test.stopTest();
		aptcc.getTemplateTasks();

		Assert.isTrue(aptcc.aptTasks.size() == 4, 'Task was not deleted correctly');
		Assert.areEqual(4, aptcc.getTemplateTasks().size(), 'Tasks get after delete failed');
	}

	@IsTest
	private static void retrievingTemplateTasks() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(2);

		ApexPages.currentPage().getParameters().put('id', apTemplate.Id);
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));
		List<ActionPlanTemplateCreationController.ApTTaskWrapper> taskList = aptcc.getTemplateWrappers();

		Test.stopTest();

		//checks that the list is not empty
		Assert.isFalse(taskList.isEmpty(), 'Task list was not empty');
	}

	@IsTest
	private static void longNameTemplateTasks() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(2);

		apTemplate.Name = '1234567890123456789012345678901234567890'; // 40 characters
		update apTemplate;

		List<APTemplateTask__c> aptts = [SELECT Id, Subject__c FROM APTemplateTask__c];
		for (APTemplateTask__c a : aptts) {
			a.Subject__c = 'abcdefghijabcdefghijabcdefghijabcdefghij'; // 40 characters
		}
		update aptts;

		ApexPages.currentPage().getParameters().put('id', apTemplate.Id);
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));
		List<ActionPlanTemplateCreationController.ApTTaskWrapper> taskList = aptcc.getTemplateWrappers();

		Test.stopTest();

		//checks that the list is not empty
		Assert.isFalse(taskList.isEmpty(), 'Task list was not empty');
	}

	@IsTest
	private static void checkTemplateTaskSize() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(TEMPLATE_TASKS_COUNT);

		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));
		List<ActionPlanTemplateCreationController.ApTTaskWrapper> taskList = aptcc.getTemplateWrappers();

		Test.stopTest();

		Integer numTasks = aptcc.getTemplateTaskSize();
		//checks that the list is not empty
		Assert.isFalse(taskList.isEmpty(), 'Task list was not empty');
		//Checks to see if both methods return same task size
		Assert.areEqual(numTasks, taskList.size(), 'Failed to create the correct number of Template Tasks: ' + numTasks);
		Assert.areEqual(TEMPLATE_TASKS_COUNT, taskList.size(), 'Failed to create the correct number of Template Tasks: ' + TEMPLATE_TASKS_COUNT);
	}

	@IsTest
	private static void checkTemplateSubjectItem() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(2);

		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));

		List<ActionPlanTemplateCreationController.ApTTaskWrapper> taskList = aptcc.getTemplateWrappers(); //NOPMD
		List<SelectOption> subjectItems = aptcc.getTemplateSubjectItems();

		Test.stopTest();

		Assert.isTrue(subjectItems.size() > 1, 'We have a task to select for dependency');
	}

	@IsTest
	private static void cyclicDependencyFail() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(2);

		APTemplateTask__c newAPTTask1 = new APTemplateTask__c();
		APTemplateTask__c newAPTTask2 = new APTemplateTask__c();
		APTemplateTask__c newAPTTask3 = new APTemplateTask__c();

		newAPTTask1.Subject__c = testUtil.createRandomWord('subject');
		newAPTTask1.DaysFromStart__c = 2;
		newAPTTask1.Dependent__c = '2';
		newAPTTask1.Type__c = 'Email';
		newAPTTask1.Priority__c = 'High';
		newAPTTask1.TaskIndex__c = 0;

		newAPTTask2.Subject__c = testUtil.createRandomWord('subject');
		newAPTTask2.DaysFromStart__c = 2;
		newAPTTask2.Dependent__c = '0';
		newAPTTask2.Type__c = 'Email';
		newAPTTask2.Priority__c = 'High';
		newAPTTask2.TaskIndex__c = 1;

		newAPTTask3.Subject__c = testUtil.createRandomWord('subject');
		newAPTTask3.DaysFromStart__c = -2;
		newAPTTask3.Dependent__c = '1';
		newAPTTask3.Type__c = 'Email';
		newAPTTask3.Priority__c = 'High';
		newAPTTask3.TaskIndex__c = 2;

		ApexPages.currentPage().getParameters().put('id', apTemplate.Id);
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));

		aptcc.aptTasks = new List<APTemplateTask__c>();
		aptcc.aptTasks.add(newAPTTask1);
		aptcc.aptTasks.add(newAPTTask2);
		aptcc.aptTasks.add(newAPTTask3);

		aptcc.checkCycleDependent();

		Assert.isTrue(aptcc.getErrorMsg() != null, 'dependency check failed');

		Test.stopTest();
	}

	@IsTest
	private static void itselfCyclicDependencyFail() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(2);

		APTemplateTask__c newAPTTask1 = new APTemplateTask__c();

		newAPTTask1.Subject__c = testUtil.createRandomWord('subject');
		newAPTTask1.DaysFromStart__c = 2;
		newAPTTask1.Dependent__c = '0';
		newAPTTask1.Type__c = 'Email';
		newAPTTask1.Priority__c = 'High';
		newAPTTask1.TaskIndex__c = 0;

		ApexPages.currentPage().getParameters().put('id', apTemplate.Id);
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));

		aptcc.aptTasks = new List<APTemplateTask__c>();
		aptcc.aptTasks.add(newAPTTask1);

		aptcc.checkCycleDependent();

		Assert.isTrue(aptcc.getErrorMsg() != null, 'dependency check failed');

		Test.stopTest();
	}

	@IsTest
	private static void cyclicDependencySuccess() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(2);

		APTemplateTask__c newAPTTask1 = new APTemplateTask__c();
		APTemplateTask__c newAPTTask2 = new APTemplateTask__c();
		APTemplateTask__c newAPTTask3 = new APTemplateTask__c();
		APTemplateTask__c newAPTTask4 = new APTemplateTask__c();

		newAPTTask1.Subject__c = testUtil.createRandomWord('subject');
		newAPTTask1.DaysFromStart__c = 2;
		newAPTTask1.TaskIndex__c = 0;
		newAPTTask1.Dependent__c = '2';
		newAPTTask1.Type__c = 'Email';
		newAPTTask1.Priority__c = 'High';

		newAPTTask2.Subject__c = testUtil.createRandomWord('subject');
		newAPTTask2.DaysFromStart__c = 2;
		newAPTTask2.TaskIndex__c = 1;
		newAPTTask2.Dependent__c = '0';
		newAPTTask2.Type__c = 'Email';
		newAPTTask2.Priority__c = 'High';

		newAPTTask3.Subject__c = testUtil.createRandomWord('subject');
		newAPTTask3.DaysFromStart__c = 2;
		newAPTTask3.TaskIndex__c = 2;
		newAPTTask3.Dependent__c = '1';
		newAPTTask3.Type__c = 'Email';
		newAPTTask3.Priority__c = 'High';

		newAPTTask4.Subject__c = testUtil.createRandomWord('subject');
		newAPTTask4.DaysFromStart__c = 2;
		newAPTTask4.TaskIndex__c = 3;
		newAPTTask4.Dependent__c = '1';
		newAPTTask4.Type__c = 'Email';
		newAPTTask4.Priority__c = 'High';

		ApexPages.currentPage().getParameters().put('id', apTemplate.Id);
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));

		aptcc.aptTasks = new List<APTemplateTask__c>();
		aptcc.aptTasks.add(newAPTTask1);
		aptcc.aptTasks.add(newAPTTask2);
		aptcc.aptTasks.add(newAPTTask3);
		aptcc.aptTasks.add(newAPTTask4);

		aptcc.checkCycleDependent();
		Assert.isTrue(aptcc.getErrorMsg() != null, 'dependency check failed');

		ApexPages.currentPage().getParameters().put('remove', '1');
		aptcc.removeTemplateTask();
		aptcc.saveTemplate();

		Test.stopTest();
	}
}