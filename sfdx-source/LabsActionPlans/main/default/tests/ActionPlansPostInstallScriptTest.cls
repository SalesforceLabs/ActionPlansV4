/*
Action Plans v4
David Schach 2022
https://appexchange.salesforce.com/appxListingDetail?listingId=a0N4V00000Gg6NVUAZ

Copyright (c) 2022, salesforce.com, inc.
All rights reserved.
SPDX-License-Identifier: BSD-3-Clause
For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
*/
/**
 * Test for PostInstallScript Utility
 * @author {@link [David Schach](https://github.com/dschach)}
 * @since 2022
 * @see ActionPlansPostInstallScript
 * @group Tests
 */
@IsTest
private class ActionPlansPostInstallScriptTest {
	@isTest
	private static void installScript() {
		ActionPlansPostInstallScript postinstall = new ActionPlansPostInstallScript();
		Test.testInstall(postinstall, null);
		System.assertNotEquals(0, [SELECT COUNT() FROM ActionPlanTemplate__c]);
		System.assertEquals(true, Action_Plans_Settings__c.getInstance().Unassigned_Task_Assigned_to_Owner__c);
		Test.testInstall(postinstall, new Version(4, 0), false);
		Test.testInstall(postinstall, new Version(4, 0), true);
	}
}