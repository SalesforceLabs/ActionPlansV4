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
 * Test for Batch Task Builder Apex
 * @group Batch Apex
 */
@IsTest
private class ActionPlansBatchTaskBuilderTest {
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
		ActionPlansBatchTaskBuilder testBatch = new ActionPlansBatchTaskBuilder(testutil.batchIds('account'));
		Id batchID = Database.executeBatch(testBatch, 20);
		Test.stopTest();

		AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :batchId];
		System.AssertEquals('Completed', a.status);
		System.AssertEquals(0, a.NumberOfErrors);
	}

	@IsTest
	private static void runBatchContact() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();

		Test.startTest();
		ActionPlansBatchTaskBuilder testBatch = new ActionPlansBatchTaskBuilder(testutil.batchIds('contact'));
		Id batchID = Database.executeBatch(testBatch, 20);
		Test.stopTest();

		AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :batchId];
		System.AssertEquals('Completed', a.status);
		System.AssertEquals(0, a.NumberOfErrors);
	}

	@IsTest
	private static void runBatchOpportunity() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();

		Test.startTest();
		ActionPlansBatchTaskBuilder testBatch = new ActionPlansBatchTaskBuilder(testutil.batchIds('opportunity'));
		Id batchID = Database.executeBatch(testBatch, 20);
		Test.stopTest();

		AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :batchId];
		System.AssertEquals('Completed', a.status);
		System.AssertEquals(0, a.NumberOfErrors);
	}

	@IsTest
	private static void runBatchLead() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();

		Test.startTest();
		ActionPlansBatchTaskBuilder testBatch = new ActionPlansBatchTaskBuilder(testutil.batchIds('lead'));
		Id batchID = Database.executeBatch(testBatch, 20);
		Test.stopTest();

		AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :batchId];
		System.AssertEquals('Completed', a.status);
		System.AssertEquals(0, a.NumberOfErrors);
	}

	@IsTest
	private static void runBatchCampaign() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();

		Test.startTest();
		ActionPlansBatchTaskBuilder testBatch = new ActionPlansBatchTaskBuilder(testutil.batchIds('campaign'));
		Id batchID = Database.executeBatch(testBatch, 20);
		Test.stopTest();

		AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :batchId];
		System.AssertEquals('Completed', a.status);
		System.AssertEquals(0, a.NumberOfErrors);
	}

	@IsTest
	private static void runBatchCase() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();

		Test.startTest();
		ActionPlansBatchTaskBuilder testBatch = new ActionPlansBatchTaskBuilder(testutil.batchIds('case'));
		Id batchID = Database.executeBatch(testBatch, 20);
		Test.stopTest();

		AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :batchId];
		System.AssertEquals('Completed', a.status);
		System.AssertEquals(0, a.NumberOfErrors);
	}

	@IsTest
	private static void runBatchContract() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();

		Test.startTest();
		ActionPlansBatchTaskBuilder testBatch = new ActionPlansBatchTaskBuilder(testutil.batchIds('contract'));
		Id batchID = Database.executeBatch(testBatch, 20);
		Test.stopTest();

		AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :batchId];
		System.AssertEquals('Completed', a.status);
		System.AssertEquals(0, a.NumberOfErrors);
	}
}