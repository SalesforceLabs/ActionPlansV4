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
 * Test class for Section Header Visualforce Controller
 * @author {@link [David Schach](https://github.com/dschach)}
 * @since 2022
 * @see ActionPlansSectionHeaderController
 * @group Tests
 */
@IsTest
private class ActionPlansSectionHeaderControllerTest {
	/**
	 * Set up custom settings
	 */
	@TestSetup
	private static void makeData() {
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		User u = testUtil.createTestUser();
		testUtil.assignAPPermissionSets(u.Id, false);
	}

	@IsTest
	private static void objectTabDescribePositive() {
		User u = [SELECT Id FROM User WHERE Email = 'test@aptest.com' AND IsActive = TRUE LIMIT 1];

		System.runAs(u) {
			ActionPlansSectionHeaderController shc = new ActionPlansSectionHeaderController();
			shc.objectName = ActionPlansUtilities.namespacePrefix + 'ActionPlan__c';
			shc.getObjectIconInfo();
			Assert.isTrue(shc.getIsCustom(), 'ActionPlan is a custom object');

			shc = new ActionPlansSectionHeaderController();
			shc.objectName = 'Account';
			shc.getObjectIconInfo();
			Assert.isFalse(shc.getIsCustom(), 'Account is a standard object');
		}
	}

	@IsTest
	private static void objectTabDescribeNegative() {
		User u = [SELECT Id FROM User WHERE Email = 'test@aptest.com' LIMIT 1];

		System.runAs(u) {
			ActionPlansSectionHeaderController shc = new ActionPlansSectionHeaderController();
			shc.objectName = 'CaseComment';
			shc.getObjectIconInfo();
			Assert.isFalse(shc.getIsCustom(), 'CaseComment is a standard object');

			shc = new ActionPlansSectionHeaderController();
			shc.objectName = ActionPlansUtilities.namespacePrefix + 'APTask__c';
			shc.getObjectIconInfo();
			Assert.isTrue(shc.getIsCustom(), 'APTask is a custom object');
			Map<String, String> iconInfo = shc.getObjectIconInfo();
			Assert.areEqual(iconInfo.get('iconTag'), 'record', 'Should not be a tab/icon for APTask');
		}
	}

	@IsTest
	private static void objectTabDescribeNotInApplication() {
		User u = [SELECT Id FROM User WHERE Email = 'test@aptest.com' LIMIT 1];

		System.runAs(u) {
			ActionPlansSectionHeaderController shc = new ActionPlansSectionHeaderController();
			shc.objectName = 'Contract';
			shc.getObjectIconInfo();
			Assert.isFalse(shc.getIsCustom(), 'Contract is a standard object');
		}
	}

	@IsTest
	private static void nullObject() {
		User u = [SELECT Id FROM User WHERE Email = 'test@aptest.com' LIMIT 1];

		System.runAs(u) {
			ActionPlansSectionHeaderController shc = new ActionPlansSectionHeaderController();
			shc.objectName = null;
			shc.getIsCustom();
			shc.getObjectIconInfo();
			String nullIconTag = shc.getObjectIconInfo().get('iconTag');
			Assert.areEqual('record', nullIconTag, 'Should have reached null section of header controller');
		}

	}
}