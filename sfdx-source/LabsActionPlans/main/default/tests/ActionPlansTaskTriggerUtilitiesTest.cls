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
 * @group Tests
 */
@IsTest
private class ActionPlansTaskTriggerUtilitiesTest {
	static String testClosedStatus;
	/**
	test trigger without skipweekends
	method for testing Task After Update trigger
	when updating task to status 'Completed'
	*/

	@IsTest
	private static void testTaskAfterUpdateToCompleted() {
		List<String> closedStatuses = new List<String>(ActionPlansUtilities.getClosedTaskStatuses());
		String testClosedStatus = closedStatuses[0];

		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		ActionPlan__c ap = testutil.createNewActionPlan('account', 0);

		List<Id> apTTaskIds = new List<Id>();
		List<Task> apTaskList = new List<Task>();
		List<APTaskTemplate__c> apttList = new List<APTaskTemplate__c>();

		for (Integer i = 0; i < 4; i++) {
			APTaskTemplate__c at = new APTaskTemplate__c();
			at.Action_Plan__c = ap.Id;
			at.DaysFromStart__c = 2.0;
			at.User__c = testutil.createTestUser().Id;
			at.SendEmail__c = false;
			if (i == 0) {
				at.SendEmail__c = true;
			}
			at.Subject__c = 'Test ' + i;
			at.Type__c = 'Email';
			at.Priority__c = 'Low';
			at.Controller__c = (i > 0) ? apttList[i - 1].Id : null;
			insert at;
			apttList.add(at);
			apTTaskIds.add(at.Id);

			if (i == 0) {
				Task x = new Task();
				x.Priority = at.Priority__c;
				x.TaskAPTaskTemplate__c = at.Id;
				x.Subject = at.Subject__c;
				insert x;
			}
		}

		Test.startTest();
		apTaskList = [SELECT Status, Id FROM Task WHERE TaskAPTaskTemplate__c IN :apTTaskIds];

		for (Task t : apTaskList) {
			t.Status = testClosedStatus;
		}

		update apTaskList;
		apTaskList = [SELECT Id FROM Task WHERE TaskAPTaskTemplate__c = :apTTaskIds[0]];

		Test.stopTest();
		System.assert(!apTaskList.isEmpty());
	}

	/**
	 * test trigger AP Delete
	 */
	@IsTest
	private static void testActionPlanDelete() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		ActionPlan__c ap = testutil.createNewActionPlan('contact', 0);
		ap.SkipWeekends__c = true;
		ap.SkipDay__c = 'End of previous week';
		update ap;

		List<Id> apTTaskIds = new List<Id>();
		List<Task> apTask = new List<Task>();
		List<APTaskTemplate__c> aptt = new List<APTaskTemplate__c>();

		Test.startTest();
		for (Integer i = 0; i < 4; i++) {
			APTaskTemplate__c at = new APTaskTemplate__c();
			at.Action_Plan__c = ap.Id;
			at.DaysFromStart__c = 2.0;
			at.User__c = testutil.createTestUser().Id;
			at.SendEmail__c = false;
			at.Subject__c = 'Test ' + i;
			at.Type__c = 'Email';
			at.Priority__c = 'Low';
			at.Comments__c = 'My Comment';
			at.Reminder__c = true;
			at.Controller__c = (i > 0) ? aptt[i - 1].Id : null;
			insert at;
			aptt.add(at);
			apTTaskIds.add(at.Id);

			if (i == 0) {
				Task x = new Task();
				x.Priority = at.Priority__c;
				x.TaskAPTaskTemplate__c = at.Id;
				x.Subject = at.Subject__c;
				insert x;
			}
		}

		delete ap;
		apTask = [SELECT Id FROM Task WHERE TaskAPTaskTemplate__c = :apTTaskIds[1]];

		Test.stopTest();

