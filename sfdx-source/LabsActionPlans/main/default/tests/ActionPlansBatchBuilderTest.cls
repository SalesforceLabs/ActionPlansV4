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
 * \Test for Action Plans Batch Builder
 * @group Batch Apex
 */
@IsTest
private class ActionPlansBatchBuilderTest {
	@TestSetup
	static void makeData() {
		Action_Plans_Settings__c aps = Action_Plans_Settings__c.getOrgDefaults();
		aps.Chatter_Object_Brag__c = true;
		try {
			upsert aps;
		} catch (Exception e) {
			update aps;
		}
	}

	@IsTest
	private static void runBatchAccount() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();

		Test.startTest();

		ActionPlan__c ap = testutil.createNewActionPlan('account', 2);
		ap.Name = 'check_undelete';
		List<APTaskTemplate__c> apTasks = new List<APTaskTemplate__c>();
		User u = testutil.createTestUser();

		APTaskTemplate__c at = new APTaskTemplate__c();
		at.Action_Plan__c = ap.Id;
		at.Dependent__c = 'None';
		at.DaysFromStart__c = 2.0;
		at.User__c = u.Id;
		at.SendEmail__c = false;
		at.Subject__c = 'Test ';
		at.Type__c = 'Email';
		at.Priority__c = 'Low';
		at.Comments__c = 'Test';
		at.Reminder__c = true;
		at.Minutes_Reminder__c = '510';
		insert at;
		apTasks.add(at);

		at = new APTaskTemplate__c();
		at.Action_Plan__c = ap.Id;
		at.Dependent__c = 'None';
		at.DaysFromStart__c = 2.0;
		at.User__c = u.Id;
		at.SendEmail__c = true;
		at.Subject__c = 'Test ';
		at.Type__c = 'Email';
		at.Priority__c = 'Low';
		at.Comments__c = 'Test';
		at.Reminder__c = true;
		at.Minutes_Reminder__c = '510';
		insert at;
		apTasks.add(at);

		Account ac = new Account();
		ac.Name = 'Doe';
		insert ac;

		Account ac1 = new Account();
		ac1.Name = 'Doe';
		insert ac1;

		Set<Id> oIdsList = new Set<Id>();
		oIdsList.add(ac.Id);
		oIdsList.add(ac1.Id);

		ActionPlansBatchBuilder testBatch = new ActionPlansBatchBuilder(ap, apTasks, 'Account', oIdsList);
		ID batchID = Database.executeBatch(testBatch, 20);
		Test.stopTest();

		AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :batchId];
		System.AssertEquals('Completed', a.status);
		System.AssertEquals(0, a.NumberOfErrors);
	}

	@IsTest
	private static void runBatchContact() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();

		Test.startTest();

		ActionPlan__c ap = testutil.createNewActionPlan('contact', 2);
		List<APTaskTemplate__c> apTasks = new List<APTaskTemplate__c>();
		User u = testutil.createTestUser();

		APTaskTemplate__c at = new APTaskTemplate__c();
		at.Action_Plan__c = ap.Id;
		at.Dependent__c = 'None';
		at.DaysFromStart__c = 2.0;
		at.User__c = u.Id;
		at.SendEmail__c = false;
		at.Subject__c = 'Test ';
		at.Type__c = 'Email';
		at.Priority__c = 'Low';
		at.Comments__c = 'Test';
		at.Reminder__c = true;
		at.Minutes_Reminder__c = '510';
		insert at;
		apTasks.add(at);

		at = new APTaskTemplate__c();
		at.Action_Plan__c = ap.Id;
		at.Dependent__c = 'None';
		at.DaysFromStart__c = 2.0;
		at.User__c = u.Id;
		at.SendEmail__c = true;
		at.Subject__c = 'Test ';
		at.Type__c = 'Email';
		at.Priority__c = 'Low';
		at.Comments__c = 'Test';
		at.Reminder__c = true;
		at.Minutes_Reminder__c = '510';
		insert at;
		apTasks.add(at);

		Contact op = new Contact();
		op.LastName = 'Doe';
		insert op;

		Contact op2 = new Contact();
		op2.LastName = 'Doe';
		insert op2;

		Set<Id> oIdsList = new Set<Id>();
		oIdsList.add(op.Id);
		oIdsList.add(op2.Id);

		ActionPlansBatchBuilder testBatch = new ActionPlansBatchBuilder(ap, apTasks, 'Contact', oIdsList);
		ID batchID = Database.executeBatch(testBatch, 20);
		Test.stopTest();

		AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :batchId];
		System.AssertEquals('Completed', a.status);
		System.AssertEquals(0, a.NumberOfErrors);
	}

	@IsTest
	private static void runBatchOpportunity() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();

		Test.startTest();

		ActionPlan__c ap = testutil.createNewActionPlan('opportunity', 2);
		List<APTaskTemplate__c> apTasks = new List<APTaskTemplate__c>();

		APTaskTemplate__c at = new APTaskTemplate__c();
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
		insert at;
		apTasks.add(at);

		at = new APTaskTemplate__c();
		at.Action_Plan__c = ap.Id;
		at.Dependent__c = 'None';
		at.DaysFromStart__c = 2.0;
		at.User__c = testutil.createTestUser().Id;
		at.SendEmail__c = true;
		at.Subject__c = 'Test ';
		at.Type__c = 'Email';
		at.Priority__c = 'Low';
		at.Comments__c = 'Test';
		at.Reminder__c = true;
		at.Minutes_Reminder__c = '510';
		insert at;
		apTasks.add(at);

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

		ActionPlansBatchBuilder testBatch = new ActionPlansBatchBuilder(ap, apTasks, 'Opportunity', oIdsList);
		ID batchID = Database.executeBatch(testBatch, 20);
		Test.stopTest();

		AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :batchId];
		System.AssertEquals('Completed', a.status);
		System.AssertEquals(0, a.NumberOfErrors);
	}

	@IsTest
	private static void runBatchException() {
		ActionPlansTestUtilities.forceError = true;
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();

		Test.startTest();

		ActionPlan__c ap = testutil.createNewActionPlan('opportunity', 2);
		List<APTaskTemplate__c> apTasks = new List<APTaskTemplate__c>();

		APTaskTemplate__c at = new APTaskTemplate__c();
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
		insert at;
		apTasks.add(at);

		at = new APTaskTemplate__c();
		at.Action_Plan__c = ap.Id;
		at.Dependent__c = 'None';
		at.DaysFromStart__c = 2.0;
		at.User__c = testutil.createTestUser().Id;
		at.SendEmail__c = true;
		at.Subject__c = 'Test ';
		at.Type__c = 'Email';
		at.Priority__c = 'Low';
		at.Comments__c = 'Test';
		at.Reminder__c = true;
		at.Minutes_Reminder__c = '510';
		insert at;
		apTasks.add(at);

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

		ActionPlansBatchBuilder testBatch = new ActionPlansBatchBuilder(ap, apTasks, 'Opportunity', oIdsList);
		ID batchID = Database.executeBatch(testBatch, 20);

		Test.stopTest();

		AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :batchId];
		System.AssertEquals('Completed', a.status);
		System.AssertEquals(0, a.NumberOfErrors);
	}
}