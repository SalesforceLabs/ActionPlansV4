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
 * Tests for the Utilities class that handles Task updates
 * @author {@link [David Schach](https://github.com/dschach)}
 * @since 2022
 * @see ActionPlansTaskTriggerUtilities
 * @group Tests
 */
@IsTest
private class ActionPlansTaskTriggerUtilitiesTest {
	private static String testClosedStatus;
	/**
	 * test trigger without skipweekends method for testing Task After Update trigger when updating task to status 'Completed'
	 */
	@IsTest
	private static void testTaskAfterUpdateToCompleted() {
		List<String> closedStatuses = new List<String>(ActionPlansUtilities.getClosedTaskStatuses());
		String testClosedStatus = closedStatuses[0];

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c ap = testUtil.createNewActionPlan('account', 0);

		List<Id> apTTaskIds = new List<Id>();
		List<Task> apTaskList = new List<Task>();
		List<APTask__c> apttList = new List<APTask__c>();

		Id defaultRTID = ActionPlansUtilities.getDefaultTaskRecordTypeId();
		String atStatus = ActionPlansUtilities.getTaskRecordTypeStatusDefaultValues().get(defaultRTID);

		for (Integer i = 0; i < 4; i++) {
			APTask__c at = new APTask__c();
			at.Action_Plan__c = ap.Id;
			at.DaysFromStart__c = 2.0;
			at.User__c = testUtil.createTestUser().Id;
			at.SendEmail__c = false;
			if (i == 0) {
				at.SendEmail__c = true;
			}
			at.Subject__c = 'Test ' + i;
			at.Type__c = 'Email';
			at.Priority__c = 'Low';
			at.Controller__c = (i > 0) ? apttList[i - 1].Id : null;
			at.Status__c = atStatus;
			insert at; //NOPMD
			apttList.add(at);
			apTTaskIds.add(at.Id);

			if (i == 0) {
				Task x = new Task();
				x.Priority = at.Priority__c;
				x.TaskAPTask__c = at.Id;
				x.Subject = at.Subject__c;
				insert x; //NOPMD
			}
		}

		Test.startTest();
		apTaskList = [SELECT Status, Id FROM Task WHERE TaskAPTask__c IN :apTTaskIds];

		for (Task t : apTaskList) {
			t.Status = testClosedStatus;
		}

		update apTaskList;
		apTaskList = [SELECT Id FROM Task WHERE TaskAPTask__c = :apTTaskIds[0]];

		Test.stopTest();
		System.assert(!apTaskList.isEmpty(), 'We should have some records here');
	}

	/**
	 * test trigger AP Delete
	 */
	@IsTest
	private static void testActionPlanDelete() {
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c ap = testUtil.createNewActionPlan('contact', 0);
		ap.SkipWeekends__c = true;
		ap.SkipDay__c = 'End of previous week';
		update ap;

		List<Id> apTTaskIds = new List<Id>();
		List<Task> apTask = new List<Task>();
		List<APTask__c> aptt = new List<APTask__c>();

		Id defaultRTID = ActionPlansUtilities.getDefaultTaskRecordTypeId();
		String atStatus = ActionPlansUtilities.getTaskRecordTypeStatusDefaultValues().get(defaultRTID);

		Test.startTest();
		for (Integer i = 0; i < 4; i++) {
			APTask__c at = new APTask__c();
			at.Action_Plan__c = ap.Id;
			at.DaysFromStart__c = 2.0;
			at.User__c = testUtil.createTestUser().Id;
			at.SendEmail__c = false;
			at.Subject__c = 'Test ' + i;
			at.Type__c = 'Email';
			at.Priority__c = 'Low';
			at.Comments__c = 'My Comment';
			at.Reminder__c = true;
			at.Controller__c = (i > 0) ? aptt[i - 1].Id : null;
			at.Status__c = atStatus;
			insert at; //NOPMD
			aptt.add(at);
			apTTaskIds.add(at.Id);

			if (i == 0) {
				Task x = new Task();
				x.Priority = at.Priority__c;
				x.TaskAPTask__c = at.Id;
				x.Subject = at.Subject__c;
				insert x; //NOPMD
			}
		}

		delete ap;
		apTask = [SELECT Id FROM Task WHERE TaskAPTask__c = :apTTaskIds[1]];

		Test.stopTest();

		System.assert(apTask.isEmpty());
	}

	/**
	 * test trigger
	 */
	@IsTest
	private static void testAPTaskUpdate() {
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c ap = testUtil.createNewActionPlan('opportunity', 0);
		ap.SkipWeekends__c = true;
		ap.SkipDay__c = 'End of previous week';
		update ap;

		List<Id> apTTaskIds = new List<Id>();
		List<Task> apTask = new List<Task>();
		List<APTask__c> aptt = new List<APTask__c>();

		Id defaultRTID = ActionPlansUtilities.getDefaultTaskRecordTypeId();
		String atStatus = ActionPlansUtilities.getTaskRecordTypeStatusDefaultValues().get(defaultRTID);

		Test.startTest();
		for (Integer i = 0; i < 4; i++) {
			APTask__c at = new APTask__c();
			at.Action_Plan__c = ap.Id;
			at.DaysFromStart__c = 2.0;
			at.User__c = testUtil.createTestUser().Id;
			at.SendEmail__c = false;
			at.Subject__c = 'Test ' + i;
			at.Type__c = 'Email';
			at.Priority__c = 'Low';
			at.Comments__c = 'My Comment';
			at.Reminder__c = true;
			at.Minutes_Reminder__c = '510';
			at.Controller__c = (i > 0) ? aptt[i - 1].Id : null;
			at.Status__c = atStatus;
			insert at; //NOPMD
			aptt.add(at);
			apTTaskIds.add(at.Id);

			if (i == 0) {
				Task x = new Task();
				x.Priority = at.Priority__c;
				x.TaskAPTask__c = at.Id;
				x.Subject = at.Subject__c;
				insert x; //NOPMD
			}
		}

		List<String> closedStatuses = new List<String>(ActionPlansUtilities.getClosedTaskStatuses());
		String testClosedStatus = closedStatuses[0];

		apTask = [SELECT Status, Id FROM Task WHERE TaskAPTask__c IN :apTTaskIds];
		for (Task t : apTask) {
			t.Status = testClosedStatus;
		}
		update apTask;
		apTask = [SELECT Id FROM Task WHERE TaskAPTask__c = :apTTaskIds[0]];

		Test.stopTest();

		System.assert(!apTask.isEmpty());
	}

	/**
	 * 	test ActionPlanTaskTemplateTrigger
	 *	When the user undeletes an ActionPlan Task Template
	 */
	@IsTest
	private static void testAPTaskUndelete() {
		Test.startTest();
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();

		ActionPlan__c ap = testUtil.createNewActionPlan('contract', 1);
		ap.SkipWeekends__c = true;
		ap.SkipDay__c = 'End of previous week';
		update ap;

		// select the APTask
		APTask__c at = [SELECT Id, Subject__c, Priority__c, User__c FROM APTask__c WHERE Action_Plan__c = :ap.id LIMIT 1];

		// create the related Task
		Task t = new Task();
		t.Subject = at.Subject__c;
		t.Priority = at.Priority__c;
		t.OwnerId = at.User__c;
		t.TaskAPTask__c = at.Id;
		insert t;

		// delete the APTask
		delete at;

		List<APTask__c> apttDel = [SELECT Id FROM APTask__c WHERE Id = :at.Id];
		System.assert(apttDel.isEmpty());

		// undelete task and APTask and get exception
		List<Id> ids = new List<Id>();
		ids.add(t.Id);
		ids.add(at.Id);
		try {
			Database.undelete(ids);
		} catch (Dmlexception e) {
			System.assert(e.getMessage().containsIgnoreCase('BROKEN'), e.getMessage());
		}

		// now undelete and trigger the code
		if (![SELECT Id FROM APTask__c WHERE Id = :at.Id AND isDeleted = TRUE ALL ROWS].isEmpty()) {
			undelete at;
			List<APTask__c> apttUnDel = [SELECT Id FROM APTask__c WHERE Id = :at.Id];
			System.assertEquals(1, apttUnDel.size());
		}

		Test.stopTest();
	}

	/**
	 * 	test ActionPlanTaskTemplateTrigger
	 *	When the user undeletes an ActionPlan Task Template
	 */
	@IsTest
	private static void testAPTTemplateUndeleteException() {
		Test.startTest();
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();

		ActionPlan__c ap = testUtil.createNewActionPlan('campaign', 3);
		ap.SkipWeekends__c = true;
		ap.SkipDay__c = 'End of previous week';
		update ap;

		// select the APTask Template
		APTask__c at = [SELECT Id, Subject__c, Priority__c, User__c FROM APTask__c WHERE Action_Plan__c = :ap.id LIMIT 1];

		// create the related Task
		Task t = new Task();
		t.Subject = at.Subject__c;
		t.Priority = at.Priority__c;
		t.OwnerId = at.User__c;
		t.TaskAPTask__c = at.Id;
		insert t;

		List<Id> ids = new List<Id>();
		ids.add(at.Id);

		// delete the APTask Template
		delete at;
		Database.emptyRecycleBin(t);
		List<APTask__c> apttDel = [SELECT Id FROM APTask__c WHERE Id = :at.Id];
		System.assert(apttDel.isEmpty());

		// undelete task and APTask and get exception
		try {
			Database.undelete(ids);
		} catch (Dmlexception e) {
			//System.debug('Dmlexception: ' + e.getMessage());
			System.assert(e.getMessage().contains(System.Label.ap_Error), e.getMessage() + '(APTask__c undelete error should have the proper format)');
		}

		Test.stopTest();
	}
	/**
	 * method for testing Task  After Update trigger
	 * when updating task to status 'In progress'
	 */
	@IsTest
	private static void testTrigger6() {
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c ap = testUtil.createNewActionPlan('lead', 0);

		List<Id> apTTaskIds = new List<Id>();
		List<Task> apTask = new List<Task>();
		List<APTask__c> aptt = new List<APTask__c>();

		Test.startTest();
		for (Integer i = 0; i < 4; i++) {
			APTask__c at = new APTask__c();
			at.Action_Plan__c = ap.Id;
			at.DaysFromStart__c = 2.0;
			at.User__c = testUtil.createTestUser().Id;
			if (i == 0) {
				at.SendEmail__c = true;
			} else {
				at.SendEmail__c = false;
			}
			at.Subject__c = 'Test ' + i;
			at.Type__c = 'Email';
			at.Priority__c = 'Low';
			at.Controller__c = (i > 0) ? aptt[i - 1].Id : null;
			Id defaultRTID = ActionPlansUtilities.getDefaultTaskRecordTypeId();
			at.Status__c = ActionPlansUtilities.getTaskRecordTypeStatusDefaultValues().get(defaultRTID);
			insert at; //NOPMD
			aptt.add(at);
			apTTaskIds.add(at.Id);

			if (i == 0) {
				Task x = new Task();
				x.Priority = at.Priority__c;
				x.TaskAPTask__c = at.Id;
				x.Subject = at.Subject__c;
				insert x; //NOPMD
			}
		}

		apTask = [SELECT Status, Id FROM Task WHERE TaskAPTask__c IN :apTTaskIds];

		List<String> openStatuses = new List<String>(ActionPlansUtilities.getOpenTaskStatuses());
		String testOpenStatus = openStatuses[1];
		for (Task t : apTask) {
			t.Status = testOpenStatus;
		}

		update apTask;
		apTask = [SELECT Id FROM Task WHERE TaskAPTask__c = :apTTaskIds[0]];

		Test.stopTest();
		System.assert(!apTask.isEmpty());
	}

	/**
	 * method for testing Task before delete trigger
	 */
	@IsTest
	private static void testTaskBeforeDelete() {
		Test.startTest();
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c ap = testUtil.createNewActionPlan('account', 0);

		Id testUserId = testUtil.createTestUser().Id;
		Id defaultRTID = ActionPlansUtilities.getDefaultTaskRecordTypeId();
		String atStatus = ActionPlansUtilities.getTaskRecordTypeStatusDefaultValues().get(defaultRTID);

		//Task Template 1
		APTask__c at = new APTask__c();
		at.Action_Plan__c = ap.Id;
		at.DaysFromStart__c = 2;
		at.SendEmail__c = false;
		at.Subject__c = 'Test1';
		at.Type__c = 'Email';
		at.Priority__c = 'Low';
		at.Controller__c = null;
		at.TaskIndex__c = 0;
		at.Status__c = atStatus;
		insert at;
		//Task Template 2
		APTask__c at2 = new APTask__c();
		at2.Action_Plan__c = ap.Id;
		at2.DaysFromStart__c = 2;
		at2.User__c = testUserId;
		at2.SendEmail__c = true;
		at2.Subject__c = 'Test2';
		at2.Type__c = 'Email';
		at2.Priority__c = 'Low';
		at2.Controller__c = at.Id;
		at2.Dependent__c = '0';
		at2.TaskIndex__c = 1;
		at2.Status__c = atStatus;
		insert at2;

		//create task for task template 1
		Task x = new Task();
		if (ActionPlansUtilities.taskUsesRecordTypes) {
			x.put('RecordTypeId', ActionPlansUtilities.getDefaultTaskRecordTypeId());
		}
		x.Priority = at.Priority__c;
		x.Status = ActionPlansUtilities.getTaskRecordTypeStatusDefaultValues().get(ActionPlansUtilities.getDefaultTaskRecordTypeId());
		x.TaskAPTask__c = at.Id;
		x.Subject = at.Subject__c;
		x.WhatId = [SELECT Id FROM Account LIMIT 1].Id;
		insert x;

		x = [SELECT Id, Status, Subject, TaskAPTask__r.Name, WhatId FROM Task WHERE Id = :x.Id LIMIT 1];

		List<String> closedStatuses = new List<String>(ActionPlansUtilities.getClosedTaskStatuses());
		String testClosedStatus = closedStatuses[0];

		x.Status = testClosedStatus;
		update x;
		Test.stopTest();

		delete x;

		//check if the dependent task was created
		List<Task> newTaskList = [SELECT Status, Id FROM Task WHERE TaskAPTask__c = :at2.Id];
		System.assert(!newTaskList.isEmpty());
		newTaskList = [SELECT Id FROM Task WHERE IsClosed = FALSE];
		System.assertEquals(1, newTaskList.size());
	}
}