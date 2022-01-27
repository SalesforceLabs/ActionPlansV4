/**
 * Action Plans v4
 * @author David Schach
 * @since 2021
 * @group Tests
 * @see ActionPlanTemplateExport
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

		System.assert(xmlId != null);
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

		System.assert(xmlId != null);
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

		System.assert(xmlId != null);
	}
}