		System.assert(apTask.isEmpty());
	}

	/**
	 * test trigger
	 */
	@IsTest
	private static void testAPTTemplateUpdate() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		ActionPlan__c ap = testutil.createNewActionPlan('opportunity', 0);
		ap.SkipWeekends__c = true;
		ap.SkipDay__c = 'End of previous week';
		update ap;

		List<Id> apTTaskIds = new List<Id>();
		List<Task> apTask = new List<Task>();
		List<APTaskTemplate__c> aptt = new List<APTaskTemplate__c>();

		Test.startTest();
		for (Integer i = 0; i < 4; i++) {
			APTaskTemplate__c at = new APTaskTemplate__c();
			at.Action_Plan__c = ap.Id;
			at.DaysFromStart__c = 2.0;
			at.User__c = testutil.createTestUser().Id;
			at.SendEmail__c = false;
			at.Subject__c = 'Test ' + i;
			at.Type__c = 'Email';
			at.Priority__c = 'Low';
			at.Comments__c = 'My Comment';
			at.Reminder__c = true;
			at.Minutes_Reminder__c = '510';
			at.Controller__c = (i > 0) ? aptt[i - 1].Id : null;
			insert at;
			aptt.add(at);
			apTTaskIds.add(at.Id);

			if (i == 0) {
				Task x = new Task();
				x.Priority = at.Priority__c;
				x.TaskAPTaskTemplate__c = at.Id;
				x.Subject = at.Subject__c;
				insert x;
			}
		}

		List<String> closedStatuses = new List<String>(ActionPlansUtilities.getClosedTaskStatuses());
		String testClosedStatus = closedStatuses[0];

		apTask = [SELECT Status, Id FROM Task WHERE TaskAPTaskTemplate__c IN :apTTaskIds];
		for (Task t : apTask) {
			t.Status = testClosedStatus;
		}
		update apTask;
		apTask = [SELECT Id FROM Task WHERE TaskAPTaskTemplate__c = :apTTaskIds[0]];

		Test.stopTest();

		System.assert(!apTask.isEmpty());
	}

	/**
	 * 	test ActionPlanTaskTemplateTrigger
	 *	When the user undeletes an ActionPlan Task Template
	 */
	@IsTest
	private static void testAPTTUndelete() {
		Test.startTest();
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();

		ActionPlan__c ap = testutil.createNewActionPlan('contract', 1);
		ap.SkipWeekends__c = true;
		ap.SkipDay__c = 'End of previous week';
		update ap;

		// select the APTask Template
		APTaskTemplate__c at = [SELECT Id, Subject__c, Priority__c, User__c FROM APTaskTemplate__c WHERE Action_Plan__c = :ap.id LIMIT 1];

		// create the related Task
		Task t = new Task();
		t.Subject = at.Subject__c;
		t.Priority = at.Priority__c;
		t.OwnerId = at.User__c;
		t.TaskAPTaskTemplate__c = at.Id;
		insert t;

		// delete the APTask Template
		delete at;

		List<APTaskTemplate__c> apttDel = [SELECT Id FROM APTaskTemplate__c WHERE Id = :at.Id];
		System.assert(apttDel.size() == 0);

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
		if ([SELECT Id FROM APTaskTemplate__c WHERE Id = :at.Id AND isDeleted = TRUE].isEmpty()) {
			undelete at;
			List<APTaskTemplate__c> apttUnDel = [SELECT Id FROM APTaskTemplate__c WHERE Id = :at.Id];
			System.assert(apttUnDel.size() == 1);
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
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();

		ActionPlan__c ap = testutil.createNewActionPlan('campaign', 3);
		ap.SkipWeekends__c = true;
		ap.SkipDay__c = 'End of previous week';
		update ap;

		// select the APTask Template
		APTaskTemplate__c at = [SELECT Id, Subject__c, Priority__c, User__c FROM APTaskTemplate__c WHERE Action_Plan__c = :ap.id LIMIT 1];

		// create the related Task
		Task t = new Task();
		t.Subject = at.Subject__c;
		t.Priority = at.Priority__c;
		t.OwnerId = at.User__c;
		t.TaskAPTaskTemplate__c = at.Id;
		insert t;

		List<Id> ids = new List<Id>();
		ids.add(at.Id);

		// delete the APTask Template
		delete at;
		Database.emptyRecycleBin(t);
		List<APTaskTemplate__c> apttDel = [SELECT Id FROM APTaskTemplate__c WHERE Id = :at.Id];
		System.assert(apttDel.size() == 0);

		// undelete task and APTask and get exception
		try {
			Database.undelete(ids);
		} catch (Dmlexception e) {
			System.debug('Dmlexception: ' + e.getMessage());
			System.assert(e.getMessage().contains(System.Label.ap_Error), e.getMessage() + '(APTaskTemplate__c undelete error should have the proper format)');
		}

		Test.stopTest();
	}
	/*
	method for testing Task  After Update trigger
	when updating task to status 'In progress'
	*/
	@IsTest
	private static void testTrigger6() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		ActionPlan__c ap = testutil.createNewActionPlan('lead', 0);

		List<Id> apTTaskIds = new List<Id>();
		List<Task> apTask = new List<Task>();
		List<APTaskTemplate__c> aptt = new List<APTaskTemplate__c>();

		Test.startTest();
		for (Integer i = 0; i < 4; i++) {
			APTaskTemplate__c at = new APTaskTemplate__c();
			at.Action_Plan__c = ap.Id;
			at.DaysFromStart__c = 2.0;
			at.User__c = testutil.createTestUser().Id;
			if (i == 0) {
				at.SendEmail__c = true;
			} else {
				at.SendEmail__c = false;
			}
			at.Subject__c = 'Test ' + i;
			at.Type__c = 'Email';
			at.Priority__c = 'Low';
			at.Controller__c = (i > 0) ? aptt[i - 1].Id : null;
			insert at;
			aptt.add(at);
			apTTaskIds.add(at.Id);

			if (i == 0) {
				Task x = new Task();
				x.Priority = at.Priority__c;
				x.TaskAPTaskTemplate__c = at.Id;
				x.Subject = at.Subject__c;
				insert x;
			}
		}

		apTask = [SELECT Status, Id FROM Task WHERE TaskAPTaskTemplate__c IN :apTTaskIds];

		List<String> openStatuses = new List<String>(ActionPlansUtilities.getOpenTaskStatuses());
		String testOpenStatus = openStatuses[1];
		for (Task t : apTask) {
			t.Status = testOpenStatus;
		}

		update apTask;
		apTask = [SELECT Id FROM Task WHERE TaskAPTaskTemplate__c = :apTTaskIds[0]];

		Test.stopTest();
		System.assert(!apTask.isEmpty());
	}

	/*
	 * method for testing Task before delete trigger
	 */
	@IsTest
	private static void testTaskBeforeDelete() {
		Test.startTest();
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		ActionPlan__c ap = testutil.createNewActionPlan('account', 0);

		Id testUserId = testutil.createTestUser().Id;

		//Task Template 1
		APTaskTemplate__c at = new APTaskTemplate__c();
		at.Action_Plan__c = ap.Id;
		at.DaysFromStart__c = 2;
		at.SendEmail__c = false;
		at.Subject__c = 'Test1';
		at.Type__c = 'Email';
		at.Priority__c = 'Low';
		at.Controller__c = null;
		at.TaskIndex__c = 0;
		insert at;
		//Task Template 2
		APTaskTemplate__c at2 = new APTaskTemplate__c();
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
		insert at2;

		//create task for task template 1
		Task x = new Task();
		if (ActionPlansUtilities.HAS_RECORD_TYPE) {
			x.put('RecordTypeId', ActionPlansUtilities.getDefaultTaskRecordTypeId());
		}
		x.Priority = at.Priority__c;
		x.Status = ActionPlansUtilities.getTaskRecordTypeStatusDefaultValues().get(ActionPlansUtilities.getDefaultTaskRecordTypeId());
		x.TaskAPTaskTemplate__c = at.Id;
		x.Subject = at.Subject__c;
		x.WhatId = [SELECT Id FROM Account LIMIT 1].Id;
		insert x;

		x = [SELECT Id, Status, Subject, TaskAPTaskTemplate__r.Name, WhatId FROM Task WHERE Id = :x.Id LIMIT 1];

		List<String> closedStatuses = new List<String>(ActionPlansUtilities.getClosedTaskStatuses());
		String testClosedStatus = closedStatuses[0];

		x.Status = testClosedStatus;
		update x;
		Test.stopTest();

		delete x;

		//check if the dependent task was created
		List<Task> newTaskList = [SELECT Status, Id FROM Task WHERE TaskAPTaskTemplate__c = :at2.Id];
		System.assert(!newTaskList.isEmpty());
		newTaskList = [SELECT Id FROM Task WHERE IsClosed = FALSE];
		System.assertEquals(1, newTaskList.size());
	}
}