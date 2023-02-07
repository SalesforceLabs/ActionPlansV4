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
 * @see ActionPlansDeleteMultipleAPsExtension
 * @group Tests
 */
@IsTest
private class ActionPlansDeleteMultipleAPExtTest {
	private static final Integer APS_TO_CREATE = 100;

	@testSetup
	private static void datasetup() {
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		User testUser;
		User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
		System.runAs(currentUser) {
			testUser = testUtil.createAdminUser();
		}

		List<ActionPlan__c> apToInsert = new List<ActionPlan__c>();
		List<APTask__c> apttToInsert = new List<APTask__c>();

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
				APTask__c newAPTask = testUtil.createNewActionPlanTask(newActionPlan, j + 1, testUser.Id, null, null);
				apttToInsert.add(newAPTask);
			}
		}

		insert apttToInsert;
	}

	@IsTest
	private static void givenRecordsToDeleteThenDeleted() {
		List<ActionPlan__c> listActionPlan = [SELECT Id, Name FROM ActionPlan__c];
		Assert.areEqual(APS_TO_CREATE, [SELECT COUNT() FROM ActionPlan__c]);
		ApexPages.StandardSetController std = new ApexPages.StandardSetController(listActionPlan);
		std.setSelected(new List<ActionPlan__c>{ listActionPlan[0], listActionPlan[1] });
		ActionPlansDeleteMultipleAPExtension ctrl = new ActionPlansDeleteMultipleAPExtension(std);

		Test.startTest();
		ctrl.deleteRecords();
		Test.stopTest();
		Assert.areEqual(APS_TO_CREATE - 2, [SELECT COUNT() FROM ActionPlan__c]);
	}

	@IsTest
	private static void givenNoRecordsToDeleteThenNotDeleted() {
		List<ActionPlan__c> listActionPlan = [SELECT Id, Name FROM ActionPlan__c];
		Assert.areEqual(APS_TO_CREATE, [SELECT COUNT() FROM ActionPlan__c]);
		ApexPages.StandardSetController std = new ApexPages.StandardSetController(listActionPlan);
		std.setSelected(new List<ActionPlan__c>{});
		ActionPlansDeleteMultipleAPExtension ctrl = new ActionPlansDeleteMultipleAPExtension(std);

		Test.startTest();
		ctrl.deleteRecords();
		Test.stopTest();

		Assert.areEqual(APS_TO_CREATE, [SELECT COUNT() FROM ActionPlan__c]);
		Assert.areEqual(null, ctrl.deleteRecords());
	}

	@IsTest
	private static void noDeletePermission() {
		User minAccessUser;

		User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
		System.runAs(currentUser) {
			Id pId = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce'].Id;
			minAccessUser = new User(
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
		}

		System.runAs(minAccessUser) {
			List<ActionPlan__c> listActionPlan = [SELECT Id, Name FROM ActionPlan__c];
			Assert.areEqual(APS_TO_CREATE, [SELECT COUNT() FROM ActionPlan__c]);
			ApexPages.StandardSetController std = new ApexPages.StandardSetController(listActionPlan);
			std.setSelected(new List<ActionPlan__c>{ listActionPlan[0], listActionPlan[1] });
			ActionPlansDeleteMultipleAPExtension ctrl = new ActionPlansDeleteMultipleAPExtension(std);
			Test.startTest();
			ctrl.deleteRecords();
			Test.stopTest();
		}
		Assert.areEqual(APS_TO_CREATE, [SELECT COUNT() FROM ActionPlan__c]);
	}
}