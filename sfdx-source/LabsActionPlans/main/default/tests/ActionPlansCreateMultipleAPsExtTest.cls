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
 * Tests for the Visualforce controller extension for the button to enable creation of multiple action plans for all checked records in a list view
 * @author {@link [David Schach](https://github.com/dschach)}
 * @see ActionPlansCreateMultipleAPsExtension
 * @group Tests
 */
@IsTest
private class ActionPlansCreateMultipleAPsExtTest {
	@IsTest
	private static void givenRecordsToCreateThenCreated() {
		List<Account> accts = new List<Account>();
		for (Integer i = 0; i < 20; i++) {
			Account newAccount = new Account();
			newAccount.Name = 'acc' + math.rint(math.random() * 100000);
			accts.add(newAccount);
		}

		Database.DMLOptions dml = new Database.DMLOptions();
		dml.DuplicateRuleHeader.allowSave = true;
		dml.DuplicateRuleHeader.runAsCurrentUser = true;
		List<Database.SaveResult> sr = Database.insert(accts, dml);
		System.assert(!sr.isEmpty(), 'We attempted to save at least one record');
		ApexPages.StandardSetController std = new ApexPages.StandardSetController(accts);
		std.setSelected(accts);
		ActionPlansCreateMultipleAPsExtension ctrl = new ActionPlansCreateMultipleAPsExtension(std);

		PageReference newAPPage = ctrl.doRedirect();

		System.assert(newAPPage.geturl().containsIgnoreCase('%2C0'));
	}

	@IsTest
	private static void givenNoRecordsToCreateThenNotCreated() {
		Test.startTest();
		ApexPages.StandardSetController std = new ApexPages.StandardSetController(new List<Account>{});
		ActionPlansCreateMultipleAPsExtension ctrl = new ActionPlansCreateMultipleAPsExtension(std);

		PageReference newAPPage = ctrl.doRedirect();
		Test.stopTest();

		System.assertEquals(null, newAPPage);
	}
}