/*
Action Plans v4
David Schach 2021

Action Plans v3
Force.com Labs 2011
http://appexchange.salesforce.com/listingDetail?listingId=a0N30000003HcINEA0

BSD 3-Clause License

Copyright (c) 2021, salesforce.com, inc.
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
 * @author David Schach
 * @see ActionPlanTemplateCreationController
 * @group Tests
 */
@IsTest
private class ActionPlanTemplateCreationCntrlTest {
	@IsTest
	private static void testContructor() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(2);

		System.currentPageReference().getParameters().put('id', null);
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(new ActionPlanTemplate__c()));
		aptcc.getTemplateTasks();

		System.currentPageReference().getParameters().put('id', apTemplate.Id);
		aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));
		aptcc.getTemplateTasks();

		System.currentPageReference().getParameters().put('clone', '1');
		aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));
		aptcc.getTemplateTasks();
		aptcc.getTemplateWrappers();
		aptcc.getDefaultTaskRecordTypeId();
		aptcc.getTaskRTPicklistValues();
		aptcc.getTaskTypes();
		aptcc.getTaskPriorities();
		aptcc.getHoursOption();

		Test.stopTest();

		System.assert(!aptcc.getTemplateTasks().isEmpty());
	}

	@IsTest
	private static void testSave() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = new ActionPlanTemplate__c();

		apTemplate.Name = testUtil.createRandomWord('Name');

		APTTaskTemplate__c newAPTTask = new APTTaskTemplate__c();

		newAPTTask.Subject__c = testUtil.createRandomWord('subject');
		newAPTTask.DaysFromStart__c = 2;
		newAPTTask.Type__c = 'Email';
		newAPTTask.Priority__c = 'High';

		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));
		aptcc.aptTasks = new List<APTTaskTemplate__c>();
		aptcc.aptTasks.add(newAPTTask);
		Pagereference page = aptcc.saveTemplate();

		Test.stopTest();

		System.assert(page != null);
		System.assert(aptcc.saveAndNew() != null);
	}

	//Test Saves Action Plan Template and all tasks
	@IsTest
	private static void testSaveTemplate() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);

		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apt = testutil.createNewActionPlanTemplate(5);
		User tUser = testutil.createTestUser();
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apt));
		Test.startTest();

		aptcc.pendingTemplateDeletes = new List<APTTaskTemplate__c>();
		aptcc.pendingTemplateDeletes.add(testutil.createNewActionPlanTemplateTask(apt, 3, tUser, 'Email', 'High'));
		insert aptcc.pendingTemplateDeletes;
		aptcc.aptTasks.add(testutil.createNewActionPlanTemplateTask(apt, 3, null, 'Email', 'High'));
		aptcc.aptTasks.add(testutil.createNewActionPlanTemplateTask(apt, 3, tUser, 'Email', 'High'));
		aptcc.aptTasks.get(0).Dependent__c = '1';

		aptcc.saveTemplate();

		System.assert(!aptcc.pendingTemplateDeletes.isEmpty());

		//Enter Task Catch()
		aptcc.pendingTemplateDeletes = new List<APTTaskTemplate__c>();
		aptcc.aptTasks.clear();
		aptcc.aptTasks.add(new APTTaskTemplate__c(DaysFromStart__c = -3));
		aptcc.saveTemplate();

		System.assert(!aptcc.aptTasks.isEmpty());

		//Enter APT Catch()
		aptcc.actionPlanTemplate = null;
		aptcc.saveTemplate();
		System.assert(!aptcc.aptTasks.isEmpty());

		Test.stopTest();
	}

	@IsTest
	private static void testCancel() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(new ActionPlanTemplate__c()));
		aptcc.cancelTemplate();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(2);

		System.currentPageReference().getParameters().put('id', apTemplate.Id);
		aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));
		PageReference cancelPage = aptcc.cancelTemplate();

		Test.stopTest();

		String urlVal = cancelPage.getUrl();
		System.assert(urlVal.containsIgnoreCase(apTemplate.Id));
	}

	@IsTest
	private static void testForceNoRecordType() {
		ActionPlansTestUtilities.forceHasRecordType = false;

		Test.setCurrentPage(Page.ActionPlanTemplateCreation);

		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(5);

		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));

		Test.stopTest();

		System.assertEquals(false, aptcc.taskHasRecordType);
	}

	@IsTest
	static void checkMaxTasksError() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(ActionPlansUtilities.MAX_APTASKS + 1);

		//System.currentPageReference().getParameters().put( 'id', apTemplate.Id );
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));
		aptcc.getTemplateTasks();
		System.currentPageReference().getParameters().put('add ', '1');
		aptcc.addTemplateTask();
		Test.stopTest();
		String errorMsg = aptcc.getErrorMsg();
		System.assert(errorMsg.containsIgnoreCase(String.valueOf(ActionPlansUtilities.MAX_APTASKS)));
	}

	@IsTest
	private static void testAddTemplateTask() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(2);

		System.currentPageReference().getParameters().put('id', apTemplate.Id);
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));
		//aptcc.getTemplateTasks();
		System.currentPageReference().getParameters().put('add ', '1');
		aptcc.addTemplateTask();

		Test.stopTest();

		Integer taskCount = aptcc.getTemplateTaskSize();
		System.assert(taskCount > 2);
	}

	@IsTest
	private static void testAddNewActionPlanTemplateTask() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c actionPlanTemplate = testUtil.createNewActionPlanTemplate(3);

		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(actionPlanTemplate));

		aptcc.addTemplateTask();

		System.assert(aptcc.geterrorMsg() == null, 'An error was returned when adding a template task ');

		ActionPlanTemplate__c actionPlanTemplate2 = testUtil.createNewActionPlanTemplate(ActionPlansUtilities.MAX_APTASKS);
		aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(actionPlanTemplate2));

		aptcc.getTemplateTasks();

		aptcc.addTemplateTask();

		System.assert(aptcc.geterrorMsg() != null, 'An error was not returned when adding a template task');

		Test.stopTest();
	}

	@IsTest
	private static void testRemoveTemplateTask() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(4);

		System.currentPageReference().getParameters().put('id', apTemplate.Id);
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));
		aptcc.getTemplateTasks();
		System.currentPageReference().getParameters().put('remove', '1');
		aptcc.removeTemplateTask();

		Test.stopTest();

		System.assertEquals(3, aptcc.getTemplateTaskSize(), 'Should have removed 1 task from 4');
	}

	@IsTest
	private static void testRemovingActionPlanTemplateTask() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c actionPlanTemplate = testUtil.createNewActionPlanTemplate(5);

		System.assertEquals(5, [SELECT COUNT() FROM APTTaskTemplate__c], 'We created 5 tasks');

		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(actionPlanTemplate));
		aptcc.getTemplateTasks();
		System.assertEquals(5, aptcc.aptTasks.size(), 'Should have 5 tasks on the template');

		System.currentPageReference().getParameters().put('remove', '1');
		aptcc.removeTemplateTask();

		aptcc.saveTemplate();

		Test.stopTest();
		aptcc.getTemplateTasks();

		System.assert(aptcc.aptTasks.size() == 4, 'Task was not deleted correctly');
		System.assertEquals(4, aptcc.getTemplateTasks().size(), 'Tasks get after delete failed');
	}

	@IsTest
	private static void testRetrievingTemplateTasks() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(2);

		System.currentPageReference().getParameters().put('id', apTemplate.Id);
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));
		List<ActionPlanTemplateCreationController.ApTTaskWrapper> taskList = aptcc.getTemplateWrappers();

		Test.stopTest();

		//checks that the list is not empty
		System.assert(!taskList.isEmpty(), 'Task list was not empty');
	}

	@IsTest
	private static void testLongNameTemplateTasks() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(2);

		apTemplate.Name = '1234567890123456789012345678901234567890'; // 40 characters
		update apTemplate;

		List<APTTaskTemplate__c> aptts = [SELECT Id, Subject__c FROM APTTaskTemplate__c];
		for (APTTaskTemplate__c a : aptts) {
			a.Subject__c = 'abcdefghijabcdefghijabcdefghijabcdefghij'; // 40 characters
		}
		update aptts;

		System.currentPageReference().getParameters().put('id', apTemplate.Id);
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));
		List<ActionPlanTemplateCreationController.ApTTaskWrapper> taskList = aptcc.getTemplateWrappers();

		Test.stopTest();

		//checks that the list is not empty
		System.assert(!taskList.isEmpty(), 'Task list was not empty');
	}

	@IsTest
	private static void checkTemplateTaskSize() {
		final Integer TEMPLATE_TASKS = 2;

		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(TEMPLATE_TASKS);

		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));
		List<ActionPlanTemplateCreationController.ApTTaskWrapper> taskList = aptcc.getTemplateWrappers();
		Integer numTasks = aptcc.getTemplateTaskSize();

		//checks that the list is not empty
		System.assert(!taskList.isEmpty(), 'Task list was not empty');

		Test.stopTest();

		//Checks to see if both methods return same task size
		System.assertEquals(numTasks, taskList.size());
		System.assertEquals(TEMPLATE_TASKS, taskList.size());
	}

	@IsTest
	private static void checkTemplateSubjectItem() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(2);

		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));

		List<ActionPlanTemplateCreationController.ApTTaskWrapper> taskList = aptcc.getTemplateWrappers();
		List<SelectOption> subjectItems = aptcc.getTemplateSubjectItems();

		Test.stopTest();

		System.assert(subjectItems.size() > 1, 'We have a task to select for dependency');
	}

	@IsTest
	private static void testCyclicDependencyFail() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(2);

		APTTaskTemplate__c newAPTTask1 = new APTTaskTemplate__c();
		APTTaskTemplate__c newAPTTask2 = new APTTaskTemplate__c();
		APTTaskTemplate__c newAPTTask3 = new APTTaskTemplate__c();

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

		System.currentPageReference().getParameters().put('id', apTemplate.Id);
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));

		aptcc.aptTasks = new List<APTTaskTemplate__c>();
		aptcc.aptTasks.add(newAPTTask1);
		aptcc.aptTasks.add(newAPTTask2);
		aptcc.aptTasks.add(newAPTTask3);

		aptcc.checkCycleDependent();

		System.assert(aptcc.getErrorMsg() != null, 'dependency check failed');

		Test.stopTest();
	}

	@IsTest
	private static void testItselfCyclicDependencyFail() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(2);

		APTTaskTemplate__c newAPTTask1 = new APTTaskTemplate__c();

		newAPTTask1.Subject__c = testUtil.createRandomWord('subject');
		newAPTTask1.DaysFromStart__c = 2;
		newAPTTask1.Dependent__c = '0';
		newAPTTask1.Type__c = 'Email';
		newAPTTask1.Priority__c = 'High';
		newAPTTask1.TaskIndex__c = 0;

		System.currentPageReference().getParameters().put('id', apTemplate.Id);
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));

		aptcc.aptTasks = new List<APTTaskTemplate__c>();
		aptcc.aptTasks.add(newAPTTask1);

		aptcc.checkCycleDependent();

		System.assert(aptcc.getErrorMsg() != null, 'dependency check failed');

		Test.stopTest();
	}

	@IsTest
	private static void testCyclicDependencySuccess() {
		Test.setCurrentPage(Page.ActionPlanTemplateCreation);
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(2);

		APTTaskTemplate__c newAPTTask1 = new APTTaskTemplate__c();
		APTTaskTemplate__c newAPTTask2 = new APTTaskTemplate__c();
		APTTaskTemplate__c newAPTTask3 = new APTTaskTemplate__c();
		APTTaskTemplate__c newAPTTask4 = new APTTaskTemplate__c();

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

		System.currentPageReference().getParameters().put('id', apTemplate.Id);
		ActionPlanTemplateCreationController aptcc = new ActionPlanTemplateCreationController(new ApexPages.StandardController(apTemplate));

		aptcc.aptTasks = new List<APTTaskTemplate__c>();
		aptcc.aptTasks.add(newAPTTask1);
		aptcc.aptTasks.add(newAPTTask2);
		aptcc.aptTasks.add(newAPTTask3);
		aptcc.aptTasks.add(newAPTTask4);

		aptcc.checkCycleDependent();
		System.assert(aptcc.getErrorMsg() != null, 'dependency check failed');

		System.currentPageReference().getParameters().put('remove', '1');
		aptcc.removeTemplateTask();
		aptcc.saveTemplate();

		Test.stopTest();
	}
}