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
 * Test for Action Plans Queueable Builder
 * @author {@link [David Schach](https://github.com/dschach)}
 * @group Tests
 * @see ActionPlansQueuableBuilder
 */
@IsTest
private class ActionPlansQueueableBuilderTest {
	@TestSetup
	private static void makeData() {
		Action_Plans_Settings__c aps = Action_Plans_Settings__c.getOrgDefaults();
		aps.Chatter_Object_Brag__c = true;
		try {
			upsert aps;
		} catch (Exception e) {
			update aps;
		}
	}

	@IsTest
	private static void runQueueContact() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();

		Test.startTest();

		ActionPlan__c ap = testutil.createNewActionPlan('contact', 5);
		List<APTask__c> apTasks = [
			SELECT
				Action_Plan__c,
				ActivityDate__c,
				Comments__c,
				Controller__c,
				DaysFromStart__c,
				Dependent__c,
				Id,
				IsClosed__c,
				Minutes_Reminder__c,
				Name,
				Priority__c,
				Reminder__c,
				SendEmail__c,
				Status__c,
				Subject__c,
				TaskIndex__c,
				Task_RecordTypeId__c,
				Time_Reminder__c,
				Type__c,
				User__c
			FROM APTask__c
		];

		Contact op = new Contact();
		op.LastName = 'Doe';
		insert op;

		Contact op2 = new Contact();
		op2.LastName = 'Doe';
		insert op2;

		Set<Id> oIdsList = new Set<Id>();
		oIdsList.add(op.Id);
		oIdsList.add(op2.Id);

		ActionPlansQueueableBuilder testQueue = new ActionPlansQueueableBuilder(ap, apTasks, 'Contact', oIdsList);
		Id queueID = System.enqueueJob(testQueue);
		Test.stopTest();

		AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :queueId];
		System.assertEquals('Completed', a.status);
		System.assertEquals(0, a.NumberOfErrors);
	}

	@IsTest
	private static void runQueueException() {
		ActionPlansTestUtilities.forceError = true;
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();

		Test.startTest();

		ActionPlan__c ap = testutil.createNewActionPlan('opportunity', 5);
		List<APTask__c> apTasks = new List<APTask__c>();

		Opportunity op = new Opportunity();
		op.Name = 'Op1';
		op.StageName = 'Won';
		op.CloseDate = Date.today();
		insert op;

		Opportunity op2 = new Opportunity();
		op2.Name = 'Op2';
		op2.StageName = 'Won';
		op2.CloseDate = Date.today();
		insert op2;

		Set<Id> oIdsList = new Set<Id>();
		oIdsList.add(op.Id);
		oIdsList.add(op2.Id);

		ActionPlansQueueableBuilder testQueue = new ActionPlansQueueableBuilder(ap, apTasks, 'Opportunity', oIdsList);
		Id queueID = System.enqueueJob(testQueue);

		Test.stopTest();

		AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :queueId];
		System.assertEquals('Completed', a.status);
		System.assertEquals(0, a.NumberOfErrors);
	}
}