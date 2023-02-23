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
 * Tests for Template Export
 * @author {@link [David Schach](https://github.com/dschach)}
 * @since 2022
 * @since 2023 System.assert to Assert class + error messages
 * @group Tests
 * @see ActionPlanTemplateExport
 * @see ActionPlanTemplateImportController
 */
@IsTest
private class ActionPlanTemplateExportTest {
	@IsTest
	private static void exportTest() {
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c actionPlanTemplate = testUtil.createNewActionPlanTemplate(3);

		ActionPlanTemplateExport exportTemplate = new ActionPlanTemplateExport(actionPlanTemplate.Id);
		Id xmlId = exportTemplate.export();

		Test.stopTest();

		Assert.areNotEqual(null, xmlId, 'Should have successfully created a Template with an Id');
	}

	@IsTest
	private static void exportDocTest() {
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c actionPlanTemplate = testUtil.createNewActionPlanTemplate(3);

		ActionPlanTemplateExport exportTemplate = new ActionPlanTemplateExport(actionPlanTemplate.Id);
		String xml = exportTemplate.buildXmlString(actionPlanTemplate);

		Id xmlId = exportTemplate.saveToDocument('templateName', xml);

		Test.stopTest();

		Assert.areNotEqual(null, xmlId, 'Should have successfully created a Document with an Id');
	}

	@IsTest
	private static void exportFileTest() {
		Test.startTest();

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlanTemplate__c actionPlanTemplate = testUtil.createNewActionPlanTemplate(3);

		ActionPlanTemplateExport exportTemplate = new ActionPlanTemplateExport(actionPlanTemplate.Id);
		String xml = exportTemplate.buildXmlString(actionPlanTemplate);

		Id xmlId = exportTemplate.saveToContent('templateName', xml);

		Test.stopTest();

		Assert.areNotEqual(null, xmlId, 'Should have successfully created a File with an Id');
	}
}