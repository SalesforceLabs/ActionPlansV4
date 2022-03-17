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
	private static void testAccountTrigger() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		ActionPlan__c ap = testutil.createNewActionPlan('account', 1);
		Account a = [SELECT Id FROM Account WHERE Id = :ap.Account__c];

		// Verifies that action plans are deleted when removing related object
		Test.startTest();
		delete a;
		Test.stopTest();
		List<ActionPlan__c> lAp = [SELECT Id FROM ActionPlan__c WHERE Id = :ap.Id];
		System.assert(lAp.size() == 0);

		// Verifies catch is working fine
		ActionPlansTestUtilities.forceError = true;
		try {
			undelete a;
		} catch (Dmlexception e) {
			System.assert(e.getMessage().contains(System.Label.ap_RelObjUndeleteError));
		}
		ActionPlansTestUtilities.forceError = false;

		// Verifies that action plans are undeleted when restoring related object
		undelete a;
		lAp = [SELECT Id FROM ActionPlan__c WHERE Id = :ap.Id];
		System.assert(lAp.size() == 1);

		// Verifies that action plans that are in recycle bin are removed when deleting the related object
		delete ap;
		delete a;
		lAp = [SELECT Id, Name, LastModifiedDate FROM ActionPlan__c WHERE Account__c = :a.Id AND IsDeleted = TRUE ALL ROWS];
		System.assert(lAp.size() == 0);
	}

	@IsTest
	private static void testCampaignTrigger() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		ActionPlan__c ap = testutil.createNewActionPlan('campaign', 1);
		Campaign c = [SELECT Id FROM Campaign WHERE Id = :ap.Campaign__c];

		// Verifies that action plans are deleted when removing related object
		Test.startTest();
		delete c;
		Test.stopTest();
		List<ActionPlan__c> lAp = [SELECT Id FROM ActionPlan__c WHERE Id = :ap.Id];
		System.assert(lAp.size() == 0);

		// Verifies catch is working fine
		ActionPlansTestUtilities.forceError = true;
		try {
			undelete c;
		} catch (Dmlexception e) {
			System.assert(e.getMessage().contains(System.Label.ap_RelObjUndeleteError));
		}
		ActionPlansTestUtilities.forceError = false;

		// Verifies that action plans are undeleted when restoring related object
		undelete (c);
		lAp = [SELECT Id FROM ActionPlan__c WHERE Id = :ap.Id];
		System.assert(lAp.size() == 1);

		// Verifies that action plans that are in recycle bin are removed when deleting the related object
		delete ap;
		delete c;
		lAp = [SELECT Id, Name, LastModifiedDate FROM ActionPlan__c WHERE Campaign__c = :c.Id AND isDeleted = TRUE ALL ROWS];
		System.assert(lAp.size() == 0);
	}

	@IsTest
	private static void testCaseTrigger() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		ActionPlan__c ap = testutil.createNewActionPlan('case', 1);
		Case c = [SELECT Id FROM Case WHERE Id = :ap.Case__c];

		// Verifies that action plans are undeleted when restoring related object
		Test.startTest();
		delete c;
		Test.stopTest();
		List<ActionPlan__c> lAp = [SELECT Id FROM ActionPlan__c WHERE Id = :ap.Id];
		System.assert(lAp.size() == 0);

		// Verifies catch is working fine
		ActionPlansTestUtilities.forceError = true;
		try {
			undelete c;
		} catch (Dmlexception e) {
			System.assert(e.getMessage().contains(System.Label.ap_RelObjUndeleteError));
		}
		ActionPlansTestUtilities.forceError = false;

		// Verifies that action plans are undeleted when restoring related object
		undelete c;
		lAp = [SELECT Id FROM ActionPlan__c WHERE Id = :ap.Id];
		System.assert(lAp.size() == 1);

		// Verifies that action plans that are in recycle bin are removed when deleting the related object
		delete ap;
		delete c;
		lAp = [SELECT Id, Name, LastModifiedDate FROM ActionPlan__c WHERE Case__c = :c.Id AND isDeleted = TRUE ALL ROWS];
		System.assert(lAp.size() == 0);
	}

	@IsTest
	private static void testContactTrigger() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		ActionPlan__c ap = testutil.createNewActionPlan('contact', 1);
		Contact c = [SELECT Id FROM Contact WHERE Id = :ap.Contact__c];

		// Verifies that action plans are undeleted when restoring related object
		Test.startTest();
		delete c;
		Test.stopTest();
		List<ActionPlan__c> lAp = [SELECT Id FROM ActionPlan__c WHERE Id = :ap.Id];
		System.assert(lAp.size() == 0);

		// Verifies catch is working fine
		ActionPlansTestUtilities.forceError = true;
		try {
			undelete c;
		} catch (Dmlexception e) {
			System.assert(e.getMessage().contains(System.Label.ap_RelObjUndeleteError));
		}
		ActionPlansTestUtilities.forceError = false;

		// Verifies that action plans are undeleted when restoring related object
		undelete c;
		lAp = [SELECT Id FROM ActionPlan__c WHERE Id = :ap.Id];
		System.assert(lAp.size() == 1);

		// Verifies that action plans that are in recycle bin are removed when deleting the related object
		delete ap;
		delete c;
		lAp = [SELECT Id, Name, LastModifiedDate FROM ActionPlan__c WHERE Contact__c = :c.Id AND isDeleted = TRUE ALL ROWS];
		System.assert(lAp.size() == 0);
	}

	@IsTest
	private static void testContractTrigger() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		ActionPlan__c ap = testutil.createNewActionPlan('contract', 1);
		Contract c = [SELECT Id FROM Contract WHERE Id = :ap.Contract__c];

		// Verifies that action plans are undeleted when restoring related object
		Test.startTest();
		delete c;
		Test.stopTest();
		List<ActionPlan__c> lAp = [SELECT Id FROM ActionPlan__c WHERE Id = :ap.Id];
		System.assert(lAp.size() == 0);

		// Verifies catch is working fine
		ActionPlansTestUtilities.forceError = true;
		try {
			undelete c;
		} catch (Dmlexception e) {
			System.assert(e.getMessage().contains(System.Label.ap_RelObjUndeleteError));
		}
		ActionPlansTestUtilities.forceError = false;

		// Verifies that action plans are undeleted when restoring related object
		undelete c;
		lAp = [SELECT Id FROM ActionPlan__c WHERE Id = :ap.Id];
		System.assert(lAp.size() == 1);

		// Verifies that action plans that are in recycle bin are removed when deleting the related object
		delete ap;
		delete c;
		lAp = [SELECT Id, Name, LastModifiedDate FROM ActionPlan__c WHERE Contract__c = :c.Id AND isDeleted = TRUE ALL ROWS];
		System.assert(lAp.size() == 0);
	}

	@IsTest
	private static void testLeadTrigger() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		ActionPlan__c ap = testutil.createNewActionPlan('lead', 1);
		Lead l = [SELECT Id FROM Lead WHERE Id = :ap.Lead__c];

		// Verifies that action plans are undeleted when restoring related object
		Test.startTest();
		delete l;
		Test.stopTest();
		List<ActionPlan__c> lAp = [SELECT Id FROM ActionPlan__c WHERE Id = :ap.Id];
		System.assert(lAp.size() == 0);

		// Verifies catch is working fine
		ActionPlansTestUtilities.forceError = true;
		try {
			undelete l;
		} catch (Dmlexception e) {
			System.assert(e.getMessage().contains(System.Label.ap_RelObjUndeleteError));
		}
		ActionPlansTestUtilities.forceError = false;

		// Verifies that action plans are undeleted when restoring related object
		undelete l;
		lAp = [SELECT Id FROM ActionPlan__c WHERE Id = :ap.Id];
		System.assert(lAp.size() == 1);

		// Verifies that action plans that are in recycle bin are removed when deleting the related object
		delete ap;
		delete l;
		lAp = [SELECT Id, Name, LastModifiedDate FROM ActionPlan__c WHERE Lead__c = :l.Id AND isDeleted = TRUE ALL ROWS];
		System.assert(lAp.size() == 0);
	}

	@IsTest
	private static void testOpportunityTrigger() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		ActionPlan__c ap = testutil.createNewActionPlan('opportunity', 1);
		Opportunity o = [SELECT Id FROM Opportunity WHERE Id = :ap.Opportunity__c];

		// Verifies that action plans are undeleted when restoring related object
		Test.startTest();
		delete o;
		Test.stopTest();
		List<ActionPlan__c> lAp = [SELECT Id FROM ActionPlan__c WHERE Id = :ap.Id];
		System.assert(lAp.size() == 0);

		// Verifies catch is working fine
		ActionPlansTestUtilities.forceError = true;
		try {
			undelete o;
		} catch (Dmlexception e) {
			System.assert(e.getMessage().contains(System.Label.ap_RelObjUndeleteError));
		}
		ActionPlansTestUtilities.forceError = false;

		// Verifies that action plans are undeleted when restoring related object
		undelete o;
		lAp = [SELECT Id FROM ActionPlan__c WHERE Id = :ap.Id];
		System.assert(lAp.size() == 1);

		// Verifies that action plans that are in recycle bin are removed when deleting the related object
		delete ap;
		delete o;
		lAp = [SELECT Id, Name, LastModifiedDate FROM ActionPlan__c WHERE Opportunity__c = :o.Id AND isDeleted = TRUE ALL ROWS];
		System.assert(lAp.size() == 0);
	}

	@IsTest
	private static void testLeadConversionContact() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		User u = testutil.createTestUser();
		testutil.assignAPPermissionSets(u.Id, true);

		System.runAs(new User(Id = UserInfo.getUserId())) {
			testutil.createNewActionPlan('lead', 1);
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
			System.assertEquals(1, [SELECT COUNT() FROM ActionPlan__c WHERE Lead__c != NULL]);
			System.assertEquals(l.Id, [SELECT Lead__c FROM ActionPlan__c LIMIT 1].Lead__c, 'Our only lead should be on this action plan');

			Database.LeadConvert lc = new Database.LeadConvert();
			lc.setDoNotCreateOpportunity(true);
			lc.setLeadId(l.id);

			LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
			lc.setConvertedStatus(convertStatus.MasterLabel);

			Database.LeadConvertResult lcr = Database.convertLead(lc);
			System.assert(lcr.isSuccess());
		}

		Test.stopTest();

		System.assertEquals(1, [SELECT COUNT() FROM ActionPlan__c WHERE Contact__c != NULL]);
	}

	@IsTest
	private static void testLeadConversionAccount() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		User u = testutil.createTestUser();
		testutil.assignAPPermissionSets(u.Id, true);

		System.runAs(new User(Id = UserInfo.getUserId())) {
			testutil.createNewActionPlan('lead', 1);
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

			System.assert(Schema.sObjectType.ActionPlan__c.fields.Account__c.isUpdateable());

			System.assertEquals(0, [SELECT COUNT() FROM Account]);
			System.assertEquals(1, [SELECT COUNT() FROM ActionPlan__c WHERE Lead__c != NULL]);

			Database.LeadConvert lc = new Database.LeadConvert();
			lc.setDoNotCreateOpportunity(true);
			lc.setLeadId(l.id);

			LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
			lc.setConvertedStatus(convertStatus.MasterLabel);

			Database.LeadConvertResult lcr = Database.convertLead(lc);
			System.assert(lcr.isSuccess());
			System.assertEquals(1, [SELECT COUNT() FROM Account]);
			System.debug('ActionPlan by test user: ' + [SELECT Id, Account__c, Contact__c, Lead__c FROM ActionPlan__c]);
		}
		Test.stopTest();

		System.debug('ActionPlan by my user: ' + [SELECT Id, Account__c, Contact__c, Lead__c FROM ActionPlan__c]);

		System.assertEquals(1, [SELECT COUNT() FROM ActionPlan__c WHERE Account__c != NULL]);
	}

	@IsTest
	private static void testLeadConversionOpportunity() {
		ActionPlansTestUtilities testutil = new ActionPlansTestUtilities();
		User u = testutil.createTestUser();
		//testutil.assignAPPermissionSets(u.Id, true);

		System.runAs(new User(Id = UserInfo.getUserId())) {
			testutil.createNewActionPlan('lead', 1);
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

			System.assertEquals(1, [SELECT COUNT() FROM ActionPlan__c WHERE Lead__c != NULL]);

			Database.LeadConvert lc = new Database.LeadConvert();
			lc.setDoNotCreateOpportunity(false);
			lc.setLeadId(l.id);

			LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
			lc.setConvertedStatus(convertStatus.MasterLabel);

			Database.LeadConvertResult lcr = Database.convertLead(lc);
			System.assert(lcr.isSuccess());
		}

		Test.stopTest();

		System.assertEquals(1, [SELECT COUNT() FROM ActionPlan__c WHERE Opportunity__c != NULL]);
	}
}