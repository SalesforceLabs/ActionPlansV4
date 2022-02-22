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
 * Test class for Batch Delete class
 * @author {@link [David Schach](https://github.com/dschach)}
 * @group Batch Apex
 */
@IsTest
private class ActionPlansBatchDeleteTest {
	@IsTest
	private static void testDelete() {
		Test.startTest();

		ActionPlansTestUtilities aptu = new ActionPlansTestUtilities();
		ActionPlan__c ap = aptu.createNewActionPlan('account', 1);

		Set<Id> sIDs = new Set<Id>();
		sIDs.add(ap.Id);

		ActionPlansBatchDelete taskBatch = new ActionPlansBatchDelete(sIDs);
		Database.ExecuteBatch(taskBatch);

		Test.stopTest();

		System.assert([SELECT Id FROM ActionPlan__c].isEmpty());
	}

	@IsTest
	private static void testFutureDelete() {
		Test.startTest();

		ActionPlansTestUtilities aptu = new ActionPlansTestUtilities();
		ActionPlan__c ap = aptu.createNewActionPlan('account', 1);

		Set<Id> sIDs = new Set<Id>();
		sIDs.add(ap.Id);

		delete ap;

		Test.stopTest();

		System.assert([SELECT Id FROM ActionPlan__c].isEmpty());
	}

	@IsTest
	private static void testDeleteException() {
		Test.startTest();

		ActionPlansTestUtilities.forceError = true;

		ActionPlansTestUtilities aptu = new ActionPlansTestUtilities();
		ActionPlan__c ap = aptu.createNewActionPlan('account', 1);

		Set<Id> sIDs = new Set<Id>();
		sIDs.add(ap.Id);

		ActionPlansBatchDelete taskBatch = new ActionPlansBatchDelete(sIDs);
		Database.ExecuteBatch(taskBatch);

		Test.stopTest();

		System.assert([SELECT Id FROM ActionPlan__c].isEmpty());
	}

	@IsTest
	private static void testUnDelete() {
		Test.startTest();

		ActionPlansTestUtilities aptu = new ActionPlansTestUtilities();
		ActionPlan__c ap = aptu.createNewActionPlan('account', 1);

		APTask__c at = new APTask__c();
		at.Action_Plan__c = ap.Id;
		at.Dependent__c = 'None';
		at.DaysFromStart__c = 2.0;
		at.User__c = Userinfo.getUserId();
		at.SendEmail__c = false;
		at.Subject__c = 'Test ';
		at.Type__c = 'Email';
		at.Priority__c = 'Low';
		at.Comments__c = 'Test';
		at.Reminder__c = true;
		at.Minutes_Reminder__c = '510';
		insert at;

		at = new APTask__c();
		at.Action_Plan__c = ap.Id;
		at.Dependent__c = 'None';
		at.DaysFromStart__c = 2.0;
		at.User__c = Userinfo.getUserId();
		at.SendEmail__c = true;
		at.Subject__c = 'Test ';
		at.Type__c = 'Email';
		at.Priority__c = 'Low';
		at.Comments__c = 'Test';
		at.Reminder__c = true;
		at.Minutes_Reminder__c = '510';
		insert at;

		Task x = new Task();
		x.Priority = at.Priority__c;
		x.TaskAPTask__c = at.Id;
		x.Subject = at.Subject__c;
		insert x;

		Set<Id> sIDs = new Set<Id>();
		sIDs.add(ap.Id);

		ActionPlansBatchDelete taskBatch = new ActionPlansBatchDelete(sIDs);
		Database.ExecuteBatch(taskBatch);

		Test.stopTest();
		undelete ap;

		System.assert(![SELECT Id FROM ActionPlan__c].isEmpty());
	}
}