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
 * @group Tests
 */
@IsTest
private class ActionPlansDeleteMultipleAPExtTest {
	private static final Integer APS_TO_CREATE = 100;

	@testSetup
	public static void setupdata() {
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();

		List<ActionPlan__c> apToInsert = new List<ActionPlan__c>();
		List<APTaskTemplate__c> apttToInsert = new List<APTaskTemplate__c>();

		Account a = testUtil.createNewAccount();

		for (Integer i = 0; i < 100; i++) {
			ActionPlan__c newActionPlan = new ActionPlan__c();
			newActionPlan.Name = testUtil.createRandomWord();
			newActionPlan.StartDate__c = Date.today();
			newActionPlan.OwnerId = Userinfo.getUserId();
			newActionPlan.Account__c = a.Id;
			apToInsert.add(newActionPlan);
		}
		insert apToInsert;

		for (ActionPlan__c newActionPlan : apToInsert) {
			for (Integer j = 0; j < 5; j++) {
				APTaskTemplate__c newAPTask = new APTaskTemplate__c();
				newAPTask.Subject__c = testUtil.createRandomWord();
				newAPTask.DaysFromStart__c = j + 1;
				newAPTask.Action_Plan__c = newActionPlan.Id;
				newAPTask.User__c = UserInfo.getUserId();
				newAPTask.Type__c = 'Call';
				newAPTask.Priority__c = (String) Task.Priority.getDescribe().getDefaultValue();
				newAPTask.Minutes_Reminder__c = '510';
				apttToInsert.add(newAPTask);
			}
		}

		insert apttToInsert;
	}

	@IsTest
	public static void givenRecordsToDeleteThenDeleted() {
		List<ActionPlan__c> listActionPlan = [SELECT Id, Name FROM ActionPlan__c];
		System.assertEquals(APS_TO_CREATE, [SELECT COUNT() FROM ActionPlan__c]);
		ApexPages.StandardSetController std = new ApexPages.StandardSetController(listActionPlan);
		std.setSelected(new List<ActionPlan__c>{ listActionPlan[0], listActionPlan[1] });
		ActionPlansDeleteMultipleAPExtension ctrl = new ActionPlansDeleteMultipleAPExtension(std);

		Test.startTest();
		ctrl.deleteRecords();
		Test.stopTest();
		System.assertEquals(APS_TO_CREATE - 2, [SELECT COUNT() FROM ActionPlan__c]);
	}

	@IsTest
	public static void givenNoRecordsToDeleteThenNotDeleted() {
		List<ActionPlan__c> listActionPlan = [SELECT Id, Name FROM ActionPlan__c];
		System.assertEquals(APS_TO_CREATE, [SELECT COUNT() FROM ActionPlan__c]);
		ApexPages.StandardSetController std = new ApexPages.StandardSetController(listActionPlan);
		std.setSelected(new List<ActionPlan__c>{});
		ActionPlansDeleteMultipleAPExtension ctrl = new ActionPlansDeleteMultipleAPExtension(std);

		Test.startTest();
		ctrl.deleteRecords();
		Test.stopTest();

		System.assertEquals(APS_TO_CREATE, [SELECT COUNT() FROM ActionPlan__c]);
		System.assertEquals(null, ctrl.deleteRecords());
	}

	@IsTest
	private static void noDeletePermission() {
		Id pId = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce'].Id;
		User minAccessUser = new User(
			profileId = pId,
			LastName = 'last',
			Email = 'Testuser@test.example.com',
			Username = 'Testuser@test.example.com' + Crypto.getRandomInteger(),
			CompanyName = 'TEST',
			Title = 'title',
			Alias = 'alias',
			TimeZoneSidKey = 'America/Los_Angeles',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US'
		);
		insert minAccessUser;

		PermissionSet ps = new PermissionSet(Label = 'testPermSet', Name = 'testPermSet');
		insert ps;
		ObjectPermissions op = new ObjectPermissions(ParentId = ps.Id, SobjectType = ActionPlansUtilities.namespacePrefix + 'ActionPlan__c');
		op.PermissionsRead = true;
		op.PermissionsViewAllRecords = true;
		insert op;
		insert new PermissionSetAssignment(PermissionSetId = ps.Id, AssigneeId = minAccessUser.Id);

		System.runAs(minAccessUser) {
			List<ActionPlan__c> listActionPlan = [SELECT Id, Name FROM ActionPlan__c];
			System.assertEquals(APS_TO_CREATE, [SELECT COUNT() FROM ActionPlan__c]);
			ApexPages.StandardSetController std = new ApexPages.StandardSetController(listActionPlan);
			std.setSelected(new List<ActionPlan__c>{ listActionPlan[0], listActionPlan[1] });
			ActionPlansDeleteMultipleAPExtension ctrl = new ActionPlansDeleteMultipleAPExtension(std);
			Test.startTest();
			ctrl.deleteRecords();
			Test.stopTest();
		}
		System.assertEquals(APS_TO_CREATE, [SELECT COUNT() FROM ActionPlan__c]);
	}
}