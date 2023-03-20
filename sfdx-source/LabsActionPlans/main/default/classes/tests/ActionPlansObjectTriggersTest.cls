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
 * Tests for trigger handlers
 * @author {@link [David Schach](https://github.com/dschach)}
 * @see ActionPlansTriggerHandlers
 * @group Tests
 */
@IsTest
private class ActionPlansObjectTriggersTest {
	private static Action_Plans_Settings__c aps;
	/**
	 * Set up custom settings
	 */
	@TestSetup
	private static void makeData() {
		aps = Action_Plans_Settings__c.getOrgDefaults();
		aps.Chatter_Object_Brag__c = true;
		aps.Default_Object_on_Lead_Conversion__c = 'Contact';
		try {
			upsert aps;
		} catch (Exception e) {
			update aps;
		}
	}

	@IsTest
	private static void accountTrigger() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		ActionPlan__c ap = testutil.createNewActionPlan('account', 1, null);
		Account a = [SELECT Id FROM Account WHERE Id = :ap.Account__c];

		// Verifies that action plans are deleted when removing related object
		Test.startTest();
		delete a;
		Test.stopTest();
		List<ActionPlan__c> lAp = [SELECT Id FROM ActionPlan__c WHERE Id = :ap.Id];
		Assert.isTrue(lAp.isEmpty(), 'Should not have any Action Plans left');

		// Verifies catch is working fine
		ActionPlansTestUtilities.forceError = true;
		try {
			undelete a;
			Assert.fail('Should not have been successful undelete');
		} catch (Exception e) {
			Assert.isInstanceOfType(e, DmlException.class, 'Should have been a DML Exception');
			Assert.isTrue(e.getMessage().contains(System.Label.ap_RelObjUndeleteError), ' Undelete error message is wrong');
		}
		ActionPlansTestUtilities.forceError = false;

		// Verifies that action plans are undeleted when restoring related object
		undelete a;
		Assert.areEqual(1, [SELECT COUNT() FROM ActionPlan__c WHERE IsDeleted = FALSE], 'We should have 1 Action Plan undeleted with the campaign');
		System.debug([SELECT Id, IsDeleted, Name FROM ActionPlan__c ALL ROWS]);
		// Verifies that action plans that are in recycle bin are removed when deleting the related object
		delete ap;
		Assert.areEqual(0, [SELECT COUNT() FROM ActionPlan__c WHERE IsDeleted = FALSE], 'We should have deleted our Action Plan');
		Assert.areEqual(1, [SELECT COUNT() FROM ActionPlan__c WHERE IsDeleted = TRUE ALL ROWS], 'No Action Plan in the recycle bin');
		delete a;
	}

	@IsTest
	private static void campaignTrigger() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		ActionPlan__c ap = testutil.createNewActionPlan('campaign', 1, null);
		Campaign c = [SELECT Id FROM Campaign WHERE Id = :ap.Campaign__c];

		// Verifies that action plans are deleted when removing related object
		Test.startTest();
		delete c;
		Test.stopTest();
		List<ActionPlan__c> lAp = [SELECT Id FROM ActionPlan__c WHERE Id = :ap.Id];
		Assert.isTrue(lAp.isEmpty(), 'Should not have any Action Plans left');

		// Verifies catch is working fine
		ActionPlansTestUtilities.forceError = true;
		try {
			undelete c;
			Assert.fail('Should not have been successful undelete');
		} catch (Exception e) {
			Assert.isInstanceOfType(e, DmlException.class, 'Should have been a DML Exception');
			Assert.isTrue(e.getMessage().contains(System.Label.ap_RelObjUndeleteError), ' Undelete error message is wrong');
		}
		ActionPlansTestUtilities.forceError = false;

		// Verifies that action plans are undeleted when restoring related object
		undelete (c);

		Assert.areEqual(1, [SELECT COUNT() FROM ActionPlan__c WHERE IsDeleted = FALSE], 'We should have 1 Action Plan undeleted with the campaign');
		System.debug([SELECT Id, IsDeleted, Name FROM ActionPlan__c ALL ROWS]);
		// Verifies that action plans that are in recycle bin are removed when deleting the related object
		delete ap;
		Assert.areEqual(0, [SELECT COUNT() FROM ActionPlan__c WHERE IsDeleted = FALSE], 'We should have deleted our Action Plan');
		Assert.areEqual(1, [SELECT COUNT() FROM ActionPlan__c WHERE IsDeleted = TRUE ALL ROWS], 'No Action Plan in the recycle bin');
		delete c;
	}

	@IsTest
	private static void caseTrigger() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		ActionPlan__c ap = testutil.createNewActionPlan('case', 1, null);
		Case c = [SELECT Id FROM Case WHERE Id = :ap.Case__c];

		// Verifies that action plans are undeleted when restoring related object
		Test.startTest();
		delete c;
		Test.stopTest();
		List<ActionPlan__c> lAp = [SELECT Id FROM ActionPlan__c WHERE Id = :ap.Id];
		Assert.isTrue(lAp.isEmpty(), 'Should not have any Action Plans left');

		// Verifies catch is working fine
		ActionPlansTestUtilities.forceError = true;
		try {
			undelete c;
			Assert.fail('Should not have been successful undelete');
		} catch (Exception e) {
			Assert.isInstanceOfType(e, DmlException.class, 'Should have been a DML Exception');
			Assert.isTrue(e.getMessage().contains(System.Label.ap_RelObjUndeleteError), ' Undelete error message is wrong');
		}
		ActionPlansTestUtilities.forceError = false;

		// Verifies that action plans are undeleted when restoring related object
		undelete c;

		Assert.areEqual(1, [SELECT COUNT() FROM ActionPlan__c WHERE IsDeleted = FALSE], 'We should have 1 Action Plan undeleted with the campaign');
		System.debug([SELECT Id, IsDeleted, Name FROM ActionPlan__c ALL ROWS]);
		// Verifies that action plans that are in recycle bin are removed when deleting the related object
		delete ap;
		Assert.areEqual(0, [SELECT COUNT() FROM ActionPlan__c WHERE IsDeleted = FALSE], 'We should have deleted our Action Plan');
		Assert.areEqual(1, [SELECT COUNT() FROM ActionPlan__c WHERE IsDeleted = TRUE ALL ROWS], 'No Action Plan in the recycle bin');
		delete c;
	}

	@IsTest
	private static void contactTrigger() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		ActionPlan__c ap = testutil.createNewActionPlan('contact', 1, null);
		Contact c = [SELECT Id FROM Contact WHERE Id = :ap.Contact__c];

		// Verifies that action plans are undeleted when restoring related object
		Test.startTest();
		delete c;
		Test.stopTest();
		List<ActionPlan__c> lAp = [SELECT Id FROM ActionPlan__c WHERE Id = :ap.Id];
		Assert.isTrue(lAp.isEmpty(), 'Should not have any Action Plans left');

		// Verifies catch is working fine
		ActionPlansTestUtilities.forceError = true;
		try {
			undelete c;
			Assert.fail('Should not have been successful undelete');
		} catch (Exception e) {
			Assert.isInstanceOfType(e, DmlException.class, 'Should have been a DML Exception');
			Assert.isTrue(e.getMessage().contains(System.Label.ap_RelObjUndeleteError), ' Undelete error message is wrong');
		}
		ActionPlansTestUtilities.forceError = false;

		// Verifies that action plans are undeleted when restoring related object
		undelete c;

		Assert.areEqual(1, [SELECT COUNT() FROM ActionPlan__c WHERE IsDeleted = FALSE], 'We should have 1 Action Plan undeleted with the campaign');
		System.debug([SELECT Id, IsDeleted, Name FROM ActionPlan__c ALL ROWS]);
		// Verifies that action plans that are in recycle bin are removed when deleting the related object
		delete ap;
		Assert.areEqual(0, [SELECT COUNT() FROM ActionPlan__c WHERE IsDeleted = FALSE], 'We should have deleted our Action Plan');
		Assert.areEqual(1, [SELECT COUNT() FROM ActionPlan__c WHERE IsDeleted = TRUE ALL ROWS], 'No Action Plan in the recycle bin');
		delete c;
	}

	@IsTest
	private static void contractTrigger() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		ActionPlan__c ap = testutil.createNewActionPlan('contract', 1, null);
		Contract c = [SELECT Id FROM Contract WHERE Id = :ap.Contract__c];

		// Verifies that action plans are undeleted when restoring related object
		Test.startTest();
		delete c;
		Test.stopTest();
		List<ActionPlan__c> lAp = [SELECT Id FROM ActionPlan__c WHERE Id = :ap.Id];
		Assert.isTrue(lAp.isEmpty(), 'Should not have any Action Plans left');

		// Verifies catch is working fine
		ActionPlansTestUtilities.forceError = true;
		try {
			undelete c;
			Assert.fail('Should not have been successful undelete');
		} catch (Exception e) {
			Assert.isInstanceOfType(e, DmlException.class, 'Should have been a DML Exception');
			Assert.isTrue(e.getMessage().contains(System.Label.ap_RelObjUndeleteError), ' Undelete error message is wrong');
		}
		ActionPlansTestUtilities.forceError = false;

		// Verifies that action plans are undeleted when restoring related object
		undelete c;

		Assert.areEqual(1, [SELECT COUNT() FROM ActionPlan__c WHERE IsDeleted = FALSE], 'We should have 1 Action Plan undeleted with the campaign');
		System.debug([SELECT Id, IsDeleted, Name FROM ActionPlan__c ALL ROWS]);
		// Verifies that action plans that are in recycle bin are removed when deleting the related object
		delete ap;
		Assert.areEqual(0, [SELECT COUNT() FROM ActionPlan__c WHERE IsDeleted = FALSE], 'We should have deleted our Action Plan');
		Assert.areEqual(1, [SELECT COUNT() FROM ActionPlan__c WHERE IsDeleted = TRUE ALL ROWS], 'No Action Plan in the recycle bin');
		delete c;
	}

	@IsTest
	private static void leadTrigger() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		ActionPlan__c ap = testutil.createNewActionPlan('lead', 1, null);
		Lead l = [SELECT Id FROM Lead WHERE Id = :ap.Lead__c];

		// Verifies that action plans are undeleted when restoring related object
		Test.startTest();
		delete l;
		Test.stopTest();
		List<ActionPlan__c> lAp = [SELECT Id FROM ActionPlan__c WHERE Id = :ap.Id];
		Assert.isTrue(lAp.isEmpty(), 'Should not have any Action Plans left');

		// Verifies catch is working fine
		ActionPlansTestUtilities.forceError = true;
		try {
			undelete l;
			Assert.fail('Should not have been successful undelete');
		} catch (Exception e) {
			Assert.isInstanceOfType(e, DmlException.class, 'Should have been a DML Exception');
			Assert.isTrue(e.getMessage().contains(System.Label.ap_RelObjUndeleteError), ' Undelete error message is wrong');
		}
		ActionPlansTestUtilities.forceError = false;

		// Verifies that action plans are undeleted when restoring related object
		undelete l;

		Assert.areEqual(1, [SELECT COUNT() FROM ActionPlan__c WHERE IsDeleted = FALSE], 'We should have 1 Action Plan undeleted with the campaign');
		System.debug([SELECT Id, IsDeleted, Name FROM ActionPlan__c ALL ROWS]);
		// Verifies that action plans that are in recycle bin are removed when deleting the related object
		delete ap;
		Assert.areEqual(0, [SELECT COUNT() FROM ActionPlan__c WHERE IsDeleted = FALSE], 'We should have deleted our Action Plan');
		Assert.areEqual(1, [SELECT COUNT() FROM ActionPlan__c WHERE IsDeleted = TRUE ALL ROWS], 'No Action Plan in the recycle bin');
		delete l;
	}

	@IsTest
	private static void opportunityTrigger() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		ActionPlan__c ap = testutil.createNewActionPlan('opportunity', 1, null);
		Opportunity o = [SELECT Id FROM Opportunity WHERE Id = :ap.Opportunity__c];

		// Verifies that action plans are undeleted when restoring related object
		Test.startTest();
		delete o;
		Test.stopTest();
		List<ActionPlan__c> lAp = [SELECT Id FROM ActionPlan__c WHERE Id = :ap.Id];
		Assert.isTrue(lAp.isEmpty(), 'Should not have any Action Plans left');

		// Verifies catch is working fine
		ActionPlansTestUtilities.forceError = true;
		try {
			undelete o;
			Assert.fail('Should not have been successful undelete');
		} catch (Exception e) {
			Assert.isInstanceOfType(e, DmlException.class, 'Should have been a DML Exception');
			Assert.isTrue(e.getMessage().contains(System.Label.ap_RelObjUndeleteError), ' Undelete error message is wrong');
		}
		ActionPlansTestUtilities.forceError = false;

		// Verifies that action plans are undeleted when restoring related object
		undelete o;

		Assert.areEqual(1, [SELECT COUNT() FROM ActionPlan__c WHERE IsDeleted = FALSE], 'We should have 1 Action Plan undeleted with the campaign');
		System.debug([SELECT Id, IsDeleted, Name FROM ActionPlan__c ALL ROWS]);
		// Verifies that action plans that are in recycle bin are removed when deleting the related object
		delete ap;
		Assert.areEqual(0, [SELECT COUNT() FROM ActionPlan__c WHERE IsDeleted = FALSE], 'We should have deleted our Action Plan');
		Assert.areEqual(1, [SELECT COUNT() FROM ActionPlan__c WHERE IsDeleted = TRUE ALL ROWS], 'No Action Plan in the recycle bin');
		delete o;
	}

	@IsTest
	private static void leadConversionContact() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		User u = testutil.createTestUser();
		testutil.assignAPPermissionSets(u.Id, true);

		System.runAs(new User(Id = UserInfo.getUserId())) {
			testutil.createNewActionPlan('lead', 1, null);
		}

		Test.startTest();
		System.runAs(u) {
			Action_Plans_Settings__c aps = Action_Plans_Settings__c.getInstance();
			aps.Default_Object_on_Lead_Conversion__c = 'Contact';
			try {
				upsert aps;
			} catch (Exception e) {
				update aps;
			}
			Lead l = [SELECT Id FROM Lead LIMIT 1];
			Assert.areEqual(1, [SELECT COUNT() FROM ActionPlan__c WHERE Lead__c != NULL], 'Incorrect number of Action Plans created');
			Assert.areEqual(l.Id, [SELECT Lead__c FROM ActionPlan__c LIMIT 1].Lead__c, 'Our only lead should be on this action plan');

			Database.LeadConvert lc = new Database.LeadConvert();
			lc.setDoNotCreateOpportunity(true);
			lc.setLeadId(l.id);

			LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
			lc.setConvertedStatus(convertStatus.MasterLabel);

			Database.LeadConvertResult lcr = Database.convertLead(lc);
			Assert.isTrue(lcr.isSuccess(), 'Lead conversion failed');
		}

		Test.stopTest();

		Assert.areEqual(1, [SELECT COUNT() FROM ActionPlan__c WHERE Contact__c != NULL], 'Incorrect number of Action Plans created');
	}

	@IsTest
	private static void leadConversionAccount() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		User u = testutil.createTestUser();
		testutil.assignAPPermissionSets(u.Id, true);

		System.runAs(new User(Id = UserInfo.getUserId())) {
			testutil.createNewActionPlan('lead', 1, null);
		}

		Test.startTest();
		System.runAs(u) {
			Lead l = [SELECT Id FROM Lead LIMIT 1];
			Action_Plans_Settings__c aps = Action_Plans_Settings__c.getInstance();
			aps.Default_Object_on_Lead_Conversion__c = 'Account';
			try {
				upsert aps;
			} catch (Exception e) {
				System.debug('exception on settings upsert. updating. ' + e.getMessage());
				update aps;
			}

			Assert.isTrue(Schema.sObjectType.ActionPlan__c.fields.Account__c.isUpdateable(), 'User unable to update Account field - cannot link Action Plan to Account');

			Assert.areEqual(0, [SELECT COUNT() FROM Account], 'Incorrect number of Accounts found');
			Assert.areEqual(1, [SELECT COUNT() FROM ActionPlan__c WHERE Lead__c != NULL], 'Incorrect number of Action Plans created');

			Database.LeadConvert lc = new Database.LeadConvert();
			lc.setDoNotCreateOpportunity(true);
			lc.setLeadId(l.id);

			LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
			lc.setConvertedStatus(convertStatus.MasterLabel);

			Database.LeadConvertResult lcr = Database.convertLead(lc);
			Assert.isTrue(lcr.isSuccess(), 'Lead conversion failed');
			Assert.areEqual(1, [SELECT COUNT() FROM Account], 'Incorrect number of Accounts found');
			System.debug('ActionPlan by test user: ' + [SELECT Id, Account__c, Contact__c, Lead__c FROM ActionPlan__c]);
		}
		Test.stopTest();

		System.debug('ActionPlan by my user: ' + [SELECT Id, Account__c, Contact__c, Lead__c FROM ActionPlan__c]);

		Assert.areEqual(1, [SELECT COUNT() FROM ActionPlan__c WHERE Account__c != NULL], 'Incorrect number of Action Plans created');
	}

	@IsTest
	private static void leadConversionOpportunity() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		User u = testutil.createTestUser();
		//testutil.assignAPPermissionSets(u.Id, true);

		System.runAs(new User(Id = UserInfo.getUserId())) {
			testutil.createNewActionPlan('lead', 1, null);
		}

		Test.startTest();
		System.runAs(u) {
			Lead l = [SELECT Id FROM Lead LIMIT 1];
			Action_Plans_Settings__c aps = ActionPlansUtilities.getCustomSetting();
			aps.Default_Object_on_Lead_Conversion__c = 'Opportunity';
			try {
				upsert aps;
			} catch (Exception e) {
				update aps;
			}

			Assert.areEqual(1, [SELECT COUNT() FROM ActionPlan__c WHERE Lead__c != NULL], 'Incorrect number of Action Plans created');

			Database.LeadConvert lc = new Database.LeadConvert();
			lc.setDoNotCreateOpportunity(false);
			lc.setLeadId(l.id);

			LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
			lc.setConvertedStatus(convertStatus.MasterLabel);

			Database.LeadConvertResult lcr = Database.convertLead(lc);
			Assert.isTrue(lcr.isSuccess(), 'Lead conversion failed');
		}

		Test.stopTest();

		Assert.areEqual(1, [SELECT COUNT() FROM ActionPlan__c WHERE Opportunity__c != NULL], 'Incorrect number of Action Plans created');
	}
}